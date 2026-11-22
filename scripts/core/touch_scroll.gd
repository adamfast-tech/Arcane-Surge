class_name TouchScroll
extends RefCounted
## Défilement au doigt dans toutes les listes (Bibliothèque, Carte, Équipement…).
##
## Par défaut, les boutons et les cadres (PanelContainer) arrêtent les évènements de pointeur : un
## glissé commencé sur une carte n'atteint jamais le ScrollContainer, qui ne défile alors que si
## l'on pose le doigt entre deux cartes. On fait donc passer les évènements (MOUSE_FILTER_PASS) de tout
## ce qui se trouve dans une liste défilante. Quand le glissé devient un défilement, l'appui en cours
## sur un bouton est annulé : relâcher le doigt ne le déclenche pas.

## Distance (px) avant qu'un appui ne devienne un défilement : un simple toucher reste un clic.
const DEADZONE := 14


static func install(tree: SceneTree) -> void:
	tree.node_added.connect(_on_node_added)


static func _on_node_added(n: Node) -> void:
	if n is ScrollContainer:
		var sc := n as ScrollContainer
		sc.scroll_deadzone = DEADZONE
		if not sc.scroll_started.is_connected(_cancel_presses.bind(sc)):
			sc.scroll_started.connect(_cancel_presses.bind(sc))
		return
	if not (n is Control) or n is ScrollBar:
		return
	var c := n as Control
	if c.mouse_filter == Control.MOUSE_FILTER_STOP and _in_scroll(c):
		c.mouse_filter = Control.MOUSE_FILTER_PASS


static func _in_scroll(c: Control) -> bool:
	var p := c.get_parent()
	while p != null and p is Control:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


## Le défilement commence : on annule l'appui en cours sur les boutons de la liste.
static func _cancel_presses(root: Node) -> void:
	for ch in root.get_children():
		if ch is BaseButton:
			var b := ch as BaseButton
			if not b.toggle_mode and b.is_pressed():
				var was := b.disabled
				b.disabled = true
				b.disabled = was
		_cancel_presses(ch)
