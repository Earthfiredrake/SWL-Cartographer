# TSW-Cartographer
Supplementary maps for The Secret World

## Overview
This mod intends to provide a supplement to the ingame regional and dungeon maps in TSW, improving on it by:
+ Having map markers with a variety of different icons (possibly including custom) for different purposes
  + Assigned by type, but may be overridden individually (ex: The location to use a password required to access a lore may count as a "lore" marker, but use the "password" icon)
+ Permitting marking of areas and paths in addition to point locations
+ Provide more support for extended descriptions and precise placement
+ Having premade packages of related markers which can be loaded or toggled as a package
  + ex: A package for Samhain might include lore, quests, vendors, rider/summon/empowerment points
+ Being able to filter or highlight markers based on some criteria:
  + ex: Unclaimed lore, missing rare spawn achivements

Due to limitations with the API, it does not seem to be possible to:
+ Integrate with the existing map in any meaningful way
  + This mod will be duplicating existing functionality and be a second map window in game
+ Entirely replace the existing map's functionality
  + Uncertain if anima leap can be supported, or whatever trick they're using to display world boss skulls
+ Directly save player added waypoints to the xml files containing pre-packaged info

## Installation
Any packaged releases can be installed by copying the contents into [Game Directory]\Data\Gui\Customized\Flash and restarting the client.

When upgrading, existing .bxml files in the Cartographer directory should be deleted to ensure changes in the .xml files are loaded (whichever is newer seems to take precedence).

I intend to permit setting migration from the first public beta to v1.0.x, but this may be subject to change. As with my other mods, this update compatibility window will occasionally be shifted to reduce legacy code clutter in the mod.

## Change Log

Version next
+ Proof of concept

As always, defect reports, suggestions, and contributions are welcome. They can be sent to Peloprata in game (by mail or pm), via the github issues system, or in the official forum post.

Source Repository: https://github.com/Earthfiredrake/TSW-Cartographer

Forum Post: TBD

## Building from Source
Requires copies of the TSW and Scaleform CLIK APIs. Existing project files are configured for Flash Pro CS5.5.

Master/Head is the most recent packaged release. Develop/Head is usually a commit or two behind my current test build. As much as possible I try to avoid regressions or unbuildable commits but new features may be incomplete and unstable and there may be additional debug code that will be removed or disabled prior to release.

Once built, 'Cartographer.swf' and the contents of 'config' should be copied to the directory 'Cartographer' in the game's mod directory. '/reloadui' is sufficient to force the game to load an updated swf or mod data file, but changes to the game config files (LoginPrefs.xml and Modules.xml) will require a restart of the client and possible deletion of .bxml caches from the mod directory.

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