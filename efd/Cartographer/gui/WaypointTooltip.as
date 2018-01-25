﻿// Copyright 2017, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

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
		if (Data.GetNote()) {
			TF_Note.backgroundColor = 0x333333;
			TF_Note.background = true;
			TF_Note.autoSize = "left";
			TF_Note.text = Data.GetNote();
		} else { TF_Note._visible = false; }
	}

	private var TF_Name:TextField;
	private var TF_Note:TextField;
	private var Data:INotation;
}
