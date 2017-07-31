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
		Mod.LogMsg("Creating new notation layer");
		RenderedWaypoints = new Array();
		Mod.LogMsg("Notation layer initialized.");
	}

	public function RenderWaypoints(newZone:Number) {
		Mod.LogMsg("Rendering new set of waypoints");
		var waypoints:Array = WaypointData[newZone];
		for (var i:Number = 0; i < waypoints.length; ++i) {
			var data:Waypoint = waypoints[i];
			var mapPos:Point = _parent.WorldToWindowCoords(data.Position);
			RenderedWaypoints.push(MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + getNextHighestDepth(), this, getNextHighestDepth(), {Data : data, _x : mapPos.x, _y : mapPos.y}));
		}
		Mod.LogMsg("Waypoints have been created");
	}

	public function ClearDisplay() {
		Mod.LogMsg("Clearing displayed waypoints");
		for (var i:Number = 0; i < RenderedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedWaypoints = new Array();
		Mod.LogMsg("Cleared");
	}

	/// Variables
	var WaypointData:Object; // Zone indexed map of waypoint data arrays
	var RenderedWaypoints:Array; // Array of currently displayed waypoints for this layer
}

/// Notes:
//  A brief experiment with placing the ClearDisplay call within RenderWaypoints resulted in some very odd behaviour
//  There seem to be some definite timing issues involved with the creation and destruction of movie clips
