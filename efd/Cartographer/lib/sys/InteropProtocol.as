// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

// Everything here is to be considered tentative until the community has had a chance to poke holes in it
//   Early adoptors may find things changing underfoot

// Base class for inter-mod communication protocols
// Allows mods to declare that they are either server or client for the subclassing protocol
//   and provides limited duplex communication (addressed or broadcast) with those in the other mode
// Handles basic functions (DV based 'ports', unique IDs, mod discovery, and error reporting?) with a minimal protocol definition

// Custom protocols are expected to be implemented as subclasses overriding ProcessUserProtocol
//   General advice for using code from other developers also applies, which can be found in Mod.as of the EFD Mod Framework
//   Notifications back to the local mod can be handled in whatever way the author feels is reasonable
//     This implementation makes use of Signals, but they could be changed with no affect on the compatibility of the system
//     Recommend that an author remove or simplify Signals they don't need (though keep the "return true" to avoid errors)
//       This will reduce the amount of processing needed by the somewhat awkward MipPacket system
//   (once finalized) Most other code should remain functionally unchanged in order to maintain compatibility with the standard

// The DV ports are unique to the protocol, but are shared by all the registered mods
// DV listeners are notified immediately and sequentially when the DV is changed, with no queuing, which can cause several issues:
//   Broadcast messages run a major risk of having the original message stomped by anything longer than a basic reply
//     Error messages have been given their own exclusive DV ports so that they don't stomp data
//     I may have a solution that involves stashing packets,
//       How to prevent a mod from replying to a packet a second time when it comes back up
//       but ensure that a mod does reply to every packet it should
//       My current thoughts on this may require moving everything into a single DV port
//     QUERY: Anybody got a better solution?
//   Particularly long message chains could cause noticable performance hitches, or possibly cause a stack overflow
//     Recommend that communications be limited to shout notifications or paired request-response
//   ProcessUserProtocol may end up being called recursively, and should be designed to be re-entrant

// Registration as both a client and server for a single protocol may cause difficult behaviour
//   there is no allowance to detect self originating broadcast messages in this case
//   QUERY: Is there a reasonable use case for which this would be the best option?
// Multiple different protocols, as long as they have independent interface objects, should not be a problem

// Once released, protocols should be maintained as backwards compatible to avoid breaking mods that make use of them
//   This includes supported message identifiers, their expected supporting data types, and any communication patterns
//   Basic version identification is provided to help support different mods compiled to different protocol versions

import com.GameInterface.DistributedValue;
import com.Utils.Signal;

import efd.Cartographer.lib.Mod;
import efd.Cartographer.lib.sys.mip.MipPacket;

class efd.Cartographer.lib.sys.InteropProtocol {

	// The info object is the one which will be passed with any MipOpen/MipAckOpen messages for this mod
	//   It should already be largely initialized by the mod and the subclass, only requiring the MIP version to be added
	// Protocol name should be provided by the subclass, while isServer will be passed through from the mod's initialization
	private function InteropProtocol(protocol:String, isServer:Boolean, info:Object) { // Abstract base
		Protocol = protocol;
		IsServer = isServer;
		LocalInfo = info;
		LocalInfo.MipVersion = MipVersion;

		var mode:String = IsServer ? "Server" : "Client";
		var other:String = IsServer ? "Client" : "Server";
		InPort = DistributedValue.Create("mip" + Protocol + mode + "Port");
		OutPort = DistributedValue.Create("mip" + Protocol + other + "Port");
		InErr = DistributedValue.Create("mip" + Protocol + mode + "Err");
		OutErr = DistributedValue.Create("mip" + Protocol + other + "Err");
		IDSource = DistributedValue.Create("mip" + Protocol + mode + "IDSource");

		SignalRemoteOpen = new Signal();
		SignalRemoteClosed = new Signal();
		SignalError = new Signal();
	}

/// Connections

	// Call when the mod is ready to start processing messages (after data has been loaded and signals hooked)
	public function Connect():Void {
		if (LocalID != -1) { return; }
		GetID();
		InErr.SignalChanged.Connect(ReceiveErr, this);
		InPort.SignalChanged.Connect(ReceivePacket, this);		
		SendMsg(MipOpen, LocalInfo);
	}

	// Data field may be ommited/undefined depending on the message being sent
	// Recipient field is left undefined if doing a broadcast
	public function SendMsg(msg:String, data:Object, recipient:Number):Void {
		OutPort.SetValue(new MipPacket(LocalID, recipient, msg, data).ToArchive());
	}

	// All fields should be filled, no broadcast for errors
	private function SendErr(msg:String, data:Object, recipient:Number):Void {
		OutErr.SetValue(new MipPacket(LocalID, recipient, msg, data).ToArchive());
	}

