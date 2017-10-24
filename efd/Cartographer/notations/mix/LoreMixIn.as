// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

class efd.Cartographer.notations.mix.LoreMixIn {
	public static function ApplyMixIn(target:INotation):Void {
		target["LoreID"] = Number(target.GetXmlView().attributes.loreID);

		target["GetName"] = function():String {
			if (this["Name"] == undefined) { this["Name"] = LoreMixIn.GetLoreName(this["LoreID"]); }
			return this["Name"]
		};

		target["GetPenColour"] = function():Number {
			if (!Lore.IsLocked(this["LoreID"])) { return 0x888888; }
			else { return undefined; }
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
/*
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
*/
}
