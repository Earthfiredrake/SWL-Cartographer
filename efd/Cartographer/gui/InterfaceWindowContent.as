// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.geom.Point;

import com.Components.WindowComponentContent;

import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;
import efd.Cartographer.lib.sys.config.ConfigWrapper;

import efd.Cartographer.gui.MapView;
import efd.Cartographer.gui.LayerList;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
	}

	public function SetData(zoneIndex:Object, layerDataList:Array, config:ConfigWrapper):Void {
		MovieClipHelper.createMovieWithClass(MapView, "MapViewport", this, getNextHighestDepth(),
			{ ZoneIndex : zoneIndex, LayerDataList : layerDataList, Config : config });

		LayerListDisplay.SetConfig(config);
		LayerListDisplay.AddLayers(layerDataList);

		// Tell window to shape up
		var size:Point = config.GetValue("InterfaceWindowSize");
		if (size.x < 0 || size.y < 0) {
			size = new Point(ViewportWidth + LayerListDisplay._width, ViewportHeight);
		}
		SetSize(size.x, size.y);
	}

	// The scaling system causes the actual _width/_height values to match the actual size of the hidden map
	// Lying about the size in an effort to get the window to behave
	// Hopefully there's minimal other calls into this
	public function GetSize():Point {
		var size = MapViewport.GetViewportSize();
		if (LayerListDisplay._visible) { size.x += LayerListDisplay._width; }
		return size;
	}

	public function SetSize(width:Number, height:Number):Void {
		super.SetSize(width, height); // Currently a no-op, but things change, occasionally in useful ways

		if (width > LayerListDisplay._width * 3) {
			// If there's enough width for the sidepanel, place it and reduce the mapview's space
			LayerListDisplay._visible = true;
			LayerListDisplay._x = width - LayerListDisplay._width;
			LayerListDisplay._height = height;
			width = LayerListDisplay._x;
		} else { LayerListDisplay._visible = false; }
		MapViewport.ResizeViewport(width, height, !LayerListDisplay._visible);

		SignalSizeChanged.Emit();
	}

	private var MapViewport:MapView;
	private var LayerListDisplay:LayerList;

	// Defaults
	public static var ViewportHeight:Number = 768;
	public static var ViewportWidth:Number = 768;
}
