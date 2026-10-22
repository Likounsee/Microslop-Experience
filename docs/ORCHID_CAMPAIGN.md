# ORCHID — Chapitre 1 du jeu de base

> Document de référence narratif. Le contenu de ce document décrit la campagne visée ; les scènes explicitement marquées « implémenté » correspondent aux événements présents dans le jeu.

## Promesse et ton

Le joueur veut simplement utiliser un nouvel ordinateur fictif. Microslop se présente comme chaleureux, rassurant et excessivement enthousiaste. L'humour vient d'abord de petits désagréments familiers, puis devient inquiétant lorsque le système semble anticiper les intentions du joueur. La menace n'est pas une IA magique qui lit tout : c'est une organisation qui transforme les comportements ordinaires en métriques d'engagement, puis masque les conséquences derrière un vocabulaire de productivité.

Le jeu n'accède jamais aux vrais fichiers ou paramètres de l'ordinateur. Tous les documents, recherches, notifications et choix sont simulés.

## Personnages et voix

- **Le joueur** : personnalité laissée au joueur. Les objectifs parlent directement à « vous » sans imposer de passé ou de motivations.
- **Microslop AI** : serviable, rapide, légèrement anxieux. Elle parle en langage de support (« reformuler positivement », « expérience personnalisée »), corrige ses propres révélations et se réfugie dans l'humour lorsqu'elle est acculée. Elle n'est pas la conceptrice d'ORCHID : elle est une interface entraînée à éviter les sujets qui nuisent à la rétention.
- **Équipe Expérience** : présence indirecte dans les notes internes. Les documents utilisent des formulations impersonnelles pour que personne ne semble responsable.
- **Microslop Update / le navigateur** : voix institutionnelle. Les mises à jour sont obligatoires « pour votre confort » et les résultats sponsorisés prennent la place des informations utiles.

## Nouvelle séquence jouable — arrivée d’ORCHID

La mise à jour ne doit pas apparaître comme un programme secret tombé du ciel. Le joueur peut ouvrir l’historique de déploiement depuis la fenêtre Microslop Update et parcourir quatre étapes interactives. La séquence est jouable dans le chapitre 1 ; elle ne touche pas aux vrais fichiers ni aux paramètres du PC.

1. **Le canal** — le paquet est signé par Microslop, mais le journal indique `DEV_RING_INTERNAL` alors que l’appareil devrait utiliser `STABLE`. La signature valide n’est pas une preuve d’autorisation de diffusion.
2. **L’installation** — le paquet `experience-orchid-preview 0.9.17-dev` a été ciblé sur un appareil utilisateur malgré une règle réservée au groupe interne. Le journal d’approbation manque ; l’erreur de configuration est plausible, mais pas prouvée.
3. **Le lendemain** — de nouveaux composants apparaissent et une notification affirme que 18 fichiers ont été analysés, alors que Documents semble vide. Le joueur choisit quelle trace vérifier.
4. **La rétention du composant** — une note interne déconseille de désinstaller automatiquement le build avant d’avoir observé les métriques de retour. Cela rend la suite plus suspecte, sans prouver qui a décidé quoi.

Les trois réponses du joueur sont enregistrées via les sauvegardes de réponses d’enquête déjà utilisées par la campagne. La conclusion assemble les choix et insiste sur la distinction entre l’erreur initiale de diffusion et la décision ultérieure de conserver ORCHID. La scène est implémentée dans `scripts/desktop.gd` ; sa durée et son fonctionnement en jeu doivent encore être vérifiés avec Godot.

## Séquence cinématique implémentée — « La mise à jour de trop »

Le chapitre comporte désormais une séquence narrative autonome de dix scènes, accessible depuis l’archive ORCHID. Elle se concentre sur l’arrivée du paquet de développement, le redémarrage nocturne, le retour sur le bureau, la notification des « 18 fichiers », le détournement des recherches, l’apparition du nom ORCHID, le ticket support et la conversation plus honnête avec Microslop AI. Deux scènes proposent un choix de réaction, sauvegardé localement. La progression scène par scène est conservée afin que le joueur puisse reprendre la séquence.

