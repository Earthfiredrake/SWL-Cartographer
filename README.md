# TSW-Cartographer
Supplementary world maps for The Secret World and Secret World Legends

## Overview
This mod intends to provide a supplement to the ingame regional and dungeon maps, with various improvements:
+ Multiple icons for custom map notations
  + Assigned by type, but may be overridden individually (ex: The location to use a password required to access a lore may count as a "lore" marker, but use the "password" icon)
  + User customization of the map icons, including replacing most icons or adding their own, without requiring a flash compiler
+ Zone and path marking in addition to point locations
+ More support for extended descriptions and precise placement based on coordinates
+ Premade packages of related markers which can be loaded or toggled as a package
  + ex: A package for Samhain might include lore, quests, vendors, rider/summon/empowerment points
  + These packages may also include more general packs of Lore, Rare Spawns, etc.
  + As much as possible the locations included in these packs will use verified exact game locations
    + This may result in one or more utility mods designed to provide absolute locations of various game objects
    + This will also likely result in an automatic marking system from LoreHound
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
	+ Flash is unable to reliably access the user's custom waypoint file
  + This mod will be duplicating as much existing functionality as is possible and be a second map window in game
+ Entirely replace the existing map's functionality
  + Anima leap and the long range detection of champion monsters and world bosses is not yet understood
    + Oddly it may be possible to integrate zone teleportation (the Shift-T menu). I've stuck in some preliminary placeholder stuff in relation to these, and will revisit them later
+ Directly save player added waypoints to the xml files containing pre-packaged info
  + Manual export and sharing features may be supported
  + Custom waypoints will have to be saved with the rest of the mod settings
    + This will likely have a slightly different data layout than the waypoint pack files, because the universe enjoys making me write parsers

The mod is currently in pre-alpha prototyping and proof of concept stages, and has minimal functionality. Graphics are temporary placeholders of less than desired quality.

All settings are saved account wide and will be shared across characters. If you'd rather have different settings for each character, renaming the file "LoginPrefs.xml" to "CharPrefs.xml" when installing/upgrading the mod should work without any problems. A clean install of the mod is recommended if doing this, as it will be unable to transfer existing settings anyway.

## Installation
Any packaged release should be unzipped (including the internal Cartographer folder) into the appropriate folder and the client restarted.
<br/>TSW: [TSW Directory]\Data\Gui\Customized\Flash.
<br/>SWL: [SWL Directory]\Data\Gui\Custom\Flash.

When upgrading, existing .bxml files in the Cartographer directory should be deleted to ensure changes in the .xml files are loaded (whichever is newer seems to take precedence).

I intend to permit setting migration from the first public beta to v1.0.x, but this may be subject to change. As with my other mods, this update compatibility window will occasionally be shifted to reduce legacy code clutter in the mod.

## Change Log

Version Next
+ Fixed the bug with icon not staying with UI edit mode overlay
+ More lore added in KD

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
  
## Testing and Further Developments

Initial feedback has provided the following suggestions:
+ Mouse coordinates should be clearly displayed someplace obvious
+ Map zooming should be a feature if at all possible
+ Window size should account for lower resolutions (1600x900 resolution was cutting things off)

As always, defect reports, suggestions, and contributions are welcome. They can be sent to Peloprata in SWL (by mail or pm), via the github issues system, or in the official forum post.

Source Repository: https://github.com/Earthfiredrake/TSW-Cartographer

Forum Post: TBD

Curse Mirror: TBD

## Building from Source
Requires copies of the TSW and Scaleform CLIK APIs. Existing project files are configured for Flash Pro CS5.5.

Master/Head is the most recent packaged release. Develop/Head is usually a commit or two behind my current test build. As much as possible I try to avoid regressions or unbuildable commits but new features may be incomplete and unstable and there may be additional debug code that will be removed or disabled prior to release.

Once built, 'Cartographer.swf', the contents of 'config' and 'resources' should be copied to the directory 'Cartographer' in the game's mod directory. '/reloadui' is sufficient to force the game to load an updated swf or mod data file, but changes to the game config files (LoginPrefs.xml and Modules.xml) will require a restart of the client and possible deletion of .bxml caches from the mod directory.

## License and Attribution
Copyright (c) 2017 Earthfiredrake<br/>
Software and source released under the MIT License

Uses the TSW-AddonUtils library and graphical elements from the UI_Tweaks mod<br/>
Both copyright (c) 2015 eltorqiro and used under the terms of the MIT License<br/>
https://github.com/eltorqiro/TSW-Utils <br/>
https://github.com/eltorqiro/TSW-UITweaks

TSW, the related API, and most graphics elements, including all maps are copyright (c) 2012 Funcom GmBH<br/>
Used under the terms of the Funcom UI License<br/>

Current Icon sourced from https://openclipart.org/detail/233062/compass-rose <br/>
CC0 1.0 Public Domain Dedication

Special Thanks to:<br/>
The TSW modding community for neglecting to properly secure important intel in their faction vaults<br/>
AliceOrwell for https://aliceorwell.github.io/TSW-Mapper/ from which much of the inspiration came