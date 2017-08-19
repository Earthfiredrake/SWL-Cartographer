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
import efd.Cartographer.gui.Layers.LoreLayer;
import efd.Cartographer.gui.WaypointIcon;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
		ClientChar = Character.GetClientCharacter();
		CurrentZoneID = ClientChar.GetPlayfieldID();

		createEmptyMovieClip("MapLayer", getNextHighestDepth());
		Loader = new MovieClipLoader();
		var listener:Object = new Object();
		listener.onLoadInit = Delegate.create(this, MapLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.ErrorMsg("Unable to load map: " + error);
		};
		Loader.addListener(listener);

		NotationLayers = new Object();
	}

	private function MapLoaded(target:MovieClip):Void {
		target._width = target._width / target._height * MaxMapHeight;
		target._height = MaxMapHeight;
		for (var s:String in NotationLayers) {
			NotationLayers[s].RenderWaypoints(CurrentZoneID);
		}
		SignalSizeChanged.Emit();
	}

	private function ChangeMap(newZone:Number):Void {
		CurrentZoneID = newZone;
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
	}

	private function SetData(zoneIndex:Object, waypoints:Object):Void {
		ZoneIndex = zoneIndex;
		if (!ZoneIndex[CurrentZoneID]) { CurrentZoneID = 5060; } // Current zone does not have map support, reset to Agartha
		Waypoints = waypoints;
		for (var s:String in waypoints) {
			switch (s) {
				case "Lore":
					NotationLayers[s] = MovieClipHelper.createMovieWithClass(LoreLayer, s + "Layer", this, getNextHighestDepth(), {WaypointData : Waypoints[s]});
					break;
				default:
					NotationLayers[s] = MovieClipHelper.createMovieWithClass(NotationLayer, s + "Layer", this, getNextHighestDepth(), {WaypointData : Waypoints[s]});
					break;
			}
		}
		PlayerMarker.swapDepths(getNextHighestDepth());
		// TODO: See if I can source maps from the RDB in any way
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
		//Loader.loadClip("rdb:1000636:9247193", MapLayer); // English map for Museum
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

	public function Close():Void {
		for (var s:String in NotationLayers) {
			NotationLayers[s].ClearDisplay();
		}
		Loader.unloadClip(MapLayer);
		super.Close();
	}

	/// Conversion routines
	private function WorldToWindowCoords(worldCoords:Point):Point {
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
