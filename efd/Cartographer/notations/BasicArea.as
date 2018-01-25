// Copyright 2017, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import efd.Cartographer.inf.IArea;

import efd.Cartographer.notations.NotationBase;

// Basic Area type implementation
class efd.Cartographer.notations.BasicArea extends NotationBase implements IArea {
	public function BasicArea(xml:XMLNode) {
		super(xml);
		Centre = new Point(Number(xml.attributes.x), Number(xml.attributes.y));
		Radius = Number(xml.attributes.radius);
	}

	// Interface implementation
	public function GetType():String { return "area"; }
	public function GetCentre():Point { return Centre; }
	public function GetRadius():Number { return Radius; }

	private var Centre:Point;
	private var Radius:Number;
}
