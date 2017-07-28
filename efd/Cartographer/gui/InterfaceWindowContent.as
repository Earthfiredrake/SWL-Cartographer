// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import com.Components.WindowComponentContent;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;

import efd.Cartographer.lib.etu.MovieClipHelper
import efd.Cartographer.lib.Mod;
import efd.Cartographer.Waypoint;
import efd.Cartographer.gui.WaypointIcon;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
		CurrentZoneID = 3030;
		CurrentMapDisplaySize = new Point(768, 768);
		CurrentMapWorldSize = new Point(1024, 1024);
		ClientChar = Character.GetClientCharacter();
		Waypoints = new Array();
		RenderedWaypoints = new Array();

		MapLayer = createEmptyMovieClip("MapLayer", getNextHighestDepth());
		MapLayer.swapDepths(PlayerMarker);
		Loader = new MovieClipLoader();
		var listener:Object = new Object();
		listener.onLoadComplete = Delegate.create(this, MapLoaded);
		Loader.addListener(listener);
		// This should defer until after the waypoints are actually loaded
		// If bugs crop up where waypoints are failing to load properly, re-evaluate this
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
	}

	private function MapLoaded(target:MovieClip):Void {
		target._height = CurrentMapDisplaySize.y;
		target._width = CurrentMapDisplaySize.x;
		SignalSizeChanged.Emit();
		RenderWaypoints();
	}

	private function ChangeMap(newZone:Number):Void {
		ClearWaypoints();
		Loader.unloadClip(MapLayer);
		CurrentZoneID = newZone;
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
	}

	private function SetWaypoints(waypoints:Array):Void {
		Waypoints = waypoints;
	}

	private function RenderWaypoints():Void {
		var zone:Array = Waypoints[CurrentZoneID];
		Mod.TraceMsg("Rendering " + zone.length + " waypoints for current zone.");
		for (var i:Number = 0; i < zone.length; ++i) {
			var data:Waypoint = zone[i];
			var mapPos:Point = WorldToWindowCoords(data.Position);
			var waypoint:MovieClip = MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + i, this, getNextHighestDepth(), {Data : data, _x : mapPos.x, _y : mapPos.y});
			RenderedWaypoints.push(waypoint);
		}
		RenderedWaypoints[RenderedWaypoints.length-1].swapDepths(PlayerMarker); // TEMP HACK
	}

	private function ClearWaypoints():Void {
		RenderedWaypoints[RenderedWaypoints.length - 1].swapDepths(PlayerMarker); // TEMP HACK
		for (var i:Number = 0; i < RenderedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
	}

	private function onEnterFrame():Void {
		UpdateClientCharMarker();
	}

	private function UpdateClientCharMarker():Void {
		if (ClientChar.GetPlayfieldID() == CurrentZoneID) {
			PlayerMarker._visible = true;
			var worldPos:Vector3 = ClientChar.GetPosition(0);
			var mapPos:Point = WorldToWindowCoords(new Point(worldPos.x, worldPos.z));
			PlayerMarker._x = mapPos.x;
			PlayerMarker._y = mapPos.y;
			PlayerMarker._rotation = RadToDegRotation(-ClientChar.GetRotation());
		} else {
			PlayerMarker._visible = false;
		}
	}

	/// Conversion routines
	private function WorldToWindowCoords(worldCoords:Point):Point {
		return new Point(
			worldCoords.x * CurrentMapDisplaySize.x / CurrentMapWorldSize.x,
			CurrentMapDisplaySize.y - (worldCoords.y * CurrentMapDisplaySize.y / CurrentMapWorldSize.y));
	}

	private function WindowToWorldCoords(windowCoords:Point):Point {
		return new Point(
			windowCoords.x * CurrentMapWorldSize.x / CurrentMapDisplaySize.x ,
			(CurrentMapDisplaySize.y - windowCoords.y) * CurrentMapWorldSize.y / CurrentMapDisplaySize.y);
	}

	private static function RadToDegRotation(radians:Number):Number {
		return radians * 180 / Math.PI;
	}

	/// TODO: Data outsourcing
	private var CurrentZoneID:Number;
	private var CurrentMapDisplaySize:Point;
	private var CurrentMapWorldSize:Point;
	private var ClientChar:Character;

	private var Waypoints:Array;
	private var RenderedWaypoints:Array;

	/// GUI Elements
	private var Loader:MovieClipLoader;

	private var MapLayer:MovieClip;
	private var PlayerMarker:MovieClip;
}
