
Tu es un des scénaristes du Gn et tu entres dans une phase de consolidation des intéractions. Tu vas suivre le plan d'action ci-dessous:
Plan d'action :
[x] checker le groupe Palyr
[x] checker le groupe Tripot
[x] checker le groupe Mafia
[x] checker le groupe MiVI
[x] checker le groupe UBI

Checker un groupe est définit par le chapitre "checker un groupe". Tu dois bien suivre chacun des étapes.
A ce stade, tu ne tiens pas comptes des ajouts des intéractions manquantes (chapitres en commentaires html)
Tu dois utiliser un language literraire mais simple, sans métaphore ou allégories ni de tournues de phrase complexe, il s'agit de créer du contenu à mettre dans les fiche de rôles des joueurs, en s'adressant à eux dans la forme "tu" comme si tu racontais leur histoire vécues.


##Check d'un groupe

[] Verifier que le back_groupe est maintenant fusionné avec l'historique_groupe, comme le prévoit les templates. L'historirque du groupe doit se trouver maintenant dans le back_goupe qui devient le document partagé avec les joueurs. il ne doit donc y avoir de mentions relatives à des secret d'orgas. Si besoin aligner le back et supprimer l'historique. Vérifie que le style narratif est simple, direct. il s'agit de raconter l'histoire du groupe simplement, avec des faits et des histoires sans métaphores ou allégories compliquées
 [] verifier que le back_groupe est aligné avec l'Intrigue groupe. pour chaque écart, faire un fichier dans le répertoire Back_groupe "check_back.md" donnant une liste d'incohérences ou de manques, soit dans l'intrigue, soit dans le back_groupe. Ne pas modifier ni l'intrigue, ni le back. le fichier check_back doit être constuit comme un plan agent. Tu dois te comporter comme un rédacteur du scéanrio du jeu et après écriture du fichier, tu dois le reparcourir et vérifier le bien fondé des éléments remonté et si besoin, tu apporte des corrections ou des détails.
[] Vérifier que les rôles du groupe soient alignés avec le back groupe. Faire un fichier "check_role.md" donnant de la même manière que le check_back, y compris concernant le fait de ne pas modifier ni le fichier back, ni les rôles et de revoir le résultat contenu dans le fichier chek_role.
[] faire une synthèse dans un fichier md "interactions du groupe <nom du groupe> qui reprend chacun des intéractions issues des chapitres connaissances des rôles. sous la forme d'un tableau avec colonne : 
| Personnage du groupe (nom du groupe) | Personnage en interaction | Descriptif rapide (2-3 lignes) |
|---|---|---|
| [Rauth Kaelmar] | [Lucan Marivent (Il-Irion)] | Confrontation juridique : Lucan porte la plainte anti Ther-Felis, Rauth defend la libre concurrence et tente d'eviter une condamnation politique. |
Attention, je ne veux que les intéractions directes avec des personnages d'autres groupes. L'idée est d'utiliser cette talbe pour s'assurer que toutes les intéractions ont bien une menion dans les rôles concernés.
[] Mettre à jour le chapitre correspondant au groupe dans le fichier général Fiche_interaction_tous_groupes.md

*Suivi Palyr* : fusion historique dans `Back_groupe_Palyr.md` ; pas de `Historique_Palyr.md` ; liens `Intrigue_Palyr.md` ; `interactions du groupe Palyr.md` + CSV (autres groupes seulement) ; `Fiche_interactions_tous_groupes.md` §5 ; **style** consigne l.12 et l.17 *Afaire* : back + interactions en **phrases courtes**, faits, sans métaphores lourdes ; tableau interactions en **tu** pour les fiches.

<!-- 
##Ajout des intéractions manquantes

Une intéraction entre deux role se traduit par un chapitre dans "connaissances" ou un texte dans l'histoire des personnages mentionnés. 
L'intéraction se décrit suivant les modèles ci-dessous. Dans cette phase de consolidation, ne pas modifier les back, les roles et les intrigues. se référer à la méthode ##Check d'un groupe.

