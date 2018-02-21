// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

// Everything here is to be considered tentative until the community has had a chance to poke holes in it
//   Early adoptors may find things changing underfoot

// Base class for inter-mod communication protocols
//   DV based communication port for mods with a shared protocol to transfer messages (addressed or broadcast)
//   Minimalist base protocol offering mod query and error notifications for extending protocols

// Custom protocols are expected to be implemented as subclasses overriding ProcessUserProtocol
//   General advice for using code from other developers applies, which can be found in Mod.as of the EFD Mod Framework
//   Notifications back to the local mod can be handled in whatever way the author feels is reasonable
//     This implementation makes use of Signals, but they could be changed with no affect on the compatibility of the system
//     Recommend that an author remove or simplify Signals they don't need (though keep the "return true" to avoid errors)
//       This will reduce the amount of processing needed by the somewhat awkward MipPacket system
//   (once finalized) Most other code should remain functionally unchanged in order to maintain compatibility with the standard

// The DV port is shared by all mods that make use of a partcular (named) protocol
// DV listeners are notified immediately and sequentially when the DV is changed, with no queuing, which can cause several issues:
//   Particularly long message sequences, especially between large sets of mods, could cause noticable performance hitches or possibly a stack overflow
//   ProcessUserProtocol may end up being called recursively, and should be designed to be re-entrant
//   Messages can often be processed out of order when triggered by previous messages
//     'A', 'B' and 'C' are mods that have been created in that order. 'A' broadcasts a message, 'B' responds by sending a message to 'C' which 'C' will process before it handles the broadcast from 'A'
//     A somewhat Indiana Jonesy distributed queue will ensure that all messages do eventually get processed, and only once
//     Unsure what happens if you disconnect in the middle of messages being processed, though side effects should be isolated to the disconnecting mod

// A single mod can have multiple protocol interfaces, even of the same protocol if that is useful:
//   It will consider them to be different mods, so cross communication between the interfaces should be anticipated

// Once released, protocols should be maintained as backwards compatible to avoid breaking mods that make use of them
//   This includes supported message identifiers, their expected supporting data types, and any communication patterns
//   Basic version identification is provided to help support different mods compiled to different protocol versions

import com.GameInterface.DistributedValue;
import com.Utils.Signal;

import efd.Cartographer.lib.sys.mip.MipPacket;

class efd.Cartographer.lib.sys.InteropProtocol {

	// The info object is the one which will be passed with any Join/Info messages from this mod
	//   It should already be largely initialized by the mod and the subclass, only requiring the MIP version to be added
	// Protocol name should be provided by the subclass
	private function InteropProtocol(protocol:String, info:Object) { // Abstract base
		Protocol = protocol;
		LocalInfo = info;
		LocalInfo.MipVersion = MipVersion;

		ComPort = DistributedValue.Create("mip" + Protocol + "Port");
		RecursionCounter = DistributedValue.Create("mip" + Protocol + "RecurCount");
		if (RecursionCounter.GetValue() == null) { RecursionCounter.SetValue(0); }
		IDSource = DistributedValue.Create("mip" + Protocol + "IDSource");

		SignalModJoined = new Signal();
		SignalModLeft = new Signal();
		SignalModInfo = new Signal();
		SignalError = new Signal();
	}

/// Connections

	// Call when the mod is ready to start processing messages (after data has been loaded and signals hooked)
	public function Connect():Void {
		if (LocalID != -1) { return; }
		GetID();
		ComPort.SignalChanged.Connect(ReceivePacket, this);		
		SendMsg(MipJoin, LocalInfo);
	}

	// Data field may be ommited/undefined depending on the message being sent
	// Recipient field is left undefined if doing a broadcast
	public function SendMsg(msg:String, data:Object, recipient:Number):Void {
		// Stashes the previous message (if any) then sends the new one, when that returns (indicating that all recipients have processed it) restore the previous message
		// The restored message will have the wrong recursion number, suppressing change notification until it resumes the original set of change notifications
		PacketStash.push(ComPort.GetValue());
		ComPort.SetValue(new MipPacket(RecursionCounter.GetValue(), LocalID, recipient, msg, data).ToArchive());
		ComPort.SetValue(PacketStash.pop());
	}

	// Call this if your mod will not be accepting further messages on this protocol
	// It should be called by your mod's OnUnload()
	//   /reloadui doesn't explicitly reset DVs, IDSource values can end up artificially inflated, resulting in empty blocks at the bottom of arrays
	public function Disconnect():Void {
		if (LocalID == -1) { return; }
		SendMsg(MipLeave);
		ComPort.SignalChanged.Disconnect(ReceivePacket, this);
		FreeID();
	}

