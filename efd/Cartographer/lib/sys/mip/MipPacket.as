// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

// Mod Interop Protocol addressing and message packet structure
// Unfortunately DVs don't accept arbitrary objects... but they do accept archives, which can be structured to hold arbitrary data
// So we have some extra hoops to jump through to pass things around
// To reduce the pain caused by the extra hoops, it deserializes lazilly
// Borrowing some code from the Config system for that

import flash.geom.Point;

import com.Utils.Archive;

class efd.Cartographer.lib.sys.mip.MipPacket {

	public function MipPacket(recNum:Number, sender:Number, recipient:Number, msg:String, data:Object, archive:Archive) {
		_RecNum = recNum;
		_Sender = sender;
		_Recipient = recipient;
		_Message = msg;
		_Data = data;
		_Archive = archive;
	}
	
	public function ToArchive():Archive {
		var archive:Archive = new Archive();
		archive.AddEntry("ArchiveType", "MipPack");
		archive.AddEntry("RecNum", RecNum);
		archive.AddEntry("Sender", Sender);
		archive.AddEntry("Recipient", Recipient);
		archive.AddEntry("Message", Message);
		archive.AddEntry("Data", Package(Data));		
		return archive;		
	}
	
	private static function Package(value:Object) {
		if (value instanceof MipPacket) { return value.ToArchive(); }
		if (value instanceof Archive) { return value; }
		if (value instanceof Point) { return value; }
		if (value instanceof Array || value instanceof Object) {
			var wrapper:Archive = new Archive();
			var values:Archive = new Archive();
			wrapper.AddEntry("ArchiveType", value instanceof Array ? "Array" : "Object");
			for (var key:String in value) {
				values.AddEntry(key, Package(value[key]));
			}
			wrapper.AddEntry("Values", values);
			return wrapper;
		}
		return value; // Basic type
	}

	public static function FromArchive(archive:Archive):MipPacket {
		return new MipPacket(null, null, null, null, null, archive);
	}

	private static function Unpack(element:Object) {
		if (element instanceof Archive) {
			var type:String = element.FindEntry("ArchiveType", null);
			if (type == null) {
				return element;	// Basic archive
			}
			switch (type) {
				case "MipPack": { return FromArchive(Archive(element)); }
				case "Array":
				case "Object": // Serialized general type
					var value = type == "Array" ? new Array() : new Object();
					var values:Archive = element.FindEntry("Values");
					for (var index:String in values["m_Dictionary"]) {
						value[index] = Unpack(values.FindEntry(index));
					}
					return value;
				default:
					return undefined;
			}
		}
		return element; // Basic type
	}
	
	public function get RecNum():Number { return _RecNum == null ? _RecNum = _Archive.FindEntry("RecNum") : _RecNum; }
	public function get Sender():Number { return _Sender == null ? _Sender = _Archive.FindEntry("Sender") : _Sender; }
	public function get Recipient():Number { return _Recipient == null ? _Recipient = _Archive.FindEntry("Recipient") : _Recipient; }
	public function get Message():String { return _Message == null ? _Message = _Archive.FindEntry("Message") : _Message; }
	public function get Data():Object { return _Data == null ? _Data = Unpack(_Archive.FindEntry("Data")) : _Data; }
	
	private var _Archive:Archive;
	private var _RecNum:Number;
	private var _Sender:Number;
	private var _Recipient:Number;
	private var _Message:String;
	private var _Data:Object;
}
