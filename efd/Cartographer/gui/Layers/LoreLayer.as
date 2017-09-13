// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.Waypoints.LorePoint;

import efd.Cartographer.gui.NotationLayer;
import efd.Cartographer.gui.WaypointIcon;

class efd.Cartographer.gui.Layers.LoreLayer extends NotationLayer {
	public static var __className:String = "efd.Cartographer.gui.Layers.LoreLayer";

	private function LoreLayer() {
		super();
		createEmptyMovieClip("ClaimedLoreSublayer", getNextHighestDepth());
		createEmptyMovieClip("UnclaimedLoreSublayer", getNextHighestDepth());
		RenderedClaimedWaypoints = new Array();
		RenderedUnclaimedWaypoints = new Array();
		Lore.SignalTagAdded.Connect(LorePickedUp, this);
	}

	public function RenderWaypoints(newZone:Number):Void {
		ClaimedCount = 0;
		UnclaimedCount = 0;
		super.RenderWaypoints(newZone);
	}

	private function AttachWaypoint(data:LorePoint, mapPos:Point):Void {
		var claim:String = Lore.IsLocked(data.LoreID) ? "Unclaimed" : "Claimed";
		var existing:WaypointIcon = this["Rendered" + claim + "Waypoints"][this[claim + "Count"]];
		this[claim + "Count"] += 1;
		if (existing) {
			if (Refresh) {
				existing.UpdatePosition(mapPos);
				LoadSequential();
			} else { existing.Reassign(data, mapPos); }
		} else {
			var targetClip:MovieClip = this[claim + "LoreSublayer"];
			var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + targetClip.getNextHighestDepth(), targetClip, targetClip.getNextHighestDepth(), {Data : data, _x : mapPos.x, _y : mapPos.y, LayerClip: this}));
			wp.SignalWaypointLoaded.Connect(LoadSequential, this);
			wp.LoadIcon();
			this["Rendered" + claim + "Waypoints"].push(wp);
		}
	}

	private function ClearDisplay(partialClear:Number):Void {
		if (partialClear == undefined) {
			ClaimedCount = 0;
			UnclaimedCount = 0;
		}
		for (var i:Number = ClaimedCount; i < RenderedClaimedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedClaimedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedClaimedWaypoints.splice(ClaimedCount);
		for (var i:Number = UnclaimedCount; i < RenderedUnclaimedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedUnclaimedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedUnclaimedWaypoints.splice(UnclaimedCount);
	}

	// First param appears to be tagID (loreID)
	// Second param is referred to as character ID, copying the verification from elsewhere in the game library, uncertain if it's actualy needed
	private function LorePickedUp(loreID:Number, character:ID32):Void {
		if (Lore.GetTagType(loreID) == _global.Enums.LoreNodeType.e_Lore && character.Equal(Character.GetClientCharID())) {
			var matches:Number = 0;
			for (var i:Number = 0; i < RenderedUnclaimedWaypoints.length; ++i) {
				var targetWP:WaypointIcon = RenderedUnclaimedWaypoints[i];
				if (targetWP.Data["LoreID"] == loreID) {
					// Create new waypoint on the claimed list
					var targetClip:MovieClip = ClaimedLoreSublayer;
					var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
						WaypointIcon, "WP" + targetClip.getNextHighestDepth(), targetClip, targetClip.getNextHighestDepth(),
						{Data : targetWP.Data, _x : targetWP._x, _y : targetWP._y}));
					wp.SignalWaypointLoaded.Connect(DeferLoaderHook, this);
					wp.LoadIcon();
					RenderedClaimedWaypoints.push(wp);
					// Remove the old waypoint
					RenderedUnclaimedWaypoints[i].Unload();
					RenderedUnclaimedWaypoints[i].removeMovieClip();
					// Copy a low index waypoint overtop
					RenderedUnclaimedWaypoints[i] = RenderedUnclaimedWaypoints[matches];
					matches += 1;
				}
			}
			// Clear the bottom x indicies
			RenderedUnclaimedWaypoints.splice(0, matches);
		}
	}

	private function DeferLoaderHook(waypoint:WaypointIcon):Void {
		// HACK: Adding and removing signals during the signal handling is risky
		//   It only really works because this is the last(only) signal in the queue
		//   So it is processing slot i, which is disconnected then replaced, and the new slot is skipped
		waypoint.SignalWaypointLoaded.Disconnect(DeferLoaderHook, this);
		waypoint.SignalWaypointLoaded.Connect(LoadSequential, this);
	}

	public function get RenderedWaypoints():Array {
		return RenderedClaimedWaypoints.concat(RenderedUnclaimedWaypoints);
	}

	private var ClaimedLoreSublayer:MovieClip;
	private var UnclaimedLoreSublayer:MovieClip;

	private var ClaimedCount:Number;
	private var UnclaimedCount:Number;

	private var RenderedClaimedWaypoints:Array;
	private var RenderedUnclaimedWaypoints:Array;
}
