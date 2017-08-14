// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import efd.Cartographer.Waypoint;

class efd.Cartographer.Waypoints.TransitPoint extends Waypoint {

	public function TransitPoint(xml:XMLNode) {
		super(xml);

		TargetZone = xml.attributes.targetZone;
		if (Icon == undefined) {
			Icon = TargetZone == 5060 ? "exit_agartha.png" : "exit_zone.png";
		}
	}

	public var TargetZone:Number;
}
