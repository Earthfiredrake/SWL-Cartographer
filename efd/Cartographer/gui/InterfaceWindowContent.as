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
		CurrentMapDisplaySize = new Point(900, 900);
		CurrentMapWorldSize = new Point(1024, 1024);
		ClientChar = Character.GetClientCharacter();
		Waypoints = new Array();
		DefaultWaypointFile = new XML();
		DefaultWaypointFile.ignoreWhite = true;
		DefaultWaypointFile.onLoad = Delegate.create(this, WaypointsLoaded);
		DefaultWaypointFile.load("Cartographer\\waypoints\\BasePack.xml");
	}

	private function WaypointsLoaded(success:Boolean):Void {
		if (success) {
			Mod.TraceMsg("Waypoints loaded");
			var xmlRoot:XMLNode = DefaultWaypointFile.firstChild;
			var zone:XMLNode = xmlRoot.firstChild;			
			for (var i:Number = 0; i < zone.childNodes.length; ++i) {
				var category:XMLNode = zone.childNodes[i];
				for (var j:Number = 0; j < category.childNodes.length; ++j) {
					var data:Waypoint = new Waypoint(category.childNodes[j]);
					var mapPos:Point = WorldToWindowCoords(data.Position);
					var icon:MovieClip = MovieClipHelper.createMovieWithClass(WaypointIcon, category.attributes.type + j, this, getNextHighestDepth(), {Data : data, IconFilename : category.attributes.icon, _x : mapPos.x, _y : mapPos.y});
					icon.swapDepths(PlayerMarker); //HACK: A slow way of pushing the player marker to the top, will re-evaluate once actual layers are being implemented
					Waypoints.push({Data: data, Icon: icon});
				}
			}
		} else {
			Mod.ErrorMsg("Could not load default waypoint file");
		}
	}

	private function onEnterFrame():Void {
		UpdateClientCharMarker();
	}

	private function UpdateClientCharMarker():Void {
		if (ClientChar.GetPlayfieldID() == CurrentMapID) {
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

	private function RadToDegRotation(radians:Number):Number {
		return radians * 180 / Math.PI;
	}

	/// TODO: Data outsourcing
	private var CurrentMapID:Number = 3030; // Currently locked to KM
	private var CurrentMapDisplaySize:Point;
	private var CurrentMapWorldSize:Point;
	private var ClientChar:Character;

	private var DefaultWaypointFile:XML;
	private var Waypoints:Array;

	/// GUI Elements
	private var PlayerMarker:MovieClip;
}
