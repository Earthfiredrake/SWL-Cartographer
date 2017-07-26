// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import gfx.utils.Delegate;

import efd.Cartographer.lib.Mod;
import efd.Cartographer.Waypoint;

class efd.Cartographer.gui.WaypointIcon extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.WaypointIcon";

	private function WaypointIcon() { // Indirect construction only
		Icon = createEmptyMovieClip("Icon", getNextHighestDepth());
		Loader = new MovieClipLoader();

		var listener:Object = new Object();
		listener.onLoadComplete = function(target:MovieClip):Void {
			target._x -= target._width / 2;
			target._y -= target._height / 2;
		};
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.ErrorMsg("Unable to load icon: " + error);
		};
		Loader.addListener(listener);

		Mod.TraceMsg("Loading waypoint icon: Cartographer\\Icons\\" + Data.Icon);
		Loader.loadClip("Cartographer\\icons\\" + Data.Icon, Icon);

		Label = CreateLabel();
	}

	private function CreateLabel():TextField {
		var label:TextField = createTextField("Label", getNextHighestDepth(), 0, 0, 50, 15);
		label.embedFonts = true;
		label.selectable = false;
		label.autoSize = "left";
		var fmt:TextFormat = new TextFormat("_StandardFont");
		label.setNewTextFormat(fmt);
		label.text = Data.Name;
		return label;
	}

	private var Data:Waypoint;

	private var Loader:MovieClipLoader;
	private var Icon:MovieClip;

	private var Label:TextField;
}
