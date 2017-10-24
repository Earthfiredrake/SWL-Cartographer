// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.inf.IPath;
import efd.Cartographer.lib.Mod;

class efd.Cartographer.gui.WaypointPath extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.WaypointPath";

	private function WaypointPath() { // Indirect construction only
		super();
		Redraw();
	}

	public function Redraw():Void {
		var colour:Number = Data.GetPenColour() ? Data.GetPenColour() : LayerClip.NotationData.ConfigView.PenColour;
		var pathPoints:Array = Data.GetPathPoints();
		var renderPoints:Array = new Array();
		renderPoints.push(LayerClip.HostClip.WorldToMapCoords(pathPoints[0]));
		var clipOrigin:Point = renderPoints[0].clone();

		for (var i:Number = 1; i < pathPoints.length; ++i) {
			var p:Point = LayerClip.HostClip.WorldToMapCoords(pathPoints[i]);
			clipOrigin.x = Math.min(clipOrigin.x, p.x);
			clipOrigin.y = Math.min(clipOrigin.y, p.y);
			renderPoints.push(p);
		}

		_x = clipOrigin.x;
		_y = clipOrigin.y;

		clear();
		lineStyle(3, colour, 100, true, "none", "round", "round");
		renderPoints[0] = renderPoints[0].subtract(clipOrigin);
		moveTo(renderPoints[0].x, renderPoints[0].y);
		for (var i:Number = 1; i < renderPoints.length; i++) {
			renderPoints[i] = renderPoints[i].subtract(clipOrigin);
			lineTo(renderPoints[i].x, renderPoints[i].y);
		}
	}

	private function onRollOver():Void {
		// This isn't actually working, seems the unfilled path doesn't have mouse collision
		Mod.TraceMsg("Rolled over a path! They do exist.");
		ShowTooltip();
	}

	private function onRollOut():Void {
		RemoveTooltip();
	}
	private function onReleaseOutside():Void { onRollOut(); }
	private function onReleaseOutsideAux():Void { onRollOut(); }

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

	private var Data:IPath;
	private var LayerClip:MovieClip;
	private var Tooltip:MovieClip;
}
