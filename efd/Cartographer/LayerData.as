// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import efd.Cartographer.lib.Mod;

import efd.Cartographer.gui.Layers.NotationLayer;
import efd.Cartographer.gui.Layers.CollectibleLayer;

import efd.Cartographer.inf.INotation;

// Holds notation data and config information for a map notation layer
class efd.Cartographer.LayerData {
	public function LayerData(layer:String, config:Object) {
		super();
		Layer = layer;
		Settings = config;
		NotationsByZone = new Object();
	}

	public function AddNotation(notation:INotation) {
		var zoneID:Number = notation.GetZoneID();
		if (NotationsByZone[zoneID] == undefined) {
			NotationsByZone[zoneID] = { Areas: new Array(), Paths: new Array(), Waypoints: new Array() };
		}
		switch (notation.GetType()) {
			case "area":
				NotationsByZone[zoneID].Areas.push(notation);
				break;
			case "path":
				NotationsByZone[zoneID].Paths.push(notation);
				break;
			case "wp":
				NotationsByZone[zoneID].Waypoints.push(notation);
				break;
			default:
				Mod.TraceMsg('A notation class declared an unknown Type="' + notation.GetType() + '" and could not be sorted.');
		}
	}

	public function GetAreas(zoneID:Number):Array { return NotationsByZone[zoneID].Areas; }
	public function GetPaths(zoneID:Number):Array { return NotationsByZone[zoneID].Paths; }
	public function GetWaypoints(zoneID:Number):Array { return NotationsByZone[zoneID].Waypoints; }

	// TODO: Previously was creating all notation layers for every map layer, which seems excessive
	//       This section is intended to limit it to just the notation types for which data is loaded (in any zone)
	//       But it may be better if layers can be created on the fly as the user migrates between zones or adds their own custom notations
	public function get HasAnyAreas():Boolean { return HasAnyX("Areas"); }
	public function get HasAnyPaths():Boolean { return HasAnyX("Paths"); }
	public function get HasAnyWaypoints():Boolean { return HasAnyX("Waypoints"); }
	private function HasAnyX(type:String):Boolean {
		for (var s:String in NotationsByZone) {
			if (NotationsByZone[s][type].length > 0) { return true; }
		}
		return false;
	}

	public function get LayerName():String { return Layer; }
	public function get IsEmpty():Boolean {
		for (var zone:String in NotationsByZone) {
			// Hacky... Objects don't have a length to query though
			return false;
		}
		return true;
	}
	public function get IsVisible():Boolean { return Settings.ShowLayer; }
	public function get ConfigView():Object { return Settings; }

	// TODO: Plugin System
	//   This should allow runtime registration of new types without need for code changes on this end
	public function get LayerType():Function {
		switch (Layer) {
			case "Champ":
			case "Lore":
				return CollectibleLayer;
			default:
				return NotationLayer;
		}
	}

	static function GetDefaultPenColour(layer:String):Number {
		switch (layer) {
			case "Champ": return 0xFF9000;
			case "Lore": return 0xFFAA00;
			default: return 0x000000;
		}
	}

	private var Layer:String; // Name of this layer
	// View of configuration settings for this layer; read access only, no change notification available
	// Fields: ShowLayer:Boolean
	//         Depth:Number (also the index in the data list?)
	private var Settings:Object;
	// Notation records stored in a sparse index using zone IDs
	// Within each index, notations are in arrays based on subtype (Areas, Paths, Waypoints)
	private var NotationsByZone:Object;
	// TODO: Something is adding a Depth field, which for reasons unknown is listed as NaN
}
