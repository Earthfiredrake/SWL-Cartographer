// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.inf.INotation;

// Interface requirements for map notations which places a filled zone at a particular location
// Implementations are expected to parse a Type of "area" for proper layer placement
// Initial design expects circular zones, however this may be re-evaluated
interface efd.Cartographer.inf.IArea extends INotation {

	// Data accessors
	public function GetCentre():Point; // Position is in game world coordinates
	public function GetRadius():Number;
}
