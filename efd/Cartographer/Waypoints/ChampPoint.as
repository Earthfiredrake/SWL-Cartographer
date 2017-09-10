// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import com.GameInterface.Lore;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.Waypoint;

class efd.Cartographer.Waypoints.ChampPoint extends Waypoint {

	public function ChampPoint(xml:XMLNode) {
		super(xml);

		ChampID = xml.attributes.champID;
		IsGroup = xml.attributes.group;

		Name = GetChampName(ChampID);
	}

	private static function GetChampName(champID:Number):String {
		var name:String = Lore.GetDataNodeById(champID).m_Name;
		if (!name) {
			Mod.TraceMsg("Unknown champion, malformed ID: " + champID);
			return "Unknown ChampID";
		}
		return name;
	}

	public function get Icon():String {
		if (_Icon) { return _Icon; }
		var filename:String = "champ"
		if (IsGroup) { filename += "_group"; }
		if (ChampID) {
			if (!Lore.IsLocked(ChampID)) { filename += "_defeated"; }
		}
		return filename + ".png";
	}

	public var ChampID:Number;
	public var IsGroup:Boolean;
}