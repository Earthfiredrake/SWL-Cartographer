// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.notations.BasicPoint;

class efd.Cartographer.notations.LorePoint extends BasicPoint {

	public function LorePoint(xml:XMLNode) {
		super(xml);

		LoreID = xml.attributes.loreID;

		Name = GetLoreName(LoreID);
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

	public function GetIcon():String {
		if (Icon) { return Icon; }
		if (LoreID) {
			if (Lore.IsLocked(LoreID)) {
				if (Lore.GetTagViewpoint(LoreID) == 1) { return "lore_sig.png"; }
				else { return "lore_buzz.png"; }
			} else { return "lore_claimed.png"; }
		} else {
			return "lore_buzz.png";
		}
	}

	// Concept: To reduce the number of icon permutations required, see about applying icon effects and overlays through code
	// Possible filter for greyscale
	// new ColorMatrixFilter([0.3086, 0.6094, 0.0820, 0, 0, 0.3086, 0.6094, 0.0820, 0, 0, 0.3086, 0.6094, 0.0820, 0, 0, 0, 0, 0, 1, 0])

	/// Supplementary icon event handlers
	public function HookEvents(icon:MovieClip, context:Object):Void {
		if (!IsCollected) { // Only applies to uncollected items
			Lore.SignalTagAdded.Connect(CollectibleUnlocked, context);
		}
	}

	public function UnhookEvents(icon:MovieClip, context:Object):Void {
		if (!IsCollected) {
			// Should only be connected on uncollected items
			// The change of icon/layering when collected should destroy the old icon and connections
			Lore.SignalTagAdded.Disconnect(CollectibleUnlocked, context);
		}
	}

	private function CollectibleUnlocked(unlockedID:Number, charID:ID32):Void {
		// I have no idea why this event might be triggered for a non-client character
		// Am following the examples in the existing API code
		if (unlockedID == this["Data"].LoreID && charID.Equal(Character.GetClientCharID())) {
			this["SignalIconChanged"].Emit(this);
		}
	}

	public function get IsCollected():Boolean {
		return !Lore.IsLocked(LoreID);
	}

	private var LoreID:Number;
}
