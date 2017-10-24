// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

class efd.Cartographer.notations.mix.ChampMixIn {
	public static function ApplyMixIn(target:INotation):Void {
		target["ChampID"] = Number(target.GetXmlView().attributes.champID);
		target["IsGroup"] = Boolean(target.GetXmlView().attributes.group);

		target["GetName"] = function():String {
			if (this["Name"] == undefined) { this["Name"] = ChampMixIn.GetChampName(this["ChampID"]); }
			return this["Name"]
		};

		target["GetPenColour"] = function():Number {
			if (!Lore.IsLocked(this["ChampID"])) { return 0x888888; }
			else { return undefined; }
		}
	}

	private static function GetChampName(champID:Number):String {
		var name:String = Lore.GetDataNodeById(champID).m_Name;
		if (!name) {
			Mod.TraceMsg("Unknown champion, malformed ID: " + champID);
			return "Unknown ChampID";
		}
		return name;
	}
}
