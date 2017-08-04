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

import efd.Cartographer.gui.NotationLayer;
import efd.Cartographer.gui.WaypointIcon;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
		Mod.LogMsg("Interface Window Content Constructor");
		CurrentZoneID = 3030;
		ClientChar = Character.GetClientCharacter();

		createEmptyMovieClip("MapLayer", getNextHighestDepth());
		Loader = new MovieClipLoader();
		var listener:Object = new Object();
		listener.onLoadInit = Delegate.create(this, MapLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.LogMsg("Map failed to load: " + error);
			Mod.ErrorMsg("Unable to load map: " + error);
		};
		Loader.addListener(listener);

		NotationLayers = new Object();

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
		for (var s:String in NotationLayers) {
			NotationLayers[s].RenderWaypoints(CurrentZoneID);
		}
		Mod.LogMsg("Map Load Complete");
	}

	private function ChangeMap(newZone:Number):Void {
		Mod.LogMsg("Changing Map:" + newZone);
		Loader.unloadClip(MapLayer);
		CurrentZoneID = newZone;
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
		Mod.LogMsg("Map Change Complete");
	}

	private function SetData(zoneIndex:Object, waypoints:Object):Void {
		ZoneIndex = zoneIndex;
		Waypoints = waypoints;
		for (var s:String in waypoints) {
			NotationLayers[s] = NotationLayer(MovieClipHelper.createMovieWithClass(NotationLayer, s + "Layer", this, getNextHighestDepth(), {WaypointData : Waypoints[s]}));
		}
		PlayerMarker.swapDepths(getNextHighestDepth());
		// TODO: See if I can source maps from the RDB in any way
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
		//Loader.loadClip("rdb:1000636:9247193", MapLayer); // English map for Museum
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
		for (var s:String in NotationLayers) {
			NotationLayers[s].ClearDisplay();
		}
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

	private var MapLayer:MovieClip;
	private var NotationLayers:Object;
	private var Waypoints:Object;

	private var ClientChar:Character;

	/// GUI Elements
	private var Loader:MovieClipLoader;

	private var PlayerMarker:MovieClip;

	private static var MaxMapHeight:Number = 768;
}
