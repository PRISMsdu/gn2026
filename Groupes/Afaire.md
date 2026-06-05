
Tu es un des scénaristes du Gn et tu entres dans une phase de consolidation des intéractions. Tu vas suivre le plan d'action ci-dessous:
Plan d'action :
[] checker le groupe Palyr
[] checker le groupe Tripot
[x] checker le groupe Mafia
[x] checker le groupe MiVI
[X] checker le groupe UBI

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
Gorvan Tresselune (compagnie du dolmen rouge) <-> Lysa Morwyn (Palyr) : intrigue de la fourniture de l'arguetheim. Lysa a mandaté Gorvan à Ther-Félis ; vente à Ulghart au plus tard samedi fin de journée ; Maren réceptionne pour le haut commandement. Intrigue Dolmen : voir `Intrigues/Intrigue_CompagnieDolmenRouge.md` (rédaction groupe voleurs). Palyr : `Intrigues/Intrigue_Palyr.md`, back et rôles `Groupes/Palyr/`.

**Model 2 d'objectifs de personnage**
Marda (Tripot) La cheffe du tripot cherche un appui politique fort, pourquoi pas Il-Irion, pour se protéger de la mafia. Il faut lui conseiller de peut-être prendre contact avec Il-Irion pour discuter d'un appui contre la Mafia. Elle connait de nom Garrick Halvaren chez Il-Irion (lui ne la connait). Il est important de ne pas mentionner à Madras qu'Il-Irion est à l'origine des détournements organisé par Edorian, ceci doit être caché (aucune mention dans le role de Marda de cette situation)

**Model 3 intéraction de groupe, back ou fiche complémentaires**
Les premiers nés sont contre l'argent donc il y a des tensions avec le tripot, ça c'est accéléré depuis quelques temps et le tripot en à marre de trouver des poissons morts dans leur tripot. Le tripot ne connait pas l'existence des premiers nés, il faut ajouter dans le back cette histoire de poisson pourris, et ajouter une intéraction concernant Ardan Trevil (tripot) qui avait des soubçons sur un garde officiel de la banque, qui fait parti des 6 morts retrouvés dernièrement. 

