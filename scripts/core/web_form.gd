class_name WebForm
extends RefCounted
## Version web : vrais champs HTML (identifiant + mot de passe) posés sur les champs Godot de
## l'écran de connexion. Les champs dessinés dans le canevas ne permettent ni le collage sur
## iPhone, ni le remplissage par le trousseau iCloud ou le gestionnaire de mots de passe.
## Les champs Godot restent en dessous comme cadres ; le texte se tape dans les champs HTML.
##
## La soumission part vers une iframe muette (action about:blank, aucune requête réseau) : le
## navigateur la voit comme une vraie connexion et peut proposer d'enregistrer le mot de passe.

const JS := """
(function () {
  if (window.arcaneLogin) return;
  var L = window.arcaneLogin = { cb: null, form: null, last: null };
  L.install = function (userPh, passPh) {
    if (L.form) return;
    var st = document.createElement('style');
    st.id = 'as-login-style';
    st.textContent = '#as-login-form input{position:fixed;box-sizing:border-box;margin:0;background:transparent;'
      + 'border:2px solid transparent;outline:none;color:#ece8ff;caret-color:#4fe3d2;-webkit-appearance:none;'
      + 'appearance:none;font-family:ArcaneJersey,system-ui,sans-serif;z-index:20;}'
      + '#as-login-form input:focus{border-color:#4fe3d2;}'
      + '#as-login-form input::placeholder{color:rgba(169,159,208,0.7);}';
    document.head.appendChild(st);
    var sink = document.createElement('iframe');
    sink.name = 'as-sink';
    sink.id = 'as-sink';
    sink.tabIndex = -1;
    sink.setAttribute('aria-hidden', 'true');
    sink.style.display = 'none';
    document.body.appendChild(sink);
    var f = document.createElement('form');
    f.id = 'as-login-form';
    f.method = 'post';
    f.action = 'about:blank';
    f.target = 'as-sink';
    f.setAttribute('autocomplete', 'on');
    f.style.cssText = 'position:fixed;left:0;top:0;width:0;height:0;margin:0;padding:0;';
    var u = document.createElement('input');
    u.id = 'as-user'; u.name = 'username'; u.type = 'text';
    u.setAttribute('autocomplete', 'username');
    u.setAttribute('autocapitalize', 'none');
    u.setAttribute('autocorrect', 'off');
    u.setAttribute('spellcheck', 'false');
    u.setAttribute('enterkeyhint', 'next');
    u.placeholder = userPh;
    var p = document.createElement('input');
    p.id = 'as-pass'; p.name = 'password'; p.type = 'password';
    p.setAttribute('autocomplete', 'current-password');
    p.setAttribute('enterkeyhint', 'go');
    p.placeholder = passPh;
    var b = document.createElement('button');
    b.type = 'submit'; b.tabIndex = -1; b.setAttribute('aria-hidden', 'true');
    b.style.cssText = 'position:fixed;left:-9999px;top:0;width:1px;height:1px;opacity:0;';
    f.appendChild(u); f.appendChild(p); f.appendChild(b);
    u.addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); p.focus(); } });
    f.addEventListener('submit', function () { if (L.cb) L.cb(); });
    document.body.appendChild(f);
    L.form = f; L.user = u; L.pass = p; L.sink = sink; L.style = st;
    window.addEventListener('resize', L.reflow);
  };
  L.setFont = function (b64) {
    if (L.fontDone || !window.FontFace) return;
    L.fontDone = true;
    try {
      var bin = atob(b64);
      var arr = new Uint8Array(bin.length);
      for (var i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
      var ff = new FontFace('ArcaneJersey', arr.buffer);
      ff.load().then(function (x) { document.fonts.add(x); }).catch(function () {});
    } catch (e) {}
  };
  L.place = function (json) { L.last = json; L.reflow(); };
  L.reflow = function () {
    if (!L.form || !L.last) return;
    var d = JSON.parse(L.last);
    var c = document.getElementById('canvas') || document.querySelector('canvas');
    if (!c) return;
    var cr = c.getBoundingClientRect();
    var k = cr.width / d.vw;
    var put = function (el, r) {
      if (!r || r[2] <= 0) { el.style.display = 'none'; return; }
      el.style.display = 'block';
      el.style.left = (cr.left + r[0] * k) + 'px';
      el.style.top = (cr.top + r[1] * k) + 'px';
      el.style.width = (r[2] * k) + 'px';
      el.style.height = (r[3] * k) + 'px';
      el.style.fontSize = Math.max(16, d.font * k) + 'px';
      el.style.padding = '0 ' + Math.round(14 * k) + 'px';
      el.style.borderRadius = Math.round(d.radius * k) + 'px';
    };
    put(L.user, d.user);
    put(L.pass, d.pass);
  };
  L.values = function () { return JSON.stringify({ u: L.user ? L.user.value : '', p: L.pass ? L.pass.value : '' }); };
  L.submit = function () {
    if (!L.form) return;
    if (L.form.requestSubmit) L.form.requestSubmit(); else if (L.cb) L.cb();
  };
  L.setDisabled = function (on) { if (L.form) { L.user.disabled = on; L.pass.disabled = on; } };
  L.remove = function () {
    window.removeEventListener('resize', L.reflow);
    ['form', 'sink', 'style'].forEach(function (k) { if (L[k] && L[k].parentNode) L[k].parentNode.removeChild(L[k]); L[k] = null; });
    L.cb = null; L.last = null;
  };
})();
"""


static func available() -> bool:
	return OS.has_feature("web")


static func install(user_placeholder: String, pass_placeholder: String) -> JavaScriptObject:
	JavaScriptBridge.eval(JS, true)
	var L := JavaScriptBridge.get_interface("arcaneLogin")
	L.install(user_placeholder, pass_placeholder)
	L.setFont(Marshalls.raw_to_base64(UiTheme.font().data))
	return L
