P = ["porteur"]
PS = ["porteur", "sylwen"]
PSB = ["porteur", "sylwen", "brann"]
CAST = {
    "z01_l01_outro": P, "z01_l02_intro": P, "z01_l02_outro": PS, "z01_l03_intro": PS, "z01_l03_outro": PSB,
    "z01_l04_intro": PSB, "z01_l04_outro": PSB, "z01_l05_intro": PSB, "z01_l05_outro": PSB, "z01_l06_intro": PSB,
    "z01_l06_outro": PSB, "z01_l07_intro": PSB, "z01_l07_outro": PSB, "z01_l08_intro": PSB, "z01_l08_outro": PSB,
    "z01_l09_intro": PSB, "z01_l09_outro": PSB, "z01_l10_intro": PSB, "z01_l10_outro": PSB,
}
CUES = [
    # Prologue : la Fracture, le Surge, Lysbourg endormi.
    ("prologue", "Valdrune. Il y a trois cents ans", {"fx": "fade", "cam": "zoom"}),
    ("prologue", "La trame du monde se déchira", {"fx": ["white", "sparkles:d93cf2"], "cam": ["shake", "zoom_out"]}),
    ("prologue", "Depuis, la magie brute", {"fx": "sparkles:b07cff", "cam": ["reset", "pan_right"]}),
    ("prologue", "Là où elle s'accumule", {"fx": "flash:d93cf2", "cam": ["zoom", "tremble"]}),
    ("prologue", "Les Canalisateurs savent", {"fx": "sparkles:4fe3d2", "cam": "reset"}),
    ("prologue", "Ce soir, à l'orée", {"fx": "fade", "cam": "zoom_out"}),
    ("prologue", "Plus pour longtemps.", {"fx": "flash:b07cff", "cam": ["punch", "shake"]}),
    # 1-1 : le réveil de Lysbourg.
    ("z01_l01_intro", "Debout ! Le ciel est devenu violet", {"fx": "flash:b07cff", "cam": "shake"}),
    ("z01_l01_intro", "Un Nexus a germé", {"cam": "pan_right"}),
    ("z01_l01_intro", "Je peux les arrêter.", {"fx": "sparkles:4fe3d2", "cam": "reset"}),
    ("z01_l01_intro", "Alors canalise !", {"act": {"porteur": "glow"}}),
    ("z01_l01_intro", "Et tant que la Barrière tient", {"act": {"porteur": "exit"}, "cam": "punch"}),
    ("z01_l01_outro", "Le Nexus s'est brisé", {"fx": "sparkles:f2c46b", "act": {"porteur": "hop"}}),
    ("z01_l01_outro", "Mais regarde la forêt", {"cam": "pan_right"}),
    # 1-2 : Sylwen.
    ("z01_l02_intro", "Halte ! Un pas de plus", {"cam": "punch", "act": {"porteur": "hurt"}}),
    ("z01_l02_intro", "Les lucioles fuient le Surge", {"fx": "sparkles:fff3b0"}),
    ("z01_l02_outro", "Les Nexus poussent plus vite", {"cam": "zoom"}),
    ("z01_l02_outro", "Allons à la Clairière brisée", {"cam": "reset"}),
    # 1-3 : Brann.
    ("z01_l03_intro", "Enfin des renforts !", {"act": {"brann": "attack"}, "cam": "shake"}),
    ("z01_l03_intro", "Il ronfle. Toute la nuit.", {"act": {"brann": "hurt"}}),
    ("z01_l03_intro", "Je ne ronfle pas, l'elfe", {"cam": "punch"}),
    ("z01_l03_intro", "Le portail de feu, là-bas", {"cam": "pan_left", "fx": "embers"}),
    ("z01_l03_outro", "Voilà ce que j'appelle un nettoyage", {"fx": "sparkles:f2c46b"}),
    ("z01_l03_outro", "Des ronces poussent sur la route", {"cam": "zoom"}),
    # 1-4 : les fées.
    ("z01_l04_intro", "Les fées sont nées de la magie pure", {"act": {"subject": "glow"}, "fx": "sparkles:ff9bf0"}),
    ("z01_l04_intro", "Leurs ronces ont maudit", {"act": {"subject": "roar"}}),
    ("z01_l04_intro", "Ton sort Purifier", {"act": {"porteur": "glow"}, "fx": "sparkles:fff3b0"}),
    ("z01_l04_outro", "Les fées causent BEAUCOUP", {"cam": "punch"}),
    ("z01_l04_outro", "Ce martèlement.", {"cam": ["tremble", "zoom"]}),
    ("z01_l04_outro", "S'il a été touché par le Surge", {"cam": "reset"}),
    # 1-5 : le Grand Cerf et le Sceau.
    ("z01_l05_intro", "Un cerf immense jaillit", {"act": {"subject": "roar"}, "fx": "flash:d93cf2", "cam": "zoom"}),
    ("z01_l05_intro", "Il baisse la tête", {"act": {"subject": "roar"}, "cam": ["shake", "reset"]}),
    ("z01_l05_outro", "La corruption s'échappe", {"act": {"subject": "rise"}, "fx": "sparkles:cfe6ff"}),
    ("z01_l05_outro", "Canalisateur… Le Sceau attendait", {"act": {"subject": "glow"}, "cam": "zoom"}),
    ("z01_l05_outro", "Une lumière brûle ta paume", {"act": {"porteur": "glow"}, "fx": ["white", "sparkles:4fe3d2"], "cam": "punch"}),
    ("z01_l05_outro", "…et il a tout brisé.", {"cam": "zoom_out"}),
    ("z01_l05_outro", "Il est parti… Un Sceau d'Écho", {"fx": "sparkles:cfe6ff", "cam": "reset"}),
    # 1-6 : les fées sombres, le premier Écho.
    ("z01_l06_intro", "Des tireuses, des porte-boucliers", {"act": {"subject": "roar"}}),
    ("z01_l06_intro", "Et toi, surveille ton Sceau", {"act": {"porteur": "glow"}}),
    ("z01_l06_outro", "Un instant, le monde s'est figé", {"fx": "white", "act": {"porteur": "glow"}, "cam": "zoom"}),
    ("z01_l06_outro", "Encore un Porteur…", {"fx": "flash:6a3aa8", "cam": "tremble"}),
    ("z01_l06_outro", "Hé ! Ton visage a perdu", {"cam": "reset"}),
    # 1-7 : la Lanterne de l'Aube, la Tour du Croissant.
    ("z01_l07_intro", "Les villageois portent la Lanterne", {"act": {"subject": "glow"}, "fx": "sparkles:ffd070"}),
    ("z01_l07_intro", "Mais elle est fragile.", {"cam": "zoom"}),
    ("z01_l07_intro", "Des embuscades viendront des flancs", {"cam": ["reset", "pan_left"]}),
    ("z01_l07_outro", "La flamme de la Lanterne", {"fx": ["white", "sparkles:ffd070"]}),
    ("z01_l07_outro", "Regardez, au loin", {"cam": "zoom", "act": {"sylwen": "jump"}}),
    ("z01_l07_outro", "Elle se rapproche…", {"cam": "zoom_out"}),
    # 1-8 : la Source des Lucioles.
    ("z01_l08_intro", "La Source des Lucioles…", {"cam": "pan_right"}),
    ("z01_l08_intro", "Toi, tu purifies avec la Lumière", {"act": {"brann": "attack"}}),
    ("z01_l08_outro", "L'eau de la Source jaillit", {"fx": ["flash:9ff0ff", "sparkles:9ff0ff"], "cam": "reset"}),
    ("z01_l08_outro", "De la Sylvarche. L'arbre-mère", {"cam": "zoom"}),
    ("z01_l08_outro", "Un arbre t'a appris", {"cam": "reset"}),
    # 1-9 : le Cœur de la Forêt, les fées captives.
    ("z01_l09_intro", "Le Cœur de la Forêt", {"cam": "pan_left"}),
    ("z01_l09_intro", "Qui ose… entrer", {"fx": "flash:d93cf2", "cam": ["tremble", "zoom"]}),
    ("z01_l09_outro", "Les Nexus s'effondrent", {"fx": "flash:d93cf2", "cam": "shake", "act": {"subject": "rise"}}),
    ("z01_l09_outro", "Merci… Nous n'oublierons pas", {"act": {"subject": "glow"}, "fx": "sparkles:ffe4f6"}),
    ("z01_l09_outro", "On fonce. Désolé, les minuscules", {"act": {"brann": "exit"}}),
    ("z01_l09_outro", "Après… il sera trop tard", {"act": {"subject": "fall"}}),
    # 1-10 : la Sylvarche.
    ("z01_l10_intro", "Au centre de la forêt se dresse", {"fx": "fade", "cam": "zoom_out", "act": {"subject": "rise"}}),
    ("z01_l10_intro", "Sylwen… petite pousse", {"act": {"subject": "roar"}, "fx": "flash:d93cf2", "cam": "tremble"}),
    ("z01_l10_intro", "Nous sommes là, comme promis", {"fx": "sparkles:ffe4f6"}),
    ("z01_l10_intro", "Son écorce ne craint que le feu", {"fx": "embers", "act": {"brann": "attack"}}),
    ("z01_l10_outro", "La Sylvarche ploie", {"act": {"subject": "hit"}, "cam": "shake"}),
    ("z01_l10_outro", "Tu poses le Sceau contre l'écorce", {"act": {"subject": "glow", "porteur": "glow"}, "fx": "sparkles:b4f0a8", "cam": "zoom"}),
    ("z01_l10_outro", "Merci… Porteur d'Écho", {"cam": "reset"}),
    ("z01_l10_outro", "Autour de vous, la forêt reprend", {"fx": ["fade", "sparkles:fff3b0"], "cam": "zoom_out"}),
    ("z01_l10_outro", "Brann frappe, encore et encore", {"act": {"brann": "attack"}, "fx": "white", "cam": "shake"}),
    ("z01_l10_outro", "Tu as fait ton choix. J'ai besoin", {"act": {"sylwen": "exit"}}),
    ("z01_l10_outro", "Acte 1 terminé", {"fx": "fade", "cam": ["reset", "zoom_out"]}),
]