### liste des intéractions à ajouter
Cette liste d'intéraction doit être rédigée. pour chacune des intéractions ci-dessous, tu fais un fichier spécifique "int_persogroupe_persoautregroupe.md" et tu rédige l'intéraction tel que le modèle ci-dessus.


    [X] Edorian (UBI) est piloté par Seraphin Kaelthorne (Il-Irion) pour le détournement organisé par Il-Irion : il n'est peut-être pas clair dans le rôle d'Edorian que les détournements d'argent pour Il-Irion soit coordonnés par Seraphin, son interface familles–banque — [utiliser modèle 1]


    [ X ] MiVI prend contact avec Sven Orlac pour Ther-Félis via scaro selt.. 
    [ X ] Ils ont également contact avec Arthas Shark Brooks. Attention, ce perso n'existe pas dans le groupe Arthas.
    [ X ] faire des lettres de mise en contact.

    [X] revoir le livret et mettre la date de creation de la banque en meme temps que l'unification de la confédéréation, soit -150 ans. (codex + Charte_UBI + Back_groupe_UBI — an 397)

    [ X ] mettre dans Palyr un responsable militaire

    [ ] mettre que l'argent détourné d'Edorian est dans une salle inondée, trouvée par Sybrel.

    - Marda (Tripot) La cheffe du tripot cherche un appui politique fort, pourquoi pas Il-Irion, pour se protéger de la mafia. Il faut lui conseiller de peut-être prendre contact avec Il-Irion pour discuter d'un appui contre la Mafia. Elle connait de nom Garrick Halvaren chez Il-Irion (lui ne la connait). Il est important de ne pas mentionner à Madras qu'Il-Irion est à l'origine des détournements organisé par Edorian, ceci doit être caché (aucune mention dans le role de Marda de cette situation) [utiliser modèle 2]

    [ X ] Il y a eu un contact entre la Styrgie (Ysel Marivent, chez MiVI) et Il-Irion (Garrick Halvaren) il y a un an, une tentative de discussion lancé par la Stygie pour entreprendre une discussion de négociation de partenariat avec Il-Irion, au motif que Il-Irion est exangue et que la confédération est mourrante, pour offrir une porte de sortie à Il-Irion. Un contact est organisé pendant le jeu. Lettre GPU-547 (`Lettre_MiVI_Garrick_Halvaren.md`) — RDV salle Guilde des Ports Unis, samedi avant 9 h, mot « registre du quai nord ».[utiliser modèle 1]
    
    [ X ] Ajouter dans l'organisation de la guilde un responsable par pole (et donc un joueur de la mafia) : les dockers, les routes commerciales (publication), chantier naval, les Marins, les entrepots.
    
    [ X ] Bourse (codex) : Ports Unis organisent les échanges, ne signent pas ; nouveaux contrats déposés à l'UBI, visa auditeurs assermentés (règles générales sans nom — instance GN : Hélias de Montclair, RAF Corbeaux) [model 3]
   
    [ X ] Ajouter dans les banquiers, que les 6 morts étaient les anciens gardiens. Les premiers nés ont été embauchés par les banquiers il y a 3 ans. curieux ? Il y avait 10 gardes et maintenant 4. les 6 morts ont été tués lors de la dernière tentative des premiers nés de briser le sceau de la vouivre. Les corps sont toujours là en attente de la cérémonie mortuaire qui se fasse avant le samedi midi. histoire : les 6 corps trouvés sur les quais ont été déplacés dans un coffre sur décision de la banque pour pas laisser des cadavre à l'arrivée de la régate. [modèle 3] 
    
    [ ]  En lien avec le point précédent : Holgrim (UBI) est responsablede la sécurité de la banque. Il dispose de 2 sergent dans le groupe UBI (définir qui, fait une propositin), et d'une garde permanente de 15 gardes. Il est en charge d'organiser les tours de garde, par relève de 2 heures, 4 gardes qui circulent en particulier autour des coffres. [modèle 2]

    [ ] Ther-Félis, n'a plus de fric donc ils n'entretiennent pas leur flotte et donc ils ont sous-traité le transport àa la Guilde des Ports Unis. Qui du coup en ont profité pour orgaser le détournement du Fer.

  
    [ X ] Palyr : Ils ont été contacté par un groupe nommé les fils du levant qui leur propose la création d'un nouvel ordre ou toutes les cités et les peuples des îles auraient leur place et leur libertés. Ca va interessé Palyr pour prendre plus de place, et dimunuer l'influence d'IL-Irion. faire une lettre pour Palyr, signée par Tavish Kaironui.

    [ ] Ther-félis possède le contrat de transport du fer. Ther-Félis a sous-traité le transport à la Mafia (mais Ther-Félis ne le sait pas que c'est la Mafia). Le contact Ther-Félis <-> guilde des ports Unis doit être dans les coffres. Prendre le représantant route commerciale chez les Ports Unis.

    [ X ] Le contact pro-Styrgie de Ther-Félis est Sven Orlac, faire une lettre de rdv avec le MiVI. Mettre un signe distinctif de reconnaissance. 

    [ ] En lien avec Palyr: les druides avait mit la vouivre pour protéger et pour la libérer il faut un sceau, cassé en 5, chaque île possède un bout de l'artéfact. et chacun a un morceau dans les coffres de la banque. Eric fait le petit texte qui explique ça. texte à intégrer dans les back + texte qui raconte l'histoire dans la bilbiothèque.

    [ X ] - Corvus a un scaphandre car il sait l'utiliser au cas où le système tombe en panne

    [ ] - refaire les lignes mémo et mettre ça dans tous les groupes cités

    [ X ] - La mafia a buté par erreur l'oblat d'Arthas. Mais c'était une grosse boulette c'est Gareth Ironfist (il a laissé son berêt écossais vert avec ponpon) Y a que Olive qui sait qu'il a perdu son berêt. Arthas a le berêt et ils vont chercher à qui il appartient. Olive doit chercher absolument à le récupérer car il assissine avec son berêt.   


    [ ] ajouter Varek comme distributeur de composants magiques + Marda
 
-->
[ ] faire les contrats
- sous-traiteance ther-felis
[ x ] - remettre a sybrel la véritable histoire

- faire le texte et les contrats du détournement d'argent pour les autres cités.
[X ]checker le changement de loblat palyr en Legat.
- donner les copies compromettantes à Selvara



histoire 

Les deux familles Cyrion Valdris Seraphin Kaelthorne ont pris peur du pouvoir croissant de la famille d'Edorian (de Courcel) qui avait des preuves de malversations des dites familles. D'Oû la suppression de la famille d'Edorian, orchestrée par un homme de main d'Il-Irion (Garrick Halvaren) sous pression des deux familles encore, les putes. Le garrick a lui même été manipulé par sa propre famille, donc il se retourne vers la styrgie. De plus, il contacte Edorian (il y a 8 ans) pour lui expliquer. Donc edorian fomente son plan de vengeance envers les 2 familles et il fait pression sur elles pour retirer leur candidature laissant la place à Edorian . A partir de là, le plan se met en place et Garrick et Edorian se connaissent - aucune famille ne sait que Garrick a vendu la mêche.

rédige:

- le chapitre pour les deux familles d'Il-Irion qui avait détruit la famille de Courcel il y a x année (regarde dans le role d'Edorian la date).

