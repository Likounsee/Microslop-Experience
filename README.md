# Microslop Experience

**Microslop Experience** is a satirical desktop simulation planned for commercial release on Steam. You try to use a familiar-looking computer while ads, unwanted recommendations, updates, and an overly enthusiastic AI assistant get in the way.

> The game simulates its own desktop. It does not modify the player's real Windows settings or access personal files.

## Current status

**Prototype stage — P0 in progress.** The repository now contains a Windows 11-inspired desktop shell using the wallpaper supplied in `assets/wallpaper.jpg`, a floating translucent centered taskbar, a Start menu with a pinned-app grid, a quick-settings flyout with working in-game volume control, rounded draggable app windows with minimize/maximize/close controls, interactive simulated applications, timed notifications, a three-step tutorial mission, locally saved campaign progress, and persistent display, audio, and FPS settings. Notification count and open windows are bounded to avoid unbounded UI growth.

## Direction

The game combines three elements:

- **A fake desktop OS:** a convincing desktop shell that acts as the stage, not the main goal.
- **A narrative campaign:** the player starts with ordinary setup tasks, notices suspicious update notes, discovers the internal ORCHID programme through the AI assistant, and finds evidence that interruptions are deliberately engineered to maximize engagement.
- **A systemic comedy layer:** ads, update prompts, AI suggestions, and events that interrupt the player at increasingly revealing moments.

### Story chapter 1 — ORCHID

Chapter 1 is an investigation told through the simulated desktop. The update now exposes an interactive four-stage deployment-history investigation: the player finds a developer-only build on a stable-channel device, compares the missing approval record, follows the suspicious file-analysis notification, and weighs whether the original installation was a configuration error or deliberate. A later note suggests the component was kept active to observe return metrics, but the logs do not identify a single culprit. Choices are saved in the existing campaign file. The browser now opens a full internal report describing predictive interruptions, sponsored-result diversion, and the rebranding of engagement metrics as user comfort. A new investigation casebook contains eight evidence pieces spanning notifications, indexing, update notes, AI dialogue, sponsored results, biased surveys, and an A/B test; the player opens each piece, tracks collected evidence across sessions, and can reconstruct a provisional timeline after examining at least four. The player can publish the report or keep a local copy; that ending choice is saved separately in the existing campaign file. The AI now deflects before explaining the clue, and accepting recommendations remains a satirical detour rather than a softlock. The full narrative, evidence chain, and remaining implementation work are tracked in [`docs/ORCHID_CAMPAIGN.md`](docs/ORCHID_CAMPAIGN.md).

### Cinematic story sequence — Chapter 1

Chapter 1 now includes a **36-scene narrative sequence**, “La mise à jour de trop”, accessible from the ORCHID archive. It begins with the overnight update and follows the next day through interruptions during work and a meeting, messages with Léa, an unhelpful support response, a follow-up meeting that sanitizes complaints, a report that gets rewritten, and a patch whose effectiveness is uncertain. Ten choices are saved locally; later scenes change some dialogue based on those choices, and progress can be resumed.

The story prioritizes character moments, escalation, humor and cinematic-style transitions over a chain of investigation quizzes. It uses in-game UI, scene titles, dialogue and animated transitions rather than pre-rendered video. Godot runtime verification is still pending. Chapter 2 remains separate DLC and is not part of this work.

### Laboratoire expérimental jouable

L’archive ORCHID includes a configurable A/B test bench: choose one of three user scenarios, select notification timing, choose the metric the dashboard optimizes, and decide whether explicit refusal is respected. It runs three fictional variants across eight simulated profiles, compares task completion with returns after notifications, flags cases where engagement rises while task success falls, and lets the player archive the result as campaign evidence. Results are deterministic and explicitly labelled pedagogical—not real telemetry or statistically valid research. Configuration and evidence are saved in the existing campaign save.



### Parcours jouable — « Une journée avec ORCHID »

En complément des 36 scènes narratives, l’archive propose maintenant une journée interactive en **41 séquences**, sept actes et un épilogue. Le joueur doit réellement choisir quoi fermer, quoi enregistrer, quoi répondre à Léa, comment gérer les interruptions en réunion, quelle formulation garder dans le rapport et comment transmettre les éléments. Chaque décision affiche une conséquence immédiate et reste sauvegardée ; le parcours reprend à la première séquence non terminée. Les choix couvrent aussi les limites de ce que les preuves permettent d’affirmer : le récit évite de transformer une notification douteuse en preuve d’accès aux fichiers ou d’inventer un responsable. Ce parcours est du contenu narratif jouable supplémentaire, pas une promesse de durée mesurée ; il reste à valider dans une exécution réelle de Godot.

