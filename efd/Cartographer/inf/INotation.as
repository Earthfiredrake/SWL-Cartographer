// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

// Minimal interface requirements for any notation types
// Note: The current design does not permit entirely new notations as most
//       are expected to fit within one of the existing categories
//       Custom notations should implement one of the derived interfaces,
//       or extend an appropriate base class
interface efd.Cartographer.inf.INotation {

	// GUI interaction hooks, to be called by notation gui initialization, prior to loading/rendering
	// Target will be the gui wrapper clip which is handling mouse events
	// At the moment Unhook is only used by Icons when the icon clip is being reused with new data
	//   This causes an unhook call, followed by a hook call to the new datasource
	//   Again this occurs before the icon is reloaded (if needed) and any modifier clips are applied
	// Can therefore be used as a slightly hacky place to get last minute state info before committing to a particular icon set
	//   Would prefer to only do this in cases where that state can change during runtime though
	// Note: Unhook is not explicitly called when the gui element is destroyed,
	//   Be wary of things which will not automatically clean up (ie: state changes to other objects)
	//   Changes to the target and Signal connections (which use a weak reference system) should be safe
	public function HookEvents(target:MovieClip):Void;
	public function UnhookEvents(target:MovieClip):Void;

	// Data accessors
	//   Annoying that properties can't be defined in interfaces
	public function GetXmlView():XMLNode;
	public function GetType():String;
	public function GetLayer():String;
	public function GetZoneID():Number;

	// TODO: Probably unhook this, having problems seeing a use case since collectible colour selection was placed at the Layer level
	// ... Nope Train paths? Alternate tinting?
	public function GetPenColour():Number; // Return undefined for layer defined colour

	public function GetName():String;
	public function GetNote():String;
	//TODO: Tooltips Merge Name/Note stuff into a tooltip data object
	//      Gives each notation subtype ability to specify and display relevant data
	//public function GetTooltipData();
}