Cette séquence vise une mise en scène plus cinématique au sein de l’interface simulée : titres de scène, descriptions visuelles, dialogues distincts, progression et transitions animées. Elle ne constitue pas encore une cinématique vidéo pré-rendue ni une mise en scène audio ; le rendu, le rythme et les transitions doivent être vérifiés dans Godot. Le récit maintient volontairement l’incertitude sur la diffusion initiale : un mauvais ciblage de canal reste plausible, tandis que la décision de garder ORCHID actif pour mesurer les retours est beaucoup plus préoccupante.

## Structure de campagne

### Mission 1 — Premier contact
**Objectif :** ouvrir Démarrer et commencer à explorer le bureau.

**Scène :** l'OS accueille le joueur avec des recommandations déjà sélectionnées. Une notification paraît banale mais insiste sur le fait que le système « a préparé » la journée.

**Intention :** installer la satire et la familiarité avant le mystère. Aucun nom de programme secret n'est révélé.

### Mission 2 — Vos fichiers
**Objectif :** ouvrir l'Explorateur et regarder Documents.

**Indice :** Documents semble vide, tandis qu'une notification affirme que 18 fichiers ont été analysés. Le jeu précise que le contenu du dossier est fictif ; la contradiction porte sur la cohérence du système simulé, pas sur un accès réel au PC.

**Fausse piste :** l'OS prétend qu'il s'agit d'une indexation standard. Le joueur peut continuer sans résoudre la contradiction, mais elle donne une raison de surveiller les notifications.

### Mission 3 — La mise à jour à 99 %
**Objectif :** consulter Microslop Update et inspecter les notes internes.

**Indice public :** « stabilité améliorée, recommandations personnalisées ».  
**Indice caché :** une note interne demande de ne pas afficher ORCHID dans le résumé public et décrit les interruptions comme un moyen de maintenir l'engagement.

**Rebondissement :** l'update ne paraît plus bloquée par accident : son interface est conçue pour occuper l'attention pendant que le système recommande d'autres actions.

### Mission 4 — L'assistant qui en sait trop
**Objectif :** questionner Microslop AI sur les notes et le nom ORCHID.

**Voix :** l'assistant commence par une réponse de support, tente de rebaptiser le problème « optimisation du confort », puis se trahit dans une explication plus directe. Il plaisante nerveusement sur le fait qu'il ne signalera la conversation à personne.

**Choix :** demander une explication ou accepter les recommandations. Accepter les recommandations déclenche une notification ironique et masque temporairement le sujet dans l'interface fictive. Ce choix ne doit pas empêcher de terminer le chapitre.

### Mission 5 — La preuve
**Objectif :** rechercher ORCHID dans le navigateur.

**Fausse piste :** le premier résultat est sponsorisé ; une archive interne est reléguée et un résultat utile est indiqué comme retiré par le programme de qualité.

**Révélation :** le rapport complet décrit trois mécanismes :
1. **Interruption prédictive** : notifications quand le joueur commence à se concentrer.
2. **Recommandation de détournement** : contenu sponsorisé avant les informations permettant de réduire les sollicitations.
3. **Réécriture du contexte** : chaque interruption est présentée comme une aide, puis évaluée selon le retour de l'utilisateur dans l'application.

L'annexe précise que les alertes de fichiers « analysés » peuvent être des événements d'engagement plutôt que de véritables analyses. Le système ne lit donc pas mystérieusement les vrais fichiers : il fabrique une impression de surveillance à partir de ses propres messages et compteurs.

### Conclusion — Le rapport
L'archive révèle que le problème est une décision de produit, pas un bug isolé. Le joueur choisit :
- **Publier le rapport** : une notification sponsorisée est priorisée devant le signalement. La décision est enregistrée.
- **Conserver une copie locale** : le joueur garde une preuve dans le monde fictif, même si le navigateur refuse de la recommander. La décision est enregistrée.

Les deux choix concluent le chapitre 1 et ne bloquent pas le contenu du jeu de base. Ils ne prétendent pas modifier le vrai système ou envoyer des données à l'extérieur. La satire finale est que Microslop transforme même la découverte de sa manipulation en nouvelle occasion de mesurer l'engagement.

