// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import gfx.utils.Delegate;

import efd.Cartographer.notations.BasicPoint;

class efd.Cartographer.notations.TransitPoint extends BasicPoint {

	public function TransitPoint(xml:XMLNode) {
		super(xml);

		TargetZone = xml.attributes.targetZone;
		if (Icon == undefined) {
			Icon = TargetZone == 5060 ? "exit_agartha.png" : "exit_zone.png";
		}
	}

	/// Supplementary icon event handlers
	public function HookEvents(target:MovieClip):Void {
		target.onPress = function():Void
			{ this["LayerClip"].HostClip.ChangeMap(this["Data"].TargetZone); };
	}

	public function UnhookEvents(target:MovieClip):Void {
		target.onPress = undefined;
	}

	private var TargetZone:Number;
}
