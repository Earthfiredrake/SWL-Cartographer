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
		// General mixin parts, applied to all notation types
		// Applies to required data members and INotation interface
		target["LoreID"] = Number(target.GetXmlView().attributes.loreID);
		target.addProperty("IsCollected", function():Boolean { return !Lore.IsLocked(this.LoreID); }, null);

		target.GetName = function():String {
			if (this.Name == undefined) { this.Name = LoreMixIn.GetLoreName(this.LoreID); }
			return this.Name;
		};

		target.GetPenColour = function():Number {
			if (this.IsCollected) { return 0x888888; }
			else { return undefined; }
		};

		target.HookEvents = function(uiElem:MovieClip):Void {
			if (!this.IsCollected) { // No need to be notified for collected items
				Lore.SignalTagAdded.Connect(this.CollectibleUnlocked, uiElem);
			}
		};
		target.UnhookEvents = function(uiElem:MovieClip):Void {
			Lore.SignalTagAdded.Disconnect(this.CollectibleUnlocked, uiElem);
		};
		target["CollectibleUnlocked"] = function(unlockedID:Number, charID:ID32):Void {
			// I have no idea why this event might be triggered for a non-client character
			// Am following the examples in the existing API code
			if (unlockedID == this.Data.LoreID && charID.Equal(Character.GetClientCharID())) {
				this.StateChanged();
			}
		};

		// Override restricted mixin parts will only be applied if type already supports function
		// Applies to interface specializations below INotation
		if (target["GetIcon"] != undefined) {
			target["GetIcon"] = function():String {
				if (this.Icon) { return this.Icon; }
				if (this.LoreID == undefined) { return "lore_buzz.png"; }
				if (this.IsCollected) { return "lore_claimed.png"; }
				return Lore.GetTagViewpoint(this.LoreID) == 1 ? "lore_sig.png" : "lore_buzz.png";
			};
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
}
