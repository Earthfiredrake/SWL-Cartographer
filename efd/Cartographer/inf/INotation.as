// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

// Minimal interface requirements for any notation types
// Note: The current design does not permit entirely new notations as most
//       are expected to fit within one of the existing categories
//       Custom notations should implement one of the derived interfaces,
//       or extend an appropriate base class
interface efd.Cartographer.inf.INotation {

	// GUI interaction hooks, to be called after notation is initialized
	// Target will be the gui data wrapper which is handling mouse events
	public function HookEvents(target:MovieClip):Void;
	public function UnhookEvents(target:MovieClip):Void;

	// Data accessors
	//   Annoying that properties can't be defined in interfaces
	public function GetXmlView():XMLNode;
	public function GetType():String;
	public function GetLayer():String;
	public function GetZoneID():Number;

	public function GetPenColour():Number; // Return undefined for layer defined colour

	public function GetName():String;
	public function GetNote():String;
	//TODO: Tooltips Merge Name/Note stuff into a tooltip data object
	//      Gives each notation subtype ability to specify and display relevant data
	//public function GetTooltipData();
}
