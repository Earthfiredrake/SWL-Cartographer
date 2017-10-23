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
	// clipContext will be the actual displayed element of the notation
	// dataContext will be the relevant gui data wrapper class
	public function HookEvents(clipContext:MovieClip, dataContext:Object):Void;
	public function UnhookEvents(clipContext:MovieClip, dataContext:Object):Void;

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
