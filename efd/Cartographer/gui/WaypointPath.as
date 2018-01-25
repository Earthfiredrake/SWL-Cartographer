// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.gui.Layers.NotationLayer;
import efd.Cartographer.inf.IPath;
import efd.Cartographer.lib.Mod;

class efd.Cartographer.gui.WaypointPath extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.WaypointPath";

	private function WaypointPath() { // Indirect construction only
		super();
		Data.HookEvents(this); // Nothing reassigns data, so not too concerned about unhooking
		Redraw();
	}

	public function Redraw():Void {
		var colour:Number = Data.GetPenColour() ? Data.GetPenColour() : MapViewLayer.NotationData.ConfigView.PenColour;
		var pathPoints:Array = Data.GetPathPoints();
		LocalPoints = new Array();
		LocalPoints.push(MapViewLayer.MapViewClip.WorldToMapCoords(pathPoints[0]));
		var clipOrigin:Point = LocalPoints[0].clone();

		for (var i:Number = 1; i < pathPoints.length; ++i) {
			var p:Point = MapViewLayer.MapViewClip.WorldToMapCoords(pathPoints[i]);
			clipOrigin.x = Math.min(clipOrigin.x, p.x);
			clipOrigin.y = Math.min(clipOrigin.y, p.y);
			LocalPoints.push(p);
		}

		_x = clipOrigin.x;
		_y = clipOrigin.y;

		clear();
		lineStyle(LineThickness, colour, 100, true, "none", "round", "round");
		LocalPoints[0] = LocalPoints[0].subtract(clipOrigin);
		moveTo(LocalPoints[0].x, LocalPoints[0].y);
		for (var i:Number = 1; i < LocalPoints.length; ++i) {
			LocalPoints[i] = LocalPoints[i].subtract(clipOrigin);
			lineTo(LocalPoints[i].x, LocalPoints[i].y);
		}
	}

	public function hitTest():Boolean {
		switch (arguments.length) {
			case 1: Mod.TraceMsg("WaypointPath hitTest(Object) called"); return super.hitTest(arguments[0]); // Object comparison hit test, not sure how to implement but doesn't seem to be needed?
			case 2: return super.hitTest(arguments[0], arguments[1]); // Basic bounding box hit test, works as advertisedish
			case 3: return super.hitTest(arguments[0], arguments[1]) ? (arguments[2] ? DetailedHitTest(arguments[0], arguments[1]) : true) : false; // Do a basic bounding test before verifying with the detailed test, if needed
			default: return false; // Bad call parameters
		}
	}

	private function DetailedHitTest(x:Number, y:Number):Boolean {
		var p:Point = new Point(x, y);
		globalToLocal(p);
		for (var i:Number = 1; i < LocalPoints.length; ++i) {
			if (SqDist(LocalPoints[i-1], LocalPoints[i], p) <= LineThickness * LineThickness) { return true; }
		}
		return super.HitTest(x, y, true); // On off chance there actually is other content in the clip
	}

	// Calculates the squared distance between line segment (a-b) and point (c)
	private static function SqDist(a:Point, b:Point, c:Point):Number {
		var ab:Point = b.subtract(a);
		var ac:Point = c.subtract(a);
		var e:Number = Dot(ac, ab);
		if (e <= 0) { return Dot(ac, ac); } // c is outside line segment, closest to a
		var f:Number = Dot(ab, ab);
		if (e >= f) { // c is outside line segment, closest to b
			var bc:Point = c.subtract(b);
			return Dot(bc, bc);
		}
		return Dot(ac, ac) - e * e / f; // c is within the line segment, calculate distance to internal point
	}

	private static function Dot(p1:Point, p2:Point):Number {
		return p1.x * p2.x + p1.y * p2.y;
	}

	private function onMouseMove():Void {
		var p:Point = new Point(_xmouse, _ymouse);
		localToGlobal(p);
		if (Mouse.getTopMostEntity() == MapViewLayer.MapViewClip["MapLayer"] && // Attempting to prevent (for now) path stealing focus from icons above it, index syntax means I don't have to make member public for this temporary code
			hitTest(p.x, p.y, true)) {
				if (!MouseOver) {
					MouseOver = true;
					onRollOver();
				}
		}
		else {
			if (MouseOver) {
				MouseOver = false;
				onRollOut();
			}
		}
	}

	private function onRollOver():Void {
		// This doesn't actually work as a onRollOver event, so it's being manually forced (see above)
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
			Tooltip = MapViewLayer.MapViewClip._parent.attachMovie("CartographerWaypointTooltip", "Tooltip", MapViewLayer.MapViewClip.getNextHighestDepth(), {Data : Data});
			var pos:Point = MapViewLayer.MapViewClip.MapToViewCoords(new Point(_x, _y));
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

	private static var LineThickness:Number = 3;

	private var Data:IPath;
	private var LocalPoints:Array; // Copy of path in clip local coords, used for rendering and collision detection
	private var MapViewLayer:NotationLayer;
	private var Tooltip:MovieClip;

	private var MouseOver:Boolean = false;
}
