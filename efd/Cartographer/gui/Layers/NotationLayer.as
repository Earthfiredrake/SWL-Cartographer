// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.IArea;

import efd.Cartographer.LayerData;
import efd.Cartographer.gui.WaypointIcon;

// Implementation Plan:
// Each notation layer is actually three seperate movie clips, at significantly different depth levels (to permit interleaving of those layers)
// The lowest layer contains the zone or area markings
// The next layer contains the path and line markings
// The top layer contains the waypoint markings
// This is done so that area markings don't interfere significantly with waypoints on lower level layers

class efd.Cartographer.gui.Layers.NotationLayer {

	public function NotationLayer(hostClip:MovieClip, data:LayerData, visible:Boolean) {
		super();
		HostClip = hostClip;
		NotationData = data;

		AreaLayer = HostClip.NewLayer("Area");
		PathLayer = HostClip.NewLayer("Path");
		WaypointLayer = HostClip.NewLayer("Waypoint");

		_RenderedWaypoints = new Array();
		_visible = visible;
		AreaLayer._visible = visible;
		PathLayer._visible = visible;
		WaypointLayer._visible = visible;
	}

	public function RenderLayer(newZone:Number):Void {
		// Map hasn't changed, waypoints will still have right data, just need refreshing
		// If the map ever changes, refresh stays false until a full reload is started
		Refresh = Refresh && (Zone == newZone);
		Zone = newZone;
		if (_visible) { // Defer for hidden layers, for faster loading of visible layers
			// NOTE: It may be possible to directly tie the Path layers scale to the Map layer scale
			//       Which may be useful to reduce redraws when changing scale
			RedrawAreas();
			RedrawPaths();
			if (Refresh) { RefreshWaypointPositions(); }
			else { ReloadAllWaypoints(); }
		}
	}

	private function RedrawAreas():Void {
		AreaLayer.clear();
		AreaLayer.lineStyle(2, 0x000000, 100, true, "none", "round", "round");
		var areas:Array = NotationData.GetAreas(Zone);
		for (var i:Number = 0; i < areas.length; ++i) {
			var points:Array = GenerateCircle(areas[i]);
			var start:Point = points[points.length -1];
			AreaLayer.beginFill(0x000000, 20);
			AreaLayer.moveTo(start.x, start.y);
			for (var p:Number = 0; p < points.length; p += 2) {
				AreaLayer.curveTo(points[p].x, points[p].y,
								  points[p+1].x, points[p+1].y);
			}
			AreaLayer.endFill();
		}
	}

	// Rough, lazy circle approximation
	private function GenerateCircle(data:IArea):Array {
		var result = new Array();
		var rad:Number = data.GetRadius();
		var ctr:Point = data.GetCentre();
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x - rad, ctr.y + rad)));
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x, ctr.y + rad)));
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x + rad, ctr.y + rad)));
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x + rad, ctr.y)));
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x + rad, ctr.y - rad)));
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x, ctr.y - rad)));
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x - rad, ctr.y - rad)));
		result.push(HostClip.WorldToMapCoords(new Point(ctr.x - rad, ctr.y)));
		return result;
	}

	private function RedrawPaths():Void {
		PathLayer.clear();
		PathLayer.lineStyle(5, 0x000000, 100, true, "none", "round", "round");
		var paths:Array = NotationData.GetPaths(Zone);
		for (var i:Number = 0; i < paths.length; ++i) {
			var points:Array = paths[i].GetPathPoints();
			var coords:Point = HostClip.WorldToMapCoords(points[0]);
			PathLayer.moveTo(coords.x, coords.y);
			for (var p:Number = 1; p < points.length; ++p) {
				coords = HostClip.WorldToMapCoords(points[p]);
				PathLayer.lineTo(coords.x, coords.y);
			}
		}
	}

	private function RefreshWaypointPositions():Void {
		var waypointList:Array = RenderedWaypoints; // Cache this, some variants have to merge multiple lists for it
		for (var i:Number = 0; i < waypointList.length; ++i) {
			var wp:WaypointIcon = waypointList[i];
			wp.UpdatePosition(HostClip.WorldToMapCoords(wp.Data.GetPosition()));
		}
	}

	private function ReloadAllWaypoints():Void {
		WaypointCount = 0;
		Refresh = true; // Unless they actually change maps, we only want one reload process to be running at a time
		TrimDisplayList(); // Trim excess waypoints
		LoadDataBlock(); // Start the loading process
	}

	private function TrimDisplayList():Void {
		var length:Number = NotationData.GetWaypoints(Zone).length;
		for (var i:Number = length; i < RenderedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedWaypoints.splice(length);
	}

	public function LoadDataBlock():Void {
		var data:Array = NotationData.GetWaypoints(Zone);
		var renderList:Array = RenderedWaypoints;
		// Attempt to reassign as many existing waypoints as possible
		// If an image needs loading, load will defer and resume through callback for stability reasons
		for (WaypointCount; WaypointCount < renderList.length; ++WaypointCount) {
			if (renderList[WaypointCount].Reassign(data[WaypointCount], HostClip.WorldToMapCoords(data[WaypointCount].Position))) {
				// Image load requested exit early and wait for callback
				return;
			}
		}
		// Load any new waypoints required
		// Each of these will trigger an image load, so will be done sequentially through callback
		if (WaypointCount < data.length) {
			var mapPos:Point = HostClip.WorldToMapCoords(data[WaypointCount].Position);
			var targetClip:MovieClip = WaypointLayer;
			var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
				WaypointIcon, "WP" + targetClip.getNextHighestDepth(), targetClip, targetClip.getNextHighestDepth(),
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
		AreaLayer._visible = value;
		PathLayer._visible = value;
		WaypointLayer._visible = value;
		if (value && !prev) {
			RenderLayer(Zone); // Do whatever redraw is needed
		}
	}

	public function set Position(pos:Point):Void {
		AreaLayer._x = pos.x;
		AreaLayer._y = pos.y;
		PathLayer._x = pos.x;
		PathLayer._y = pos.y;
		WaypointLayer._x = pos.x;
		WaypointLayer._y = pos.y;
	}

	/// Variables
	private var Zone:Number;
	private var Refresh:Boolean;
	private var WaypointCount:Number; // Number of loaded waypoints, used exclusively during load, may not be valid
	private var _visible:Boolean;

	// External data caches
	private var NotationData:LayerData;
	private var HostClip:MovieClip; // The movie clip that contains all the layers, on which tooltips will be placed

	// Display layers
	private var AreaLayer:MovieClip;
	private var PathLayer:MovieClip;
	private var WaypointLayer:MovieClip;
	private var _RenderedWaypoints:Array;
}
