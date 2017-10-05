// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import efd.Cartographer.lib.Mod;

import efd.Cartographer.gui.Layers.NotationLayer;
import efd.Cartographer.gui.Layers.CollectibleLayer;

// Holds notation data and config information for a map notation layer
class efd.Cartographer.LayerData {
	public function LayerData(layer:String, config:Object) {
		super();
		Layer = layer;
		Settings = config;
		NotationsByZone = new Object();
	}

	public function AddNotation(notation:Object) {
		var zoneID:Number = notation.ZoneID;
		if (NotationsByZone[zoneID] == undefined) {
			NotationsByZone[zoneID] = { Areas: new Array(), Paths: new Array(), Waypoints: new Array() };
		}
		switch (notation.Type) {
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
				Mod.TraceMsg('A notation of unknown type="' + notation.Type + '" could not be sorted.');
		}
	}

	public function GetWaypoints(zoneID:Number):Array { return NotationsByZone[zoneID].Waypoints; }

	public function get LayerName():String { return Layer; }
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

	private var Layer:String; // Name of this layer
	// View of configuration settings for this layer; read access only, no change notification available
	// Fields: ShowLayer:Boolean
	//         Depth:Number (also the index in the data list?)
	private var Settings:Object;
	// Notation records stored in a sparse index using zone IDs
	// Within each index, notations are in arrays based on subtype (Areas, Paths, Waypoints)
	private var NotationsByZone:Object;
}
