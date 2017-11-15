// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.inf.IArea;
import efd.Cartographer.lib.Mod;

class efd.Cartographer.gui.WaypointArea extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.WaypointArea";

	private function WaypointArea() { // Indirect construction only
		super();
		Data.HookEvents(this); // Nothing reassigns data, so not too concerned about unhooking
		Redraw();
	}

	public function Redraw():Void {
		var pos:Point = LayerClip.HostClip.WorldToMapCoords(Data.GetCentre());
		_x = pos.x;
		_y = pos.y;

		// Using only x because y flips the coordinate frame
		var scaleRad:Number = LayerClip.HostClip.WorldToMapCoords(new Point(Data.GetRadius(), 0)).x;
		var colour:Number = Data.GetPenColour() ? Data.GetPenColour() : LayerClip.NotationData.ConfigView.PenColour;
		clear();
		lineStyle(2, colour, 100, true, "none", "round", "round");
		beginFill(colour, 20);
		this["drawEllipse"](-scaleRad, -scaleRad, scaleRad * 2, scaleRad * 2);
		endFill();
	}

	private function onRollOver():Void {
		ShowTooltip();
	}

	private function onRollOut():Void {
		RemoveTooltip();
	}
	private function onReleaseOutside():Void { onRollOut(); }
	private function onReleaseOutsideAux():Void { onRollOut(); }

	public function StateChanged():Void { Redraw(); }

	private function ShowTooltip():Void {
		if (!Tooltip) {
			Tooltip = LayerClip.HostClip._parent.attachMovie("CartographerWaypointTooltip", "Tooltip", LayerClip.HostClip.getNextHighestDepth(), {Data : Data});
			var pos:Point = LayerClip.HostClip.MapToViewCoords(new Point(_x, _y));
			Tooltip._x = pos.x;
			Tooltip._y = pos.y;
		}
	}

	private function RemoveTooltip():Void {
		if (Tooltip) {
			Tooltip.removeMovieClip();
			Tooltip = null;
		}
	}

	private function onUnload():Void {
		RemoveTooltip();
	}

	private var Data:IArea;
	private var LayerClip:MovieClip;
	private var Tooltip:MovieClip;
}
