// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import com.Utils.WeakPtr;

class efd.Cartographer.lib.util.WeakDelegate {
	// Holds a weak reference to the object context used as 'this' by the wrapped function
	// Use to avoid circular references that keep objects alive past the destruction of their root
	// If the target object no longer exists, does not call wrapped function to avoid side effects
	public static function Create(obj:Object, func:Function):Function {
		var f = function() {
			var target:Object = arguments.callee.target.Get();
			var _func:Function = arguments.callee.func;
			return target != undefined ? _func.apply(target, arguments) : undefined;
		};
		f.target = new WeakPtr(obj);
		f.func = func;
		return f;
	}
}
