// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import com.Components.WindowComponentContent;

import efd.Cartographer.lib.ConfigWrapper;
import efd.Cartographer.lib.etu.MovieClipHelper;

import efd.Cartographer.gui.MapView;
import efd.Cartographer.gui.LayerList;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
	}

	private function SetData(zoneIndex:Object, notationLayerData:Array, config:ConfigWrapper):Void {
		MovieClipHelper.createMovieWithClass(MapView, "MapViewport", this, getNextHighestDepth(),
			{ ZoneIndex : zoneIndex, NotationLayerData : notationLayerData, Config : config, Height : ViewportHeight, Width : ViewportWidth });

		LayerListDisplay.SetConfig(config);
		LayerListDisplay.AddLayers(notationLayerData);
	}

	private var MapViewport:MapView;
	private var LayerListDisplay:LayerList;

	private static var ViewportHeight:Number = 768;
	private static var ViewportWidth:Number = 768;
}
