// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.inf.INotation;

// Interface requirements for map notations which place an icon at a particular, singular, location
// Implementations are expected to parse a Type of "wp" for proper layer placement
interface efd.Cartographer.inf.IWaypoint extends INotation {

	// Data accessors
	public function GetPosition():Point; // Position is in game world coordinates
	public function GetIcon():String;
}
