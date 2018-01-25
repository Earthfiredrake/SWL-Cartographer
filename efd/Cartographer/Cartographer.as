// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import gfx.utils.Delegate;

import com.GameInterface.DistributedValue;
import com.GameInterface.DressingRoom;

import efd.Cartographer.lib.ara.BasicMCGraphics;

import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;
import efd.Cartographer.lib.sys.ConfigManager;
import efd.Cartographer.lib.sys.config.Versioning;
import efd.Cartographer.lib.sys.ModIcon;
import efd.Cartographer.lib.sys.VTIOHelper;
import efd.Cartographer.lib.sys.Window;

import efd.Cartographer.inf.INotation;

import efd.Cartographer.LayerData;
import efd.Cartographer.notations.NotationBase;

// TODO: Area tooltips seem to be conflicting with path tooltips
//       In South KD, the Namahage path tooltip is being superceded by the Spectres #6 tooltip
//       - Paths should in general be above areas in the layering system
//       - Champions should be above Lore in the layering system (though the interleaf may affect this)
//       This does not prevent the new tooltip system from detecting both tooltip targets, but may impact their ordering
//       Further investigation suggests that this may be due to one or both of:
//         Tooltip creation (and the copy used to check if it exists) being local to each waypoint object, but using a common name for the clip they attach to the WindowContent
//         An attempt to keep path tooltips from stomping overlapping icons that may permit areas to stomp paths
//       As the new multi-waypoint design should move waypoint management into the MapView (or some other single location) and uses different detection logic, this should come out in the wash

// TODO: Reminder list of things I've been looking at doing, roughly prioritized:
//       Write the reminder list
//       Tooltips that can handle multiple data sources at once (ie: everything under the mouse, ideally sorted somewhat sensibly... by layer maybe?)
//         Look into using it (at least the detection system) to trigger additional notations; ex: to pop up a path or area as additional information on a point icon
//       Reduce required icon permutations, possible features that might help:
//         Runtime greyscaling for Collectible layer icons
//         Runtime tinting for icons based on layer colour? icon data? the reverse of above, advantage here is greater flexibility
//           ex: I reused Champ markers for Krampii, with this they could have been blue skulls to be obviously different
//         Icon modifiers; may be particularly useful to identify event/seasonal points (a little snowflake or pumpkin in the corner like in other sections of the UI), could also be used on group champions
//           Particularly valuable for mission overlay (available, in progress, paused, on cooldown, locked etc.)
//           A variant system could be used for numbered waypoints (maps of mission farming routes perhaps)?
//       Mission overlay:
//         Need to decide how to represent some things: main/side missions, mission types, mission state; particularly in cases where a single quest giver has multiple options
//         What's important enough, or possible, to squeeze into the map icon, and what will have to stay on the tooltip
//       Cleaning up the naming conventions. There's a number of identifiers that have more than one meaning, Waypoint and Layer are both suspect, should probably settle on some better names before too many more types get added
//         Am liking Overlay as a possible replacement for Layer, would Marker work better than Waypoint and Notation in some places?
//         Remember to check the MixIns and other places the compiler doesn't look at closely when doing renames, would help to minimize ducktyping elsewhere too
//         The mental picture I have is a projector with a bunch of transparencies on top of a map, not sure any of that terminology is useful though
//       Change project name. The mod's TSW support is actually minimal so SWL-Cartographer would make more sense
//         Documentation suggests GitHub will handle this with grace, redirecting both web and git requests to the new repository as long as I don't reuse the old name. They still suggest updating the remotes anyway
//       Window resizing... should be reasonably simple to enable on the framework/window side, passing that to the content will be more fun
//         What parts should rescale, and which should just crop differently. How big/small should it be limited to.
//         Minimap mode should probably be a different (mostly frameless) display, should try to ensure that the MapView can exist independently of a window
//         On a similar line, would be nice to improve the zoom behaviour so it zooms in on the cursor and isn't stymied by every icon and area along the way
//       Data extension tags and data defined overlay configurations
//         Have reserved the set of <_Tag> for special directives, some notes in BasePack.xml, quick definitions here:
//         _Section: Already exists, currently used to group marker definitions for easier editing
//         _SectionDefaults: Base data that is shared (with infrequent overrides) by every marker definition in that section
//           Reduces data duplication for things like Krampii
//           For some reason my initial attempts at this were hanging the game,
//         _OverlayDef: Data defined overlay setup, specifying things like overlay type, marker mix-ins
//           See factory function in NotationBase, LayerData, BasicPoint for inspiration on what can fit in there
//           Not sure that this will be able to directly include third party mixin/overlay types due to loading issues
//             Might be able to stall the load long enough for the third party mod to load the mix-in protoypes
//             An alternative would be to use a VTIO style interface to delay the file load (in one of several ways)
//         _Strings: Allows an overlay pack to define additional entries for the string tables provided by LocaleManager
//           They can then be used elsewhere in that overlay pack or as UI labels (though things like overlay naming may be better as part of the _OverlayDef tag)
//       Harden data structures/parser against bad input
//         Malformed xml can cause some very interesting and problematic data to end up in the system
//         This data then has a bad habit of getting stuck in the settings, and causing crashes and other issues when the xml is fixed
//         Need to identify the causes of those crashes, and fix it so that bad data triggers an error message and is discarded
//         This is vital for the overlay pack system, as it's very likely that people trying to write their own will muck it up somewhere along the way (I do it regularly, and I wrote the dang thing)
//       Sidebar layer settings, beyond just toggling the whole layer (show/hide should probably become an icon/button)
//         Filter out collected sublayers on the lore/champ overlays; Known/unknown anima wells (if I can somehow figure out how to check that); Similar filters for missions
//         Possibly toggle areas/paths/points here?
//         Ability to re-order the sidebar/layer orders
//       Config window for more general settings:
//         Standard framework settings (Think that's just Topbar Integration here)
//         Datafile load list (with ability to selectively disable or remove? files, or add new ones)
//         Other general options:
//           Toggle between showing paths/areas by default or as a mouseover for an icon?
//           Mod integration options, probably just a general permit/disable toggle here, leave it up to the other mods whether they offer an option to not integrate
//             If it turns out Cartog can usefully send data to other mods, should probably list them
//       Wishlist (Get Daimon on these, they could use some crazed laughter)
//         Search feature
//         Custom player waypoints
//         Default minimap overlay investigation

