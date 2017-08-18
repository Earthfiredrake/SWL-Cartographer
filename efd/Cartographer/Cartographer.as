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
		Version : "0.0.6.alpha"
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
		//defaultPacks.push({ name : "Missions", load : true });
		defaultPacks.push({ name : "LoreGlobal", load : true });
		defaultPacks.push({ name : "LoreRegional", load : true });
		defaultPacks.push({ name : "LoreBestiary", load : true });
		Config.NewSetting("OverlayPacks", defaultPacks);
	}

	private function ConfigLoaded():Void {
		Config.ResetValue("OverlayPacks"); // TEMP: Not actually saving this while files are in flux/no config UI
		var packList:Array = Config.GetValue("OverlayPacks");
		TraceMsg("OverlayPacks to load: " + (packList.length + 1));
		for (var i:Number = 0; i < packList.length; ++i) {
			if (packList[i].load) { OverlayList.push(packList[i].name); }
		}
		OverlayLoader = LoadXmlAsynch("waypoints\\" + OverlayList[0], Delegate.create(this, ParseOverlayPack));
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

	private function ParseOverlayPack(success:Boolean):Void {
		if (success) {
			var waypoints:Array = ParseSection(OverlayLoader.firstChild);
			TraceMsg("Sorting " + waypoints.length + " waypoints");
			for (var i:Number = 0; i < waypoints.length; ++i) {
				var layer:String = waypoints[i].Layer;
				var zone:Number = waypoints[i].ZoneID;
				if (Waypoints[layer] == undefined) {
					Waypoints[layer] = new Object();
				}
				if (Waypoints[layer][zone] == undefined) {
					Waypoints[layer][zone] = new Array();
				}
				Waypoints[layer][zone].push(waypoints[i]);
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
			TraceMsg("Waypoints loaded");
		}
	}

	private static function ParseSection(section:XMLNode):Array {
		var waypoints:Array = new Array();
		TraceMsg("Parsing " + section.childNodes.length + " entries at this level");
		for (var i:Number = 0; i < section.childNodes.length; ++i) {
			var node:XMLNode = section.childNodes[i];
			if (node.nodeName == "Section") {
				TraceMsg("Parsing nested section.");
				waypoints = waypoints.concat(ParseSection(node));
			} else {
				TraceMsg("Parsing waypoint.");
				waypoints.push(Waypoint.Create(node));
			}
		}
		return waypoints;
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
