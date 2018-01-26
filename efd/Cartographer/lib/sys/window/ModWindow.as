// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-Cartographer

import gfx.utils.Delegate;

import com.Components.WinComp;
import com.GameInterface.DistributedValue;
import com.GameInterface.EscapeStack;
import com.GameInterface.EscapeStackNode;

class efd.Cartographer.lib.sys.window.ModWindow extends WinComp {
	private function ModWindow() { // Indirect construction
		super();

		m_ShowFooter = false;
		m_ShowResize = false;
		m_ShowStroke = false;

		EscNode = new EscapeStackNode();
		EscNode.SignalEscapePressed.Connect(TriggerWindowClose, this);
		EscapeStack.Push(EscNode);

		ResolutionScaleDV = DistributedValue.Create("GUIResolutionScale");
		ResolutionScaleDV.SignalChanged.Connect(SetResolutionScale, this);
		SetResolutionScale(ResolutionScaleDV);
	}

	private function configUI():Void {
		super.configUI();
		if (m_ShowResize) {
			// Disable WinComp's buggy event handling
			m_ResizeButton.onPress = function() {}; // undefined ?? Is there some need to put a no-op function here?
			m_ResizeButton.onRelease = undefined;
			m_ResizeButton.onReleaseOutside = undefined;

			// Setup alternate resize handler (based on AchivementWindow)
			m_ResizeButton.onMousePress = Delegate.create(this, SlotResizePress);
			m_ResizeButton.onMouseUp = Delegate.create(this, SlotResizeRelease);
			m_ResizeButton.onMouseMove = Delegate.create(this, SlotResizeMove);
			m_ResizeButton.disableFocus = true;
		}
	}

	private function onUnload():Void {
		super.onUnload();
	}

	public function PermitResize(limits:Object):Void {
		SetMinHeight(limits.Min.y);
		SetMinWidth(limits.Min.x);
		SetMaxHeight(limits.Max.y);
		SetMaxWidth(limits.Max.x);

		m_ShowResize = true;
	}

	private function SetResolutionScale(dv:DistributedValue):Void {
		var scale:Number = dv.GetValue() * 100;
		_xscale = scale;
		_yscale = scale;
	}

	public function TriggerWindowClose():Void {
		SignalClose.Emit(this);
		m_Content.Close();
	}

	private function SlotResizePress()
	{
		if (Mouse["IsMouseOver"](m_ResizeButton)) {
			IsResizing = true;
		}
	}

	private function SlotResizeRelease() { IsResizing = false; }

	private function SlotResizeMove()
	{
		// Delegate actual calculations back to the WinComp implementation
		// This will skip the (largely redundant) call to SetSize onRelease
		if (IsResizing) { MouseResizeMovingHandler(); }
	}

	private var IsResizing:Boolean = false;

	private var EscNode:EscapeStackNode;
	private var ResolutionScaleDV:DistributedValue;
}
