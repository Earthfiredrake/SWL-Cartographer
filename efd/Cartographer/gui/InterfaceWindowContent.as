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
import efd.Cartographer.gui.Layers.ChampLayer;
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
				case "Champ": { layerType = ChampLayer; break; }
				case "Lore": { layerType = LoreLayer; break; }
				default: { layerType = NotationLayer; break; }
			}
			NotationLayers[i] = MovieClipHelper.createMovieWithClass(layerType, layerName + "Layer", this, getNextHighestDepth(), { WaypointData : Waypoints[i], Config : config.GetValue("LayerSettings")[layerName], HostClip : this });
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

		for (var i:Number = 0; i < NotationLayers.length; ++i) {
			if (NotationLayers[i].RefreshIncomplete) {
				NotationLayers[i].LoadSequential();
			}
		}
	}

	private function UpdateClientCharMarker():Void {
		if (ClientChar.GetPlayfieldID() == CurrentZoneID) {
			var worldPos:Vector3 = ClientChar.GetPosition(0);
			var mapPos:Point = WorldToViewCoords(new Point(worldPos.x, worldPos.z));
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
				NotationLayers[i].Visible = Waypoints[i].Settings.ShowLayer;
			}
		}
	}

	private function MapLoaded(target:MovieClip):Void {
		target.onMouseWheel = Delegate.create(target._parent, HandleMapScaling);
		target.onPress = Delegate.create(target._parent, HandleMapScrollStart);
		var releaseHandler:Function = Delegate.create(target._parent, HandleMapScrollEnd);
		target.onRelease = releaseHandler;
		target.onReleaseOutside = releaseHandler;

		// Return the image to its natural size and calculate if it needs to be scaled down at "default" size
		target._xscale = 100;
		target._yscale = 100;
		target._parent.MapImageScale = Math.min(1, MaxMapHeight / target._height) * 100;
		// Restore the proper zoom level
		target._parent.HandleMapScaling(0); // Need
	}

	private function HandleMapScaling(delta:Number):Void {
		ZoomLevel = Math.min(100, Math.max(0, ZoomLevel + delta * 2));
		MapLayer._xscale = MapImageScale + ZoomLevel;
		MapLayer._yscale = MapImageScale + ZoomLevel;
		// Confirm that current position meets the constraints at the new zoom level
		UpdatePosition(new Point(MapLayer._x, MapLayer._y));
		// Update all the waypoints
		RefreshLayers();
	}

	private function HandleMapScrollStart():Void {
		PrevMousePos = new Point(_xmouse, _ymouse);

		onMouseMove = HandleMapScroll;
	}

	private function HandleMapScroll():Void {
		var diff:Point = new Point(_xmouse - PrevMousePos.x, _ymouse - PrevMousePos.y);
		PrevMousePos = new Point(_xmouse, _ymouse);
		UpdatePosition(new Point(MapLayer._x + diff.x, MapLayer._y + diff.y));
	}

	private function UpdatePosition(targetPos:Point):Void {
		// Constrain the edges of the map to the viewport
		// Map can scroll only if it is wider/taller than the viewport (limits of 0 trump)
		// Max scroll value is 0; Min scroll value is viewport-map
		// TEMP: Likely to be replaced by an actual viewport/clipping frame
		var viewportHeight = MaxMapHeight;
		var viewportWidth = MaxMapHeight;
		targetPos.x = Math.min(0, Math.max(viewportWidth - MapLayer._width, targetPos.x));
		targetPos.y = Math.min(0, Math.max(viewportHeight - MapLayer._height, targetPos.y));

		// Update the map and layer positions
		MapLayer._x = targetPos.x;
		MapLayer._y = targetPos.y;
		for (var i:Number = 0; i < NotationLayers.length; ++i) {
			NotationLayers[i]._x = targetPos.x;
			NotationLayers[i]._y = targetPos.y;
		}
	}

	private function HandleMapScrollEnd():Void {
		onMouseMove = undefined;
	}

	private function RefreshLayers():Void {
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
	// Converts from world coordinates to a coordinate set based on the full map image size
	// Any layer which uses this should make sure to lock its origin point to the map's origin when scrolling
	private function WorldToMapCoords(worldCoords:Point):Point {
		return new Point(
			worldCoords.x * MapLayer._width / ZoneIndex[CurrentZoneID].worldX,
			MapLayer._height - (worldCoords.y * MapLayer._height / ZoneIndex[CurrentZoneID].worldY));
	}

	// Adjusts map coordinates to account for a scrolled map when rendering to the viewport
	// Used for objects which are positioned relative to the viewport
	private function MapToViewCoords(mapCoords:Point):Point {
		return new Point(mapCoords.x + MapLayer._x, mapCoords.y + MapLayer._y);
	}

	// Converts from world coordinates to ones relative to the viewport
	private function WorldToViewCoords(worldCoords:Point):Point {
		return MapToViewCoords(WorldToMapCoords(worldCoords));
	}

	private function MapToWorldCoords(mapCoords:Point):Point {
		return new Point(
			mapCoords.x * ZoneIndex[CurrentZoneID].worldX / MapLayer._width ,
			(MapLayer._height - mapCoords.y) * ZoneIndex[CurrentZoneID].worldY / MapLayer._height);
	}

	private static function RadToDegRotation(radians:Number):Number {
		return radians * 180 / Math.PI;
	}

	private var Config:ConfigWrapper;

	private var ZoneIndex:Object;
	private var CurrentZoneID:Number;

	private var MapImageScale:Number;
	private var ZoomLevel:Number = 0;
	private var PrevMousePos:Point;

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
