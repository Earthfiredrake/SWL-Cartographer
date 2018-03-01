// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

class efd.Cartographer.notations.mix.LoreMixIn {
	public static function ApplyMixIn(target:INotation):Void {
		var loreID:Number = Number(target.GetXmlView().attributes.loreID);
		var isValid:Boolean = Lore.GetTagType(loreID) == _global.Enums.LoreNodeType.e_Lore;
		var isIcon:Boolean = target["GetIcon"] != undefined;

		// General mixin parts, applied to all notation types
		// Applies to required data members and INotation interface

		if (isValid) {
			if (target["Name"] == undefined) { target["Name"] = GetLoreName(loreID); }
			target["LoreID"] = loreID;
			target["IsCollected"] = !Lore.IsLocked(loreID);
			target["VerifyCollected"] = function():Boolean {
				return this.IsCollected || (this.IsCollected = !Lore.IsLocked(this.LoreID));
			}

			target.HookEvents = function(uiElem:MovieClip):Void {
				if (!this.IsCollected) { // No need to be notified for already collected items
					Lore.SignalTagAdded.Connect(this.CollectibleUnlocked, uiElem);
				}
			};
			target.UnhookEvents = function(uiElem:MovieClip):Void {
				Lore.SignalTagAdded.Disconnect(this.CollectibleUnlocked, uiElem);
			};
			// This event is called in the context of the WaypointIcon
			target["CollectibleUnlocked"] = function(unlockedID:Number, charID:ID32):Void {
				if (unlockedID == this.Data.LoreID) {
					this.Data.IsCollected = true;
					this.StateChanged();
				}
			};
		} else {
			// Avoid stomping existing name, it may identify the offending record
			Mod.ErrorMsg("Unknown LoreID: " + loreID);
			target["Name"] = (target["Name"] == undefined ? "" : target["Name"] + ": ") + "Unknown LoreID";
			if (isIcon) { target["IconMod"] = "error"; }
		}

		// Override restricted mixin parts will only be applied if type already supports function
		// Applies to interface specializations below INotation
		if (isIcon && target["Icon"] == undefined) {
			target["Icon"] = isValid && Lore.GetTagViewpoint(loreID) == 1 ?
				"lore_blsig.png" : "lore_buzz.png";
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
		var index:Number = 1; // Lore entries display index starting at 1
		for (var i:Number = 0; i < siblings.length; ++i) {
			var sibling:Number = siblings[i].m_Id;
			if (loreID == sibling) { return index; }
			if (Lore.GetTagViewpoint(sibling) == source) { ++index; } // Only count the same source (BS #1 may be i == 11)
		}
	}
}
