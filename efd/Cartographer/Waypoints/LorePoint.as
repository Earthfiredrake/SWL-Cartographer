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
		var source:Number = Lore.GetTagViewpoint(loreID);
		var index:Number = GetLoreIndex(loreID, source);
		if (!(topic && index)) {
			Mod.TraceMsg("Unknown topic or entry #, malformed lore ID: " + loreID);
			//return LocaleManager.GetString("LoreHound", "InvalidLoreID");
			return "Unknown LoreID";
		}
		var catCode:String;
		switch (source) {
			case 0: // Buzzing
				//catCode = LocaleManager.GetString("LoreHound", "BuzzingSource");
				catCode = " ";
				break;
			case 1: // Black Signal
				//catCode = LocaleManager.GetString("LoreHound", "BlackSignalSource");
				catCode = " BS ";
				break;
			default: // Unknown source
				// Consider setting up a report here, with LoreID as tag
				// Low probability of it actually occuring, but knowing sooner rather than later might be nice
				//catCode = LocaleManager.GetString("LoreHound", "UnknownSource");
				catCode = " ?? ";
				Mod.TraceMsg("Lore has unknown source: " + source);
				break;
		}
		//return LocaleManager.FormatString("LoreHound", "LoreName", topic, catCode, index);
		return topic + catCode + "#" + index;
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
