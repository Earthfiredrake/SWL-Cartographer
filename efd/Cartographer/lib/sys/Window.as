// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import com.GameInterface.DistributedValue;

import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;

// Window subsystem implementation
// Dependencies:
//   Subsystems: Config, Localization
//   Library Symbols:
//     [ModName]Window:Movieclip Instance of ModWindow; handles window frame and other chrome
//       Easiest to just copy a window object out of an existing mod and tweak things on it for the new mod
//     [ModName][WindowName]Content:Movieclip The actually useful part of the window; entirely custom for the mod
// InitObj:
//   WindowName:String (required: no default, can't be "")
//     Used to generate unique identifiers for this window, including DVs and library resource IDs
//     Only needs to be unique within the mod, global identifiers will be further specified with ModName and DVPrefix as needed
//   LoadEvent:Delegate(WindowContent) (optional: not implementing may limit access to mod data)
//     Called once the content object has been loaded, usually used to pass data directly to that clip
//   ResizeLimits:Object {Min:Point, Max:Point} (optional: default disables resizing)
//     Enables the window resize handle and defines the size limits for the window;
//     If included, all values must be defined and sane (some of that will be checked)
//     When enabled will add a "[WindowName]Size" point element to the config settings (This will actually be the size of [WindowName]Content that would create the properly sized window)
//     Content object needs to implement an override of SetSize(width:Number, height:Number)
//       This function should adjust the content clip to fit the dimensions, and then raise SignalSizeChanged
//       TODO: Currently only the resize tab and opening the window (with the saved setting) can affect the window layout
//             If other sources want to adjust window size, will have to refactor to direct changes through Config.ValueChanged
//       TODO: Max size could be optional, most people wouldn't go to the effort of making hugely unwieldy windows
//             Might want to adjust the ReturnWindowToBounds function to catch those sorts of things though
// Handles window creation and display, may be included multiple times to provide additional windows if needed (once modular subsystems handle arbitrary additions)
//   Config system includes a ConfigWindow instance without having to be added separately (though content must be provided)

class efd.Cartographer.lib.sys.Window {
	public static function Create(mod:Mod, initObj:Object):Window {
		// Check required parameters
		if (!initObj.WindowName) {
			Mod.ErrorMsg("Name is a required parameter and may not be an empty string", {system : "Window"});
			return undefined;
		}
		// Check dependencies
		if (!mod.Config) {
			Mod.ErrorMsg("Subsystem dependency missing: Config", {system : initObj.WindowName});
			return undefined;
		}

		return new Window(mod, initObj);
	}

	private function Window(mod:Mod, initObj:Object) {
		ModObj = mod;
		WindowName = initObj.WindowName;
		LoadEvent = initObj.LoadEvent;

		ModObj.Config.NewSetting(WindowName + "Position", new Point(20, 30));
		if (CheckResizeLimits(initObj.ResizeLimits)) {
			ResizeLimits = initObj.ResizeLimits;
			ModObj.Config.NewSetting(WindowName + "Size", new Point(-1, -1));
		}

		ShowDV = DistributedValue.Create(Mod.DVPrefix + "Show" + mod.ModName + WindowName);
		ShowDV.SetValue(false);
		ShowDV.SignalChanged.Connect(ShowWindowChanged, this);
	}

	private function CheckResizeLimits(limits:Object):Boolean {
		if (!limits) { return false; }
		var min:Point = limits.Min;
		var max:Point = limits.Max;
		if (min.x == undefined || min.y == undefined || max.x == undefined || max.y == undefined) {
			Mod.ErrorMsg("Resize limits are not all defined, resize disabled", {system : WindowName});
			return false;
		}
		if (min.x > max.x || min.y > max.y) {
			Mod.ErrorMsg("Resize limits do not define a closed range, resize disabled", {system : WindowName});
			return false;
		}
		// Hopefully that covers the most likely mistakes, most devs should realize negative or particularly small/large values aren't wise either
		return true;
	}

	private function ShowWindowChanged(dv:DistributedValue):Void {
		if (dv.GetValue()) {
			if (ModObj.ModLoadedDV.GetValue() == false) {
				dv.SetValue(false);
				Mod.ErrorMsg("Did not load properly, and has been disabled.");
				return;
			}
			if (WindowClip == null) { WindowClip = OpenWindow(); }
		}
		else {
			if (WindowClip != null) {
				WindowClosed();
				WindowClip = null;
			}
		}
	}

	public function ToggleWindow():Void {
		if (!ShowDV.GetValue()) { ShowDV.SetValue(true); }
		else { WindowClip.TriggerWindowClose; }
	}

	public function OpenWindow():MovieClip {
		// Can't pass a useful cached initObj here, constructors stomp almost all the things I would set
		var clip:MovieClip = ModObj.HostMovie.attachMovie(ModObj.ModName + "Window", WindowName, ModObj.HostMovie.getNextHighestDepth());

		clip.SignalContentLoaded.Connect(TriggerLoadEvent, this); // Defer config bindings until content is loaded
		clip.SetContent(ModObj.ModName + WindowName + "Content");

		var localeTitle:String = LocaleManager.FormatString("GUI", WindowName + "Title", ModObj.ModName);
		clip.SetTitle(localeTitle, "left");

		var position:Point = ModObj.Config.GetValue(WindowName + "Position");
		clip._x = position.x;
		clip._y = position.y;

		if (ResizeLimits) {
			clip.SignalSizeChanged.Connect(UpdateSize, this);
			clip.PermitResize(ResizeLimits);
		}

		clip.SignalClose.Connect(CloseWindow, this);

		return clip;
	}

	private function UpdateSize():Void { ModObj.Config.SetValue(WindowName + "Size", WindowClip.GetSize()); }

	private function TriggerLoadEvent():Void { LoadEvent(WindowClip.m_Content); }

	private function CloseWindow():Void { ShowDV.SetValue(false); }

	private function WindowClosed():Void {
		ReturnWindowToVisibleBounds(WindowClip, ModObj.Config.GetDefault(WindowName + "Position"));
		ModObj.Config.SetValue(WindowName + "Position", new Point(WindowClip._x, WindowClip._y));

		WindowClip.removeMovieClip();
	}

	private static function ReturnWindowToVisibleBounds(window:MovieClip, defaults:Point):Void {
		var visibleBounds = Stage.visibleRect;
		if (window._x < 0) { window._x = 0; }
		else if (window._x + window.m_Background._width > visibleBounds.width) {
			window._x = visibleBounds.width - window.m_Background._width;
		}
		if (window._y < defaults.y) { window._y = defaults.y; }
		else if (window._y + window.m_Background._height > visibleBounds.height) {
			window._y = visibleBounds.height - window.m_Background._height;
		}
	}

	private var ModObj:Mod;

	private var WindowName:String;
	private var LoadEvent:Function;
	private var ResizeLimits:Object;
	private var ShowDV:DistributedValue; // Using a DV lets other mods (topbars) and chat commands toggle windows
	private var WindowClip:MovieClip = null;
}
