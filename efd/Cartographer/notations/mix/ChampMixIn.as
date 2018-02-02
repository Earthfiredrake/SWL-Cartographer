// Copyright 2017, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

class efd.Cartographer.notations.mix.ChampMixIn {
	public static function ApplyMixIn(target:INotation):Void {
		// General mixin parts, applied to all notation types
		target["ChampID"] = Number(target.GetXmlView().attributes.champID);
		target["IsGroup"] = Boolean(target.GetXmlView().attributes.group);
		target.addProperty("IsCollected", function():Boolean { return !Lore.IsLocked(this.ChampID); }, null);

		target.GetName = function():String {
			if (this.Name == undefined) { this.Name = ChampMixIn.GetChampName(this.ChampID); }
			return this.Name;
		};

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
			// I have no idea why this event might be triggered for a non-client character
			// Am following the examples in the existing API code
			if (unlockedID == this.Data.ChampID && charID.Equal(Character.GetClientCharID())) {
				this.StateChanged();
			}
		};

		// Override restricted mixin parts will only be applied if type already supports function
		if (target["GetIcon"] != undefined) {
			target["GetIcon"] = function():String {
				if (this.Icon) { return this.Icon; }
				return "champ.png";
			};
		}
		if (target["TintIcon"] != undefined) {
			target["TintIcon"] = function():Boolean { return true; };
		}
		if (target["GetIconModifier"] != undefined) {
			target["GetIconModifier"] = function():Array {
				// Flags the icon if the ID isn't an achievement or sub-achievement under the Champions topic
				//   Also flags the collective "Hunter" achievements
				if ((Lore.GetTagType(this.ChampID) == _global.Enums.LoreNodeType.e_Achievement &&
					 Lore.GetTagParent(Lore.GetTagParent(this.ChampID)) == 4061 &&
					 Lore.GetTagChildrenIdArray(this.ChampID, _global.Enums.LoreNodeType.e_Achievement).length == 0) ||
					(Lore.GetTagType(this.ChampID) == _global.Enums.LoreNodeType.e_SubAchievement &&
					 Lore.GetTagParent(Lore.GetTagParent(Lore.GetTagParent(this.ChampID))) == 4061)) {
					return this.IsGroup ? ["star"] : undefined;
				} else { return ["error"]; }
			};
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
