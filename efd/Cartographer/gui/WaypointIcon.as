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
		listener.onLoadComplete = Delegate.create(this, IconLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.ErrorMsg("Unable to load icon: " + error);
		};
		Loader.addListener(listener);

		Mod.TraceMsg("Loading waypoint icon: Cartographer\\Icons\\" + Data.Icon);
		Loader.loadClip("Cartographer\\icons\\" + Data.Icon, Icon);

		Label = CreateLabel();
	}

	private function IconLoaded(target:MovieClip):Void {
			CenterIcon(target);

			target.onRollOver = function():Void {
				target._xscale = FocusScale;
				target._yscale = FocusScale;
				CenterIcon(target);
			};
			var rollOut:Function = function():Void {
				target._xscale = 100;
				target._yscale = 100;
				CenterIcon(target);
			}
			target.onRollOut = rollOut;
			target.onReleaseOutside = rollOut;

			target.onPress = Delegate.create(this, IconAction);
	}

	private function IconAction():Void {
		if (Data["TargetZone"] != undefined) {
			_parent.ChangeMap(Data["TargetZone"]);
		}
	}

	private static function CenterIcon(target:MovieClip):Void {
		target._x = -target._width / 2;
		target._y = -target._height / 2;
	}

	private function CreateLabel():TextField {
		var label:TextField = createTextField("Label", getNextHighestDepth(), 0, 0, 50, 15);
		label.embedFonts = true;
		label.selectable = false;
		label.autoSize = "left";
		var fmt:TextFormat = new TextFormat("_StandardFont");
		label.setNewTextFormat(fmt);
		label.text = Data.Name ? Data.Name : "";
		return label;
	}

	public function Unload():Void {
		Loader.unloadClip(Icon);
	}

	private var Data:Waypoint;

	private var Loader:MovieClipLoader;
	private var Icon:MovieClip;

	private var Label:TextField;

	private static var FocusScale:Number = 110;
}
