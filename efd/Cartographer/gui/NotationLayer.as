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
		_RenderedWaypoints = new Array();
		_visible = Config.ShowLayer;
	}

	public function RenderWaypoints(newZone:Number):Void {
		WaypointCount = -1;
		// Map hasn't changed, waypoints will still have right data, just need refreshing
		// If the map ever changes, refresh stays false until a full reload is completed
		Refresh = Refresh && (Zone == newZone);
		Zone = newZone;
		if (_visible) {
			// Defer this if the layer has been hidden, for faster loading of visible layers
			LoadSequential();
		}
	}

	public function LoadSequential():Void {
		WaypointCount += 1;
		var waypoints:Array = WaypointData[Zone];
		if (WaypointCount < waypoints.length) {
			AttachWaypoint(waypoints[WaypointCount], _parent.WorldToMapCoords(waypoints[WaypointCount].Position));
		} else {
			ClearDisplay(waypoints.length);
			Refresh = true;
		}
	}

	private function AttachWaypoint(data:Waypoint, mapPos:Point):Void {
		if (RenderedWaypoints[WaypointCount]) {
			if (Refresh) {
				RenderedWaypoints[WaypointCount].UpdatePosition(mapPos);
				LoadSequential(); // We better be able to barrel through basic updates
			} else { RenderedWaypoints[WaypointCount].Reassign(data, mapPos); }
		} else {
			var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + getNextHighestDepth(), this, getNextHighestDepth(), { Data : data, _x : mapPos.x, _y : mapPos.y, LayerClip: this}));
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
	private var HostClip:MovieClip; // The movie clip that contains all the layers, on which tooltips will be placed
	private var Zone:Number;
	private var Refresh:Boolean;

	private var Config:Object;

	private var WaypointCount:Number;
	private var WaypointData:Object; // Zone indexed map of waypoint data arrays
	private var _RenderedWaypoints:Array;
	public function get RenderedWaypoints():Array {	return _RenderedWaypoints; }
	// Array of currently displayed waypoints for this layer

	public function get RefreshIncomplete():Boolean {
		// Adding a check of Refresh here prevents it from trying to hijack the initial zone load
		// However letting the hijack occur seems to significantly decrease load times
		// Have not noticed any instability as a result, but will monitor
		return _visible && WaypointCount < WaypointData[Zone].length;
	}

	public function set Visible(value:Boolean):Void {
		if (value && !_visible) {
			LoadSequential(); // Refresh the waypoints, as they may be out of date
			// RenderWaypoints(Zone); Do I need to force a hard refresh of the full layer?
		}
		_visible = value;
	}

	// TODO: Consider doing some sorting of waypoints based on icon, in an effort to minimize reloads
}

/// Notes:
//  A brief experiment with placing the ClearDisplay call within RenderWaypoints resulted in some very odd behaviour
//  There seem to be some definite timing issues involved with the creation and destruction of movie clips
