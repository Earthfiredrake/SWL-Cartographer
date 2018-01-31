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
			if (unlockedID == this.Data.ChampID && charID.Equal(Character.GetClientCharID())) {
				this.StateChanged();
			}
		};

		// Override restricted mixin parts will only be applied if type already supports function
		if (target["GetIcon"] != undefined) {
			target["GetIcon"] = function():String {
				if (this.Icon) { return this.Icon; }
				var filename:String = "champ";
				// if (this.IsGroup) { filename += "_group"; }
				// if (this.ChampID != undefined && this.IsCollected) { filename += "_defeated"; }
				return filename + ".png";
			};
		}
		if (target["GetIconModifier"] != undefined) {
			target["GetIconModifier"] = function():Array {
				return [this.IsGroup ? "star" : "none"];
			}
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
