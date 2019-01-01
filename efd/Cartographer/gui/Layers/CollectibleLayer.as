// Copyright 2017-2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import flash.filters.ColorMatrixFilter;
import flash.geom.Point;

import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.LayerData;
import efd.Cartographer.gui.Layers.NotationLayer;
import efd.Cartographer.gui.MapView;
import efd.Cartographer.gui.WaypointIcon;
import efd.Cartographer.inf.INotation;

// Layer type supporting waypoints that can be collected to unlock entries in the lore or achievements
// Splits point icons across two layers, so uncollected ones aren't obscured, and collected ones can be hidden
// Area and path marks aren't split, but are generally infrequent enough to just redraw the sheet

class efd.Cartographer.gui.Layers.CollectibleLayer extends NotationLayer {

	public function CollectibleLayer(mapView:MapView, data:LayerData, visible:Boolean) {
		super(mapView, data, visible);

		WaypointLayer.createEmptyMovieClip("CollectedSublayer", WaypointLayer.getNextHighestDepth());
		WaypointLayer.createEmptyMovieClip("UncollectedSublayer", WaypointLayer.getNextHighestDepth());

		RenderedUncollected = new Array();
		RenderedCollected = new Array();
	}

	private function ReloadWaypoints():Void {
		// Split the data on collection status
		var uncollectedData:Array = new Array();
		var collectedData:Array = new Array();
		var waypoints:Array = NotationData.GetWaypoints(Zone);
		for (var i:Number = 0; i < waypoints.length; ++i) {
			if (waypoints[i].VerifyCollected()) { collectedData.push(waypoints[i]); }
			else { uncollectedData.push(waypoints[i]); }
		}

		UpdateDisplayList(RenderedUncollected, uncollectedData, WaypointLayer.UncollectedSublayer);
		UpdateDisplayList(RenderedCollected, collectedData, WaypointLayer.CollectedSublayer);

		for (var i:Number = 0; i < RenderedCollected.length; ++i) {
			RenderedCollected[i].filters = [GreyscaleConverter];
		}
	}

	public function GetPenColour(data:INotation):Number {
		return data["IsCollected"] ? GreyPenColour : super.GetPenColour(data);
	}

	private function ChangeIcon(icon:WaypointIcon):Void {
		// Create a replacement icon on the collected sublayer
		var targetLayer:MovieClip = WaypointLayer.CollectedSublayer;
		var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
			WaypointIcon, "WP" + targetLayer.getNextHighestDepth(), targetLayer, targetLayer.getNextHighestDepth(),
			{ Data : icon.Data, _x : icon._x, _y : icon._y, filters : [GreyscaleConverter], MapViewLayer : this }));
		wp.SignalIconChanged.Connect(ChangeIcon, this);
		wp.LoadIcon();
		RenderedCollected.push(wp);

		// Find and remove the existing waypoint from the render list
		// The splice call may not be the most efficient method, but it does retain the order
		// If the order doesn't really matter (likely) and more efficiency is needed (unlikely)
		// Copying the last element into that slot then popping the end is likely to be quicker
		for (var i:Number = 0; i < RenderedUncollected.length; ++i) {
			if (RenderedUncollected[i] == icon) {
				RenderedUncollected.splice(i, 1);
				break;
				}
		}

		// Remove the existing waypoint movie clip
		icon.removeMovieClip();
	}

	public function get RenderedWaypoints():Array { return RenderedUncollected.concat(RenderedCollected); }

	// Needs a greyscale converter that brightens black (signal) without overly affecting other values
	// Adding a flat value and scaling the conversion down comes close
	private static var GreyscaleConverter:ColorMatrixFilter =
		new ColorMatrixFilter([0.18516, 0.36564, 0.0492, 0, 0.4,
							   0.18516, 0.36564, 0.0492, 0, 0.4,
							   0.18516, 0.36564, 0.0492, 0, 0.4,
							   0, 0, 0, 1, 0]);
	// Original suggested values for pure greyscale conversion below
	//	new ColorMatrixFilter([0.3086, 0.6094, 0.0820, 0, 0,
	//						   0.3086, 0.6094, 0.0820, 0, 0,
	//						   0.3086, 0.6094, 0.0820, 0, 0,
	//						   0, 0, 0, 1, 0]);
	// Adjusted midrange grey to match converter's output
	// By happy coincidence, when passed through the converter it actually looks not bad
	//   which is good, because the converter is still required to grey out any modifier sprites

	private var UncollectedData:Array;
	private var UncollectedCount:Number;
	private var RenderedUncollected:Array;

	private var CollectedData:Array;
	private var CollectedCount:Number;
	private var RenderedCollected:Array;
	private static var GreyPenColour:Number = 0xBCBCBC;
}
