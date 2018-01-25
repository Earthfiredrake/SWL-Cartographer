// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import efd.Cartographer.inf.INotation;

class efd.Cartographer.notations.mix.TransitMixIn {
	public static function ApplyMixIn(target:INotation):Void {
		target["TargetZone"] = Number(target.GetXmlView().attributes.targetZone);

		target.HookEvents = function(uiElem:MovieClip):Void {
			uiElem.onPress = function():Void
				{ this.MapViewLayer.MapViewClip.ChangeMap(this.Data.TargetZone); };
		};
		target.UnhookEvents = function(uiElem:MovieClip):Void {
			uiElem.onPress = undefined;
		}

		if (target["GetIcon"] != undefined && target["Icon"] == undefined) {
			target["Icon"] = target["TargetZone"] == AgarthaZoneID ? "exit_agartha.png" : "exit_zone.png";
		}
	}

	private static var AgarthaZoneID:Number = 5060;
}
