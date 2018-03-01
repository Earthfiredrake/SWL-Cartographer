// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

class efd.Cartographer.notations.mix.ChampMixIn {
	public static function ApplyMixIn(target:INotation):Void {
		var champID:Number = Number(target.GetXmlView().attributes.champID);
		var champType:Number = GetChampType(champID);

		// General mixin parts, applied to all notation types
		if (champType > 0) {
			if (target["Name"] == undefined) { target["Name"] = Lore.GetDataNodeById(champID).m_Name; }
			target["ChampID"] = champID;
			target["IsCollected"] = !Lore.IsLocked(champID);
			target["VerifyCollected"] = function():Boolean {
				return this.IsCollected || (this.IsCollected = !Lore.IsLocked(this.ChampID));
			}

			target.HookEvents = function(uiElem:MovieClip):Void {
				if (!this.IsCollected) { // No need to be notified for collected items
					Lore.SignalTagAdded.Connect(this.CollectibleUnlocked, uiElem);
				}
			};
			target.UnhookEvents = function(uiElem:MovieClip):Void {
				Lore.SignalTagAdded.Disconnect(this.CollectibleUnlocked, uiElem);
			};
			// This event is called in the context of the WaypointIcon
			target["CollectibleUnlocked"] = function(unlockedID:Number, charID:ID32):Void {
				if (unlockedID == this.Data.ChampID) {
					this.Data.IsCollected = true;
					this.StateChanged();
				}
			};
		} else {
			// Avoid stomping existing name, it may identify the offending record
			Mod.ErrorMsg("Unknown ChampID: " + champID);
			target["Name"] = (target["Name"] == undefined ? "" : target["Name"] + ": ") + "Unknown ChampID";
		}

		// Override restricted mixin parts will only be applied if type already supports function
		if (target["GetIcon"] != undefined) {
			target["UseTint"] = true;
			if (target["IconMod"] == undefined || champType == 0) {
				target["IconMod"] = champType == 2 ? "star" : (champType == 1 ? target["IconMod"] : "error");
			}
		}
	}

	// 0 is not a champ, 1 is a normal champ, 2 is group
	private static function GetChampType(champID:Number):Number {
		var tagType = Lore.GetTagType(champID);
		var grandparent = Lore.GetTagParent(Lore.GetTagParent(champID));
		if (tagType == _global.Enums.LoreNodeType.e_Achievement &&
			grandparent == 4061 &&
			Lore.GetTagChildrenIdArray(champID, _global.Enums.LoreNodeType.e_SubAchievement).length == 0) {
				return 2; // Group champ
			}
		if (tagType == _global.Enums.LoreNodeType.e_SubAchievement &&
			Lore.GetTagParent(grandparent) == 4061) {
				return 1; // Normal champ
			}
		return 0; // Nota champ
	}
}
