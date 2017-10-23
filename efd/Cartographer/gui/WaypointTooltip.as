// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import efd.Cartographer.inf.INotation;

class efd.Cartographer.gui.WaypointTooltip extends MovieClip {

	private function WaypointTooltip() {
		// Indirect construction only
		// Requires Data be passed in initializer object
		super();
		TF_Name.backgroundColor = 0x333333;
		TF_Name.background = true;
		TF_Name.autoSize = "left";
		TF_Name.text = Data.GetName();
	}

	private var TF_Name:TextField;
	private var Data:INotation;
}