// ConfigWindow does not have content, disabling simple access (can still /setoption the DV manually, will probably crash the game)
class efd.Cartographer.Cartographer extends Mod {
	private function GetModInfo():Object {
		return {
			// Debug settings at top so that commenting out leaves no hanging ','
			// Trace : true,
			Name : "Cartographer",
			Version : "0.1.5.alpha",
			Subsystems : {
				Config : {
					Init : ConfigManager.Create,
					InitObj : {
						LibUpgrades : [{mod : "0.1.4.alpha", lib : "1.0.0"}]
					}
				},
				Icon : {
					Init : ModIcon.Create,
					InitObj : {
						LeftMouseInfo : IconMouse_ToggleInterfaceWindow
						//RightMouseInfo : IconMouse_ToggleConfigWindow
					}
				},
				LinkVTIO : {
					Init : VTIOHelper.Create,
					InitObj : {
						//ConfigDV : "efdShowCartographerConfigWindow"
					}
				},
				Interface : {
					Init : Window.Create,
					InitObj : {
						WindowName : "InterfaceWindow",
						LoadEvent : Delegate.create(this, InterfaceWindowLoaded)
					}
				}
			}
		};
	}

	/// Initialization
	public function Cartographer(hostMovie:MovieClip) {
		super(GetModInfo(), hostMovie);

		SystemsLoaded.ZoneIndex = false;

		// Ingame debug menu registers variables that are initialized here, but not those initialized at class scope

		InitializeConfig();

		ZoneIndex = new Object();
		ZoneIndexLoader = LoadXmlAsynch("Zones", Delegate.create(this, LoadZoneInfo));

		OverlayList = new Array("BasePack");
		LayerDataList = new Array();
		BasicMCGraphics.setup();

		TraceMsg("Initialized");
	}

