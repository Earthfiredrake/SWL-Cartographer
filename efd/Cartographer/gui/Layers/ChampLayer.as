// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.Utils.ID32;

import efd.Cartographer.lib.etu.MovieClipHelper;
import efd.Cartographer.lib.Mod;

import efd.Cartographer.Waypoints.ChampPoint;

import efd.Cartographer.gui.NotationLayer;
import efd.Cartographer.gui.WaypointIcon;

class efd.Cartographer.gui.Layers.ChampLayer extends NotationLayer {
	public static var __className:String = "efd.Cartographer.gui.Layers.ChampLayer";

	private function ChampLayer() {
		super();
		createEmptyMovieClip("DefeatedChampionsSublayer", getNextHighestDepth());
		createEmptyMovieClip("UndefeatedChampionsSublayer", getNextHighestDepth());
		RenderedDefeatedWaypoints = new Array();
		RenderedUndefeatedWaypoints = new Array();
		Lore.SignalTagAdded.Connect(AchievementUnlocked, this);
	}

	public function RenderWaypoints(newZone:Number):Void {
		DefeatedCount = 0;
		UndefeatedCount = 0;
		super.RenderWaypoints(newZone);
	}

	private function LoadNextSequential(icon:WaypointIcon) {
		var status:String = Lore.IsLocked(icon.Data["ChampID"]) ? "Undefeated" : "Defeated";
		this[status + "Count"] += 1;
		super.LoadNextSequential(icon);
	}

	private function AttachWaypoint(data:ChampPoint, mapPos:Point):Void {
		var status:String = Lore.IsLocked(data.ChampID) ? "Undefeated" : "Defeated";
		var wp:WaypointIcon = this["Rendered" + status + "Waypoints"][this[status + "Count"]];
		if (wp) {
			if (Refresh) {
				wp.UpdatePosition(mapPos);
				LoadNextSequential(wp);
			} else { wp.Reassign(data, mapPos); }
		} else {
			var targetClip:MovieClip = this[status + "ChampionsSublayer"];
			wp = WaypointIcon(MovieClipHelper.createMovieWithClass(WaypointIcon, "WP" + targetClip.getNextHighestDepth(), targetClip, targetClip.getNextHighestDepth(), { Data : data, _x : mapPos.x, _y : mapPos.y, LayerClip: this }));
			wp.SignalWaypointLoaded.Connect(LoadNextSequential, this);
			wp.LoadIcon();
			this["Rendered" + status + "Waypoints"].push(wp);
		}
	}

	private function ClearDisplay(partialClear:Number):Void {
		if (partialClear == undefined) {
			DefeatedCount = 0;
			UndefeatedCount = 0;
		}
		for (var i:Number = DefeatedCount; i < RenderedDefeatedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedDefeatedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedDefeatedWaypoints.splice(DefeatedCount);
		for (var i:Number = UndefeatedCount; i < RenderedUndefeatedWaypoints.length; ++i) {
			var waypoint:MovieClip = RenderedUndefeatedWaypoints[i];
			waypoint.Unload();
			waypoint.removeMovieClip();
		}
		RenderedUndefeatedWaypoints.splice(UndefeatedCount);
	}

	private function DeferLoaderHook(waypoint:WaypointIcon):Void {
		// HACK: Adding and removing signals during the signal handling is risky
		//   It only really works because this is the last(only) signal in the queue
		//   So it is processing slot i, which is disconnected then replaced, and the new slot is skipped
		waypoint.SignalWaypointLoaded.Disconnect(DeferLoaderHook, this);
		waypoint.SignalWaypointLoaded.Connect(LoadNextSequential, this);
	}

	private function AchievementUnlocked(cheevID:Number, character:ID32):Void {
		if (!character.Equal(Character.GetClientCharID())) {
			Mod.TraceMsg("Callback for achivement unlocked on non client character!");
		}
		if ((Lore.GetTagType(cheevID) == _global.Enums.LoreNodeType.e_Achievement ||
			 Lore.GetTagType(cheevID) == _global.Enums.LoreNodeType.e_SubAchievement)
			&& character.Equal(Character.GetClientCharID())) {
			var matches:Number = 0;
			for (var i:Number = 0; i < RenderedUndefeatedWaypoints.length; ++i) {
				var targetWP:WaypointIcon = RenderedUndefeatedWaypoints[i];
				if (targetWP.Data["ChampID"] == cheevID) {
					// Create new waypoint on the claimed list
					var targetClip:MovieClip = DefeatedChampionsSublayer;
					var wp:WaypointIcon = WaypointIcon(MovieClipHelper.createMovieWithClass(
						WaypointIcon, "WP" + targetClip.getNextHighestDepth(), targetClip, targetClip.getNextHighestDepth(),
						{Data : targetWP.Data, _x : targetWP._x, _y : targetWP._y}));
					wp.SignalWaypointLoaded.Connect(DeferLoaderHook, this);
					wp.LoadIcon();
					RenderedDefeatedWaypoints.push(wp);
					// Remove the old waypoint
					RenderedUndefeatedWaypoints[i].Unload();
					RenderedUndefeatedWaypoints[i].removeMovieClip();
					// Copy a low index waypoint overtop
					RenderedUndefeatedWaypoints[i] = RenderedUndefeatedWaypoints[matches];
					matches += 1;
				}
			}
			// Clear the bottom x indicies
			DefeatedCount += matches;
			UndefeatedCount -= matches;
			RenderedUndefeatedWaypoints.splice(0, matches);
		}
	}

	public function get RenderedWaypoints():Array {
		return RenderedDefeatedWaypoints.concat(RenderedUndefeatedWaypoints);
	}

	private var DefeatedChampionsSublayer:MovieClip;
	private var UndefeatedChampionsSublayer:MovieClip;

	private var RenderedDefeatedWaypoints:Array;
	private var RenderedUndefeatedWaypoints:Array;

	private var DefeatedCount:Number;
	private var UndefeatedCount:Number;
}
