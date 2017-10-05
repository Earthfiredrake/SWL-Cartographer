// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.notations.BasicPoint;

class efd.Cartographer.notations.ChampPoint extends BasicPoint {

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

	/// Supplementary icon event handlers
	public function HookIconEvents(icon:MovieClip, context:Object) {
		if (!IsCollected) { // Only applies to uncollected items
			Lore.SignalTagAdded.Connect(CollectibleUnlocked, context);
		}
	}

	public function UnhookIconEvents(icon:MovieClip, context:Object) {
		if (!IsCollected) {
			// Should only be connected on uncollected items
			// The change of icon/layering when collected should destroy the old icon and connections
			Lore.SignalTagAdded.Disconnect(CollectibleUnlocked, context);
		}
	}

	private function CollectibleUnlocked(unlockedID:Number, charID:ID32):Void {
		// I have no idea why this event might be triggered for a non-client character
		// Am following the examples in the existing API code
		if (unlockedID == this["Data"].ChampID && charID.Equal(Character.GetClientCharID())) {
			this["SignalIconChanged"].Emit(this);
		}
	}

	public function get IsCollected():Boolean {
		return !Lore.IsLocked(ChampID);
	}

	public var ChampID:Number;
	public var IsGroup:Boolean;
}