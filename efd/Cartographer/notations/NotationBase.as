// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

// TODO: Plugin System
// A registration system so that I can add these without changing the factory method
// Seems that plugins will be creating mix-ins rather than directly overriding basic classes
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
		public static function Create(xml:XMLNode):INotation {
		var notation:INotation;
		switch (xml.attributes.type) {
			case "area": notation = new BasicArea(xml); break;
			case "path": notation = new BasicPath(xml); break;
			case "wp":
			case undefined:
				notation = new BasicPoint(xml);	break;
			default:
				Mod.TraceMsg("Unknown notation type=" + xml.attributes.type);
				return undefined;
		}
		switch (xml.nodeName) {
			case "Champ": ChampMixIn.ApplyMixIn(notation); break;
			case "Lore": LoreMixIn.ApplyMixIn(notation); break;
			case "Transit": TransitMixIn.ApplyMixIn(notation); break;
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
					//ShowLabel = subNode.attributes.showLabel == "true";
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