### Chapter 2 — Separate DLC: your home OS

The second chapter is planned as a separately distributed DLC, not as a required continuation bundled into the base game. It will focus on the creator's own operating system, designed to replace Windows. Its name, interface, capabilities, lore, and missions will be defined only after the creator supplies the OS files and documentation; the project will not invent technical claims about it. The base game remains complete and playable without this DLC. The in-game teaser currently marks Chapter 2 as in preparation.

The DLC architecture and outstanding requirements are tracked in [`dlc/chapter-2/README.md`](dlc/chapter-2/README.md).

## Technology

- Godot 4.4+
- GDScript
- Windows-first desktop release
- All desktop behaviour is simulated inside the game

## Run locally

1. Install the stable Godot 4.x standard build from <https://godotengine.org/download/windows/>.
2. Open `project.godot` in Godot Project Manager.
3. Press **F6** to run the current scene or **F5** to run the project.

Keyboard shortcuts in the prototype:
- `F1`: open Settings
- `F2`: advance the prototype mission (progress is saved locally)
- `Esc`: close the Start menu and quick settings

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| P0 | Project foundation, desktop shell, window system | In progress |
| P1 | Fake OS applications and persistent display/audio/performance settings | Partly prototyped |
| P2 | Campaign, missions, ads, update events and progression | ORCHID report, two saved endings, evidence casebook, 36-scene narrative sequence, 41-stage interactive workday, and configurable three-variant A/B test simulator implemented; runtime QA, audio and systemic interruption polish remain |
| P3 | Audio, animation, accessibility, saves and polish | Planned |
| P4 | Steam store page, builds, QA and release | Planned |

Percentages will be reported as estimates based on verified implementation and tests, not as claims that unimplemented work is complete.

## Development principles

- Never access or alter the player's real personal files or Windows settings.
- Keep simulated OS behaviour isolated inside the game.
- Save game settings under Godot's `user://` path.
- Prefer small, testable systems over one giant script.
- Do not claim a test or build passed unless it was actually run.


### Windows 11-inspired visual pass

The desktop UI uses a consistent light acrylic-inspired palette, more pronounced rounded surfaces and shadows, a narrower centered taskbar, and matching Start, Quick Settings, notification, mission, and app-window surfaces. App windows now restore their previous position and size when unmaximized, and dragging keeps enough of the title bar on-screen to recover a window. These are in-game visual approximations, not native Windows acrylic or blur effects.


### Desktop interaction polish

The Start menu now has a Windows 11-inspired pinned-app header, a distinct recommended/sponsored card, and a profile/power row. The system-tray clock is presented on a compact two-line layout. App windows raise when clicked and support double-clicking the title bar to maximize or restore. Power options remain simulated in-game and never affect the host operating system.


### Version du moteur

Le projet et la CI ciblent Godot **4.7.2-stable**, dernière version stable au moment de cette mise à jour. Godot 4.8 étant encore en bêta, il n'est pas utilisé sur la branche de production. La CI importe/vérifie le projet et lance la scène principale en mode headless.


### Enquêtes ORCHID approfondies

L’archive de campagne comprend maintenant des enquêtes interactives supplémentaires : journal chronologique du déploiement, ticket d’assistance interne avec choix de réponse, enquête de satisfaction dont le tableau de bord révèle le biais de mesure, et banc d’essai comparant trois recommandations à l’intention initiale de l’utilisateur. Les éléments examinés sont ajoutés au dossier de preuves via la sauvegarde de campagne. Ces scènes restent à valider dans une exécution réelle de Godot ; leur présence dans le dépôt ne signifie pas que le parcours a déjà passé les tests en jeu.


### Contrôle de diffusion et comité d’incident

L’archive ORCHID inclut aussi une revue de conformité en quatre contrôles (signature, canal, approbation et information utilisateur) ainsi qu’un comité d’incident proposant trois décisions persistantes : escalader avec un rapport sourcé, surveiller et reproduire, ou clore comme incident de configuration. Un récapitulatif classe les indices collectés par famille. Ces ajouts narratifs restent à valider par exécution dans Godot avant d’être considérés comme testés.


### Parcours interactif après redémarrage

La fenêtre de mise à jour propose désormais une séquence narrative en cinq étapes : redémarrage, première notification, recherche de désactivation, conversation avec l’assistant et décision sur la preuve à conserver. Trois actions sont proposées à chaque étape ; leurs conséquences sont affichées et les réponses sont sauvegardées séparément. Le bilan final récapitule la progression et donne accès à l’archive ou à l’historique du déploiement. Cette séquence reste à valider par exécution dans Godot.


