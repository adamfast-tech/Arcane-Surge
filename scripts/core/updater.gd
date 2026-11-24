class_name Updater
extends Node
## Mises à jour de la version web (Options) : la CI grave l'empreinte de la version dans data/build.json et
## publie la même empreinte dans version.json, à côté du jeu. check() compare les deux ; apply_update()
## retélécharge les fichiers du jeu (sans passer par le cache du navigateur) puis recharge la page.

signal checked(state: String, remote: Dictionary) ## « latest », « update », « error » ou « unsupported »


## Empreinte de cette version : {sha, time, title} ; sha « dev » hors CI.
static func local_build() -> Dictionary:
	var d: Dictionary = GameData.load_json("res://data/build.json")
	return d if not d.is_empty() else {"sha": "dev", "time": "", "title": ""}


static func supported() -> bool:
	return OS.has_feature("web")


func check() -> void:
	if not supported():
		checked.emit("unsupported", {})
		return
	var url := str(JavaScriptBridge.eval("new URL('version.json?t=' + Date.now(), window.location.href).href", true))
	var req := HTTPRequest.new()
	req.timeout = 12.0
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			checked.emit("error", {})
			return
		var remote: Variant = JSON.parse_string(body.get_string_from_utf8())
		if not (remote is Dictionary) or not (remote as Dictionary).has("sha"):
			checked.emit("error", {})
			return
		var same := str((remote as Dictionary)["sha"]) == str(local_build().get("sha", ""))
		checked.emit("latest" if same else "update", remote))
	if req.request(url) != OK:
		req.queue_free()
		checked.emit("error", {})


## Retélécharge les fichiers du jeu en contournant le cache, puis recharge la page (la progression est
## sauvegardée juste avant ; le délai laisse le temps à la sauvegarde locale de s'écrire).
static func apply_update() -> void:
	Profile.save_local()
	if Cloud.instance != null:
		Cloud.instance.push()
	if not supported():
		return
	JavaScriptBridge.eval("""
		(function () {
			var files = ['index.html', 'index.js', 'index.wasm', 'index.pck', 'version.json'];
			var wait = new Promise(function (ok) { setTimeout(ok, 1200); });
			Promise.all(files.map(function (f) { return fetch(f, {cache: 'reload'}).catch(function () { return null; }); }).concat([wait]))
				.then(function () { window.location.reload(); });
		})();
	""", true)
