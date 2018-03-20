// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import efd.Cartographer.lib.DebugUtils;
import efd.Cartographer.lib.LocaleManager;

import efd.Cartographer.inf.INotation;

// TODO: Plugin System
// A registration system so that I can add these without changing the factory method
// Seems that plugins will be creating mix-ins rather than directly overriding basic classes
import efd.Cartographer.Cartographer;
import efd.Cartographer.notations.BasicArea;
import efd.Cartographer.notations.BasicPath;
import efd.Cartographer.notations.BasicPoint;
import efd.Cartographer.notations.mix.ChampMixIn;
import efd.Cartographer.notations.mix.LoreMixIn;
import efd.Cartographer.notations.mix.TransitMixIn;

// Boilerplate implementation of INotation interface for use as base class to more complex types
// Also contains the factory method for generating new notations
// Each notation type has a further base implementation
// Layer specific processing is extended onto those types using a series of mix-in classes
//   (reduces per layer type creation to 1 instead of 3)
// Note: Mix-ins may fully override base class behaviour, and are unlikely to cooperate if more than one is applied

class efd.Cartographer.notations.NotationBase implements INotation {
	// The second parameter bugs me
	//   It's provided because the TransitMixIn wants ZoneIndex info to determine if there's a map on the other side of a transition
	//   And on further consideration I don't know in advance what state info might be useful for a mixin to have access to
	//   But it feels like an invitation to some seriously messy code
	// TODO: Going to have to handle loading from alternate serialization systems at some point
	//   (Config packs, DV interop (strings or whole objects?), a "share this waypoint" button and a helper chat script (like the lag scripts) would be awesome (and would be a string based DV) etc.)
	//   Need to abstract away the serialization format
	public static function Create(xml:XMLNode, mod:Cartographer):INotation {
		var notation:INotation;
		switch (xml.attributes.type) {
			case "area": notation = new BasicArea(xml); break;
			case "path": notation = new BasicPath(xml); break;
			case "point":
			case "wp":
			case undefined:
				notation = new BasicPoint(xml);	break;
			default:
				DebugUtils.ErrorMsgS("Unknown notation type=" + xml.attributes.type);
				return undefined;
		}
		switch (notation.GetLayer()) {
			case "Champ": ChampMixIn.ApplyMixIn(notation, mod); break;
			case "Lore": LoreMixIn.ApplyMixIn(notation, mod); break;
			case "Transit": TransitMixIn.ApplyMixIn(notation, mod); break;
			case "Krampus": notation["UseTint"] = true; break; // TEMP: Mini mixin
		}
		return notation;
	}

	public function NotationBase(xml:XMLNode) {
		XmlCache = xml;
		Layer = xml.attributes.layer ? xml.attributes.layer : xml.nodeName;
		ZoneID = xml.attributes.zone;

		for (var i:Number = 0; i < xml.childNodes.length; ++i) {
			var subNode:XMLNode = xml.childNodes[i];
			switch (subNode.nodeName) {
				case "Name":
					Name = LocaleManager.GetLocaleString(subNode);
					break;
				case "Note":
					Note = LocaleManager.GetLocaleString(subNode);
					break;
			}
		}
	}

	// Interface implementation
	public function GetXmlView():XMLNode { return XmlCache; }
	public function GetType():String { return undefined; } // Lacks required subsidary interface
	public function GetLayer():String { return Layer; }
	public function GetZoneID():Number { return ZoneID; }
	public function GetPenColour():Number { return undefined; } // Use the layer defined colour
	public function GetName():String { return Name; }
	public function GetNote():String { return Note; }

	public function HookEvents(target:MovieClip):Void { }
	public function UnhookEvents(target:MovieClip):Void { }

	private var XmlCache:XMLNode; // Cache of xml data for mixin access to elements not stored by default constructor

	private var ZoneID:Number; // Map instance
	private var Layer:String; // Layer category name
	private var Name:String; // Notation name
	private var Note:String; // Detail notes
}