	private function InitializeConfig():Void {
		var defaultPacks:Array = new Array();
		//defaultPacks.push({ name : "Missions", load : true });
		defaultPacks.push({ name : "Champions", load : true });
		defaultPacks.push({ name : "LoreGlobal", load : true });
		defaultPacks.push({ name : "LoreRegional", load : true });
		defaultPacks.push({ name : "LoreBestiary", load : true });
		if (DressingRoom.IsEventActive(EventSamhain)) {
			// defaultPacks.push({ name : "EvSamhain", load : true }); (Implement mission layer first)
		}
		if (DressingRoom.IsEventActive(EventKrampus)) { defaultPacks.push({ name : "EvKrampusnacht", load : true }); }
		Config.NewSetting("OverlayPacks", defaultPacks);

		Config.NewSetting("LayerSettings", new Object());

		// HACK: Forcibly replace the ResetConfig DV handler
		if (!ConfigHost.ResetDV.SignalChanged.Disconnect(ConfigHost.ResetConfig, ConfigHost)) {
			TraceMsg("Warning! Failed to disconnect default config reset handler.");
		}
		ConfigHost.ResetDV.SignalChanged.Connect(ResetConfig, this);
	}

	private function ConfigLoaded():Void {
		var layerConfig:Object = Config.GetValue("LayerSettings");
		for (var key:String in layerConfig) {
			LayerDataList[layerConfig[key].Depth] = new LayerData(key, layerConfig[key]);
		}

		Config.ResetValue("OverlayPacks"); // TEMP: Not actually saving this while files are in flux/no config UI
		var packList:Array = Config.GetValue("OverlayPacks");
		for (var i:Number = 0; i < packList.length; ++i) {
			if (packList[i].load) { OverlayList.push(packList[i].name); }
		}
		TraceMsg("OverlayPacks to load: " + (OverlayList.length));

		super.ConfigLoaded();
	}

