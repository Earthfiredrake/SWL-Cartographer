// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import com.Utils.LDBFormat;

import efd.Cartographer.Cartographer;
import efd.Cartographer.inf.INotation;

class efd.Cartographer.notations.mix.TransitMixIn {
	public static function ApplyMixIn(target:INotation, mod:Cartographer):Void {
		var targetZone:Number = Number(target.GetXmlView().attributes.targetZone);
		var hasMap:Boolean = mod.ZoneIndex[targetZone] != undefined;
		var isPoint:Boolean = target["GetIcon"] != undefined;

		if (target["Name"] == undefined) {
			target["Name"] = LDBFormat.Translate("<localized category=52000 id=" + targetZone + " />");
		}

		if (hasMap) { // Not even bothering if there is no map to go to
			target["TargetZone"] = targetZone;
			target.HookEvents = function(uiElem:MovieClip):Void {
				uiElem.onPress = function():Void
					{ this.MapViewLayer.MapViewClip.ChangeMap(this.Data.TargetZone); };
			};
			target.UnhookEvents = function(uiElem:MovieClip):Void {	uiElem.onPress = undefined; };
		} else { // TODO: Make a more suitable icon modifier sprite for a "no map here" icon
			if (isPoint) { target["IconMod"] = "error"; }
		}

		if (isPoint && target["Icon"] == undefined) {
			target["Icon"] = targetZone == AgarthaZoneID ? "exit_agartha.png" : "exit_zone.png";
		}
	}

	private static var AgarthaZoneID:Number = 5060;
}
