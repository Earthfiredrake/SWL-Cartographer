// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

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
		CurrentMapDisplaySize = new Point(900, 900);
		CurrentMapWorldSize = new Point(1024, 1024);
		ClientChar = Character.GetClientCharacter();
		Waypoints = new Array();
		RenderedWaypoints = new Array();
	}

	public function SetWaypoints(waypoints:Array):Void {
		Mod.TraceMsg("Adding waypoint zones to list.");
		Waypoints = waypoints;
		RenderWaypoints();
	}

	private function RenderWaypoints():Void {
		var zone:Array = Waypoints[CurrentZoneID];
		Mod.TraceMsg("Rendering " + zone.length + " waypoints for current zone.");
		for (var i:Number = 0; i < zone.length; ++i) {
			var wp:Waypoint = zone[i];
			var mapPos:Point = WorldToWindowCoords(wp.Position);
			Mod.TraceMsg("Creating waypoint: " + wp.Name);
			Mod.TraceMsg("  @ " + mapPos.toString());
			var icon:MovieClip = MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + i, this, getNextHighestDepth(), {Data : wp, _x : mapPos.x, _y : mapPos.y});
			icon.swapDepths(PlayerMarker);
			RenderedWaypoints.push(icon);
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
	private var CurrentZoneID:Number = 3030; // Currently locked to KM
	private var CurrentMapDisplaySize:Point;
	private var CurrentMapWorldSize:Point;
	private var ClientChar:Character;

	private var Waypoints:Array;
	private var RenderedWaypoints:Array;

	/// GUI Elements
	private var PlayerMarker:MovieClip;
}
