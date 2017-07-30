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
		Mod.LogMsg("Interface Window Content Constructor");
		CurrentZoneID = 3030;
		ClientChar = Character.GetClientCharacter();
		RenderedWaypoints = new Array();

		MapLayer = createEmptyMovieClip("MapLayer", getNextHighestDepth());
		MapLayer.swapDepths(PlayerMarker);
		Loader = new MovieClipLoader();
		var listener:Object = new Object();
		listener.onLoadComplete = Delegate.create(this, MapLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.LogMsg("Map failed to load: " + error);
			Mod.ErrorMsg("Unable to load map: " + error);
		};
		Loader.addListener(listener);
		// This should defer until after the waypoints and zone index are available
		// If bugs crop up where waypoints are failing to load properly, consider moving this
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
		Mod.LogMsg("Interface Window Content Constructor Complete");
	}

	private function MapLoaded(target:MovieClip):Void {
		Mod.LogMsg("Map Loaded");
		if (!target._height) {
			Mod.LogMsg("Map loaded, but failed to update height: DivZero");
		}
		target._width = target._width / target._height * MaxMapHeight;
		target._height = MaxMapHeight;
		SignalSizeChanged.Emit();
		RenderWaypoints();
		Mod.LogMsg("Map Load Complete");
	}

	private function ChangeMap(newZone:Number):Void {
		Mod.LogMsg("Changing Map:" + newZone);
		ClearWaypoints();
		Loader.unloadClip(MapLayer);
		CurrentZoneID = newZone;
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
		Mod.LogMsg("Map Change Complete");
	}

	private function SetData(zoneIndex:Object, waypoints:Object):Void {
		ZoneIndex = zoneIndex;
		Waypoints = waypoints;
	}

	private function RenderWaypoints():Void {
		Mod.LogMsg("RenderWP");
		var zone:Array = Waypoints[CurrentZoneID];
		Mod.TraceMsg("Rendering " + zone.length + " waypoints for current zone.");
		for (var i:Number = 0; i < zone.length; ++i) {
			var data:Waypoint = zone[i];
			var mapPos:Point = WorldToWindowCoords(data.Position);
			var waypoint:MovieClip = MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + i, this, getNextHighestDepth(), {Data : data, _x : mapPos.x, _y : mapPos.y});
			RenderedWaypoints.push(waypoint);
		}
		RenderedWaypoints[RenderedWaypoints.length-1].swapDepths(PlayerMarker); // TEMP HACK
		Mod.LogMsg("RenderWP End");
	}

	private function ClearWaypoints():Void {
		Mod.LogMsg("Clearing");
		RenderedWaypoints[RenderedWaypoints.length - 1].swapDepths(PlayerMarker); // TEMP HACK
		for (var i:Number = 0; i < RenderedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		Mod.LogMsg("Cleared");
	}

	private function onEnterFrame():Void {
		Mod.LogMsg("Frame Entered");
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

	public function Close():Void {
		Mod.LogMsg("Closing");
		ClearWaypoints();
		Loader.unloadClip(MapLayer);
		super();
	}

	/// Conversion routines
	private function WorldToWindowCoords(worldCoords:Point):Point {
		Mod.LogMsg("Converting point (world x/y is: " +  ZoneIndex[CurrentZoneID].worldX + "/" + ZoneIndex[CurrentZoneID].worldY);
		return new Point(
			worldCoords.x * MapLayer._width / ZoneIndex[CurrentZoneID].worldX,
			MapLayer._height - (worldCoords.y * MapLayer._height / ZoneIndex[CurrentZoneID].worldY));
	}

	private function WindowToWorldCoords(windowCoords:Point):Point {
		return new Point(
			windowCoords.x * ZoneIndex[CurrentZoneID].worldX / MapLayer._width ,
			(MapLayer._height - windowCoords.y) * ZoneIndex[CurrentZoneID].worldY / MapLayer._height);
	}

	private static function RadToDegRotation(radians:Number):Number {
		return radians * 180 / Math.PI;
	}

	private var ZoneIndex:Object;
	private var CurrentZoneID:Number;

	private var Waypoints:Object;
	private var RenderedWaypoints:Array;

	private var ClientChar:Character;

	/// GUI Elements
	private var Loader:MovieClipLoader;

	private var MapLayer:MovieClip;
	private var PlayerMarker:MovieClip;

	private static var MaxMapHeight:Number = 768;
}