	// Call this if your mod will not be accepting further messages on this protocol
	// It should be called by your mod's OnUnload()
	//   /reloadui doesn't explicitly reset DVs, IDSource values can end up artificially inflated, resulting in empty blocks at the bottom of arrays
	public function Disconnect():Void {
		if (LocalID == -1) { return; }
		SendMsg(MipClose);
		InPort.SignalChanged.Disconnect(ReceivePacket, this);
		InErr.SignalChanged.Disconnect(ReceiveErr, this);
		FreeID();
	}

	private function ReceivePacket(dv:DistributedValue):Void {
		var msg:MipPacket = MipPacket.FromArchive(dv.GetValue());
		if (msg.Recipient == undefined || msg.Recipient == LocalID) {
			if (ProcessMipCore(msg)) { return; }
			if (ProcessUserProtocol(msg)) { return; }
			SendErr(ErrUnknownMsg, msg, msg.Sender);
		}
	}

	private function ReceiveErr(dv:DistributedValue):Void {
		var err:MipPacket = MipPacket.FromArchive(dv.GetValue());
		if (err.Recipient == LocalID) {
			if (ProcessMipErr(err)) { return; }
			if (ProcessUserProtocolErr(err)) { return; }
			SignalError.Emit("Error (" + err.Message + ") when sending message (" + err.Data.Message + ") was not handled by protocol (" + Protocol + ")");
		}
	}

/// Protocol porcessing

	private function ProcessMipCore(msg:MipPacket):Boolean {
		switch (msg.Message) {
			case MipOpen: {
				SignalRemoteOpen.Emit(msg.Sender, msg.Data);
				SendMsg(MipAckOpen, LocalInfo, msg.Sender);
				return true;
			}
			case MipAckOpen: {
				SignalRemoteOpen.Emit(msg.Sender, msg.Data);
				return true;
			}
			case MipClose: {
				SignalRemoteClosed.Emit(msg.Sender);
				return true;
			}
			default: { return false; }
		}
	}

	private function ProcessMipErr(err:MipPacket):Boolean {
		switch (err.Message) {
			case ErrUnknownMsg: {
				SignalError.Emit("Message (" + err.Data.Message + ") is not part of protocol (" + Protocol + ")");
				return true;
			}
			case ErrInvalidData: {
				SignalError.Emit("Data for message (" + err.Data.Message + ") did not have values expected by protocol (" + Protocol + ")");
				return true;
			}
			default: { return false; }
		}
	}

	// For subclass protocol
	//   You will only recieve messages not defined in the core MIP protocol
	//   Return true if the protocol defines and handles the provided message
	private function ProcessUserProtocol(msg:MipPacket):Boolean { return false; }
	private function ProcessUserProtocolErr(err:MipPacket):Boolean { return false; }

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
	private static var MipVersion:String = "0.0.1"; // Placeholder version
	private var Protocol:String; // Name of this protocol; Used to create DV names and provide error report details; subclasses should pass overriden name to constructor

	private var InPort:DistributedValue; // Port for inbound messages (matching requested client/server mode)
	private var OutPort:DistributedValue; // Port for sent messages (matching other mode)
	// Dedicated error ports
	private var InErr:DistributedValue;
	private var OutErr:DistributedValue;
	private var IDSource:DistributedValue; // Source for the LocalID (a slightly glorified counter)

	private var IsServer:Boolean; // Useful when a protocol has different behaviour between server and client modes
	private var LocalID:Number = -1; // This mod's ID for this particular protocol
	private var LocalInfo:Object; // Assorted identifying information passed with an Open or AckOpen message

	// Internal MIP messages
	private static var MipOpen:String = "MipOpen"; // Data = { ModName:String, ModVersion:String, DevName:String, MipVersion:String, ProtocolVersion:String }
	private static var MipAckOpen:String = "MipAckOpen"; // Response to a MipOpen request; same data format
	private static var MipClose:String = "MipClose"; // No data, senderID available if needed
	// Error messages, include the offending MipPacket in the Data field
	private static var ErrUnknownMsg:String = "ErrUnknownMsg";
	private static var ErrInvalidData:String = "ErrInvalidData";

	// Local mod notifications, not required by the interop interface
	public var SignalRemoteOpen:Signal; // Func(senderID:Number, info:Object); info object with information used to identify the mod and protocol version support
	public var SignalRemoteClosed:Signal; // Func(senderID:Number); sender can still receive replies but be careful about triggering message chains
	public var SignalError:Signal; // Func(desc:String); string describing the error; used for all error messages
}
