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
