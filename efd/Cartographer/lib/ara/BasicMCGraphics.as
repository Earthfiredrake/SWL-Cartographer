// Copyright 2017, by Aralicia
// Used and redistributed under the terms of the MIT License
// Edited for Cartographer:
//   https://github.com/Earthfiredrake/TSW-Cartographer

import flash.geom.Point;

class efd.Cartographer.lib.ara.BasicMCGraphics {
	public static function setup() {
		if (MovieClip.prototype.drawRect == undefined) {
			MovieClip.prototype.drawRect = function(x:Number, y:Number, w:Number, h:Number) {
				this.moveTo(x, y);
				this.lineTo(x + w, y);
				this.lineTo(x + w, y + h);
				this.lineTo(x, y + h);
				this.lineTo(x, y);
			};
		}
		if (MovieClip.prototype.drawCurve == undefined) {
			MovieClip.prototype.drawCurve = function(origin, anchor, controlA, controlB, move) {
				if (controlB == undefined || controlB == null) controlB = controlA;
				if (move == undefined) move = false;
				origin = (origin instanceof  Point ? origin : (origin instanceof  Array ? new Point(origin[0], origin[1]) : new Point(origin.x, origin.y)));
				anchor = (anchor instanceof  Point ? anchor : (anchor instanceof  Array ? new Point(anchor[0], anchor[1]) : new Point(anchor.x, anchor.y)));
				controlA = (controlA instanceof  Point ? controlA : (controlA instanceof Array ? new Point(controlA[0], controlA[1]) : new Point(controlA.x, controlA.y)));
				controlB = (controlB instanceof  Point ? controlB : (controlB instanceof Array ? new Point(controlB[0], controlB[1]) : new Point(controlB.x, controlB.y)));

				var a0:Point = origin;
				var a1:Point = new Point((27 * origin.x + 27 * controlA.x + 9 * controlB.x + anchor.x) / 64, (27 * origin.y + 27 * controlA.y + 9 * controlB.y + anchor.y) / 64);
				var a2:Point = new Point((origin.x + 3 * controlA.x + 3 * controlB.x + anchor.x) / 8, (origin.y + 3 * controlA.y + 3 * controlB.y + anchor.y) / 8);
				var a3:Point = new Point((origin.x + 9 * controlA.x + 27 * controlB.x + 27 * anchor.x) / 64, (origin.y + 9 * controlA.y + 27 * controlB.y + 27 * anchor.y) / 64);
				var a4:Point = new Point(anchor.x, anchor.y);
				var c1:Point = new Point((5 * origin.x + 3 * controlA.x) / 8, (5 * origin.y + 3 * controlA.y) / 8);
				var c2:Point = new Point((7 * origin.x + 15 * controlA.x + 9 * controlB.x + anchor.x) / 32, (7 * origin.y + 15 * controlA.y + 9 * controlB.y + anchor.y) / 32);
				var c3:Point = new Point((origin.x + 9 * controlA.x + 15 * controlB.x + 7 * anchor.x) / 32, (origin.y + 9 * controlA.y + 15 * controlB.y + 7 * anchor.y) / 32);
				var c4:Point = new Point((3 * controlB.x + 5 * anchor.x) / 8, (3 * controlB.y + 5 * anchor.y) / 8);

				if (move) {
					this.moveTo(a0.x, a0.y);
				}
				this.curveTo(c1.x, c1.y, a1.x, a1.y);
				this.curveTo(c2.x, c2.y, a2.x, a2.y);
				this.curveTo(c3.x, c3.y, a3.x, a3.y);
				this.curveTo(c4.x, c4.y, a4.x, a4.y);
			};
		}
		if (MovieClip.prototype.drawEllipse == undefined) {
			MovieClip.prototype.drawEllipse = function(x:Number, y:Number, w:Number, h:Number) {
				var r:Number = 0.224108; // = (1 - 0.551784) / 2
				var hw:Number = w / 2;
				var hh:Number = h / 2;
				var rw:Number = w * r;
				var rh:Number = h * r;

				this.moveTo(x+hw, y);
				this.drawCurve([x + hw, y], [x + w, y + hh], [x + w - rw, y], [x + w, y + rh], false);
				this.drawCurve([x + w, y + hh], [x + hw, y + h], [x + w, y + h - rh], [x + w - rw, y + h], false);
				this.drawCurve([x + hw, y + h], [x, y + hh], [x + rw, y + h], [x, y + h - rh], false);
				this.drawCurve([x, y + hh], [x + hw, y], [x, y + rh], [x + rw, y], false);
			};
		}
	}
}