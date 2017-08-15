// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import com.GameInterface.Lore;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.Waypoint;

class efd.Cartographer.Waypoints.LorePoint extends Waypoint {

	public function LorePoint(xml:XMLNode) {
		super(xml);

		LoreID = xml.attributes.loreID;

		Name = GetLoreName(LoreID);

		if (Icon == undefined) {
			// TODO: Further icon support
			Icon = "lore_buzz.png";
		}
	}

	private static function GetLoreName(loreID:Number):String {
		var topic:String = Lore.GetDataNodeById(loreID).m_Parent.m_Name;
		var index:Number = GetLoreIndex(loreID, Lore.GetTagViewpoint(loreID));
		if (!(topic && index)) {
			Mod.TraceMsg("Unknown topic or entry #, malformed lore ID: " + loreID);
			//return LocaleManager.GetString("LoreHound", "InvalidLoreID");
			return "Unknown LoreID";
		}
		//return LocaleManager.FormatString("LoreHound", "LoreName", topic, catCode, index);
		return topic + " #" + index;
	}

	private static function GetLoreIndex(loreID:Number, source:Number):Number {
		var siblings:Array = Lore.GetDataNodeById(loreID).m_Parent.m_Children;
		var index:Number = 1; // Lore entries start count at 1
		for (var i:Number = 0; i < siblings.length; ++i) {
			var sibling:Number = siblings[i].m_Id;
			if (loreID == sibling) { return index; }
			if (Lore.GetTagViewpoint(sibling) == source) {
				++index;
			}
		}
	}

	public var LoreID:Number;
}
