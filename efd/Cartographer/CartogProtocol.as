// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

// Currently just a thin sample wrapper around the MIP base class for testing of proof of concept
// Will eventually be expanded into a system for other mods to interact with Cartographer more usefully

import com.Utils.Signal;

import efd.Cartographer.lib.sys.InteropProtocol;
import efd.Cartographer.lib.sys.mip.MipPacket;

class efd.Cartographer.CartogProtocol extends InteropProtocol {
	public function CartogProtocol(info:Object) {
		super("Cartog", AdjustInfo(info));
		
		SignalTestMsg = new Signal();
	}
	
	private function ProcessUserProtocol(msg:MipPacket):Boolean {
		if (msg.Message == "TestMsg") {
			SignalTestMsg.Emit();
			return true;
		}
		return false;
	}
	
	private static function AdjustInfo(info:Object):Object {
		info.ProtocolVersion = CnpVersion;
		return info;
	}
	
	private static var CnpVersion:String = "0.0.1"; // Placeholder
	
	public var SignalTestMsg:Signal;
}