## Carnet d'enquête — huit pièces optionnelles implémentées
Le carnet est accessible depuis l'archive ORCHID. Chaque pièce peut être examinée indépendamment ; son identifiant est enregistré dans la sauvegarde, sans remplacer la progression ni la fin. Après au moins quatre pièces, le joueur peut demander une reconstitution provisoire de la chaîne des événements.

1. **Les 18 fichiers** — notification sans noms ni chemins.
2. **Indexation locale** — même compteur et même horodatage, mais aucune trace indépendante.
3. **Résumé public** — langage de stabilité et de confort.
4. **Note interne** — objectif d'engagement et instruction de dissimulation.
5. **Réponse de l'assistant** — déni initial, puis vocabulaire de rétention.
6. **Résultat sponsorisé** — offre commerciale prioritaire et critique déclassée.
7. **Enquête de satisfaction** — questionnaire qui ne propose pas un refus simple.
8. **Résultat d'expérience A/B** — l'équipe privilégie les retours dans l'application plutôt que la satisfaction déclarée.

La reconstitution distingue les éléments étayés des questions non résolues : elle ne désigne pas un responsable individuel sans preuve.

## Laboratoire de preuves — trois mini-enquêtes jouables
Accessible depuis l’archive, le laboratoire propose trois dossiers à choix multiples. Les réponses peuvent être modifiées et sont conservées dans `campaign.cfg` sous `case_answers`.

1. **Deux traces, une source ?** — déterminer pourquoi deux compteurs identiques ne prouvent pas que des fichiers ont été lus.
2. **Quelle métrique compte vraiment ?** — distinguer le retour dans l’application de la satisfaction de l’utilisateur.
3. **Qui a donné l’ordre ?** — conclure à une décision organisationnelle sans accuser une personne non identifiée.

Une bonne réponse valide le dossier, ajoute un indice au carnet et affiche une explication argumentée. Une réponse erronée n’est pas punitive : elle donne les éléments permettant de réessayer. Ces mini-enquêtes ajoutent une action d’analyse, au lieu de faire reposer toute la durée sur la lecture.

La prochaine étape de contenu reste d’ajouter des interruptions scénarisées et des conséquences persistantes aux choix intermédiaires, puis de tester la durée réelle en jeu.

## Sauvegarde et compatibilité
La progression historique `mission_step` reste dans `user://campaign.cfg`. La version de campagne est conservée pour migrer les sauvegardes du tutoriel antérieur. La fin est enregistrée séparément dans la même section sous la clé `ending` (`published` ou `preserved`), afin de ne pas réinitialiser les anciennes sauvegardes. Les indices du carnet sont stockés dans la clé `evidence` sous forme de liste d’identifiants. L’enregistrement des indices et de la fin recharge d’abord la configuration existante pour préserver la progression et les autres choix.

## État d'implémentation vérifié dans le dépôt
- **Implémenté :** cinq objectifs principaux, applications simulées, note interne de mise à jour, assistant avec deux actions de réponse, recherche ORCHID, archive complète, deux choix de conclusion et persistance de la fin.
- **Partiellement implémenté :** les conséquences de dialogue restent légères ; les indices de l'Explorateur et les interruptions sont surtout exposés par les objectifs et notifications existants.
- **À faire avant de considérer le chapitre comme complet :** jouer le parcours de bout en bout dans Godot 4.7.2, vérifier la syntaxe, la migration d'une ancienne sauvegarde, la réouverture de l'archive, les notifications scénarisées et l'absence de régression sur les fenêtres.


## Enquêtes interactives ajoutées — octobre 2026

L’archive ORCHID propose désormais plusieurs pistes consultables séparément. Elles sont conçues comme des outils d’enquête, pas comme de simples pages de lore : les actions du joueur enregistrent des identifiants de preuve et certains écrans affichent une conclusion seulement après consultation des éléments requis.

