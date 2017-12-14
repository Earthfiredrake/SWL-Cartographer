// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import gfx.utils.Delegate;

import com.GameInterface.DistributedValue;

import efd.Cartographer.lib.ara.BasicMCGraphics;

import efd.Cartographer.lib.ConfigWrapper;
import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

import efd.Cartographer.LayerData;
import efd.Cartographer.notations.NotationBase;

class efd.Cartographer.Cartographer extends Mod {
	private static var ModInfo:Object = {
		// Debug settings at top so that commenting out leaves no hanging ','
		// Trace : true,
		GuiFlags : ef_ModGui_NoConfigWindow,
		Name : "Cartographer",
		Version : "0.1.4.alpha"
	};

	/// Initialization
	public function Cartographer(hostMovie:MovieClip) {
		super(ModInfo, hostMovie);

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
		if (_global.com.GameInterface.DressingRoom.IsEventActive(EventKrampus)) {
			// Hacky access via _global so I can continue to avoid linking to SWL API
			defaultPacks.push({ name : "EvKrampusnacht", load : true });
		}
		Config.NewSetting("OverlayPacks", defaultPacks);

		Config.NewSetting("LayerSettings", new Object());
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
		if (SystemsLoaded.LocalizedText) {
			// Overlay loading additionally dependent on LocaleManager being initialized
			OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseOverlayPack));
		}

		super.ConfigLoaded();
	}

	private function StringsLoaded(success:Boolean):Void {
		if (success && SystemsLoaded.Config) {
			// Overlay loading additionally dependent on Config being initialized
			OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseOverlayPack));
		}

		super.StringsLoaded(success);
	}

	private function ResetConfig(dv:DistributedValue):Void {
		if (dv.GetValue()) {
			super.ResetConfig(dv);
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
			TraceMsg("Zone index loaded");
			SystemsLoaded.ZoneIndex = true;
			CheckLoadComplete();
		} else {
			ErrorMsg("Unable to load zone index");
		}
	}

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
		} else {
			ErrorMsg("Unable to load waypoint file: " + OverlayList.shift() + ".xml");
		}
		if (OverlayList.length > 0) {
			OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseOverlayPack));
		} else {
			delete OverlayList;
			delete OverlayLoader;
			CleanupLayers();
			TraceMsg("Waypoints loaded");
		}
	}

	private static function ParseSection(section:XMLNode):Array {
		var entries:Array = new Array();
		for (var i:Number = 0; i < section.childNodes.length; ++i) {
			var node:XMLNode = section.childNodes[i];
			if (node.nodeName == "Section") {
				entries = entries.concat(ParseSection(node));
			} else {
				var entry:INotation = NotationBase.Create(node);
				if (entry != undefined) {
					entries.push(entry);
				}
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
		if (CompareVersions("0.1.2.alpha", oldVersion) > 0) {
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

	private function InterfaceWindowLoaded():Void {
		InterfaceWindowClip.m_Content.SetData(ZoneIndex, LayerDataList, Config);
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
