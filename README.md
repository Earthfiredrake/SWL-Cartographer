# TSW-Cartographer
Supplementary world maps for Secret World Legends
Legacy support for The Secret World is largely untested and provided waypoint packs use SWL locations. I will not be taking the time to generate waypoints for TSW myself, but would be willing to include an alternative pack if one was volunteered.

## Overview
This mod is in an early state of development, consider this to be a wishlist, and consult the changelog for which parts have been implemented. It intends to provide a supplement to the ingame regional and dungeon maps, with various improvements:
+ Multiple icons for custom map notations
  + Assigned by type, but may be overridden individually (ex: The location to use a password required to access a lore may count as a "lore" marker, but use the "password" icon)
  + User customization of the map icons, including replacing most icons or adding their own, without requiring a flash compiler
+ Zone and path marking in addition to point locations
+ More support for extended descriptions and precise placement based on coordinates
+ Premade packages of related markers which can be loaded or toggled as a package
  + ex: A package for Samhain (TSW) might include lore, quests, vendors, rider/summon/empowerment points
  + These packages may also include more general packs of Lore, Rare Spawns, etc.
  + As much as possible the locations included in these packs will use verified exact game locations
    + This may result in one or more utility mods designed to provide absolute locations of various game objects
    + This will also likely result in an automatic marking system from LoreHound
	+ Had a thought about feeding data back to LoreHound, but lack enough camera info to create my own world-screen calculation, and the existing one requires a dynel and doesn't work on arbitrary points
  + While the native format will likely not be compatible with existing waypoint packs (Lassie's etc.), I may see if I can handle their format as well at least on a transition basis
  + I'd love for this to be a full plugin system, adding custom logic to the provided waypoints
    + I have no idea where to even begin with this part of the concept but no shortage of random ideas if it can be made to work:
	  + Extracting lore and worldboss packs, with the logic required to provide ids and verify completion into optional plugins
      + A pack for the museum, showing exhibit locations and an overview of their levels, upgradability, requirements etc.
+ Filter, highlight and search for particular map marks:
  + ex: Unclaimed lore, missing rare spawn achivements

Due to limitations with the API, it does not seem to be possible to:
+ Integrate with the existing map in any meaningful way
  + Existing map can not be modded, and renders above all other UI elements, preventing an overlay system
  + Existing map waypoint data can not be used directly
    + Default ones with points of interest are malformed as far as the flash XML loader is concerned
	+ Flash is unable to reliably access the user's custom waypoint file (can only access relative paths on same drive (no C:\ and no %LocalAppData%), could be circumvented with junction points but would require non-trivial additional setup)
  + This mod will be duplicating as much existing functionality as is possible and be a second map window in game
+ Entirely replace the existing map's functionality
  + Anima leap and the long range detection of champion monsters and world bosses is not yet understood
    + It may be easier to integrate zone teleportation (the Shift-T menu)
+ Directly save player added waypoints to the xml files containing pre-packaged info
  + Manual export and sharing features may be supported
  + Custom waypoints will have to be saved with other mod settings
    + This will likely have a slightly different data layout than the waypoint pack files, because the universe enjoys making me write parsers

The mod is currently in alpha, with limited functionality. Some graphics are temporary placeholders of less than desired quality. Settings may be reset while upgrading.

All settings are saved account wide and will be shared across characters. If you'd rather have different settings for each character, renaming the file "LoginPrefs.xml" to "CharPrefs.xml" when installing/upgrading the mod should work without any problems. A clean install of the mod is recommended if doing this, as it will be unable to transfer existing settings anyway.

## Installation
Any packaged release should be unzipped (including the internal Cartographer folder) into the appropriate folder and the client restarted.
<br/>TSW: [TSW Directory]\Data\Gui\Customized\Flash.
<br/>SWL: [SWL Directory]\Data\Gui\Custom\Flash.

The safest method for upgrading (required for installing) is to have the client closed and delete any existing .bxml files in the Cartographer directory. Hotpatching (using /reloadui) works as long as neither Modules.xml or LoginPrefs.xml have changed.

I intend to permit setting migration from the first public beta to v1.0.x, but this may be subject to change. As with my other mods, this update compatibility window will occasionally be shifted to reduce legacy code clutter.

## Change Log

Version Next
+ Change to Modules.xml & LoginPrefs.xml (standardization of DV names)

Version 0.1.4-alpha
+ Krampusnacht waypoint pack
  + All open world lore (added to Lore layer)
  + Incomplete sample of Krampus spawn points (on a new layer, though it uses the champ mob icon)
  + The pack *should* automatically stop loading once the event ends (and maybe even come back next year)
+ Circles now more circular
+ Tooltips on paths
  + Additional mouse interaction TBD

Version 0.1.3-alpha
+ More detailed tooltips
+ Adds clutter; I've a couple ideas for how to reduce this, but it'll take a little while
+ Path notations
  + No tooltips (or other mouse interaction) yet
  + Patrolling champion bosses now included with patrol paths
    + All champions except Deathstalker and Congealed Disgust accounted for
+ Area notations
  + Mobs that drop bestiary lore have been surveyed and their habitats marked
  + Most lore now accounted for (a few are still missing in mapped areas)

Version 0.1.1-alpha
+ It zooms, it scrolls, hopefully it doesn't shuffle the waypoints when it does
+ Outer KD waypoint update, all open world lore, most champs

Version 0.1.0-alpha
+ Champion waypoints, with similar completion tracking as Lore
  + All known champions with fixed locations are included, roaming ones are waiting on additional display options (zones and paths) and tools
+ Sidebar list of layers; allows them to be selectively hidden; may have other uses in the future
+ Tooltips are less shy, no longer hide behind other waypoints randomly
+ Map now stalks the player, changing automatically if they leave the current displayed zone for another mapped zone

Version 0.0.6-alpha
+ Fixed the bug with icon not staying with UI edit mode overlay
+ Config can now be manually reset (/setoption efdCartographerResetConfig true) WARNING: Until further notice, this will delete any custom waypoints, once they are implemented
+ Picking up lore now immediately updates the map if it's open
+ Icons for lore that has been picked up now renders behind unclaimed lore icons
+ Slight data schema change ("Notes" tag -> "Note")
+ All placed lore added to currently mapped zones (also some instances/dungeons)
+ Spends less time spamming the log file

Version 0.0.5-alpha
+ Most lore locations in Agartha KM, KD added as continuing stress test
  + All locations added have been verified with LoreHound, and should be fixed location placed or triggered lore (some drops might have ended up in by accident)
+ Lore pickup status should now be reflected on map change or re-open
+ Now opens to current region if a map is available (as defined in Zones.xml)

Version 0.0.4-alpha
+ Stability much improved, concept may actually be approaching viable
+ Waypoint data files significantly reworked
+ Features included:
	+ First sample lore markers (Bogeyman #4 spawn locations becase the numbers were convenient)
	  + Note: Recent pickups will not be reflected until datafiles are reloaded (on /reloadui)
	+ Very basic tooltips
	+ Backend support for multiple overlay layers, multiple data files (no actual customization in current interface)

Version 0.0.3-alpha
+ Unstable release continuing proof of concept stages
+ Features included:
  + Map swapping using transitional waypoints
  + Additional waypoints added (Vendors and Transitions on Solomon Island, Some Agartha markers, one transition to SD)
  + Hides labels by default

Version 0.0.2-alpha
+ Initial proof of concept and feedback query
+ Features included:
  + Player location tracking when in zone
  + Customizable waypoint marker (parser limited to single waypoint group)
  + Localized waypoint labels (to be converted to tooltips)
  + Waypoints for KM anima wells as test set

## Known Issues

This is a very early version of this mod. Everything is an issue, some of them are known.
I'm always open to hearing comments and suggestions though, better to start with the good ideas than rewrite from the bad ones.

There is a known bug when using this mod with ModFolder v1, which causes issues when using /reloadui or swapping characters. As a temporary workaround, use "/setoption VTIO_IsLoaded false" before /reloadui.

## Testing and Further Developments

Current goals for the next versions:
+ Expanding tooltips (continuing)
  + Making more info available (note fields, coordinates, etc.)
  + Handling stacked waypoints
  + Enabling tooltips on Paths
  + Considering making path/area notations behave as tooltips for icons
+ Mission layer
+ Work on config settings
  + Layer options (hiding the collected lore)
  + Adding/Removing files (preferably without /reloadui)

Initial feedback has provided the following suggestions which are not yet implemented:
+ Mouse coordinates should be clearly displayed someplace obvious
+ Window size should account for lower resolutions (1600x900 resolution was cutting things off)
  + Window resizing should be a thing
+ Minimap mode
  + Small frameless window, centred on player location
  + No sidebars
+ Mission markers should be filterable by main/side for challenge completion

As always, defect reports, suggestions, and contributions are welcome. They can be sent to Peloprata in SWL (by mail or pm), via the github issues system, or in the official forum post.

Source Repository: https://github.com/Earthfiredrake/TSW-Cartographer

Curse Mirror: TBD

## Building from Source
Requires copies of the SWL and Scaleform CLIK APIs. Existing project files are configured for Flash Pro CS5.5.

Master/Head is the most recent packaged release. Develop/Head is usually a commit or two behind my current test build. As much as possible I try to avoid regressions or unbuildable commits but new features may be incomplete and unstable and there may be additional debug code that will be removed or disabled prior to release.

Once built, 'Cartographer.swf', the contents of 'config' and 'resources' should be copied to the directory 'Cartographer' in the game's mod directory. '/reloadui' is sufficient to force the game to load an updated swf or mod data file, but changes to the game config files (LoginPrefs.xml and Modules.xml) will require a restart of the client and possible deletion of .bxml caches from the mod directory.

## License and Attribution
Copyright (c) 2017-2018 Earthfiredrake<br/>
Additional code contributions: Aralicia<br/>
Software and source released under the MIT License

Uses the TSW-AddonUtils library and graphical elements from the UI_Tweaks mod<br/>
Both copyright (c) 2015 eltorqiro and used under the terms of the MIT License<br/>
https://github.com/eltorqiro/TSW-Utils <br/>
https://github.com/eltorqiro/TSW-UITweaks

TSW, SWL, the related API, and most graphics elements, including all maps and current waypoint icons are copyright (c) 2012 Funcom GmBH<br/>
Used under the terms of the Funcom UI License<br/>

Current Icon sourced from https://openclipart.org/detail/233062/compass-rose <br/>
CC0 1.0 Public Domain Dedication

Special Thanks to:<br/>
The TSW modding community for neglecting to properly secure important intel in their faction vaults<br/>
AliceOrwell for https://aliceorwell.github.io/TSW-Mapper/ from which much of the inspiration came<br/>
Everyone who provided suggestions, testing and feedback
The Krampus tag and bag team