### Tableau de synthèse et conséquences réactives

L’archive ORCHID donne accès à un tableau de synthèse persistant qui regroupe cinq familles de preuves, les cinq décisions du parcours de redémarrage, la décision du comité et la conclusion choisie. Le tableau distingue enquête en cours, faisceau partiel et convergence de plusieurs sources ; il ne prétend pas identifier l’auteur sans trace correspondante. Les dialogues de Microslop AI et les résultats de Recherche réagissent désormais aux preuves déjà sauvegardées : une enquête avancée modifie les réponses de l’assistant, et les audits/conclusions de conformité rendent visibles des avertissements dans la recherche. Les doublons de commandes d’interface dans l’archive et la fenêtre de mise à jour ont aussi été retirés. Cette passe n’a pas été exécutée dans Godot : ces changements sont présents dans le code mais restent à vérifier en jeu.


### Enquête de terrain jouable — 12 défis à validation

L’archive ORCHID donne accès à une nouvelle enquête structurée en trois actes et douze défis : reconstituer la chronologie, tester les mécanismes de rétention, puis évaluer la chaîne de conformité et rédiger une conclusion prudente. Chaque défi présente des traces, une question à résoudre et trois réponses. Une réponse incorrecte affiche un indice et permet de réessayer ; seule la bonne réponse valide la pièce et débloque l’étape suivante. Les validations sont sauvegardées et le parcours reprend au premier défi non résolu. Le tableau de synthèse inclut ces pièces. Cela ajoute des décisions réelles au-delà de la lecture des fenêtres, mais la durée réelle dépend du temps de réflexion du joueur. **Non testé en exécution Godot dans cette passe.**


### Interactive ORCHID notification controls

The ORCHID archive and campaign dashboard now expose a notification control center. The player can choose standard delivery, block promotional toasts, or keep promotional alerts in the notification history without interrupting the desktop. System-status alerts remain visible in all modes. The controls affect actual in-game toast delivery, save the selected policy in the campaign save, and provide promotional/system test buttons plus evidence checks. This is an in-game simulation only; it does not change host OS settings.


### ORCHID task sprint

The ORCHID archive now includes a separate thirteen-task interactive work sprint: finish a document, handle a sponsored interruption, prepare for a meeting, inspect a misleading urgent alert, and report outcomes. Choices have distinct feedback and quality-score impacts. Some choices trigger simulated promotional notifications, which obey the player's saved notification policy. Stage, choices, score, and interruption count persist separately from the 41-scene workday; the sprint can be replayed from its ending screen. All scenarios are fictional and the score is a gameplay signal, not scientific productivity measurement.


### ORCHID incident-response tabletop

A twelve-decision incident exercise is available from the ORCHID archive, spanning containment, evidence, hypothesis testing, communication, remediation, and committee handoff. Each decision has three options, consequences, persistent progress, and a score-dependent ending. Containment choices can change the saved in-game notification policy, so this activity interacts with the existing notification center. The scenario is fictional and is not a real security audit.


### Dossier transversal ORCHID

Nouveau parcours jouable en dix étapes, du triage du signalement à la passation documentée. Il sauvegarde les décisions, produit des preuves, relie le confinement à la politique de notifications et propose un bilan rejouable. Les scénarios sont fictifs. Voir [la documentation de campagne](docs/ORCHID_CAMPAIGN.md).


Les décisions des parcours ORCHID (cinématique, sprint, workflow et exercice de crise) enregistrent désormais leurs réponses et leur marqueur de preuve dans une seule écriture de sauvegarde. En cas d’échec disque, l’interface n’applique pas le score local ni ne valide le choix comme enregistré. La suite de tests couvre aussi les écritures atomiques et leur échec.


Les effets secondaires des décisions du workflow et de l’exercice de crise sont maintenant inclus dans la même écriture que le choix, le score et la preuve. L’avancement vers l’étape suivante vérifie aussi le succès de la sauvegarde avant de modifier l’interface : une panne disque ne fait plus avancer un parcours à tort.

Les tests couvrent désormais aussi la reprise après fermeture simulée : une instance fraîche du magasin relit choix, score et preuve d’une décision atomique. La réinitialisation cinématique est rejouée pour vérifier qu’elle reste idempotente et préserve les données hors parcours ; une sauvegarde illisible doit faire échouer le reset sans écrasement. Ces cas sont couverts par la CI headless, sans remplacer un test manuel dans Godot.

