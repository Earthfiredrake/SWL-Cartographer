// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;
import com.GameInterface.WaypointInterface;

import efd.Cartographer.lib.DebugUtils;
import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.sys.config.ConfigWrapper;

import efd.Cartographer.gui.InterfaceWindowContent;
import efd.Cartographer.LayerData;

class efd.Cartographer.gui.MapView extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.MapView"; // For elT's clip helper library

	private function MapView() {
		// Indirect construction only
		// Requires following parameters passed via init object
		//   ZoneIndex: Zone index data
		//   LayerDataList: Waypoint data
		//   Config: Mod config record
		// A call to ResizeViewport should follow construction promptly
		super();

		// Init data
		Config.SignalValueChanged.Connect(ConfigChanged, this);
		ClientChar = Character.GetClientCharacter();
		var targetZone:Number = ClientChar.GetPlayfieldID();
		if (!ZoneIndex[targetZone]) { targetZone = 5060; } // Player zone not mapped, reset to Agartha
		ZoomLevel = 0;

		// Init clipping mask
		var mask:MovieClip = createEmptyMovieClip("ViewportMask", getNextHighestDepth());
		setMask(mask);

		onMouseMove = ManageTooltips;

		// Init map layer
		createEmptyMovieClip("MapLayer", getNextHighestDepth());
		Loader = new MovieClipLoader();
		var listener:Object = new Object();
		listener.onLoadInit = Delegate.create(this, MapLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			DebugUtils.ErrorMsgS("Unable to load map: " + error);
		};
		Loader.addListener(listener);
		WaypointInterface.SignalPlayfieldChanged.Connect(PlayerZoneChanged, this);

		// Init notation layers
		NotationLayerViews = new Array();
		if (LayerDataList.length > MaxLayerCount) {
			DebugUtils.ErrorMsgS("Too many layers loaded");
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
		if (!ZoneIndex[newZone]) return; // No map to load
		newZone = ZoneIndex[newZone].masterZone || newZone;
		ClientCharMarker._visible = IsPlayerOnMap(newZone);
		PrevZoneID = CurrentZoneID;
		CurrentZoneID = newZone;
		// TODO: See if I can source maps from the RDB in any way
		// Loader.loadClip("rdb:1000636:9247193", MapLayer); // English map for Museum
		// Loader.loadClip("rdb:1010013:" + CurrentZoneID, MapLayer); // In theory the right rdb index for a zone map, but doesn't load
		Loader.loadClip("Cartographer\\maps\\" + ZoneIndex[newZone].mapID + ".png", MapLayer);
	}

	private function MapLoaded(target:MovieClip):Void {
		target.onPress = Delegate.create(this, StartScrollMap);
		var releaseHandler:Function = Delegate.create(this, EndScrollMap);
		target.onRelease = releaseHandler;
		target.onReleaseOutside = releaseHandler;

		// Calculate the scale adjustment to contain the image in full at lowest zoom
		target._xscale = 100;
		target._yscale = 100;
		MapImageScale = 100 * Math.min(1,
			Math.min(InterfaceWindowContent.ViewportWidth / target._width, InterfaceWindowContent.ViewportHeight / target._height));
		RescaleMap(ZoomLevel); // Restore the previous zoom level
		FocusOnTransit();
	}

	private function onMouseWheel(delta:Number):Void {
	 	var mouseCoords:Point = new Point(_xmouse, _ymouse);
		var targetCoords:Point = ViewToWorldCoords(mouseCoords);
		RescaleMap(ZoomLevel + delta * 2);
		targetCoords = ViewToMapCoords(mouseCoords).subtract(WorldToMapCoords(targetCoords));
		targetCoords.x += MapLayer._x;
		targetCoords.y += MapLayer._y;
		UpdatePosition(targetCoords);
	}

	private function RescaleMap(zoomLevel:Number):Void {
		ZoomLevel = Math.min(MaxZoomLevel, Math.max(MinZoomLevel, zoomLevel));
		MapLayer._xscale = MapImageScale + ZoomLevel;
		MapLayer._yscale = MapImageScale + ZoomLevel;

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

	private function EndScrollMap():Void { onMouseMove = ManageTooltips; }

	// TargetPos is offset for top left corner in map/image coordinates
	// Values are clamped between 0 and a negative value that matches the lower right corners of the image and the viewport
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

	// Try to place the point in the center of the view
	// targetPos is point to place as close to the middle of the view as possible in map/image coordinates
	private function AttemptCenterView(targetPos:Point):Void { UpdatePosition(new Point(Width / 2 - targetPos.x, Height / 2 - targetPos.y)); }

	private function FocusOnTransit():Void {
		if (PrevZoneID) {
			for (var i:Number = 0; i < LayerDataList.length; ++i) {
				if (LayerDataList[i].Layer != "Transit") { continue; }
				var transitPoints:Array = LayerDataList[i].NotationsByZone[CurrentZoneID].Waypoints;
				for (var j:Number = 0; j < transitPoints.length; ++j) {
					if (transitPoints[j].TargetZone == PrevZoneID) { AttemptCenterView(WorldToMapCoords(transitPoints[j].Position)); }
				}
				break;
			}
		}
		UpdatePosition(new Point(MapLayer._x, MapLayer._y));
	}

	private function IsPlayerOnMap(zoneID:Number):Boolean {
		var playerZone:Number = ClientChar.GetPlayfieldID();
		if (playerZone == zoneID) { return true; }
		var mergeZones:Array = ZoneIndex[zoneID].mergeZones;
		for (var i:Number = 0; i < mergeZones.length; ++i) {
			if (playerZone == mergeZones[i]) { return true; }
		}
		return false;
	}

/// Window manipulation
	public function ResizeViewport(width:Number, height:Number, miniMode:Boolean):Void {
		// Concept here is that if the window is resized the map should:
		//   Pan back into view if it is being enlarged
		//   Scale to fill unless it was set at an odd scale
		// While this works, it's a little bit fudgy, and prone to not locking in correctly

		UpdatePosition(new Point(MapLayer._x + (width > Width ? width - Width : 0),
								 MapLayer._y + (height > Height ? height - Height : 0)));
		// Map and view widths are unlikely to be exact, so going with "close enough" to trigger this
		var scaleWidth:Number = (Math.abs(MapLayer._width - Width) < 5) ? width : 0;
		var scaleHeight:Number = (Math.abs(MapLayer._height - Height) < 5) ? height : 0;
		scaleWidth /= MapLayer._width / MapLayer._xscale;
		scaleHeight /= MapLayer._height / MapLayer._yscale;
		var targetScale:Number = Math.max(scaleWidth, scaleHeight);

		Width = width;
		Height = height;
		MinimapMode = miniMode;

		ViewportMask.clear();
		ViewportMask.beginFill(0xFFFFFF);
		ViewportMask.lineTo(Width, 0);
		ViewportMask.lineTo(Width, Height);
		ViewportMask.lineTo(0, Height);
		ViewportMask.lineTo(0, 0);
		ViewportMask.endFill();

		if (targetScale > 0) { RescaleMap(targetScale - MapImageScale); }
	}

	public function GetViewportSize():Point { return new Point(Width, Height); }

/// Event handlers
	private function onEnterFrame():Void { UpdateClientCharMarker(); }

	private function UpdateClientCharMarker():Void {
		if (IsPlayerOnMap(CurrentZoneID)) {
			var worldPos:Vector3 = ClientChar.GetPosition(0);
			var mapPos:Point = WorldToViewCoords(new Point(worldPos.x, worldPos.z));
			ClientCharMarker._x = mapPos.x;
			ClientCharMarker._y = mapPos.y;
			ClientCharMarker._rotation = RadToDegRotation(-ClientChar.GetRotation());
			if (MinimapMode) { AttemptCenterView(ViewToMapCoords(mapPos)); }
		}
	}

	private function PlayerZoneChanged(newZone:Number):Void {
		if (ClientChar.GetPlayfieldID() == 0) {
			setTimeout(Delegate.create(this, PlayerZoneChanged), 1000, newZone);
			return;
		}

		if (ClientCharMarker._visible) { // Player on previous map
			if (ZoneIndex[newZone]) { ChangeMap(newZone); }
			else { ClientCharMarker._visible = false; }
		} else {
			if (IsPlayerOnMap(CurrentZoneID)) { ClientCharMarker._visible = true; }
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
			// DebugUtils.TraceMsgS("Number of tooltip targets: " + tooltipTargets.length);
			for (var i:Number = 0; i < tooltipTargets.length; ++i) {
				// DebugUtils.TraceMsgS("  " + tooltipTargets[i].Data.GetName());
			}
			// TODO: Create/Update tooltip
		} else {
			// TODO: Hide/Close tooltip
		}
	}

/// Coordinate Conversions
	// World Coordinates: Based on game world locations used for game data and UI invariant coordinates
	// Image Coordinates: Based on map image at current scale
	// View Coordinates: Based on viewport, with current map scale and panning offsets
	// Converts from world coordinates to a coordinate set based on the full map image size
	// Any layer which uses this should make sure to lock its origin point to the map's origin when scrolling
	public function WorldToMapCoords(worldCoords:Point):Point {
		return new Point(
			worldCoords.x * MapLayer._width / ZoneIndex[CurrentZoneID].worldX,
			MapLayer._height - (worldCoords.y * MapLayer._height / ZoneIndex[CurrentZoneID].worldY));
	}

	// Adjusts map coordinates to account for a scrolled map when rendering to the viewport
	// Used for objects which are positioned relative to the viewport
	public function MapToViewCoords(mapCoords:Point):Point { return new Point(mapCoords.x + MapLayer._x, mapCoords.y + MapLayer._y); }
	private function ViewToMapCoords(viewCoords:Point):Point { return new Point(viewCoords.x - MapLayer._x, viewCoords.y - MapLayer._y); }

	// Converts from world coordinates to ones relative to the viewport
	private function WorldToViewCoords(worldCoords:Point):Point { return MapToViewCoords(WorldToMapCoords(worldCoords)); }
	private function ViewToWorldCoords(viewCoords:Point):Point { return MapToWorldCoords(ViewToMapCoords(viewCoords)); }

	private function MapToWorldCoords(mapCoords:Point):Point {
		return new Point(
			mapCoords.x * ZoneIndex[CurrentZoneID].worldX / MapLayer._width ,
			(MapLayer._height - mapCoords.y) * ZoneIndex[CurrentZoneID].worldY / MapLayer._height);
	}


	private static function RadToDegRotation(radians:Number):Number { return radians * 180 / Math.PI; }

	// General state
	private var ClientChar:Character;
	private var Config:ConfigWrapper;
	private var ZoneIndex:Object;
	private var CurrentZoneID:Number;
	private var PrevZoneID:Number;
	private var MinimapMode:Boolean; // Partial minimap behaviour, currently locks view centered on player icon

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
	private static var MinZoomLevel:Number = -20;
	private static var MaxZoomLevel:Number = 100;
	private static var MaxLayerCount:Number = 50;
}