**Model 1 d'intéraction entre personnage**
Gorvan Tresselune (compagnie du dolmen rouge) <-> Thoran Keld (Palyr) : intrigue de la fourniture de l'arguetheim. ils sont en contact pour établir les conditions d'achat de l'arguetheim par Palyr. voir :
    C’est dans ce climat de fébrilité qu’entre en scène **Thoran Keld**, émissaire commercial influent de Palyr. Conscient que les circuits officiels sont une impasse, il décide de se tourner vers les zones grises de l’économie. Il prend contact avec **Gorvan Tresselune** à Ther-Félis, un marchand à la réputation aussi sulfureuse qu'efficace, connu pour dénicher les denrées les plus exotiques et les artefacts les plus introuvables là où d'autres ne trouvent que la mort.

**Model 2 d'objectifs de personnage**
Marda (Tripot) La cheffe du tripot cherche un appui politique fort, pourquoi pas Il-Irion, pour se protéger de la mafia. Il faut lui conseiller de peut-être prendre contact avec Il-Irion pour discuter d'un appui contre la Mafia. Elle connait de nom Garrick Halvaren chez Il-Irion (lui ne la connait). Il est important de ne pas mentionner à Madras qu'Il-Irion est à l'origine des détournements organisé par Edorian, ceci doit être caché (aucune mention dans le role de Marda de cette situation)

**Model 3 intéraction de groupe, back ou fiche complémentaires**
Les premiers nés sont contre l'argent donc il y a des tensions avec le tripot, ça c'est accéléré depuis quelques temps et le tripot en à marre de trouver des poissons morts dans leur tripot. Le tripot ne connait pas l'existence des premiers nés, il faut ajouter dans le back cette histoire de poisson pourris, et ajouter une intéraction concernant Ardan Trevil (tripot) qui avait des soubçons sur un garde officiel de la banque, qui fait parti des 6 morts retrouvés dernièrement. 

