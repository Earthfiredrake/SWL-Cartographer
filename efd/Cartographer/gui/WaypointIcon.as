// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import efd.Cartographer.lib.Mod;
import efd.Cartographer.Waypoint;

class efd.Cartographer.gui.WaypointIcon extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.WaypointIcon";

	private function WaypointIcon() { // Indirect construction only
		super();
		Mod.LogMsg("Waypoint Icon Constructor");
		Mod.LogMsg("Icon file: " + Data.Icon);
		var icon:MovieClip = createEmptyMovieClip("Icon", getNextHighestDepth());
		Loader = new MovieClipLoader();

		var listener:Object = new Object();
		listener.onLoadComplete = Delegate.create(this, IconLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			Mod.LogMsg("Icon (" + target._parent.Data.Icon + ") failed to load: " + error);
			Mod.ErrorMsg("Unable to load icon (" + target._parent.Data.Icon + "): " + error);
		};
		Loader.addListener(listener);

		Loader.loadClip("Cartographer\\icons\\" + Data.Icon, icon);

		if (Data.ShowLabel) {
			Label = CreateLabel(Data.Name);
		}
		Mod.LogMsg("Waypoint Icon Constructed");
	}

	private function IconLoaded(target:MovieClip):Void {
			Mod.LogMsg("Waypoint Icon Loaded");
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
			Mod.LogMsg("Waypoint Icon Initialization finished");
	}

	private function IconAction():Void {
		Mod.LogMsg("Waypoint Icon Clicked");
		if (Data["TargetZone"] != undefined) {
			_parent._parent.ChangeMap(Data["TargetZone"]);
		}
	}

	private static function CenterIcon(target:MovieClip):Void {
		target._x = -target._width / 2;
		target._y = -target._height / 2;
	}

	private function CreateLabel(name:String):TextField {
		Mod.LogMsg("Creating Label");
		var label:TextField = createTextField("LabelTxt", getNextHighestDepth(), 0, 0, 50, 15);
		label.embedFonts = true;
		label.selectable = false;
		label.autoSize = "left";
		var fmt:TextFormat = new TextFormat("_StandardFont");
		label.setNewTextFormat(fmt);
		label.text = name ? name : "";
		return label;
	}

	public function Reassign(data:Waypoint, pos:Point):Void {
		if (Data.Icon != data.Icon) {
			Mod.TraceMsg("Waypoint icon swapping");
			Loader.loadClip("Cartographer\\icons\\" + data.Icon, Icon);
		}
		if (data.ShowLabel) {
			if (Data.ShowLabel) {
				Label.text = data.Name ? data.Name : "";
			} else {
				Label = CreateLabel(data.Name);
			}
		} else {
			if (Data.ShowLabel) {
				// TODO:Destroy label
			}
		}
		Data = data;
		_x = pos.x;
		_y = pos.y;
	}

	public function Unload():Void {
		Mod.LogMsg("Unloading mod Icon");
		Loader.unloadClip(Icon);
	}

	private var Data:Waypoint;

	private var Loader:MovieClipLoader;
	private var Icon:MovieClip;

	private var Label:TextField;

	private static var FocusScale:Number = 110;
}

/// Notes:
//   I've been experiencing some instablity that randomly crashes the game when opening/changing maps
//   The cause has not yet been determined, and the process of narrowing it down has proven challenging, as it exits immediately with limited feedback
//   Current hypothesis is that it is related to io failure or delay, possibly caused by trying to read too much data from disk too quickly
//   Unfortunately there does not seem to be a convenient solution:
//     Flash requires that the icons be reloaded every time they are used unless they are defined as part of a library type
//       Defining them as part of a library type means that they will no longer be available to the user for customization/extension
//       Movie clips, once created, are locked to their parent, and without the library type can only be duplicated as children of their own
//       Duplicated movie clips do not contain dynamically loaded content from their parent, it must be re-loaded
//       The window system expects that the window content be a child element of it, and that it be destroyed and re-created each time the window is closed
//     A similar set of arguments is present for the map files, though the motivation there is more an ease of extension than actual customization
//   The current strategy for dealing with this is attempted mitigation, with stability to be assessed as development approaches a more complete product:
//     Attemptng to be clean with the code, explicitly tidy up memory leaks and close things off when they are no longer in use
//     Avoid loading more than required, notation layers can defer loading of markers if they are hidden and can reuse existing markers when changing maps
//     Stage the loading, ensure that the map and layers load sequentially rather than asynchronously, possibly with delays so that large data sets don't devour entire time blocks
//     Extensive use of Mod.LogMsg() in an effort to trace/locate any replicatable crash locations
