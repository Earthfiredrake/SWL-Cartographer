// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import gfx.utils.Delegate;

import efd.Cartographer.lib.ConfigWrapper;
import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;
import efd.Cartographer.Waypoint;

class efd.Cartographer.Cartographer extends Mod {
	private static var ModInfo:Object = {
		// Debug settings at top so that commenting out leaves no hanging ','
		//Trace : true,
		GuiFlags : ef_ModGui_NoConfigWindow,
		Name : "Cartographer",
		Version : "0.0.4.alpha"
	};

	/// Initialization
	public function Cartographer(hostMovie:MovieClip) {
		super(ModInfo, hostMovie);
		// Ingame debug menu registers variables that are initialized here, but not those initialized at class scope

		InitializeConfig();

		ZoneIndex = new Object();
		ZoneIndexLoader = LoadXmlAsynch("Zones", Delegate.create(this, LoadZoneInfo));

		OverlayList = new Array("BasePack");
		Waypoints = new Object();

		TraceMsg("Initialized");
	}

	private function InitializeConfig(arConfig:ConfigWrapper):Void {
		var defaultPacks:Array = new Array();
		defaultPacks.push({ name : "Missions", load : true });
		defaultPacks.push({ name : "Lore", load : true });
		Config.NewSetting("OverlayPacks", defaultPacks);
	}

	private function ConfigLoaded():Void {
		var packList:Array = Config.GetValue("OverlayPacks");
		TraceMsg("OverlayPacks to load: " + (packList.length + 1));
		for (var i:Number = 0; i < packList.length; ++i) {
			if (packList[i].load) { OverlayList.push(packList[i].name); }
		}
		OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseWaypoints));
		super.ConfigLoaded();
	}

	private function LoadZoneInfo(success:Boolean):Void {
		if (success) {
			var xmlRoot:XMLNode = ZoneIndexLoader.firstChild;
			for (var i:Number = 0; i < xmlRoot.childNodes.length; ++i) {
				var zone:XMLNode = xmlRoot.childNodes[i];
				ZoneIndex[zone.attributes.id] = { worldX : zone.attributes.worldX, worldY : zone.attributes.worldY };
			}
			delete ZoneIndexLoader;
			TraceMsg("Zone index loaded");
		} else {
			ErrorMsg("Unable to load zone index");
		}
	}

	private function ParseWaypoints(success:Boolean):Void {
		if (success) {
			var xmlRoot:XMLNode = OverlayLoader.firstChild;
			for (var i:Number = 0; i < xmlRoot.childNodes.length; ++i) {
				var zone:XMLNode = xmlRoot.childNodes[i];
				for (var j:Number = 0; j < zone.childNodes.length; ++j) {
					var category:XMLNode = zone.childNodes[j];
					if (Waypoints[category.attributes.type] == undefined) {
						Waypoints[category.attributes.type] = new Object();
					}
					if (Waypoints[category.attributes.type][zone.attributes.id] == undefined) {
						Waypoints[category.attributes.type][zone.attributes.id] = new Array();
					}
					for (var k:Number = 0; k < category.childNodes.length; ++k) {
						Waypoints[category.attributes.type][zone.attributes.id].push(new Waypoint(category.childNodes[k], category.attributes.icon));
					}
				}
			}
			TraceMsg("Loaded waypoint file: "  + OverlayList.shift() + ".xml");
		} else {
			ErrorMsg("Unable to load waypoint file: " + OverlayList.shift() + ".xml");
		}
		if (OverlayList.length > 0) {
			OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseWaypoints));
		} else {
			//delete OverlayList;
			delete OverlayLoader;
			TraceMsg("Waypoints loaded");
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
	}

	private function Activate():Void {
	}

	private function Deactivate():Void {
	}

	private function InterfaceWindowLoaded():Void {
		TraceMsg("Opening interface window");
		InterfaceWindowClip.m_Content.SetData(ZoneIndex, Waypoints);
	}

	/// Variables
	private var ZoneIndexLoader:XML;
	private var ZoneIndex:Object;

	private var OverlayList:Array;
	private var OverlayLoader:XML;
	private var Waypoints:Object; // Multi level array/map (Layer/Type->Zone->WaypointData)
}
