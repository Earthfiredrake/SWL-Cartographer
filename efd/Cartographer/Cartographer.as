// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import com.GameInterface.DistributedValue;
import com.GameInterface.DressingRoom;
import com.GameInterface.Game.Character;
import com.GameInterface.Utils;

import efd.Cartographer.lib.ara.BasicMCGraphics;

import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;
import efd.Cartographer.lib.sys.ConfigManager;
import efd.Cartographer.lib.sys.config.Versioning;
import efd.Cartographer.lib.sys.ModIcon;
import efd.Cartographer.lib.sys.VTIOHelper;
import efd.Cartographer.lib.sys.Window;
import efd.Cartographer.lib.util.WeakDelegate;

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
//       STABILITY: This is a big one right now, but I'll need to talk to Glaucon about a few things, see the bottom
//       Tooltips that can handle multiple data sources at once (ie: everything under the mouse, ideally sorted somewhat sensibly... by layer maybe?)
//         Look into using it (at least the detection system) to trigger additional notations; ex: to pop up a path or area as additional information on a point icon
//       Reduce required icon permutations, possible features that might help:
//         Icon modifiers: There's a basic system in, demonstrating possible use with group champions and error detection on lore, champs, and map transitions
//           Expanding on this: Faction locked vendors in KD and other faction walled things (quests, lore locations in bases, etc.)
//           Identify anima wells that are also zone teleport destinations? Consider how/if to handle the zone teleport possibilities in general.
//           Particularly valuable for mission overlay (available, in progress, paused, on cooldown, locked etc.) (consider putting this on a different corner/layer as a state identifier)
//           Also for identifying seasonal items (see about jacking snowflake/pumpkin graphics from game somewhere?)
//           A variant system could be used for numbered waypoints (maps of mission farming routes perhaps, for that see also Interop)?
//           Going to need a certain amount of standardization when designing icons, so that they are easily identified underneath any modifiers
//             See if an icon could be identified with just the top half?
//           Should the tint possibilities above apply to the modifier as well as the base icon?
//       Cleaning up the naming conventions. There's a number of identifiers that have more than one meaning, Waypoint and Layer are both suspect, should probably settle on some better names before too many more types get added
//         Am liking Overlay as a possible replacement for Layer, would Marker work better than Waypoint and Notation in some places?
//         Remember to check the MixIns and other places the compiler doesn't look at closely when doing renames, would help to minimize ducktyping elsewhere too
//         The mental picture I have is a projector with a bunch of transparencies on top of a map, not sure any of that terminology is useful though
//       Harden data structures/parser against bad input
//         Malformed xml can cause some very interesting and problematic data to end up in the system
//         This data then has a bad habit of getting stuck in the settings, and causing crashes and other issues when the xml is fixed
//         Need to identify the causes of those crashes, and fix it so that bad data triggers an error message and is discarded
//         This is vital for the overlay pack system, as it's very likely that people trying to write their own will muck it up somewhere along the way (I do it regularly, and I wrote the dang thing)
//       Reduce the amount of repetitive data that is required in the NotationPacks
//          This may help with making it more resilient (above); by simplifying the parser, limiting the number of ways data can be bad
//			Some of this can be accomplished with the data extension tags (below)
//			Restrict str="" localized string definitions to a category based on the requesting object type (eliminates need for cat="" in the same field)
//			See if I can permit construction of rdb="" source strings with placeholders using the fmt="true" flag
//            Noticed that some of the common strings (RequiresMission, DropsFrom) always draw from the same rdb category, being able to reduce that to a single instance in the str def would be nice
//            This gets tricky though, as I'll have to deal with having a half initialized string lying around in the string table (should check to see if the order of an rdb id cat pair matters)
//       Sidebar layer settings, beyond just toggling the whole layer (show/hide should probably become an icon/button)
//         Filter out collected sublayers on the lore/champ overlays; Known/unknown anima wells (if I can somehow figure out how to check that); Similar filters for missions
//         Possibly toggle areas/paths/points here?
//         Ability to re-order the sidebar/layer orders
//       Interop with other mods
//         Note: This is relatively non-urgent, but am going to start work on the base interop protocols so that they have plenty of time for peer review
//               VTIO has demonstrated the ability of a dominant protocol to lock in modders far down the line, so I don't want this to be half baked when it actually goes into use
//         Discussions with Starfox turned to an idea I had of an interop plugin between Cartographer and GuideFox
//         While they feel that GuideFox files are too dense to display usefully in whole, it might be enough to display just the next target
//         Am thinking of an "Objectives" layer which could hold temp waypoints as well as those made by missions ingame
//           Will have to see if I can find a place to hook on to that which won't cause issues with LoreHound/LairTracker (I think the waypoints get registered in there... the trick would be identifying the right ones)
//         For interop am thinking of providing two interfaces:
//           The first will be a basic DV with a text based data format. Its primary role will be to (hopefully) support a chat/script based "share" button
//             Other mods can make use of it, but it will have limited options, likely only being able to add new map markers in a fire and forget manner
//           The second will be a more powerful system, built on top of a generic interop protocol (MIP, see the forthcoming files in lib.sys for details)
//             It will permit significantly more control, letting the external mod edit or delete map markers it has placed, and providing the registration interface for the layer plugin system
//       Layered map display
//         Need to be able to handle the maps (such as NYC and Ankh) that have multiple vertical layers
//         Ideally some combination of automatically detecting which layer the player is in, and being able to peek into the others, similar to how it deals with zones at the moment
//       Data extension tags and data defined overlay configurations:
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
//         Icon: Should be elevated to a full sub-element of the marker record, as it is likely to pick up additional attributes (filename, modifiers, etc.)
//       Mission overlay:
//         Need to decide how to represent some things: main/side missions, mission types, mission state; particularly in cases where a single quest giver has multiple options
//         What's important enough, or possible, to squeeze into the map icon, and what will have to stay on the tooltip
//         Should this have current mission objectives? or should that be a separate (near top stacked?) layer. (See also Interop for other uses of that)
//       Config window for more general settings:
//         Standard framework settings (Think that's just Topbar Integration here)
//         Datafile load list (with ability to selectively disable or remove? files, or add new ones)
//         Other general options:
//           Toggle between showing paths/areas by default or as a mouseover for an icon?
//           For multilayer zones, a choice between hiding the marks that aren't on the current layer, or displaying them with some sort of above/below marker
//           Mod integration options, probably just a general permit/disable toggle here, leave it up to the other mods whether they offer an option to not integrate
//             If it turns out Cartog can usefully send data to other mods, should probably list them
//       Wishlist (Get Daimon on these, they could use some crazed laughter)
//         Search feature
//         Custom player waypoints
//         The new easy source of transition data has suggested that adding conditions to marking displays might be an interesting endeavor
//           Consider having markers for mission related instance entrances that would only render if that mission is currently active
//         Default minimap overlay investigation, or an improved self supporting minimap mode (try to ensure that the MapView can exist independently of a window)
//         I've a couple *very* unlikely ideas to look into for the main map as well... will have to see

