// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.filters.ColorMatrixFilter;
import flash.geom.Point;

import gfx.utils.Delegate;

import com.Utils.Signal;

import efd.Cartographer.gui.Layers.NotationLayer;
import efd.Cartographer.inf.IWaypoint;
import efd.Cartographer.lib.Mod;

class efd.Cartographer.gui.WaypointIcon extends MovieClip {
	public static var __className:String = "efd.Cartographer.gui.WaypointIcon";

	private function WaypointIcon() { // Indirect construction only
		super();
		SignalWaypointLoaded = new Signal();
		SignalIconChanged = new Signal();
		Loader = new MovieClipLoader();

		Data.HookEvents(this);

		var listener:Object = new Object();
		listener.onLoadInit = Delegate.create(this, IconLoaded);
		listener.onLoadError = function(target:MovieClip, error:String):Void {
			// Attempt to filter out spurious error messsages caused by closing the window during loading
			// While still detecting conditions where Data is corrupt or missing.
			if (target._parent) { Mod.ErrorMsg("Unable to load icon (" + target._parent.Data.GetIcon() + "): " + error); }
		};
		Loader.addListener(listener);
	}

	public function LoadIcon():Void {
		// Loading the icon overwrites the data in the clip, so wrap it in an empty subclip
		var icon:MovieClip = createEmptyMovieClip("Icon", getNextHighestDepth());
		// NOTE: It seems that loadClip can also be used to access the rdb
		//   Path syntax is "rdb:[Type]:[ID]"
		//   Type 1000624 contains swf files
		//   Type 1000636 contains png files
		//   Not sure how useful this is, as I have limited knowledge of what is actually tucked away in there
		// TODO: Wonder if other paths could be loaded from the rdb in a similar fashion
		Loader.loadClip("Cartographer\\icons\\" + Data.GetIcon(), icon);
		ApplyModifier();
	}

	private function IconLoaded(target:MovieClip):Void {
		CenterIcon(target);
		ApplyTint(target);
		SignalWaypointLoaded.Emit(this);
	}

	private function ApplyTint(target:MovieClip):Void {
		if (Data.TintIcon()) {
			target.filters = [CreateTintFilter(MapViewLayer.GetPenColour(Data))];
		}
	}

	private function ApplyModifier():Void {
		var modifier:Array = Data.GetIconModifier().split("|");
		if (modifier != undefined) {
			if (!Modifier) { attachMovie("CartographerPointMarkerModifier", "Modifier", getNextHighestDepth()); }
			Modifier.gotoAndStop(modifier[0]);

			switch (modifier[0]) {
				case "text" : {
					var fmt:TextFormat = Modifier.ModifierText.getNewTextFormat();
					fmt.bold = true;
					Modifier.ModifierText.setNewTextFormat(fmt);
					Modifier.ModifierText.text = modifier[1];
					break;
				}
			}
		} else {
			if (Modifier) { Modifier.removeMovieClip(); }
		}
	}

	private function onRollOver():Void {
		_xscale = FocusScale;
		_yscale = FocusScale;
		ShowTooltip();
	}

	private function onRollOut():Void {
		_xscale = 100;
		_yscale = 100;
		RemoveTooltip();
	}
	private function onDragOut():Void { onRollOut(); }
	private function onDragOutAux():Void { onRollOut(); }

	// Doesn't center the registration point for the subclip,
	//   so has to be called whenever subclip is rescaled independently
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
		Data.UnhookEvents(this);

		var oldData:IWaypoint = Data;
		Data = data;
		Data.HookEvents(this);
		UpdatePosition(pos);
		var loading:Boolean = oldData.GetIcon() != data.GetIcon();
		if (loading) {
			Loader.loadClip("Cartographer\\icons\\" + data.GetIcon(), Icon);
		}
		ApplyModifier();
		return loading;
	}

	// Usually means the icon or overlay needs to be changed
	public function StateChanged():Void {
		SignalIconChanged.Emit(this);
	}

	private function ShowTooltip():Void {
		if (!Tooltip) {
			// At MapViewClip._parent level to circumvent viewport mask
			Tooltip = MapViewLayer.MapViewClip._parent.attachMovie("CartographerWaypointTooltip", "Tooltip", MapViewLayer.MapViewClip.getNextHighestDepth(), {Data : Data});
			var pos:Point = MapViewLayer.MapViewClip.MapToViewCoords(new Point(_x, _y));
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

	private function onUnload():Void {
		RemoveTooltip();
	}

	private static function CreateTintFilter(color:Number):ColorMatrixFilter {
		var r:Number = ((color & 0xFF0000) >> 16) / 255;
		var g:Number = ((color & 0x00FF00) >> 8) / 255;
		var b:Number =  (color & 0x0000FF) / 255;
		return new ColorMatrixFilter(
			[r, 0, 0, 0, 0,
			 0, g, 0, 0, 0,
			 0, 0, b, 0, 0,
			 0, 0, 0, 1, 0]);
	}

	public var Data:IWaypoint;

	public var SignalIconChanged:Signal; // Used to notify host layer that this icon has changed due to outside events
	public var SignalWaypointLoaded:Signal; // WARNING: Adding additional hooks to this may be an issue, see HACK in CollectibleLayer
	private var Loader:MovieClipLoader;

	private var Icon:MovieClip;
	private var Modifier:MovieClip;

	private var Label:TextField;

	private var MapViewLayer:NotationLayer; // The manager for this notation layer
	private var Tooltip:MovieClip;

	private static var FocusScale:Number = 110;
}

/// Notes:
//   The following problem has been largely fixed by forcing image loading into a largely sequential process
//     At the moment the main map image is loaded prior to any icon images, overlay layers start loading in parallel, but each layer loads a single icon file at a time
//     Efforts have also been made to minimize the amount of loading, with layers attempting to reuse existing icons if possible
//     While this has a noticable impact on map loading and transition times, the game has been much more stable since these changes were implemented
//   Retaining the remainder of the analysis for informational purposes
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
