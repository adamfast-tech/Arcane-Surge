class_name Cloud
extends Node
## Compte Académie et sauvegarde en ligne (Supabase, projet partagé avec les apps Académie).
## Connexion identique aux apps : pseudo ou e-mail -> rpc/resolve_login -> jeton (mot de passe).
## Tables : public.profiles (pseudo), public.arcane_saves (progression, protégée par RLS).

signal status_changed

const URL := "https://cfcygkmrpxcjideljxxo.supabase.co"
const KEY := "sb_publishable_i68zVFGjYsUyKef3b3p4Zw_x_COmUOS"
const SESSION_PATH := "user://session.json"

static var instance: Cloud

var status := "offline" ## offline, connecting, online, error
var message := ""
var access_token := ""
var refresh_token := ""
var user_id := ""
var username := ""
var _push_pending := false
var _pushing := false


func _enter_tree() -> void:
	instance = self


func is_online() -> bool:
	return status == "online"


func _set_status(s: String, msg: String = "") -> void:
	status = s
	message = msg
	status_changed.emit()


# ---------------------------------------------------------------- HTTP

func _request(method: int, path: String, body: Variant = null, use_auth: bool = true, extra: Array[String] = []) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 15.0
	add_child(http)
	var headers := PackedStringArray(["apikey: " + KEY, "Content-Type: application/json", "Accept: application/json"])
	if use_auth and access_token != "":
		headers.append("Authorization: Bearer " + access_token)
	for h in extra:
		headers.append(h)
	var payload := "" if body == null else JSON.stringify(body)
	var err := http.request(URL + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "code": 0, "data": null}
	var res: Array = await http.request_completed
	http.queue_free()
	var code: int = res[1]
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	var data: Variant = null
	if text != "":
		data = JSON.parse_string(text)
	return {"ok": int(res[0]) == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300, "code": code, "data": data}


## Requête authentifiée : rafraîchit la session une fois si le jeton a expiré.
func _authed(method: int, path: String, body: Variant = null, extra: Array[String] = []) -> Dictionary:
	var r := await _request(method, path, body, true, extra)
	if int(r["code"]) == 401 and refresh_token != "":
		if await _refresh():
			r = await _request(method, path, body, true, extra)
	return r


# ---------------------------------------------------------------- session

## Retourne "" si la connexion réussit, sinon un message d'erreur.
func login(identifier: String, password: String) -> String:
	_set_status("connecting")
	var r := await _request(HTTPClient.METHOD_POST, "/rest/v1/rpc/resolve_login", {"p_login": identifier.strip_edges(), "p_password": password}, false)
	if int(r["code"]) == 0:
		_set_status("error", "Serveur injoignable")
		return message
	var email := "" if r["data"] == null else str(r["data"])
	if not r["ok"] or email == "" or email == "<null>":
		_set_status("offline", "Identifiant ou mot de passe incorrect")
		return message
	var t := await _request(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=password", {"email": email, "password": password}, false)
	if not t["ok"] or not (t["data"] is Dictionary):
		_set_status("offline", "Identifiant ou mot de passe incorrect")
		return message
	_apply_session(t["data"])
	await _fetch_username()
	_save_session()
	_set_status("online")
	return ""


## Reprend la session enregistrée (jeton de rafraîchissement). Retourne true si connecté.
func resume() -> bool:
	if not FileAccess.file_exists(SESSION_PATH):
		return false
	var f := FileAccess.open(SESSION_PATH, FileAccess.READ)
	var s: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
	if not (s is Dictionary):
		return false
	refresh_token = str(s.get("refresh_token", ""))
	username = str(s.get("username", ""))
	user_id = str(s.get("user_id", ""))
	if refresh_token == "":
		return false
	_set_status("connecting")
	if not await _refresh():
		_set_status("offline", "Session expirée : reconnecte-toi")
		return false
	await _fetch_username()
	_save_session()
	_set_status("online")
	return true


func logout() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
	username = ""
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(SESSION_PATH)
	_set_status("offline")


func _refresh() -> bool:
	var t := await _request(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=refresh_token", {"refresh_token": refresh_token}, false)
	if not t["ok"] or not (t["data"] is Dictionary):
		return false
	_apply_session(t["data"])
	_save_session()
	return true


func _apply_session(d: Dictionary) -> void:
	access_token = str(d.get("access_token", ""))
	refresh_token = str(d.get("refresh_token", refresh_token))
	var u: Variant = d.get("user", {})
	if u is Dictionary:
		user_id = str(u.get("id", user_id))


func _save_session() -> void:
	var f := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"refresh_token": refresh_token, "user_id": user_id, "username": username}))


func _fetch_username() -> void:
	if user_id == "":
		return
	var r := await _authed(HTTPClient.METHOD_GET, "/rest/v1/profiles?select=username&id=eq." + user_id)
	if r["ok"] and r["data"] is Array and not (r["data"] as Array).is_empty():
		username = str(r["data"][0].get("username", username))


# ---------------------------------------------------------------- sauvegarde

## Récupère la sauvegarde en ligne et garde la plus récente des deux (locale ou en ligne).
func sync_pull() -> void:
	if not is_online():
		return
	var r := await _authed(HTTPClient.METHOD_GET, "/rest/v1/arcane_saves?select=data&user_id=eq." + user_id)
	if not r["ok"]:
		message = "Sauvegarde en ligne indisponible"
		status_changed.emit()
		return
	var rows: Array = r["data"] if r["data"] is Array else []
	if not rows.is_empty() and rows[0].get("data") is Dictionary:
		var remote: Dictionary = rows[0]["data"]
		# La progression la plus avancée l'emporte (à égalité : la plus récente). L'autre est
		# gardée en copie de secours, ici et dans l'historique du serveur.
		var lp := Profile.progress_of(Profile.data)
		var rp := Profile.progress_of(remote)
		if prefer_remote(Profile.data, remote):
			if lp > 0.0:
				Profile.backup(Profile.data, "appareil")
			Profile.replace_with(remote)
			Profile.save_local()
			message = "Progression récupérée depuis ton compte"
			status_changed.emit()
			return
		if rp > 0.0:
			Profile.backup(remote, "compte")
		if lp > rp:
			message = "Progression de cet appareil envoyée sur ton compte"
	await push()


## Vrai si la sauvegarde du compte doit remplacer celle de l'appareil : la plus avancée gagne,
## la plus récente seulement à progression égale.
static func prefer_remote(local: Dictionary, remote: Dictionary) -> bool:
	var lp := Profile.progress_of(local)
	var rp := Profile.progress_of(remote)
	if not is_equal_approx(lp, rp):
		return rp > lp
	return float(remote.get("updated", 0.0)) > float(local.get("updated", 0.0))


## Envoie la progression locale (regroupe les envois rapprochés).
func push() -> void:
	if not is_online():
		return
	if _pushing:
		_push_pending = true
		return
	_pushing = true
	var body := {"user_id": user_id, "data": Profile.data, "version": Profile.VERSION, "updated_at": Time.get_datetime_string_from_system(true) + "Z"}
	var r := await _authed(HTTPClient.METHOD_POST, "/rest/v1/arcane_saves?on_conflict=user_id", body,
		["Prefer: resolution=merge-duplicates,return=minimal"])
	_pushing = false
	message = "Synchronisé" if r["ok"] else "Échec de la synchronisation (code %d)" % int(r["code"])
	status_changed.emit()
	if _push_pending:
		_push_pending = false
		await push()
