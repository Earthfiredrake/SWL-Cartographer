// Copyright 2017, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import efd.Cartographer.inf.INotation;

// Interface requirements for map notations which display as a line connecting a series of points
// Implementations are expected to parse a Type of "path" for proper layer placement
interface efd.Cartographer.inf.IPath extends INotation {

	// Data accessors
	public function GetPathPoints():Array; // Points to be used to draw the line, in game world coordinates
}