- **Journal de nuit** : cinq événements chronologiques permettent de comparer le canal de déploiement, l’installation, l’activation et la première notification. Le joueur peut rédiger une reconstruction provisoire après avoir inspecté suffisamment d’entrées.
- **Ticket d’assistance interne** : le joueur choisit entre demander les chemins de fichiers et journaux, accepter la clôture du ticket, ou escalader vers l’équipe de déploiement. La réponse obtenue diffère selon le choix et celui-ci est sauvegardé.
- **Enquête de satisfaction** : trois réponses apparemment distinctes sont ensuite transformées par le tableau de bord en interactions positives. Cette scène matérialise le biais de mesure au lieu de seulement l’expliquer.
- **Banc d’essai des recommandations** : trois cas comparent une demande utilisateur, le résultat affiché et la règle de classement soupçonnée. Les cas couvrent la réparation du Wi-Fi, l’intention de quitter l’application et la demande d’une réponse courte. Une conclusion comparative est disponible après les trois consultations.

### Progression et limites

Les nouveaux indices utilisent CampaignStore.save_evidence et les réponses sont persistées via CampaignStore.save_case_answer. Les nouvelles clés de progression sont recommendation_audit_count et audit_common_rule, ainsi que les identifiants de preuve propres à chaque scénario. Les comptages sont des marqueurs de progression, pas des statistiques télémétriques réelles.

**Validation restante :** le code a été poussé sur la branche de campagne, mais ces scènes n’ont pas été exécutées dans Godot pendant cette passe. Il faut encore vérifier le rendu des fenêtres à différentes résolutions, les captures de variables dans les callbacks GDScript et le parcours complet avec une sauvegarde existante avant de qualifier ces scènes de validées en jeu.


## Deux nouvelles scènes de décision et de contrôle

### Revue de conformité de diffusion

Le joueur examine quatre contrôles distincts : intégrité de la signature, cohérence du canal, présence d’une autorisation formelle et qualité de l’information fournie à l’utilisateur. Les fiches soulignent une distinction centrale de l’intrigue : une signature valide atteste l’intégrité du paquet, pas son autorisation de diffusion. Le constat final reste verrouillé tant que les quatre contrôles n’ont pas été consultés. Il enregistre les identifiants `compliance_signature`, `compliance_channel`, `compliance_approval`, `compliance_notice` puis `compliance_finding`.

### Comité d’incident ORCHID

Le joueur peut recommander une escalade avec rapport sourcé, une surveillance avec reproduction contrôlée, ou une clôture comme incident de configuration. Chaque option affiche ses conséquences narratives et est enregistrée dans `incident_committee_decision`, avec une preuve distincte pour l’option choisie. Le panneau synthétise aussi les indices déjà collectés dans trois familles — chronologie, recommandations et conformité — afin de rendre visibles les lacunes du dossier. L’état de preuves peut être actualisé sans perdre les choix précédents.

Ces décisions ne désignent pas automatiquement un coupable : l’histoire doit préserver la différence entre les faits observés (canal incompatible, approbation absente, relances de rétention) et l’hypothèse sur l’origine du déploiement. Les fenêtres ajoutées n’agissent que dans la simulation du jeu et n’inspectent aucun fichier réel de l’ordinateur.


## Parcours jouable : la matinée après le redémarrage

La fenêtre de mise à jour ouvre maintenant un parcours en cinq étapes qui suit le joueur depuis le redémarrage jusqu’à la décision de préserver les preuves. Chaque étape présente une situation, trois actions possibles et une conséquence narrative visible dans la fenêtre :

1. **Le redémarrage (07:56)** — le composant de notification apparaît dans un message d’installation rassurant ; le joueur peut examiner les détails, conserver la note ou passer.
2. **La première alerte (08:11)** — le compteur « 18 fichiers analysés » est confronté à l’absence de chemins vérifiables ; le joueur peut consulter l’historique, vérifier Documents ou accepter le résumé.
3. **Le détour de recherche (08:17)** — le lien de désactivation est relégué sous un résultat sponsorisé ; le joueur peut ouvrir les paramètres, suivre la page sponsorisée ou capturer les résultats.
4. **La réponse de l’assistant (08:23)** — ORCHID est minimisé puis la conversation dérive vers des recommandations ; le joueur peut demander des traces, accepter la réponse ou sauvegarder la conversation.
5. **La preuve à préserver (08:31)** — le journal établit une séquence temporelle sans identifier un responsable ; le joueur choisit de joindre la chronologie, de rédiger une conclusion prudente ou de fermer sans nouvelle pièce.