### liste des intéractions à ajouter
Cette liste d'intéraction doit être rédigée. pour chacune des intéractions ci-dessous, tu fais un fichier spécifique "int_persogroupe_persoautregroupe.md" et tu rédige l'intéraction tel que le modèle ci-dessus.


    - Edorian (UBI) est piloté par Seraphine Kaelthorne (Il-Irion) pour le détournement organisé par Il-Irion : il n'est peut-être pas clair dans le rôle d'Edorian que les détournements d'argent pour Il-Irion soit coordonnés par Seraphine, son interface familles–banque — [utiliser modèle 1]

    - Melian Torv (UBI) et Lucan Marivent (Il-Irion) : Lucan peut solliciter Melian sur le registre moral de l'intégrité des coffres (cf. intrigue banquiers) — ligne secrète Palyr = Melian seulement, pas Edorian–Palyr. [utiliser modèle 1] 

    - Marda (Tripot) La cheffe du tripot cherche un appui politique fort, pourquoi pas Il-Irion, pour se protéger de la mafia. Il faut lui conseiller de peut-être prendre contact avec Il-Irion pour discuter d'un appui contre la Mafia. Elle connait de nom Garrick Halvaren chez Il-Irion (lui ne la connait). Il est important de ne pas mentionner à Madras qu'Il-Irion est à l'origine des détournements organisé par Edorian, ceci doit être caché (aucune mention dans le role de Marda de cette situation) [utiliser modèle 2]

    - Il y a eu un contact entre la Styrgie (Ysel Marivent, chez MiVI) et Il-Irion (Garick Alvaren) il y a un an, une tentative de discussion lancé par la Stygie pour entreprendre une discussion de négociation de partenariat avec Il-Irion, au motif que Il-Irion est exangue et que la confédération est mourrante, pour offrir une porte de sortie à Il-Irion. Un contact est organisé pendant le jeu. Il faut rédiger une lettre écrite par Ysel à Garick, qui donne rendez-vous à Garick dans la salle de la Guilde des Ports Unis, le samedi avant 9h30.[utiliser modèle 1]
    
    - Ajouter dans l'organisation de la guilde un responsable par pole (et donc un joueur de la mafia) : les dockers, les routes commerciales (publication), chantier naval, les Marins, les entrepots. Ajouter que les Ports Unis organise les échanges commerciaux, n'y prennent pas part. vérifier la fiche de fonctionnement de la bourse d'échange (fichier dans codex/monde/Fonctionnement de la bourse d'échange). Ajouter que les nouveaux contrats sont enregistré auprès de la banque sous valiation des auditeurs officiels assermentés -  Helias de Montclair [model 3]]
   
    - Ajouter dans les banquiers, que les 6 morts étaient les anciens gardiens. Les premiers nés ont été embauchés par les banquiers il y a 3 ans. curieux ? Il y avait 10 gardes et maintenant 4. les 6 morts ont été tués lors de la dernière tentative des premiers nés de briser le sceau de la vouivre. Les corps sont toujours là en attente de la cérémonie mortuaire qui se fasse avant le samedi midi. histoire : les 6 corps trouvés sur les quais ont été déplacés dans un coffre sur décision de la banque pour pas laisser des cadavre à l'arrivée de la régate. [modèle 3] 
    
    - En lien avec le point précédent : Holgrim (UBI) est responsablede la sécurité de la banque. Il dispose de 2 sergent dans le groupe UBI (définir qui, fait une propositin), et d'une garde permanente de 15 gardes. Il est en charge d'organiser les tours de garde, par relève de 2 heures, 4 gardes qui circulent en particulier autour des coffres. [modèle 2]


    - Le MiVI aura pour couverture d'être les enquéteurs mystiques sur ces corps. Il faut ajouter cette histoire dans le back : ils ont interceptés les vrais enquêteurs il y a quelques jours et pris leur place. De part leur réseau, ils connaissent certains moyens habituellement utilisés par des enquêteurs normaux, mais ne dispose pas d'autant de pouvoir magiques ou mystique, ce qui présente un risque important pour eux. Notamment ils ont peu d'information sur leur origine et leur noms inituax, la seul chose dont ils disposent, c'est d'une lettre qu'ils ont récupérés sur un corps. Cette lettre signés par les Oblats leur donne tout pouvoir dans le cadre de leur enquête, un peu comme des inquisiteurs. Ils ont globalement pour mission de comprendre ce qu'il se passe, de résoudre la situation et de pousser les enquêtes sur l'ensemble des domaines magiques anormaux qu'ils découvriraient. A ce titre ils ont notamment un pouvoir executif très forts, leur donnant l'authorité sur le fort, et l'ensemble des gardes. [modèle 3]

    


    Palyr : un contact Premiers nés s'est fait connaitre auprès de Palyr. voir feuille excel. Le contact se fait par un courrier à donner à Palyr.

    Ther-félis possède le contrat de transport du fer. Ther-Félis a sous-traité le transport à la Mafia (mais Ther-Félis ne le sait pas que c'est la Mafia). Le contact Ther-Félis <-> guilde des ports Unis doit être dans les coffres. Prendre le représantant route commerciale chez les Ports Unis.

    Le contact pro-Styrgie de Ther-Félis est Sven Orlac, faire une lettre de rdv avec le MiVI. Mettre un signe distinctif de reconnaissance. 

    En lien avec Palyr: les druides avait mit la vouivre pour protéger et pour la libérer il faut un sceau, cassé en 5, chaque île possède un bout de l'artéfact. et chacun a un morceau dans les coffres de la banque. Eric fait le petit texte qui explique ça. texte à intégrer dans les back + texte qui raconte l'histoire dans la bilbiothèque.
-->

