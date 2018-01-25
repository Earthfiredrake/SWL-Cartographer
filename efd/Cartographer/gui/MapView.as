// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.GameInterface.WaypointInterface;

import efd.Cartographer.lib.sys.config.ConfigWrapper;
import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.LayerData;

class efd.Cartographer.gui.MapView extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.MapView"; // For elT's clip helper library

	private function MapView() {
		// Indirect construction only
		// Requires following parameters passed via init object
		//   Height, Width: Viewport dimensions
		//   ZoneIndex: Zone index data
		//   LayerDataList: Waypoint data
		//   Config: Mod config record
		super();

		// Init data
		Config.SignalValueChanged.Connect(ConfigChanged, this);
		ClientChar = Character.GetClientCharacter();
		var targetZone:Number = ClientChar.GetPlayfieldID();
		if (!ZoneIndex[targetZone]) { targetZone = 5060; } // Player zone not mapped, reset to Agartha
		ZoomLevel = 0;

		// Init clipping mask
		var mask:MovieClip = createEmptyMovieClip("ViewportMask", getNextHighestDepth());
		mask.beginFill(0xFFFFFF);
		mask.lineTo(Width, 0);
		mask.lineTo(Width, Height);
		mask.lineTo(0, Height);
		mask.lineTo(0, 0);
		mask.endFill();
		setMask(mask);

		onMouseMove = ManageTooltips;

		// Init map layer
		createEmptyMovieClip("MapLayer", getNextHighestDepth());
		Loader = new MovieClipLoader();
		var listener:Object = new Object();
		listener.onLoadInit = Delegate.create(this, MapLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.ErrorMsg("Unable to load map: " + error);
		};
		Loader.addListener(listener);
		WaypointInterface.SignalPlayfieldChanged.Connect(PlayerZoneChanged, this);

		// Init notation layers
		NotationLayerViews = new Array();
		if (LayerDataList.length > MaxLayerCount) {
			Mod.ErrorMsg("Too many layers loaded");
		}
		for (var i:Number = LayerDataList.length -1; i >= 0; --i) {
			// In reverse so that the depths here match the order on the sidebar list
			var layer:LayerData = LayerDataList[i];
			NotationLayerViews[i] = new layer.LayerType(this, layer, layer.IsVisible);
			_NextAreaDepth++; // Increment the layer depth count
		}

		// Init top level elements (player marker)
		attachMovie("CartographerPlayerMarker", "ClientCharMarker", getNextHighestDepth());

		// Initialization finished, request map load
		ChangeMap(targetZone);
	}

	/// Notation layer construction callback
	// Valid types = "Zone", "Path", "Waypoint"
	public function NewLayer(type:String):MovieClip {
		var depth:Number = this["Next" + type + "Depth"];
		return createEmptyMovieClip(type + "Layer" + depth, depth);
	}

	/// Map manipulation
	private function ChangeMap(newZone:Number):Void {
		var charZone:Number = ClientChar.GetPlayfieldID();
		ClientCharMarker._visible = (charZone == newZone);
		CurrentZoneID = newZone;
		// TODO: See if I can source maps from the RDB in any way
		// Loader.loadClip("rdb:1000636:9247193", MapLayer); // English map for Museum
		// Loader.loadClip("rdb:1010013:" + CurrentZoneID, MapLayer); // In theory the right rdb index for a zone map, but doesn't load
		Loader.loadClip("Cartographer\\maps\\" + CurrentZoneID + ".png", MapLayer);
	}

	private function MapLoaded(target:MovieClip):Void {
		target.onMouseWheel = Delegate.create(target._parent, RescaleMap);
		target.onPress = Delegate.create(target._parent, StartScrollMap);
		var releaseHandler:Function = Delegate.create(target._parent, EndScrollMap);
		target.onRelease = releaseHandler;
		target.onReleaseOutside = releaseHandler;

		// Calculate the scale adjustment to contain the image in full at lowest zoom
		target._xscale = 100;
		target._yscale = 100;
		target._parent.MapImageScale = 100 * Math.min(1,
			Math.min(Width / target._width ,  Height / target._height));
		target._parent.RescaleMap(0); // Restore the previous zoom level
	}

	private function RescaleMap(delta:Number):Void {
		ZoomLevel = Math.min(MaxZoomLevel, Math.max(0, ZoomLevel + delta * 2));
		MapLayer._xscale = MapImageScale + ZoomLevel;
		MapLayer._yscale = MapImageScale + ZoomLevel;
		// Confirm that current position meets the constraints at the new zoom level
		UpdatePosition(new Point(MapLayer._x, MapLayer._y));
		// Update all the notation layers
		for (var i:Number = 0; i < NotationLayerViews.length; ++i) {
			NotationLayerViews[i].RenderLayer(CurrentZoneID);
		}
	}

	private function StartScrollMap():Void {
		PrevMousePos = new Point(_xmouse, _ymouse);
		onMouseMove = ScrollMap;
	}

	private function ScrollMap():Void {
		var diff:Point = new Point(_xmouse - PrevMousePos.x, _ymouse - PrevMousePos.y);
		PrevMousePos = new Point(_xmouse, _ymouse);
		UpdatePosition(new Point(MapLayer._x + diff.x, MapLayer._y + diff.y));
	}

	private function EndScrollMap():Void {
		onMouseMove = ManageTooltips;
	}

	private function UpdatePosition(targetPos:Point):Void {
		// Constrain the edges of the map to the viewport
		// Map can scroll only if it is wider/taller than the viewport (limits of 0 trump)
		// Max scroll value is 0; Min scroll value is viewport-map
		targetPos.x = Math.min(0, Math.max(Width - MapLayer._width, targetPos.x));
		targetPos.y = Math.min(0, Math.max(Height - MapLayer._height, targetPos.y));

		// Update the map and layer positions
		MapLayer._x = targetPos.x;
		MapLayer._y = targetPos.y;
		for (var i:Number = 0; i < NotationLayerViews.length; ++i) {
			NotationLayerViews[i].Position = targetPos;
		}
	}

	/// Event handlers
	private function onEnterFrame():Void {
		UpdateClientCharMarker();
	}

	private function UpdateClientCharMarker():Void {
		if (ClientCharMarker._visible) {
			var worldPos:Vector3 = ClientChar.GetPosition(0);
			var mapPos:Point = WorldToViewCoords(new Point(worldPos.x, worldPos.z));
			ClientCharMarker._x = mapPos.x;
			ClientCharMarker._y = mapPos.y;
			ClientCharMarker._rotation = RadToDegRotation(-ClientChar.GetRotation());
		}
	}

	private function PlayerZoneChanged(newZone:Number):Void {
		if (ClientCharMarker._visible) { // Player on previous map
			if (ZoneIndex[newZone]) { ChangeMap(newZone); }
			else { ClientCharMarker._visible = false; }
		} else {
			if (CurrentZoneID == newZone) { ClientCharMarker._visible = true; }
		}
	}

	private function ConfigChanged(setting:String, newValue) {
	    // TODO: This is needlessly redundant, can I work out a way of triggering on more specific settings
		// At the very least this can be done at the notation layer level, it should have access to the config somehow
		if (setting == "LayerSettings" || setting == undefined) {
			for (var i:Number = 0; i < LayerDataList.length; ++i) {
				NotationLayerViews[i].Visible = LayerDataList[i].IsVisible;
			}
		}
	}

	private function ManageTooltips() {
		var tooltipTargets:Array = new Array;
		var p:Point = new Point(_xmouse, _ymouse);
		localToGlobal(p);
		// Ignore all mouse movement outside the map viewport
		//   Will close any open tooltip when the mouse is out of bounds
		if (ViewportMask.hitTest(p.x, p.y)) {
			for (var i:Number = 0; i < NotationLayerViews.length; ++i) {
				if (NotationLayerViews[i].Visible) {
					tooltipTargets = tooltipTargets.concat(NotationLayerViews[i].GetNotationsAtPoint(p));
				}
			}
		}
		if (tooltipTargets.length > 0) {
			Mod.TraceMsg("Number of tooltip targets: " + tooltipTargets.length);
			for (var i:Number = 0; i < tooltipTargets.length; ++i) {
				Mod.TraceMsg("  " + tooltipTargets[i].Data.GetName());
			}
			// TODO: Create/Update tooltip
		} else {
			// TODO: Hide/Close tooltip
		}
	}

	/// Coordinate Conversions
	// Converts from world coordinates to a coordinate set based on the full map image size
	// Any layer which uses this should make sure to lock its origin point to the map's origin when scrolling
	public function WorldToMapCoords(worldCoords:Point):Point {
		return new Point(
			worldCoords.x * MapLayer._width / ZoneIndex[CurrentZoneID].worldX,
			MapLayer._height - (worldCoords.y * MapLayer._height / ZoneIndex[CurrentZoneID].worldY));
	}

	// Adjusts map coordinates to account for a scrolled map when rendering to the viewport
	// Used for objects which are positioned relative to the viewport
	public function MapToViewCoords(mapCoords:Point):Point {
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

	// General state
	private var ClientChar:Character;
	private var Config:ConfigWrapper;
	private var ZoneIndex:Object;
	private var CurrentZoneID:Number;

	// Zoom and scroll
	private var ZoomLevel:Number;
	private var PrevMousePos:Point;

	// Map layer
	private var MapLayer:MovieClip;
	private var Loader:MovieClipLoader;
	private var MapImageScale:Number;

	// Notation layers
	private var LayerDataList:Array;
	private var NotationLayerViews:Array;
	private var _NextAreaDepth:Number = 100;
	public function get NextAreaDepth() { return _NextAreaDepth; }
	public function get NextPathDepth() { return NextAreaDepth + MaxLayerCount; }
	public function get NextWaypointDepth() { return NextPathDepth + MaxLayerCount; }

	// Auxillary markings
	private var ClientCharMarker:MovieClip;
	// Tooltips should be attached at _parent level to avoid clipping

	// Clipping mask
	private var Width:Number;
	private var Height:Number;
	private var ViewportMask:MovieClip;

	// Constants
	private static var MaxZoomLevel:Number = 100;
	private static var MaxLayerCount:Number = 50;
}
