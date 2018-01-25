// Copyright 2017, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import efd.Cartographer.inf.IPath;

import efd.Cartographer.notations.NotationBase;

// Basic Path type implementation
class efd.Cartographer.notations.BasicPath extends NotationBase implements IPath {
	public function BasicPath(xml:XMLNode) {
		super(xml);
		PathPoints = new Array();
		for (var i:Number = 0; i < xml.childNodes.length; ++i) {
			var subNode:XMLNode = xml.childNodes[i];
			if (subNode.nodeName == "Point") {
				PathPoints.push(new Point(Number(subNode.attributes.x), Number(subNode.attributes.y)));
			}
		}
	}

	// Interface implementation
	public function GetType():String { return "path"; }
	public function GetPathPoints():Array { return PathPoints; }

	private var PathPoints:Array;
}