	private function UpdateLoadProgress(loadedSystem:String):Boolean {
		if ((loadedSystem == "Config" && SystemsLoaded.LocalizedText) ||
			(loadedSystem == "LocalizedText" && SystemsLoaded.Config)) {
				OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseOverlayPack));
			}
		return super.UpdateLoadProgress(loadedSystem);
	}

	private function ResetConfig(dv:DistributedValue):Void {
		if (dv.GetValue()) {
			Config.ResetAll();
			var layerConfig:Object = Config.GetValue("LayerSettings");
			// Rebuild the layer config based on the existing cached views in the LayerData structures
			for (var i:Number = 0; i < LayerDataList.length; ++i) {
				var settings:Object = LayerDataList[i].ConfigView;
				settings.ShowLayer = true; // Not sure if this is the best choice
				settings.Depth = i;
				settings.PenColour = LayerData.GetDefaultPenColour(LayerDataList[i].LayerName);
				layerConfig[LayerDataList[i].LayerName] = settings;
			}
			Config.NotifyChange("LayerSettings");
			dv.SetValue(false);
		}
	}

	private function LoadZoneInfo(success:Boolean):Void {
		if (success) {
			var xmlRoot:XMLNode = ZoneIndexLoader.firstChild;
			for (var i:Number = 0; i < xmlRoot.childNodes.length; ++i) {
				var zone:XMLNode = xmlRoot.childNodes[i];
				ZoneIndex[zone.attributes.id] = { worldX : Number(zone.attributes.worldX), worldY : Number(zone.attributes.worldY) };
			}
			delete ZoneIndexLoader;
			UpdateLoadProgress("ZoneIndex");
		} else { ErrorMsg("Unable to load zone index", {fatal : true}); }
	}

	// TODO: Get those shift() side effects out of the trace messages
	private function ParseOverlayPack(success:Boolean):Void {
		if (success) {
			var pack:Array = ParseSection(OverlayLoader.firstChild);
			TraceMsg("Sorting " + pack.length + " entries");
			for (var i:Number = 0; i < pack.length; ++i) {
				var layer:String = pack[i].Layer;
				var layerConfig:Object = Config.GetValue("LayerSettings")[layer];
				if (layerConfig == undefined) {
					layerConfig = new Object();
					layerConfig.ShowLayer = OverlayList[0] == "BasePack"; // Only shows layers defined in the base pack by default
					layerConfig.Depth = LayerDataList.push(new LayerData(layer, layerConfig)) - 1;
					layerConfig.PenColour = LayerData.GetDefaultPenColour(layer);
					Config.GetValue("LayerSettings")[layer] = layerConfig;
					Config.NotifyChange("LayerSettings");
				}
				LayerDataList[layerConfig.Depth].AddNotation(pack[i]);
			}
			TraceMsg("Loaded waypoint file: "  + OverlayList.shift() + ".xml");
		} else { ErrorMsg("Unable to load waypoint file: " + OverlayList.shift() + ".xml"); }
		if (OverlayList.length > 0) { OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseOverlayPack)); }
		else {
			delete OverlayList;
			delete OverlayLoader;
			CleanupLayers();
			TraceMsg("Waypoints loaded");
		}
	}

	private function ParseSection(section:XMLNode):Array {
		var entries:Array = new Array();
		for (var i:Number = 0; i < section.childNodes.length; ++i) {
			var node:XMLNode = section.childNodes[i];
			if (node.nodeName.charAt(0) == '_') {
				switch (node.nodeName.slice(1)) {
					case "Section": { entries = entries.concat(ParseSection(node)); break; }
					default: { ErrorMsg("Tags starting with '_' are reserved for internal use but " + node.nodeName + " is not defined and will be ignored. File: " + OverlayList[0] + ".xml"); }
				}
			} else {
				var entry:INotation = NotationBase.Create(node);
				if (entry != undefined) { entries.push(entry); }
			}
		}
		return entries;
	}

	// Remove empty layers after load
	//   Can be caused by removing a particular file from the loading sequence
	private function CleanupLayers():Void {
		var removed:Number = 0;
		var settings:Object = Config.GetValue("LayerSettings");
		for (var i:Number = 0; i < LayerDataList.length; ++i) {
			LayerDataList[i].Depth -= removed;
			if (LayerDataList[i].IsEmpty) {
				settings[LayerDataList[i].Layer] = undefined;
				// Shuffle the front up to avoid removal during iteration
				for (var j:Number = i; j > 0; --j) {
					LayerDataList[j] = LayerDataList[j-1];
				}
				++removed;
			}
		}
		if (removed > 0) {
			LayerDataList.splice(0, removed);
			Config.SetValue("LayerSettings", settings);
		}
	}

	/// Mod framework extensions and overrides
	private function ConfigChanged(setting:String, newValue, oldValue):Void {
		switch(setting) {
			default:
				super.ConfigChanged(setting, newValue, oldValue);
				break;
		}
	}

	private function DoUpdate(newVersion:String, oldVersion:String):Void {
		// Version specific updates
		//   Some upgrades may reflect unreleased builds, for consistency on develop branch
		if (Versioning.CompareVersions("0.1.2.alpha", oldVersion) > 0) {
			// Adding pen colour to saved layer settings
			var layerSettings:Object = Config.GetValue("LayerSettings");
			for (var key:String in layerSettings) {
				layerSettings[key].PenColour = LayerData.GetDefaultPenColour(key);
			}
		}
	}

	private function Activate():Void {
	}

	private function Deactivate():Void {
	}

	private function InterfaceWindowLoaded(windowContent:Object):Void {
		windowContent.SetData(ZoneIndex, LayerDataList, Config);
	}

	/// Variables
	private var ZoneIndexLoader:XML;
	private var ZoneIndex:Object;

	private var OverlayList:Array;
	private var OverlayLoader:XML;
	private var LayerDataList:Array; // Array of LayerData objects

	private static var EventSamhain:Number = 1;
	private static var EventKrampus:Number = 2;
}

// The big list of future Glaucon questions (stuff to pester him with when I run out of things I can do without it):
//   Sourcing map backgrounds from RDB
//   Anima well locks and leaps
//   Long range champion detection
//   GetScreenPos() for arbitrary world coordinates