	private function ReceivePacket(dv:DistributedValue):Void {
		var recNum = RecursionCounter.GetValue();
		RecursionCounter.SetValue(recNum + 1);
		var msg:MipPacket = MipPacket.FromArchive(dv.GetValue());
		// Ignore the packet if:
		//   Sequence number is wrong (it's a newly unstashed message with handlers already waiting)
		//   Broadcast originating from self
		//   Addressed to different mod
		if (msg.RecNum == recNum && ((msg.Recipient == undefined && msg.Sender != LocalID) || msg.Recipient == LocalID)) {
			if (!(ProcessMipCore(msg) || ProcessUserProtocol(msg))) {
				SendMsg(ErrUnknownMsg, msg, msg.Sender);
			}
		}
		RecursionCounter.SetValue(recNum);
	}

/// Protocol porcessing

	// QUERY: Does it make sense to treat Join as an implicit Query?
	private function ProcessMipCore(msg:MipPacket):Boolean {
		switch (msg.Message) {			
			case MipJoin: { SignalModJoined.Emit(msg.Sender, msg.Data); } // Fallthrough intended
			case MipQuery: {
				SendMsg(MipInfo, LocalInfo, msg.Sender);
				return true;
			}
			case MipInfo: {
				SignalModInfo.Emit(msg.Sender, msg.Data);
				return true;
			}
			case MipLeave: {
				SignalModLeft.Emit(msg.Sender);
				return true;
			}
			case ErrUnknownMsg: {
				SignalError.Emit("Message (" + msg.Data.Message + ") is not part of protocol (" + Protocol + ")");
				return true;
			}
			case ErrInvalidData: {
				SignalError.Emit("Data for message (" + msg.Data.Message + ") did not have values expected by protocol (" + Protocol + ")");
				return true;
			}
			default: { return false; }
		}
	}

	// For subclass protocol
	//   You will only recieve messages not defined in the core MIP protocol
	//   Return true if the protocol defines and handles the provided message
	private function ProcessUserProtocol(msg:MipPacket):Boolean { return false; }

/// ID system
	// Gets an ID from the IDSource, and pushes it to the next free value
	private function GetID():Void {
		if (LocalID != -1) { return; }
		LocalID = IDSource.GetValue();
		if (LocalID == null) { LocalID = 0; }
		IDSource.SetValue(LocalID + 1);
		IDSource.SignalChanged.Connect(GuardID, this);
	}

	// Protect our ID from collisions
	private function GuardID(dv:DistributedValue):Void {
		if (dv.GetValue() == LocalID) { dv.SetValue(LocalID + 1); }
	}

	// Frees this ID, permitting its use elsewhere (and avoiding running the DV counter up)
	private function FreeID():Void {
		if (LocalID == -1) { return; }
		IDSource.SignalChanged.Disconnect(GuardID, this);
		if (IDSource.GetValue() > LocalID) { IDSource.SetValue(LocalID); }
		LocalID = -1;
	}

/// Variables
	private static var MipVersion:String = "0.0.2"; // Placeholder version
	private var Protocol:String; // Name of this protocol; Used to create DV names and provide error report details; subclasses should pass overriden name to constructor

	private var ComPort:DistributedValue; // Communications port, across which all messages are sent
	private var IDSource:DistributedValue; // Source for the LocalID (a slightly glorified counter)
	private var RecursionCounter:DistributedValue; // Used to avoid multi-processing messages (a counter, no glory)

	private var PacketStash:Array = []; // For stashing the contents of ComPort when this mod needs to send a message

	private var LocalID:Number = -1; // This mod's ID for this particular protocol interface
	private var LocalInfo:Object; // Assorted identifying information passed with Join messages or in response to Query requests

	//
	public static var MipQuery:String = "MipQuery"; // Requests that each recipient reply with an Info packet
	// Internal MIP messages
	private static var MipJoin:String = "MipJoin"; // Uses Info data format
	private static var MipInfo:String = "MipInfo"; // Response to Join or Query request; Data = { ModName:String, ModVersion:String, DevName:String, MipVersion:String, ProtocolVersion:String }	
	private static var MipLeave:String = "MipLeave"; // No data
	// Error messages, include the offending MipPacket in the Data field
	private static var ErrUnknownMsg:String = "ErrUnknownMsg";
	private static var ErrInvalidData:String = "ErrInvalidData";

	// Local mod notifications, not required by the interop interface
	public var SignalModJoined:Signal; // Func(senderID:Number, info:Object); Info message data format
	public var SignalModLeft:Signal; // Func(senderID:Number); sender can still receive replies
	public var SignalModInfo:Signal; // Func(senderID:Number, info:Object); Info message data format
	public var SignalError:Signal; // Func(desc:String); string describing the error; shared by all error messages
}
