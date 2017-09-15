// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import efd.Cartographer.lib.etu.MovieClipHelper;

import efd.Cartographer.gui.Layers.NotationLayer;
import efd.Cartographer.gui.WaypointIcon;
import efd.Cartographer.Waypoint;

// Layer type supporting waypoints that can be collected to unlock entries in the lore or achievements
// Splits waypoint icons between two layers, so that collected entries don't hide uncollected ones
// TODO: Automatic icon updates when a collectible is claimed

class efd.Cartographer.gui.Layers.CollectibleLayer extends NotationLayer {
	public static var __className:String = "efd.Cartographer.gui.Layers.CollectibleLayer"; // For elT's clip helper library

	private function CollectibleLayer() { // Indirect construction only
		super();

		createEmptyMovieClip("CollectedSublayer", getNextHighestDepth());
		createEmptyMovieClip("UncollectedSublayer", getNextHighestDepth());

		RenderedUncollected = new Array();
		RenderedCollected = new Array();
	}

	private function ReloadAll():Void {
		// Reset some local copies
		UncollectedCount = 0;
		CollectedCount = 0;
		UncollectedData = new Array();
		CollectedData = new Array();

		// Split the data on collection status
		var waypoints:Array = WaypointData[Zone];
		for (var i:Number = 0; i < waypoints.length; ++i) {
			if (waypoints[i].IsCollected) { CollectedData.push(waypoints[i]); }
			else { UncollectedData.push(waypoints[i]); }
		}

		super.ReloadAll();
	}

	private function TrimDisplayList():Void {
		TrimImpl(RenderedUncollected, UncollectedData.length);
		TrimImpl(RenderedCollected, CollectedData.length);
	}

	private function TrimImpl(list:Array, length:Number):Void {
		for (var i:Number = length; i < list.length; ++i) {
			var wp:MovieClip = list[i];
			wp.Unload();
			wp.removeMovieClip();
		}
		list.splice(length);
	}

	private function LoadDataBlock():Void {
		// Load both data sets, prioritizing the uncollected
		// TODO: Consider revising this to prioritize reassignments,
		//       clearing the old map's data off the new map faster
		if (LoadDataImpl("Uncollected")) {
			LoadDataImpl("Collected");
		}
	}

	// Load data, return false on early exits
	private function LoadDataImpl(state:String):Boolean {
		var data:Array = this[state + "Data"];
		var renderList:Array = this["Rendered" + state];
		// Reassignment of existing waypoints
		for (var i:Number = this[state + "Count"]; i < renderList.length; ++i) {
			if (renderList[i].Reassign(data[i], _parent.WorldToMapCoords(data[i].Position))) {
				return false;
			}
			this[state + "Count"] += 1;
		}
		// New waypoints
		var i:Number = this[state + "Count"]; // This will no longer be changed for lifetime of function, can cache
		if (i < data.length) {
			var mapPos:Point = _parent.WorldToMapCoords(data[i].Position);
			var sublayer:MovieClip = this[state + "Sublayer"];
			var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
				WaypointIcon, "WP" + sublayer.getNextHighestDepth(), sublayer, sublayer.getNextHighestDepth(),
				{ Data : data[i], _x : mapPos.x, _y : mapPos.y, LayerClip : this }));
			wp.SignalIconChanged.Connect(ChangeIcon, this);
			wp.SignalWaypointLoaded.Connect(LoadNextBlock, this);
			wp.LoadIcon();
			renderList.push(wp);
			return false;
		}
		return true; // All waypoints of this type have been loaded already
	}

	private function LoadNextBlock(icon:WaypointIcon):Void {
		var state:String = icon.Data["IsCollected"] ? "Collected" : "Uncollected";
		this[state + "Count"] += 1;
		LoadDataBlock();
	}

	private function ChangeIcon(icon:WaypointIcon):Void {
		// Create a replacement icon on the collected sublayer
		var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
			WaypointIcon, "WP" + CollectedSublayer.getNextHighestDepth(), CollectedSublayer, CollectedSublayer.getNextHighestDepth(),
			{ Data : icon.Data, _x : icon._x, _y : icon._y, LayerClip : this }));
		wp.SignalIconChanged.Connect(ChangeIcon, this);
		wp.SignalWaypointLoaded.Connect(DeferLoadBehaviour, this);
		wp.LoadIcon();
		RenderedCollected.push(wp);

		// Find and remove the existing waypoint from the render list
		// The splice call may not be the most efficient method, but it does retain the order
		// If the order doesn't really matter (likely) and more efficiency is needed (unlikely)
		// Copying the last element into that slot then removing the original is likely to be quicker
		var index:Number;
		for (var i:Number = 0; i < RenderedUncollected.length; ++i) {
			if (RenderedUncollected[i] == icon) { index = i; break; }
		}
		if (index) { RenderedUncollected.splice(index, 1); }

		// Remove the existing waypoint movie clip
		icon.Unload();
		icon.removeMovieClip();
	}

	private function DeferLoadBehaviour(icon:WaypointIcon):Void {
		// HACK: Adding and removing signals during the signal handling is risky
		//   It only really works because this is the last(only) signal in the queue
		//   So it is processing slot i, which is disconnected then replaced, and the new slot is skipped
		icon.SignalWaypointLoaded.Disconnect(DeferLoadBehaviour, this);
		icon.SignalWaypointLoaded.Connect(LoadNextBlock, this);
	}

	public function get RenderedWaypoints():Array { return RenderedUncollected.concat(RenderedCollected); }

	private var UncollectedData:Array;
	private var UncollectedCount:Number;
	private var UncollectedSublayer:MovieClip;
	private var RenderedUncollected:Array;

	private var CollectedData:Array;
	private var CollectedCount:Number;
	private var CollectedSublayer:MovieClip;
	private var RenderedCollected:Array;
}
