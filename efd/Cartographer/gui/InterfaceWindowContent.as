// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import com.Components.WindowComponentContent;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.GameInterface.WaypointInterface;

import efd.Cartographer.lib.ConfigWrapper;
import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.Waypoint;

import efd.Cartographer.gui.NotationLayer;
import efd.Cartographer.gui.LayerList;
import efd.Cartographer.gui.Layers.LoreLayer;
import efd.Cartographer.gui.WaypointIcon;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
		ClientChar = Character.GetClientCharacter();

		createEmptyMovieClip("MapLayer", getNextHighestDepth());
		Loader = new MovieClipLoader();
		var listener:Object = new Object();
		listener.onLoadInit = Delegate.create(this, MapLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.ErrorMsg("Unable to load map: " + error);
		};
		Loader.addListener(listener);

		NotationLayers = new Array();

		WaypointInterface.SignalPlayfieldChanged.Connect(onPlayfieldChanged, this);
	}

	private function SetData(zoneIndex:Object, waypoints:Array, config:ConfigWrapper):Void {
		ZoneIndex = zoneIndex;
		var targetZone:Number = ClientChar.GetPlayfieldID();
		if (!ZoneIndex[targetZone]) { targetZone = 5060; } // Current zone does not have map support, reset to Agartha

		Waypoints = waypoints;
		Config = config;
		Config.SignalValueChanged.Connect(ConfigChanged, this);

		LayerListDisplay.SetConfig(config);
		LayerListDisplay.AddLayers(Waypoints);

		for (var i:Number = Waypoints.length - 1; i >= 0; --i) {
			var layerName:String = Waypoints[i].Layer;
			var layerType:Function;
			switch (layerName) {
				case "Lore": { layerType = LoreLayer; break; }
				default: { layerType = NotationLayer; break; }
			}
			NotationLayers[i] = MovieClipHelper.createMovieWithClass(layerType, layerName + "Layer", this, getNextHighestDepth(), {WaypointData : Waypoints[i], Config : config.GetValue("LayerSettings")[layerName]});
		}

		PlayerMarker.swapDepths(getNextHighestDepth());
		ChangeMap(targetZone);
	}

	private function ChangeMap(newZone:Number):Void {
		var charZone:Number = ClientChar.GetPlayfieldID();
		if (charZone == CurrentZoneID) {
			PlayerMarker._visible = false;
		}
		if (charZone == newZone) {
			PlayerMarker._visible = true;
		}
		CurrentZoneID = newZone;
		// TODO: See if I can source maps from the RDB in any way
		//Loader.loadClip("rdb:1000636:9247193", MapLayer); // English map for Museum
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
	}

	private function onEnterFrame():Void {
		UpdateClientCharMarker();
	}

	private function UpdateClientCharMarker():Void {
		if (ClientChar.GetPlayfieldID() == CurrentZoneID) {
			var worldPos:Vector3 = ClientChar.GetPosition(0);
			var mapPos:Point = WorldToWindowCoords(new Point(worldPos.x, worldPos.z));
			PlayerMarker._x = mapPos.x;
			PlayerMarker._y = mapPos.y;
			PlayerMarker._rotation = RadToDegRotation(-ClientChar.GetRotation());
		}
	}

	private function onPlayfieldChanged(newZone:Number):Void {
		if (PlayerMarker._visible) { // Player was on the old map
			if (ZoneIndex[newZone]) { // Map exists for the new zone
				ChangeMap(newZone);
			} else { PlayerMarker._visible = false; }
		} else {
			if (newZone == CurrentZoneID) { // Player now on the current map
				PlayerMarker._visible = true;
			}
		}
	}

	private function ConfigChanged(setting:String, newValue) {
	    // TODO: This is needlessly redundant, can I work out a way of triggering on more specific settings
		if (setting == "LayerSettings" || setting == undefined) {
			for (var i:Number = 0; i < Waypoints.length; ++i) {
				NotationLayers[i]._visible = Waypoints[i].Settings.ShowLayer;
			}
		}
	}

	private function MapLoaded(target:MovieClip):Void {
		target._width = target._width / target._height * MaxMapHeight;
		target._height = MaxMapHeight;
		for (var i:Number = 0; i < NotationLayers.length; ++i) {
			NotationLayers[i].RenderWaypoints(CurrentZoneID);
		}
	}

	public function Close():Void {
		for (var i:Number = 0; i < NotationLayers.length; ++i) {
			NotationLayers[i].ClearDisplay();
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

	private var Config:ConfigWrapper;

	private var ZoneIndex:Object;
	private var CurrentZoneID:Number;

	private var LayerListDisplay:LayerList;
	private var MapLayer:MovieClip;
	private var NotationLayers:Array;
	private var Waypoints:Array;

	private var ClientChar:Character;

	/// GUI Elements
	private var Loader:MovieClipLoader;

	private var PlayerMarker:MovieClip;

	private static var MaxMapHeight:Number = 768;
}
