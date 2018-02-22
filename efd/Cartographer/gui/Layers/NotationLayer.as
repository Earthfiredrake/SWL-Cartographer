// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.LayerData;
import efd.Cartographer.gui.MapView;
import efd.Cartographer.gui.WaypointArea;
import efd.Cartographer.gui.WaypointPath;
import efd.Cartographer.gui.WaypointIcon;
import efd.Cartographer.inf.INotation;

// Implementation Plan:
// Each notation layer is actually three seperate movie clips, at significantly different depth levels (to permit interleaving of those layers)
// The lowest layer contains the zone or area markings
// The next layer contains the path and line markings
// The top layer contains the waypoint markings
// This is done so that area markings don't interfere significantly with waypoints on lower level layers

class efd.Cartographer.gui.Layers.NotationLayer {

	public function NotationLayer(mapView:MapView, data:LayerData, visible:Boolean) {
		super();
		MapViewClip = mapView;
		NotationData = data;

		if (data.HasAnyAreas) { AreaLayer = MapViewClip.NewLayer("Area"); }
		if (data.HasAnyPaths) { PathLayer = MapViewClip.NewLayer("Path"); }
		if (data.HasAnyWaypoints) { WaypointLayer = MapViewClip.NewLayer("Waypoint"); }

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
			if (Refresh) {
				// Map hasn't changed, so data list is correct, rendering positions may need updating
				RefreshAreas();
				RefreshPaths();
				RefreshWaypoints();
			} else {
				// Map has changed, so data list likely to be incorrect, do a full reassignment
				ReloadAreas();
				ReloadPaths()
				ReloadWaypoints();
				Refresh = true;
			}
		}
	}

	private function ReloadAreas():Void {
		for (var i:Number = 0; i < AreaLayer.RenderList.length; ++i) {
			AreaLayer.RenderList[i].removeMovieClip();
		}
		AreaLayer.RenderList = new Array();
		var areas:Array = NotationData.GetAreas(Zone);
		for (var i:Number = 0; i < areas.length; ++i) {
			AreaLayer.RenderList.push(MovieClipHelper.createMovieWithClass(
				WaypointArea, "WPA" + AreaLayer.getNextHighestDepth(), AreaLayer, AreaLayer.getNextHighestDepth(),
				{ Data : areas[i], MapViewLayer : this }));
		}
	}

	private function RefreshAreas():Void {
		for (var i:Number = 0; i < AreaLayer.RenderList.length; ++i) {
			AreaLayer.RenderList[i].Redraw();
		}
	}

	private function ReloadPaths():Void {
		for (var i:Number = 0; i < PathLayer.RenderList.length; ++i) {
			PathLayer.RenderList[i].removeMovieClip();
		}
		PathLayer.RenderList = new Array();
		var paths:Array = NotationData.GetPaths(Zone);
		for (var i:Number = 0; i < paths.length; ++i) {
			PathLayer.RenderList.push(MovieClipHelper.createMovieWithClass(
				WaypointPath, "WPP" + PathLayer.getNextHighestDepth(), PathLayer, PathLayer.getNextHighestDepth(),
				{ Data : paths[i], MapViewLayer : this }));
		}
	}

	private function RefreshPaths():Void {
		for (var i:Number = 0; i < PathLayer.RenderList.length; ++i) {
			PathLayer.RenderList[i].Redraw();
		}
	}

	private function ReloadWaypoints():Void { UpdateDisplayList(RenderedWaypoints, NotationData.GetWaypoints(Zone)); }

	private function RefreshWaypoints():Void {
		var waypointList:Array = RenderedWaypoints; // Cache this, some variants have to merge multiple lists for it
		for (var i:Number = 0; i < waypointList.length; ++i) {
			var wp:WaypointIcon = waypointList[i];
			wp.UpdatePosition(MapViewClip.WorldToMapCoords(wp.Data.GetPosition()));
		}
	}

	private function UpdateDisplayList(list:Array, data:Array, targetClip:MovieClip):Void {
		var i:Number = 0;
		for (; i < list.length; ++i) {
			if (i < data.length) {
				list[i].Reassign(data[i], MapViewClip.WorldToMapCoords(data[i].Position));
			} else {
				list[i].removeMovieClip();
			}
		}
		list.splice(data.length);
		for (; i < data.length; ++i) {
			var mapPos:Point = MapViewClip.WorldToMapCoords(data[i].Position);
			if (targetClip == undefined) { targetClip = WaypointLayer; }
			var depth:Number = targetClip.getNextHighestDepth();
			var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
				WaypointIcon, "WP" + depth, targetClip, depth,
				{ Data : data[i], _x : mapPos.x, _y : mapPos.y, MapViewLayer : this }));
			wp.SignalIconChanged.Connect(ChangeIcon, this);
			wp.LoadIcon();
			list.push(wp);
		}
	}

	// For icons that can change while map is open
	// TODO: It would shuffle the render order slightly... might be worth considering a bug
	private function ChangeIcon(icon:WaypointIcon):Void {
		var targetClip:MovieClip = WaypointLayer;
		var depth:Number = targetClip.getNextHighestDepth();
		var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
			WaypointIcon, "WP" + depth, targetClip, depth,
			{ Data : icon.Data, _x : icon._x, _y : icon._y, MapViewLayer : this }));
		wp.SignalIconChanged.Connect(ChangeIcon, this);
		wp.LoadIcon();
		RenderedWaypoints.push(wp);
		for (var i:Number = 0; i < RenderedWaypoints.length; ++i) {
			if (RenderedWaypoints[i] == icon) {
				RenderedWaypoints.splice(i, 1);
				break;
			}
		}
		icon.removeMovieClip();
	}

	/// Render effects
	public function GetPenColour(data:INotation):Number {
		var colour:Number = data.GetPenColour();
		return colour != undefined ? colour : NotationData.ConfigView.PenColour;
	}

	/// Tooltip helper tests
	public function GetNotationsAtPoint(p:Point):Array {
		var result:Array = new Array();
		var waypts:Array = RenderedWaypoints;
		for (var i:Number = 0; i < waypts.length; ++i) {
			if (waypts[i].hitTest(p.x, p.y, true)) {
				result.push(waypts[i]);
			}
		}
		for (var i:Number = 0; i < PathLayer.RenderList.length; ++i) {
			if (PathLayer.RenderList[i].hitTest(p.x, p.y, true)) {
				result.push(PathLayer.RenderList[i]);
			}
		}
		for (var i:Number = 0; i < AreaLayer.RenderList.length; ++i) {
			if (AreaLayer.RenderList[i].hitTest(p.x, p.y, true)) {
				result.push(AreaLayer.RenderList[i]);
			}
		}
		return result;
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

	public function get Visible():Boolean { return _visible; }

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
	private var _visible:Boolean;

	// External data caches
	public var NotationData:LayerData;
	public var MapViewClip:MapView; // The MapView, should be in charge of tooltips

	// Display layers
	private var AreaLayer:MovieClip;
	private var PathLayer:MovieClip;
	private var WaypointLayer:MovieClip;
	private var _RenderedWaypoints:Array;
}