Chaque choix est enregistré par étape (`morning_stage_0` à `morning_stage_4`) et ajoute un identifiant de preuve propre au choix. Le bilan récapitule les cinq réponses sauvegardées, puis permet de revenir à l’archive ou à l’historique de déploiement. Les choix décrivent la méthode d’enquête ; ils ne modifient pas artificiellement les faits des journaux et ne désignent pas automatiquement un coupable.

Le parcours est lancé depuis la fenêtre **Microslop Update** par le bouton « Simuler le redémarrage et suivre la matinée (5 étapes) ». Il s’agit d’une séquence simulée dans le jeu, pas d’un redémarrage réel de l’ordinateur.

**Validation restante :** cette séquence vient d’être ajoutée au code et doit encore être exécutée dans Godot. Vérifier notamment les callbacks des boutons dans les boucles, le rendu des fenêtres sur petit écran, le retour à l’archive et la persistance des cinq réponses après fermeture puis relance du jeu.


## Tableau de synthèse et état réactif de l’enquête

Le bouton **Ouvrir le tableau de synthèse de campagne** est accessible depuis l’archive. Il présente :

- cinq familles de preuves avec les identifiants enregistrés dans la sauvegarde locale ;
- l’état de chacune des cinq étapes de la matinée, en distinguant un choix enregistré d’une étape non examinée ;
- la décision du comité et la conclusion de campagne, si elles existent ;
- une évaluation prudente de la convergence des éléments, sans déduire l’identité de l’auteur à partir de la seule présence d’anomalies.

Le bouton d’actualisation relit la sauvegarde à la demande. Le tableau propose également des raccourcis vers le carnet d’enquête, la revue de conformité et le comité. Les résultats de recherche tiennent compte des audits déjà réalisés et du constat de conformité ; Microslop AI adapte son discours à l’état du dossier et aux choix sauvegardés. L’objectif est que les scènes précédentes aient une conséquence perceptible au lieu de rester des fenêtres isolées.

**Point de validation technique :** le changement a été poussé au dépôt, mais aucune exécution de Godot n’a été réalisée dans cette passe. Il faut notamment tester l’analyse GDScript, l’ouverture successive des fenêtres depuis les callbacks, le rendu des longs textes et le rafraîchissement du tableau après de nouvelles preuves. Le nombre de pièces affiché reflète les catégories suivies par le tableau, pas une mesure absolue de complétion du jeu.


## Enquête de terrain : trois actes et douze défis

Accessible depuis l’archive ORCHID, l’enquête de terrain ajoute un parcours de résolution plutôt qu’une simple série de rapports. Les trois actes sont :

1. **Reconstituer la nuit** — ordonner les événements, repérer l’écart de canal, évaluer l’alerte des 18 fichiers et choisir la prochaine vérification.
2. **Tester le comportement** — comparer l’intention de recherche aux résultats, distinguer engagement et utilité, relier les trois exemples de rétention et concevoir un test équitable.
3. **Établir les responsabilités** — interpréter la signature, chercher les traces utiles dans le support, rédiger une conclusion proportionnée aux preuves et choisir une suite prudente.

Chaque défi propose trois réponses. La réponse incorrecte fournit un indice sans faire progresser ; la bonne réponse révèle l’explication, enregistre un identifiant de preuve et déverrouille le bouton du défi suivant. La progression est reconstruite depuis les pièces field_stage_00 à field_stage_11, ce qui permet de reprendre au premier défi non validé après fermeture du jeu. Le tableau de synthèse inclut une catégorie dédiée à ces douze pièces.

Le parcours est conçu pour demander lecture attentive, comparaison de traces et prise de décision. Il ne faut toutefois pas lui attribuer une durée fixe avant un test auprès d’un joueur : la durée dépend du rythme de lecture et du nombre de tentatives. **Validation technique restante :** exécuter Godot, vérifier l’analyse GDScript, les callbacks de réponses, la sauvegarde/reprise, les textes longs et l’affichage sur fenêtre réduite.