- redige le chapitre pour Garrick

- redige le chapitre pour Edorian

---

## Chapitres rédigés — affaire de Courcel

Chronologie retenue : destruction de la famille de Courcel il y a 12 ans (pendant l'ascension d'Edorian à l'UBI, avant qu'il rencontre Vaelric Dorn). Contact de Garrick il y a 8 ans. Prise de la direction d'Ulghart il y a 5 ans. Ces dates sont cohérentes avec le Chapitre III du back Edorian.

---

### Chapitre — Valdris et Kaelthorne : l'affaire de Courcel

- À intégrer dans `back_joueur_Cyrion_Valdris.md` et `back_joueur_Seraphin_Kaelthorne.md`, en « tu », dans la biographie (période ascension / consolidation).

Il y a douze ans, une famille de comptoir à Il-Irion — les de Courcel — travaillait dans les bureaux proches des greffes de l'Union bancaire. Le père tenait des fonctions de gestion de registres et avait accès aux dépôts de correspondance interne. Sur plusieurs années, il avait reconstitué un dossier documentant des pratiques illicites de plusieurs maisons : réévaluation de taux sans mandat confédéral, contrats signés sous des prête-noms liés à des familles alliées, transferts dissimulés entre coffres privés. Le dossier visait en particulier la Maison Valdris et la Maison Kaelthorne.

La famille de Courcel n'avait pas encore sorti ces pièces. Elle les constituait. Les deux maisons l'ont su avant qu'elle en fasse usage.

La décision a été prise entre les deux maisons : la famille de Courcel devait être neutralisée avant qu'elle sorte le dossier. La demande a été transmise à la Maison Halvaren, le bras de sécurité de la coalition pour les affaires qui ne devaient pas remonter à un conseil. La Maison Halvaren a désigné Garrick Halvaren pour l'exécution. La mission consistait à stopper la famille — l'arrêter, la discréditer, l'isoler. Les deux maisons n'avaient pas demandé des morts.

En quelques mois, Garrick a ruiné les de Courcel : cautionnements retirés, dettes présentées au mauvais moment, clients détournés. Puis il a provoqué un accident. Les parents sont morts. Personne n'a posé de questions. Un fils survivait, Edorian, déjà entré en apprentissage à la banque. Les deux maisons ont préféré ne pas demander comment les choses s'étaient passées exactement. Elles ont jugé qu'Edorian était trop jeune et trop périphérique pour représenter un risque. Le dossier a été clos.

Il y a cinq ans, quand il a fallu placer un directeur sûr à la tête de l'agence d'Ulghart, Edorian était disponible, compétent et apparemment redevable envers les maisons qui avaient laissé sa famille sombrer sans intervenir. Vous l'avez soutenu pour le poste. Vous pensiez tenir un homme qui n'avait aucune raison de se retourner.

Ce que vous ignorez : Garrick Halvaren a contacté Edorian il y a huit ans pour lui expliquer ce qui s'est passé. Edorian sait que sa famille a été délibérément ruinée et par qui. Garrick et lui maintiennent un contact discret depuis lors. Aucune maison de la coalition n'a été informée de cette conversation.

---

### Chapitre — Garrick Halvaren : ce qu'il a fait et ce qu'il sait

- À intégrer dans `back_joueur_Garrick_Halvaren.md`, en « tu », comme section biographique complémentaire.

Il y a douze ans, ta famille — la Maison Halvaren — t'a désigné pour exécuter une mission confiée par les Maisons Valdris et Kaelthorne : stopper une famille de comptoir, les de Courcel, qui constituait un dossier de preuves sur les malversations des deux maisons. L'ordre était de les neutraliser, les discréditer, les isoler. Pas autre chose.

Tu as ruiné la famille. Dettes présentées au mauvais moment, cautionnements retirés, clients détournés. Ensuite tu as provoqué un accident. Tu voulais les faire taire définitivement. Les parents sont morts. Ce n'était pas ce qu'on t'avait demandé, et tu le savais. Un fils, Edorian, était déjà entré à la banque. Tu ne t'en es pas occupé. Il était trop jeune pour compter, et tu avais déjà fait plus que prévu.