### Réinitialisation atomique des parcours ORCHID

Le rejeu du sprint de travail, du dossier transversal et de l’exercice de crise réinitialise maintenant les réponses, le score et la progression dans une seule écriture. Les preuves historiques propres au parcours rejoué sont nettoyées dans la même opération, tandis que les réponses et preuves des autres dossiers restent conservées. Si la sauvegarde échoue, l’interface garde le bilan terminé et affiche une erreur au lieu de prétendre avoir recommencé. Les tests couvrent la remise à zéro, le nettoyage ciblé des preuves, la conservation des données sans rapport et le rejet d’une demande de reset invalide.

À la reprise du sprint, du dossier transversal et du tabletop de crise, l’étape, le score et les compteurs associés sont maintenant lus depuis un même instantané de sauvegarde. Les valeurs restaurées sont bornées selon les limites de chaque parcours ; une entrée absente ou mal formée ne peut plus injecter un score arbitraire dans le bilan. Des tests headless vérifient la lecture groupée, les valeurs manquantes et la reprise des données enregistrées.

Le bilan du sprint affiche désormais le même dénominateur maximal (26 points) dans toutes ses issues. Les tests de reprise couvrent aussi les réponses sauvegardées avec un type incorrect ou hors limites ; elles sont traitées comme absentes plutôt que réinjectées dans l’état de jeu.

### Vérification et remplacement des sauvegardes ORCHID

Le magasin de campagne écrit désormais les modifications dans un fichier temporaire voisin, relit ce fichier pour vérifier qu'il est interprétable, puis remplace la sauvegarde existante en conservant temporairement une copie de secours. Si le remplacement échoue, il tente de restaurer l'ancienne sauvegarde et signale l'échec au lieu de confirmer la transaction. Les tests de `CampaignStore` vérifient aussi le nettoyage des fichiers temporaires et de secours après une écriture réussie. La suite headless doit être exécutée par la CI ; ces changements ne remplacent pas une vérification manuelle des parcours dans Godot.

### Récupération après interruption d'une sauvegarde

La couche de persistance distingue maintenant le code d'erreur du résultat de sauvegarde : un enregistrement réussi renvoie `OK`, et non un booléen interprété comme une erreur. À la lecture, si le fichier principal est absent ou illisible, le magasin vérifie le fichier `.bak` et restaure une copie valide laissée par une interruption entre la mise à l'abri de l'ancien fichier et son remplacement. Un test de régression simule cet arrêt en déplaçant la sauvegarde principale vers le fichier de secours, puis vérifie la récupération des données. Cette couverture est ajoutée à la suite headless, mais son exécution CI reste à confirmer.

Les chemins de lecture des réponses, preuves, conclusions et brouillons passent également par cette récupération commune : un fichier principal absent ou mal formé ne masque donc pas automatiquement une sauvegarde de secours valide. Les tests couvrent maintenant les deux situations — fichier principal absent et fichier principal corrompu — sans prétendre remplacer l'exécution de la suite dans Godot.


### Tolérance aux fichiers de secours obsolètes

Lors d'une nouvelle écriture, le magasin valide d'abord la sauvegarde principale avant de remplacer un fichier `.bak` résiduel. Si le fichier principal est valide, un ancien fichier de secours corrompu est nettoyé au lieu de bloquer indéfiniment toute sauvegarde ; si le principal est illisible, le fichier de secours est conservé et l'écriture échoue sans l'écraser. Des tests de régression couvrent le nettoyage et la conservation des données existantes. L'exécution Godot/CI doit encore confirmer ces cas.


Les tests vérifient aussi le scénario où la sauvegarde principale et le fichier `.bak` sont tous deux mal formés : la lecture échoue proprement et les deux fichiers sont conservés pour diagnostic, plutôt que supprimés au cours d'une tentative de récupération. Le test restaure ensuite son fixture valide avant de poursuivre les cas d'échec d'écriture.

### Persistance atomique des paramètres

Les paramètres utilisateur sont maintenant écrits dans un fichier temporaire, relus pour vérifier chaque valeur, puis installés par remplacement avec une sauvegarde intermédiaire. Si l'écriture ou le remplacement échoue, la valeur en mémoire revient à son état précédent ; le magasin refuse aussi d'écraser une configuration existante illisible. La CI lance une suite dédiée qui couvre l'écriture, le rechargement dans une nouvelle instance, le rejet des valeurs invalides et le rollback après échec. L'exécution réelle de cette suite doit encore être confirmée par un résultat GitHub Actions.
