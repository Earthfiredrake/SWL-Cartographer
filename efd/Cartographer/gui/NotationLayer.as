// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.lib.etu.MovieClipHelper;

import efd.Cartographer.gui.WaypointIcon;
import efd.Cartographer.Waypoint;

// Implementation Plan:
// Each notation layer is actually three seperate movie clips, at significantly different depth levels (to permit interleaving of those layers)
// The lowest layer contains the zone or area markings
// The next layer contains the path and line markings
// The top layer contains the waypoint markings
// This is done so that area markings don't interfere significantly with waypoints on lower level layers

class efd.Cartographer.gui.NotationLayer extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.NotationLayer";

	private function NotationLayer() { // Indirect construction only
		super();
		_RenderedWaypoints = new Array();
		_visible = Config.ShowLayer;
	}

	public function RenderLayer(newZone:Number):Void {
		// Map hasn't changed, waypoints will still have right data, just need refreshing
		// If the map ever changes, refresh stays false until a full reload is started
		Refresh = Refresh && (Zone == newZone);
		Zone = newZone;
		if (_visible) {
			// Defer this if the layer has been hidden, for faster loading of visible layers
			if (Refresh) { RefreshPositions(); }
			else { ReloadAll(); }
		}
	}

	private function RefreshPositions() {
		var waypointList:Array = RenderedWaypoints; // Cache this, some variants have to merge multiple lists for it
		for (var i:Number = 0; i < waypointList.length; ++i) {
			var wp:WaypointIcon = waypointList[i];
			wp.UpdatePosition(_parent.WorldToMapCoords(wp.Data.Position));
		}
	}

	private function ReloadAll():Void {
		WaypointCount = 0;
		Refresh = true; // Unless they actually change maps, we only want one reload process to be running at a time
		TrimDisplayList(); // Trim excess waypoints
		LoadDataBlock(); // Start the loading process
	}

	public function TrimDisplayList():Void {
		var length:Number = WaypointData[Zone].length;
		for (var i:Number = length; i < RenderedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedWaypoints.splice(length);
	}

	public function LoadDataBlock():Void {
		var data:Array = WaypointData[Zone];
		var renderList:Array = RenderedWaypoints;
		// Attempt to reassign as many existing waypoints as possible
		// If an image needs loading, load will defer and resume through callback for stability reasons
		for (WaypointCount; WaypointCount < renderList.length; ++WaypointCount) {
			if (renderList[WaypointCount].Reassign(data[WaypointCount], _parent.WorldToMapCoords(data[WaypointCount].Position))) {
				// Image load requested exit early and wait for callback
				return;
			}
		}
		// Load any new waypoints required
		// Each of these will trigger an image load, so will be done sequentially through callback
		if (WaypointCount < data.length) {
			var mapPos:Point = _parent.WorldToMapCoords(data[WaypointCount].Position);
			var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
				WaypointIcon, "WP" + getNextHighestDepth(), this, getNextHighestDepth(),
				{ Data : data[WaypointCount], _x : mapPos.x, _y : mapPos.y, LayerClip : this }));
			wp.SignalWaypointLoaded.Connect(LoadNextBlock, this);
			wp.LoadIcon();
			renderList.push(wp);
		}
	}

	// Loader callback
	private function LoadNextBlock(icon:WaypointIcon):Void {
		WaypointCount += 1;
		LoadDataBlock();
	}

	/// Properties
	public function get RenderedWaypoints():Array {	return _RenderedWaypoints; }
	// Array of currently displayed waypoints for this layer

	public function set Visible(value:Boolean):Void {
		var prev:Boolean = _visible;
		_visible = value;
		if (value && !prev) {
			RenderLayer(Zone); // Do whatever redraw is needed
		}
	}

	/// Variables
	private var HostClip:MovieClip; // The movie clip that contains all the layers, on which tooltips will be placed
	private var Zone:Number;
	private var Refresh:Boolean;

	private var Config:Object;

	private var WaypointCount:Number; // Number of loaded waypoints, used exclusively during load, may not be valid
	private var WaypointData:Object; // Zone indexed map of waypoint data arrays
	private var _RenderedWaypoints:Array;
}
