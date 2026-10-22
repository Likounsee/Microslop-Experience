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
