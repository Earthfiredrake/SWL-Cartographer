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
		var colour:Number = Data.GetPenColour() ? Data.GetPenColour() : LayerClip.NotationData.ConfigView.PenColour;
		var points:Array = GenerateCircle();

		var pos:Point = LayerClip.HostClip.WorldToMapCoords(Data.GetCentre());
		_x = pos.x;
		_y = pos.y;

		clear();
		lineStyle(2, colour, 100, true, "none", "round", "round");
		var start:Point = points[points.length - 1];
		moveTo(start.x, start.y);
		beginFill(colour, 20);
		for (var p:Number = 0; p < points.length; p += 2) {
			curveTo(points[p].x, points[p].y,
					points[p + 1].x, points[p + 1].y);
		}
		endFill();
	}

	// Rough, lazy circle approximation
	private function GenerateCircle():Array {
		var result:Array = new Array();
		var rad:Number = Data.GetRadius();
		var yOffset:Number = LayerClip.HostClip.ZoneIndex[Data.GetZoneID()].worldY;
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(-rad, yOffset + rad)));
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(0, yOffset + rad)));
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(rad, yOffset + rad)));
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(rad, yOffset)));
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(rad, yOffset - rad)));
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(0, yOffset - rad)));
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(-rad, yOffset - rad)));
		result.push(LayerClip.HostClip.WorldToMapCoords(new Point(-rad, yOffset)));
		return result;
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
