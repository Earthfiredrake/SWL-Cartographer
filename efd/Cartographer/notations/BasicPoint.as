// Copyright 2017, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

// Notes on game waypoint files:
// Default waypoint files are malformed, the XML parser included in flash chokes on them
// Custom waypoint files are largely inaccessible:
//   The flash file loader doesn't like to use absolute paths to other drives, or system paths
//   There also seems to be no way short of a user prompt to get their OS or SWL usernames (both required for the path)
// The data remains potentially valuable, though given the lack of ability to parse existing files a custom format for my own data seems reasonable
// The following waypoint types have been observed in the default file:
//   Point of interest: Does not have a visible overlay, but does provide a tooltip for streetnames and locations etc.
//   Transitions: Region, Agartha, and Dungeon transition waypoints
//   Vendors: Though not all of them
// In all cases they provide localized text through the rdb
// Standard waypoints which appear to be provided entirely from the backend side:
//   Anima Wells: And the anima leap subsystem
//   Missions: Side mission and NPC locations, as well as their current state (incomplete (also in progress or paused), on cooldown, complete)
//	 Champion markers: Some form of enhanced proximity detection involved here
// Data for these will have to be acquired or sourced, preferably including localized info
// Some of the more complex aspects (Anima Leap, mob detection) may not actually be exposed for modding

// Notes on waypoint data
// Basic (point) waypoints require:
// Position in world coordinates (x,z (y/height useful at all? maybe for tiered zones?))
//   Also Zone... that's slightly important
// Descriptive text, preferably localized as much as possible
//   Label: Appears on the map. Use minimally to avoid excessive clutter. In most cases this should only be a copy of the tooltip title (would a checkbox be enough?)
//   Name: Tooltip title. Game localization can be used for many of these when provided by the mod, including: Lore topics, monsters, anything from the default file, missions and sources
//   Note: Further details contained in tooltip. Manual localization support
// Category: How to group the waypoint for filtering or other purposes. Support for multiple categories (ie: samhain + lore)? How many custom categories can/should be provided?
//   Category may also affect some background processing, which would restrict the user from adding their own waypoints directly for certain things
//     - Lore, mobs, missions... Should I bake autopopulation tools into this mod, or provide them as utlity mods on the side?
//     - Leaning towards the second option, as it would provide more flexible integration options, and duplicate a minimal amount of LoreHound code on this side
//   Subcategories: ? Is there any need, or would a combination of careful categorization + per-waypoint icons be enough?
// Icon: The icon to use for the waypoint, possibly user provided
// What other useful bits and pieces of information might there be?
// How much of this can be done on a default or tiered basis to avoid redundancy or duplication?

import flash.geom.Point;

import efd.Cartographer.inf.IWaypoint;
import efd.Cartographer.notations.NotationBase;

class efd.Cartographer.notations.BasicPoint extends NotationBase implements IWaypoint {
	public function BasicPoint(xml:XMLNode) {
		super(xml);
		Icon = xml.attributes.icon ? xml.attributes.icon : GetDefaultIcon(xml.nodeName);
		Position = new Point(Number(xml.attributes.x), Number(xml.attributes.y));
	}

	private static function GetDefaultIcon(typeName:String):String {
		switch (typeName) {
			case "AnimaWell": return "well.png";
			case "Krampus": return "champ.png";
			case "Vendor": return "service_vendor.png";
			default: return undefined;
		}
	}

	// Interface implementation
	public function GetType():String { return "wp"; }

	public function GetPosition():Point { return Position; }
	public function GetIcon():String { return Icon; }
	public function TintIcon():Boolean { return false; }
	public function GetIconModifier():Array { return undefined; }

	/// Data fields
	private var Position:Point; // World space coordinates

	private var Icon:String;
}
