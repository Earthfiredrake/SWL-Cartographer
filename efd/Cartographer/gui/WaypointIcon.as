// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import com.Utils.Signal;

import efd.Cartographer.lib.Mod;
import efd.Cartographer.inf.IWaypoint;

class efd.Cartographer.gui.WaypointIcon extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.WaypointIcon";

	private function WaypointIcon() { // Indirect construction only
		super();
		SignalWaypointLoaded = new Signal();
		SignalIconChanged = new Signal();
		Loader = new MovieClipLoader();

		var listener:Object = new Object();
		listener.onLoadInit = Delegate.create(this, IconLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			// Attempt to filter out spurious error messsages caused by closing the window during loading
			// While still detecting conditions where Data is corrupt or missing.
			if (target._parent) {
				Mod.ErrorMsg("Unable to load icon (" + target._parent.Data.Icon + "): " + error);
			}
		};
		Loader.addListener(listener);
	}

	public function LoadIcon():Void {
		var icon:MovieClip = createEmptyMovieClip("Icon", getNextHighestDepth());
		// NOTE: It seems that loadClip can also be used to access the rdb
		//   Path syntax is "rdb:[Type]:[ID]"
		//   Type 1000624 contains swf files
		//   Type 1000636 contains png files
		//   Not sure how useful this is, as I have limited knowledge of what is actually tucked away in there
		// TODO: Wonder if other paths could be loaded from the rdb in a similar fashion
		Loader.loadClip("Cartographer\\icons\\" + Data.GetIcon(), icon);
	}

	private function IconLoaded(target:MovieClip):Void {
			CenterIcon(target);

			target.onRollOver = function():Void {
				target._xscale = FocusScale;
				target._yscale = FocusScale;
				CenterIcon(target);
				target._parent.ShowTooltip();
			};
			var rollOut:Function = function():Void {
				target._xscale = 100;
				target._yscale = 100;
				CenterIcon(target);
				target._parent.RemoveTooltip();
			}
			target.onRollOut = rollOut;
			target.onReleaseOutside = rollOut;
			target._parent.Data.HookEvents(target, target._parent);

			SignalWaypointLoaded.Emit(this);
	}

	// This doesn't actually center the registration point, so it has to be called whenever the icon changes size
	private static function CenterIcon(target:MovieClip):Void {
		target._x = -target._width / 2;
		target._y = -target._height / 2;
	}

	public function UpdatePosition(pos:Point):Void {
		_x = pos.x;
		_y = pos.y;
	}

	public function Reassign(data:IWaypoint, pos:Point):Boolean {
		RemoveTooltip();
		Data.UnhookEvents(Icon, this);

		var oldData:IWaypoint = Data;
		Data = data;
		UpdatePosition(pos);
		if (oldData.GetIcon() != data.GetIcon()) {
			Loader.loadClip("Cartographer\\icons\\" + data.GetIcon(), Icon);
			return true;
		} else {
			Data.HookEvents(Icon, this); // Hook in other case will be handled by loader callback
			return false;
		}
	}

	private function ShowTooltip():Void {
		if (!Tooltip) {
			Tooltip = LayerClip.HostClip._parent.attachMovie("CartographerWaypointTooltip", "Tooltip", LayerClip.HostClip.getNextHighestDepth());
			Tooltip.TF_Name.backgroundColor = 0x333333;
			Tooltip.TF_Name.background = true;
			Tooltip.TF_Name.autoSize = "left";
			Tooltip.TF_Name.text = Data.GetName();
			var pos:Point = LayerClip.HostClip.MapToViewCoords(new Point(_x, _y));
			Tooltip._x = pos.x;
			Tooltip._y = pos.y;
		}
	}

	private function RemoveTooltip():Void {
		if (Tooltip) {
			Tooltip.removeMovieClip();
			Tooltip = null;
		}
	}

	public function Unload():Void {
		RemoveTooltip();
		Loader.unloadClip(Icon);
	}

	public var Data:IWaypoint;

	public var SignalIconChanged:Signal; // Used to notify host layer that this icon has changed due to outside events
	public var SignalWaypointLoaded:Signal;
	private var Loader:MovieClipLoader;

	private var Icon:MovieClip;

	private var Label:TextField;

	private var LayerClip:MovieClip; // The clip containing all of this layer's waypoints (equivalent to _parent on simple layers, but there may be intermediate clips in other layers)
	private var Tooltip:MovieClip;

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
