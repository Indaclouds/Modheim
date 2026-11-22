<p align="center"><img src="assets/logo.svg" alt="Modheim" width="560"></p>

## La liste des mods

| Mod | Ce qu'il fait | Installé sur | Version |
|---|---|---|---|
| [BepInEx](https://thunderstore.io/c/valheim/p/denikson/BepInExPack_Valheim/) | Chargeur de mods (mod loader) | Serveur + Client | 5.4.2360 |
| [Jotunn](https://thunderstore.io/c/valheim/p/ValheimModding/Jotunn/) | Bibliothèque utilisée par les autres mods | Serveur + Client | 2.30.2 |
| [Heightmap Unlimited JvL](https://thunderstore.io/c/valheim/p/Digitalroot/Heightmap_Unlimited_JvL/) | Creuser et monter le terrain sans la limite | Serveur + Client | 2.0.2 |
| [ValheimInfiniteFire](https://thunderstore.io/c/valheim/p/MidnightMods/ValheimInfiniteFire/) | Torches sans combustible | Serveur + Client | 1.4.0 |
| [Equipment and Quick Slots](https://thunderstore.io/c/valheim/p/RandyKnapp/EquipmentAndQuickSlots/) | Emplacements dédiés pour l'équipement + 6 raccourcis rapides | Serveur + Client | 3.2.1 |
| [PlanBuild](https://thunderstore.io/c/valheim/p/MathiasDecrock/PlanBuild/) | Copier-coller des constructions (plans à remplir avec les matériaux) | Serveur + Client | 0.20.0 |
| [NetworkPerformanceSystem](https://thunderstore.io/c/valheim/p/MidnightMods/NetworkPerformanceSystem/) | Réseau optimisé, surtout quand un joueur a un ping élevé | Serveur + Client | 1.18.2 |
| [ValheimCommunityPatch](https://thunderstore.io/c/valheim/p/MidnightMods/ValheimCommunityPatch/) | Corrige des bugs et lenteurs de Valheim, sans changer le gameplay | Serveur + Client | 0.46.0 |
| [ValheimPerformanceOptimizations](https://thunderstore.io/c/valheim/p/ontrigger/ValheimPerformanceOptimizations/) | Plus de FPS, surtout dans les grosses bases | Client | 2.2.0 |
| [Server Devcommands](https://thunderstore.io/c/valheim/p/JereKuusela/Server_devcommands/) | Commandes admin sur le serveur (debugmode, god, fly…), réservées aux admins | Serveur + Client | 1.116.0 |
| [MultiUserChest](https://thunderstore.io/c/valheim/p/MSchmoecker/MultiUserChest/) | Plusieurs joueurs peuvent ouvrir le même coffre en même temps | Serveur + Client | 0.6.2 |
| [NoRainDamage](https://thunderstore.io/c/valheim/p/JoelOliMclean/NoRainDamage/) | La pluie n'abîme plus les constructions (plus d'aspect usé/vert) | Serveur + Client | 1.3.2 |
| [PlantEasily](https://thunderstore.io/c/valheim/p/Advize/PlantEasily/) | Mod QoL pour planter et récolter | Client | 2.3.1 |
| [Valheim Clock](https://thunderstore.io/c/valheim/p/orfox/ValheimClock/) | Horloge sous la minimap | Client | 1.5.3 |
| [RememberServerPassword](https://thunderstore.io/c/valheim/p/MagiCorp/RememberServerPassword/) | Retient le mot de passe du serveur + bouton « Quick Connect » | Client | 1.2.4 |

## Comment utiliser ?

1. Fermer Valheim.
2. Ouvrir **PowerShell** sur son ordinateur.
3. Coller cette commande et appuyer sur Entrée :

```powershell
irm https://raw.githubusercontent.com/Indaclouds/Modheim/main/install.ps1 | iex
```

4. Le script affiche la liste des mods (nouveaux, mises à jour, déjà installés) et propose :
   - **1** : Tout installer / mettre à jour (recommandé, Entrée seule)
   - **2** : Choisir les mods à installer (les mods décochés sont retirés)
   - **3** : Supprimer des mods (tout, ou seulement certains)
   - **4** : Quitter sans rien changer
5. Lancer Valheim depuis Steam, comme d'habitude.

### Mettre à jour

Quand la liste des mods change, il suffit de relancer la même commande : elle ajoute les nouveaux mods, retire ceux qui ne sont plus dans la liste et met à jour les versions.

## Dossier Valheim introuvable

Si Valheim n'est pas trouvé (installation hors Steam, par exemple), indiquer le dossier du jeu avec l'argument `-GamePath` :

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Indaclouds/Modheim/main/install.ps1))) -GamePath "D:\Jeux\Valheim"
```

## Reset de tous les mods

Pour remettre le jeu sans les mods, utiliser l'argument `-Uninstall` :

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Indaclouds/Modheim/main/install.ps1))) -Uninstall
```
