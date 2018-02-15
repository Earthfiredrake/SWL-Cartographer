// Copyright 2017, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import efd.Cartographer.inf.INotation;

// Interface requirements for map notations which place an icon at a particular, singular, location
// Implementations are expected to parse a Type of "point" for proper layer placement
interface efd.Cartographer.inf.IWaypoint extends INotation {

	// Data accessors
	public function GetPosition():Point; // Position is in game world coordinates
	public function GetIcon():String; // Filename to load from Icons\[filename]
	public function TintIcon():Boolean; // Apply the layer pen colour as a tint to the icon (white(or light grey) areas will be tinted, black or transparent areas will not)
	// Frame name (or number) to use from the modifier clip
	//   Some frames ('text') need additional parameters, the '|' character is used as a separator
	public function GetIconModifier():String;
}
