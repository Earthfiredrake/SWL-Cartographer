// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.inf.INotation;

// TODO: Plugin System
// A registration system so that I can add these without changing the factory method
import efd.Cartographer.notations.BasicArea;
import efd.Cartographer.notations.BasicPath;
import efd.Cartographer.notations.BasicPoint;
import efd.Cartographer.notations.ChampPoint;
import efd.Cartographer.notations.LorePoint;
import efd.Cartographer.notations.TransitPoint;

// Boilerplate implementation of INotation interface for use as base class to more complex types
// Also contains the factory method for generating new notations
class efd.Cartographer.notations.NotationBase implements INotation {
		public static function Create(xml:XMLNode):INotation {
		switch (xml.attributes.type) {
			case "area": return new BasicArea(xml);
			case "path": return new BasicPath(xml);
			case "wp":
			case undefined:
				switch (xml.nodeName) {
					case "Champ": return new ChampPoint(xml);
					case "Lore": return new LorePoint(xml);
					case "Transit": return new TransitPoint(xml);
					default: return new BasicPoint(xml);
				}
			default:
				Mod.TraceMsg("Unknown notation type=" + xml.attributes.type);
		}
		return undefined;
	}

	public function NotationBase(xml:XMLNode) {
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
	public function GetType():String { return undefined; } // Lacks required subsidary interface
	public function GetLayer():String { return Layer; }
	public function GetZoneID():Number { return ZoneID; }
	public function GetName():String { return Name; }
	public function GetNote():String { return Note; }

	public function HookEvents(clipContext:MovieClip, dataContext:Object):Void { }
	public function UnhookEvents(clipContext:MovieClip, dataContext:Object):Void { }

	private var ZoneID:Number; // Map instance
	private var Layer:String; // Layer category name
	private var Name:String; // Notation name
	private var Note:String; // Detail notes
}