// ConfigWindow does not have content, disabling simple access (can still /setoption the DV manually, will probably crash the game)
class efd.Cartographer.Cartographer extends Mod {
	private function GetModInfo():Object {
		return {
			// Debug flag at top so that commenting out leaves no hanging ','
			// Debug : true,
			Name : "Cartographer",
			Version : "0.2.0.beta",
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
						LoadEvent : WeakDelegate.Create(this, InterfaceWindowLoaded),
						ResizeLimits : {
							Min : new Point(200, 200),
							Max : new Point(1500, 1000)
						}
					}
				}
			}
		};
	}

	/// Initialization
	public function Cartographer(hostMovie:MovieClip) {
		super(GetModInfo(), hostMovie);

		SystemsLoaded.ZoneIndex = false;
		SystemsLoaded.MapNotations = false;

		// Ingame debug menu registers variables that are initialized here, but not those initialized at class scope

		InitializeConfig();

		ZoneIndex = new Object();
		ZoneIndexLoader = LoadXmlAsynch("Zones", Delegate.create(this, LoadZoneInfo));

		OverlayList = new Array("BasePack");
		LayerDataList = new Array();
		BasicMCGraphics.setup();

		DefaultMapDV = CreateDV("fullscreen_map", undefined, HookDefaultMapShortcut, this);
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
		// TEMP: *really* dislike the game tweak method of detecting an event for this
		//       mostly as it looks to need annual updates, but also because it's a special case for this particular event
		//       replace as soon as an alternative is available
		if (Utils.GetGameTweak("Seasonal_SWL_Anniversary2018") > 0) { defaultPacks.push({ name : "EvAnniversary", load : true}); }
		Config.NewSetting("OverlayPacks", defaultPacks);

		Config.NewSetting("LayerSettings", new Object());

		Config.NewSetting("EnableKBShortcut", true, "");

		// HACK: Forcibly replace the ResetConfig DV handler
		ConfigHost.ResetDV.SignalChanged.Disconnect(ConfigHost.ResetConfig, ConfigHost);
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

		super.ConfigLoaded();
	}

	private function UpdateLoadProgress(loadedSystem:String):Boolean {
		if ((loadedSystem == "Config" && SystemsLoaded.LocalizedText && SystemsLoaded.ZoneIndex) ||
			(loadedSystem == "LocalizedText" && SystemsLoaded.Config && SystemsLoaded.ZoneIndex) ||
			(loadedSystem == "ZoneIndex" && SystemsLoaded.Config && SystemsLoaded.LocalizedText)) {
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
				var zoneID:String = zone.attributes.id;
				if (!zone.attributes.mapID) {
					ZoneIndex[zoneID] = { mapID : zoneID, worldX : zone.attributes.worldX, worldY : zone.attributes.worldY, mergeZones : new Array()};
				} else {
					ZoneIndex[zoneID] = {  mapID : zone.attributes.mapID, worldX : ZoneIndex[zone.attributes.mapID].worldX, worldY : ZoneIndex[zone.attributes.mapID].worldX, mergeZones : new Array() };
				}
				for (var j:Number = 0; j < zone.childNodes.length; ++j) {
					var subNode:XMLNode = zone.childNodes[j];
					if (subNode.nodeName == "Merge") {
						var mergeID:String = subNode.attributes.zone;
						ZoneIndex[zoneID].mergeZones.push(mergeID);
						ZoneIndex[mergeID] = { masterZone : zoneID };
					}
				}
			}
			UpdateLoadProgress("ZoneIndex");
		} else { Debug.ErrorMsg("Unable to load zone index", {fatal : true}); }
		delete ZoneIndexLoader;
	}

	private function ParseOverlayPack(success:Boolean):Void {
		if (success) {
			var pack:Array = ParseSection(OverlayLoader.firstChild);
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
			Debug.TraceMsg("Loaded " + pack.length + " waypoints from " + OverlayList[0] + ".xml");
		} else { Debug.ErrorMsg("Unable to load waypoint file: " + OverlayList[0] + ".xml"); }
		OverlayList.shift();
		if (OverlayList.length > 0) { OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseOverlayPack)); }
		else {
			delete OverlayList;
			delete OverlayLoader;
			CleanupLayers();
			UpdateLoadProgress("MapNotations");
		}
	}

	private function ParseSection(section:XMLNode):Array {
		var entries:Array = new Array();
		for (var i:Number = 0; i < section.childNodes.length; ++i) {
			var node:XMLNode = section.childNodes[i];
			if (node.nodeName.charAt(0) == '_') {
				switch (node.nodeName.slice(1)) {
					case "Section": { entries = entries.concat(ParseSection(node)); break; }
					default: { Debug.ErrorMsg("Tags starting with '_' are reserved for internal use but " + node.nodeName + " is not defined and will be ignored. File: " + OverlayList[0] + ".xml"); }
				}
			} else {
				var entry:INotation = NotationBase.Create(node, this);
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
			case "EnableKBShortcut":
				if (newValue) { DefaultMapDV.SignalChanged.Connect(HookDefaultMapShortcut, this); }
				else { DefaultMapDV.SignalChanged.Disconnect(HookDefaultMapShortcut, this); }
				break;
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

	private function Activate():Void { }

	private function Deactivate():Void { }

	private function KBSToggle(dv:DistributedValue):Void { Config.SetValue("EnableKBShortcut", dv.GetValue()); }

	private function HookDefaultMapShortcut(dv:DistributedValue):Void {
		if (dv.GetValue() && Key.isDown(Key.CONTROL)) {
			dv.SetValue(false);
			// Closing default map forces reticule mode; Ok when closing Cartog, override when opening
			if(InterfaceWindow.ToggleWindow()) { Character.ExitReticuleMode(); }
		}
	}

	private function InterfaceWindowLoaded(windowContent:Object):Void {
		windowContent.SetData(ZoneIndex, LayerDataList, Config);
	}

	/// Variables
	private var DefaultMapDV:DistributedValue;
	private var KBShortcutToggleDV:DistributedValue;

	private var ZoneIndexLoader:XML;
	public var ZoneIndex:Object;

	private var OverlayList:Array;
	private var OverlayLoader:XML;
	private var LayerDataList:Array; // Array of LayerData objects

	private static var EventSamhain:Number = 1;
	private static var EventKrampus:Number = 2;
}

// The big list of future Glaucon questions (stuff to pester him with when I run out of things I can do without it):
//   Sourcing map backgrounds from RDB (would be more stable than loading loose images?, still extendable, and would significantly reduce the game assets I need to redistribute)
//   Stabilize the loading of loose images (still valuable if I'm going to permit extending the icon set)
//   Anima well locks and leaps
//   Long range champion detection
//   GetScreenPos() for arbitrary world coordinates
//   Thread-safety of game API calls
//     Hypothesis on some stability issues is that loading multiple icons simultaniously occasionally resulted in multiple calls to the game API, which didn't handle it well
//     Will see if increased pre-processing (sequentially) improves the situation

/// List of map IDs from TSW
// 1000 : London
// 1100 : New York
// 1120 : Co-op City Parking Garage
// 1123 : Co-op City Parking Garage
// 1124 : Co-op City Parking Garage
// 1200 : Seoul
// 1300 : The Sunken Library
// 2200 : Seoul
// 3030 : Kingsmouth Town
// 3035 : Kingsmouth Sewer Junction
// 3040 : The Savage Coast
// 3050 : The Blue Mountain
// 3070 : Kaidan
// 3090 : The Scorched Desert
// 3100 : City of the Sun God
// 3120 : The Besieged Farmlands
// 3130 : The Shadowy Forest
// 3140 : The Carpathian Fangs
// 5000 : The Slaughterhouse
// 5040 : The Polaris
// 5060 : Agartha
// 5080 : The Ankh
// 5110 : Beyond the Sargasso Sea
// 5120 : Dreaming Prison
// 5140 : Hell Raised
// 5150 : Hell Fallen
// 5160 : Hell Eternal
// 5170 : The Darkness War
// 5190 : The Facility
// 5200 : The Gate
// 5300 : Road to Xibalba
// 5710 : Manhattan Exclusion Zone
// 5720 : N'Gha-Pei the Corpse-Island
// 5811 : Seoul Fight Club
// 5820 : El Dorado
// 5840 : Stonehenge
// 6001 : Illuminati Cellar
// 6003 : Mining Museum Basement
// 6007 : Kingsmouth Sewer
// 6008 : Illuminati Underground
// 6009 : Maintenance Tunnels
// 6010 : Illuminati Archives
// 6012 : Well of Our Forefathers
// 6013 : Dr Bannerman's Clinic
// 6014 : The Illuminati Tunnels
// 6020 : Room 13
// 6030 : Memory of Stonehenge
// 6070 : Lair of Darkness
// 6071 : Innsmouth Academy Basement
// 6072 : Safehouse
// 6073 : Atlantic Island Park Shadow
// 6074 : Mancave
// 6075 : The Guardian's Cave
// 6076 : The Fog
// 6120 : Devore Mansion Crypt
// 6130 : Organ Smugglers' Basement
// 6152 : Blue Ridge Mine
// 6154 : The Ak'ab Abyss
// 6161 : The Shadow World
// 6163 : The Devore Mansion
// 6200 : Hotel Wahid Basement
// 6201 : Ancient Marya Atheneum
// 6202 : Butcher Shop Cellar
// 6203 : Al-Merayah Tunnels
// 6206 : The Howling
// 6207 : Aten Temple
// 6208 : The Black Pyramid
// 6209 : Ancient Tomb
// 6210 : The Pinnacle
// 6213 : The Last Train to Cairo
// 6215 : Date Factory
// 6220 : Sol Glorificus, 329 AD
// 6222 : Old Al-Merayah
// 6224 : Thinis, 1897 BCE
// 6401 : Underground Bunker
// 6404 : Dutchman's lair
// 6407 : The Lonely Patriot
// 6461 : Dimir Farm Cellar
// 6471 : Occulted Crypt
// 6536 : Emma's Dream
// 6537 : Dracula's Castle
// 6540 : The Palace Below
// 6550 : Tomb of the Prince
// 6560 : Dracul's Rest
// 6570 : Hatchet Falls Facility
// 6580 : The Nursery
// 6590 : Emma's Dreamscape
// 6600 : Ground Zero Flashback
// 6620 : Kaidan Station
// 6630 : Akiyama Building Parking Garage
// 6640 : The Fear Nothing Foundation
// 6660 : Ibaraki's Lair
// 6670 : Yuichi's Apartment
// 6672 : Yasuraka House
// 6680 : Kaidan District Sewers
// 6690 : Mefisto Security
// 6700 : Niflheim
// 6710 : Hell
// 6730 : The Clubhouse
// 6740 : The AV Suite
// 7000 : The Crucible
// 7010 : The Crucible
// 7020 : London Fight Club
// 7050 : Cold Room
// 7070 : Albion Ballroom Theatre
// 7071 : Albion Ballroom Theatre
// 7075 : Albion Rehearsal Stage
// 7080 : Tabula Rasa
// 7090 : Amity House
// 7100 : The Mithraeum
// 7103 : The Mithraeum
// 7110 : Ockham's Razor
// 7120 : Squatter's Den
// 7130 : Phoenician Warehouse
// 7140 : Londinium Excavation
// 7142 : The San Nicolo al Lido Catacombs
// 7160 : The Crusades Club
// 7200 : Test Chamber
// 7203 : Test Chamber
// 7210 : Warehouse
// 7220 : Illuminati Office
// 7230 : Brooklyn Fight Club
// 7240 : Orochi Office
// 7251 : The Modern Prometheus
// 7252 : Dr. Aldini's Meat Locker
// 7260 : New York Sewers
// 7280 : The Creature's Abode
// 7400 : Dojang
// 7403 : Dojang
// 7410 : Agartha
// 7416 : Corrupted Agartha
// 7420 : Shambala
// 7440 : The Abandoned Asylum
// 7450 : Orochi Office
// 7600 : Hotel Wahid
// 7602 : The Hotel - Elite
// 7603 : The Hotel - Nightmare
// 7610 : Franklin Mansion
// 7612 : Mansion - Elite
// 7613 : Mansion - Nightmare
// 7620 : The Castle
// 7622 : The Castle - Elite
// 7623 : The Castle - Nightmare
// 7640 : Arturo Castiglion's Office
// 34171 : Fusang Projects