Ta famille a refermé le dossier sans commenter l'accident. Elle ne t'a pas reproché d'être allé trop loin. Elle a protégé l'opération et, par là, elle t'a protégé. Tu restes Halvaren. Tu ne peux pas te retourner contre les tiens : ils savent ce que tu as fait et tu sais qu'ils te couvrent.

La Styrgie t'a approché il y a une dizaine d'années, indépendamment de tout cela. Des contacts discrets, une offre de protection extérieure. Tu n'as pas signé d'accord, mais les échanges existent. C'est une porte que tu gardes ouverte sans en parler à la coalition.

Il y a huit ans, tu as contacté Edorian de Courcel. La culpabilité pour l'accident y était pour une part — les parents n'auraient pas dû mourir. Mais tu avais aussi une raison pratique : Edorian montait dans la banque, il avait des raisons de s'intéresser aux deux maisons, et tu avais besoin de quelqu'un qui ne soit pas dans la coalition. Tu lui as dit que la ruine de sa famille avait été décidée par Cyrion Valdris (Maison Valdris) et Seraphin Kaelthorne (Maison Kaelthorne), transmise à ta famille, et exécutée par toi. Tu lui as donné les noms et les étapes. Tu n'as pas mis la Maison Halvaren en cause devant lui — tu n'as pas trahi les tiens.

Edorian et toi vous connaissez. Vous ne vous fréquentez pas en public. Aucune maison de la coalition ne sait que tu lui as parlé. Si les familles apprennent que tu as prévenu Edorian, ta couverture par les Halvaren ne tiendra plus. Tu perds leur protection et tu portes seul l'accident.

---

### Chapitre — Edorian : ce que Garrick t'a dit (complément du Chapitre III)

- À insérer dans `UBI_Edorian_Directeur_general.md`, dans le Chapitre III, après le paragraphe sur la faillite de la famille et la mort des parents.

Ta famille portait un nom : de Courcel. Tes parents tenaient des fonctions de gestion de registres à Il-Irion, proches des greffes de l'UBI. Sur plusieurs années, ton père avait reconstitué un dossier documentant des malversations de plusieurs maisons — réévaluation illicite de taux, transferts dissimulés, prête-noms. Ce dossier visait en particulier la Maison Valdris et la Maison Kaelthorne. Il n'avait pas encore servi. Il était prêt.

La faillite de ta famille n'était pas un enchaînement de malchances. Quelqu'un a retiré les cautionnements au mauvais moment, détourné les clients, présenté les dettes de façon coordonnée. Ensuite tes parents sont morts dans un accident. Tu avais mis ça sur le compte de la fragilité d'une petite maison et d'une série de coups du sort. L'accident était provoqué.

Il y a huit ans, Garrick Halvaren (Il-Irion, Maison Halvaren) t'a contacté. Il t'a dit que la décision de neutraliser ta famille avait été prise par Cyrion Valdris (Maison Valdris) et Seraphin Kaelthorne (Maison Kaelthorne), transmise à la Maison Halvaren, et exécutée par lui. L'accident qui a tué tes parents n'était pas dans l'ordre d'origine — Garrick avait outrepassé la mission. Il t'a donné les noms et les étapes. Il l'a fait en partie par culpabilité, en partie parce que tu montais dans la banque et qu'il cherchait un interlocuteur hors coalition. Il ne t'a pas mis la Maison Halvaren en cause — il t'a donné Valdris et Kaelthorne.

À partir de là, ton plan a changé d'ampleur. Sortir de l'UBI avec de l'argent ne suffisait plus. Tu voulais que Valdris et Kaelthorne perdent ce qu'elles avaient protégé en détruisant les tiens : leur réputation, leurs avoirs, et leur capacité à se couvrir l'une l'autre. Garrick t'a transmis, dans les mois suivants, des informations précises sur les pratiques des deux maisons — les mêmes pratiques que ton père avait documentées avant de mourir.

Quand Cyrion Valdris et Seraphin Kaelthorne t'ont proposé leur soutien pour la direction d'Ulghart, il y a cinq ans, tu as accepté sans hésiter. Elles pensaient installer quelqu'un de redevable. Tu avais déjà leur dossier. Tu savais exactement ce qu'elles valaient et ce que tu ferais de leur aide.

Garrick et toi maintenez un contact discret depuis huit ans. Aucune des maisons d'Il-Irion ne sait qu'il t'a parlé. Ce secret est le seul qui compte : si les familles comprennent que Garrick t'a prévenu, elles sauront que tu les as utilisées depuis le premier jour. Elles ne te laisseront pas aller jusqu'à la Régate.