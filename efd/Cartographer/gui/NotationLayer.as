// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.Waypoint;

import efd.Cartographer.gui.WaypointIcon;

class efd.Cartographer.gui.NotationLayer extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.NotationLayer";

	private function NotationLayer() { // Indirect construction only
		super();
		RenderedWaypoints = new Array();
	}

	public function RenderWaypoints(newZone:Number):Void {
		WaypointCount = -1;
		Zone = newZone;
		LoadSequential();
	}

	private function LoadSequential():Void {
		WaypointCount += 1;
		var waypoints:Array = WaypointData[Zone];
		if (WaypointCount < waypoints.length) {
			AttachWaypoint(waypoints[WaypointCount], _parent.WorldToWindowCoords(waypoints[WaypointCount].Position));
		} else {
			ClearDisplay(waypoints.length);
		}
	}

	private function AttachWaypoint(data:Waypoint, mapPos:Point):Void {
		if (RenderedWaypoints[WaypointCount]) {
			RenderedWaypoints[WaypointCount].Reassign(data, mapPos);
		} else {
			var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + getNextHighestDepth(), this, getNextHighestDepth(), {Data : data, _x : mapPos.x, _y : mapPos.y}));
			wp.SignalWaypointLoaded.Connect(LoadSequential, this);
			wp.LoadIcon();
			RenderedWaypoints.push(wp);
		}
	}

	public function ClearDisplay(firstIndex:Number):Void {
		for (var i:Number = firstIndex ? firstIndex : 0; i < RenderedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedWaypoints.splice(firstIndex);
	}

	/// Variables
	private var Zone:Number;

	private var WaypointCount:Number;
	private var WaypointData:Object; // Zone indexed map of waypoint data arrays
	private var RenderedWaypoints:Array; // Array of currently displayed waypoints for this layer

	// TODO: Consider doing some sorting of waypoints based on icon, in an effort to minimize reloads
}

/// Notes:
//  A brief experiment with placing the ClearDisplay call within RenderWaypoints resulted in some very odd behaviour
//  There seem to be some definite timing issues involved with the creation and destruction of movie clips
