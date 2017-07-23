// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

import gfx.utils.Delegate;

import com.Components.WindowComponentContent;
import com.GameInterface.Game.Character;
import com.GameInterface.MathLib.Vector3;

import efd.Cartographer.lib.Mod;

class efd.Cartographer.gui.InterfaceWindowContent extends WindowComponentContent {

	private function InterfaceWindowContent() { // Indirect construction only
		super();
		CurrentMapDisplaySize = new Point(900, 900);
		CurrentMapWorldSize = new Point(1024, 1024);
		ClientChar = Character.GetClientCharacter();
	}

// Notes on game waypoint files:
// Default waypoint files are malformed, the XML parser included in flash chokes on them
// Custom waypoint files are largely inaccessible:
//   The flash file loader doesn't like to use absolute paths to other drives, or system paths
//   There also seems to be no way short of a user prompt to get their OS or SWL usernames (both required for the path)
// The data remains potentially valuable, though given the lack of ability to parse existing files a custom format for my own data seems reasonable
// The following waypoint types have been observed in the default file:
//   Point of interest: Does not have a visible overlay, but does provide a tooltip for streetnames and locations etc.
//   Transitions: Region, Agartha, and Dungeon transition waypoints
//   Vendors
// In all cases they provide localized text through the rdb
// Standard waypoints which appear to be provided entirely from the backend side:
//   Anima Wells: And the anima leap subsystem
//   Missions: Side mission and NPC locations, as well as their current state (incomplete (also in progress or paused), on cooldown, complete)
//	 Champion markers: Some form of enhanced proximity detection involved here
// Data for these will have to be acquired or sourced, preferably including localized info
// Some of the more complex aspects (Anima Leap, mob detection) may not actually be exposed for modding

// Notes on waypoint data
// Basic (point) waypoints should have:
// Position in world coordinates (x,z (y/height useful at all? maybe for tiered zones?))
// Descriptive text, preferably localized as much as possible
//   Label: Appears on the map. Use minimally to avoid excessive clutter. In most cases this should only be a copy of the tooltip title (would a checkbox be enough?)
//   Name: Tooltip title. Game localization can be used for many of these when provided by the mod, including: Lore topics, monsters, anything from the default file, missions and sources
//   Details: Further details contained in tooltip. Manual localization support
// Category: How to group the waypoint for filtering or other purposes. Support for multiple categories (ie: samhain + lore)? How many custom categories can/should be provided?
//   Category may also affect some background processing, which would restrict the user from adding their own waypoints directly for certain things
//     - Lore, mobs, missions... Should I bake autopopulation tools into this mod, or provide them as utlity mods on the side?
//     - Leaning towards the second option, as it would provide more flexible integration options, and duplicate a minimal amount of LoreHound code on this side
//   Subcategories: ? Is there any need, or would a combination of careful categorization + per-waypoint icons be enough?
// Icon Type: The icon to use for the waypoint. Is there any way to let the user provide custom icons?
// What other useful bits and pieces of information might there be?

	private function onEnterFrame():Void {
		UpdateClientCharMarker();
	}

	private function UpdateClientCharMarker():Void {
		if (ClientChar.GetPlayfieldID() == CurrentMapID) {
			PlayerMarker._visible = true;
			var worldPos:Vector3 = ClientChar.GetPosition(0);
			var mapPos:Point = WorldToWindowCoords(new Point(worldPos.x, worldPos.z));
			PlayerMarker._x = mapPos.x;
			PlayerMarker._y = mapPos.y;
			PlayerMarker._rotation = RadToDegRotation(-ClientChar.GetRotation());
		} else {
			PlayerMarker._visible = false;
		}
	}

	/// Conversion routines
	private function WorldToWindowCoords(worldCoords:Point):Point {
		return new Point(
			worldCoords.x * CurrentMapDisplaySize.x / CurrentMapWorldSize.x,
			CurrentMapDisplaySize.y - (worldCoords.y * CurrentMapDisplaySize.y / CurrentMapWorldSize.y));
	}

	private function WindowToWorldCoords(windowCoords:Point):Point {
		return new Point(
			windowCoords.x * CurrentMapWorldSize.x / CurrentMapDisplaySize.x ,
			(CurrentMapDisplaySize.y - windowCoords.y) * CurrentMapWorldSize.y / CurrentMapDisplaySize.y);
	}

	private function RadToDegRotation(radians:Number):Number {
		return radians * 180 / Math.PI;
	}

	/// TODO: Data outsourcing
	private var CurrentMapID:Number = 3030; // Currently locked to KM
	private var CurrentMapDisplaySize:Point;
	private var CurrentMapWorldSize:Point;
	private var ClientChar:Character;

	/// GUI Elements
	private var PlayerMarker:MovieClip;
	private var TestWell:MovieClip;
}
