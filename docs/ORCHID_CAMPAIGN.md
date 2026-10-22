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

## Indices secondaires à développer
- Comparer la notification « 18 fichiers analysés » au contenu vide de Documents.
- Réexaminer la mise à jour après avoir parlé à l'assistant : les formulations « confort » et « engagement » décrivent la même mécanique.
- Rechercher un terme générique comme « désactiver les notifications » pour voir le navigateur prioriser les recommandations.
- Remarquer la formulation passive « résultat retiré » : aucun responsable n'est nommé.
- Revenir à l'archive après avoir fait un choix : la sauvegarde doit conserver la fin sélectionnée.

## Sauvegarde et compatibilité
La progression historique `mission_step` reste dans `user://campaign.cfg`. La version de campagne est conservée pour migrer les sauvegardes du tutoriel antérieur. La fin est enregistrée séparément dans la même section sous la clé `ending` (`published` ou `preserved`), afin de ne pas réinitialiser les anciennes sauvegardes. Les choix de dialogue et les indices secondaires devraient être stockés dans des clés supplémentaires, sans modifier ni supprimer les clés historiques.

## État d'implémentation vérifié dans le dépôt
- **Implémenté :** cinq objectifs principaux, applications simulées, note interne de mise à jour, assistant avec deux actions de réponse, recherche ORCHID, archive complète, deux choix de conclusion et persistance de la fin.
- **Partiellement implémenté :** les conséquences de dialogue restent légères ; les indices de l'Explorateur et les interruptions sont surtout exposés par les objectifs et notifications existants.
- **À faire avant de considérer le chapitre comme complet :** jouer le parcours de bout en bout dans Godot 4.7.2, vérifier la syntaxe, la migration d'une ancienne sauvegarde, la réouverture de l'archive, les notifications scénarisées et l'absence de régression sur les fenêtres.
