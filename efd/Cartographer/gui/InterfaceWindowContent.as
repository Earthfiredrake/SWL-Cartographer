// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import com.Components.WindowComponentContent;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
		CurrentMapDisplaySize = new Point(1080, 1080);
		CurrentMapWorldSize = new Point(1024, 1024);
		ClientChar = Character.GetClientCharacter();
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

	/// GUI Elements
	private var PlayerMarker:MovieClip;
}
