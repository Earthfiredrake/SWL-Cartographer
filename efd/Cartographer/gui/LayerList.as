// Copyright 2017, Earthfiredrake (Peloprata)
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/TSW-Cartographer

import gfx.core.UIComponent;
import gfx.utils.Delegate;

import efd.Cartographer.lib.ConfigWrapper;
import efd.Cartographer.lib.LocaleManager;
import efd.Cartographer.lib.Mod;

class efd.Cartographer.gui.LayerList extends UIComponent {

	private function LayerList() {
		super();
		LayerLabelTest = new Array();

		LayerLabelFormat = new TextFormat("_StandardFont");
		LayerLabelFormat.color = 0xFFFFFF;
		LayerLabelFormat.size = 20;

		HiddenLayerLabelFormat = new TextFormat("_StandardFont");
		HiddenLayerLabelFormat.color = 0xAAAAAA;
		HiddenLayerLabelFormat.size = 20;
	}

	public function SetConfig(config:ConfigWrapper) {
		Config = config;
		Config.SignalValueChanged.Connect(ConfigChanged, this);
	}

	public function AddLayers(layers:Array) {
		for (var i:Number = 0; i < layers.length; ++i) {
			var layerClip = createEmptyMovieClip(layers[i].Layer + "Clip", getNextHighestDepth());
			layerClip._y = 25 * i;
			var label:TextField = layerClip.createTextField("Label", layerClip.getNextHighestDepth(), 10, 0, 50, 20);
			label.embedFonts = true;
			label.selectable = false;
			label.autoSize = "left";
			label.setNewTextFormat(LayerLabelFormat);
			var text = LocaleManager.GetString("GUI", "LayerLabel" + layers[i].LayerName);
			label.text = text ? text : layers[i].LayerName;
			if (!layers[i].IsVisible) {
				label.setTextFormat(HiddenLayerLabelFormat);
			}
			layerClip.Settings = layers[i].ConfigView;
			layerClip.onPress = Delegate.create(layerClip, LabelPressed);
			LayerLabelTest.push(layerClip);
		}
	}

	private function LabelPressed():Void {
		var target:Object = this;
		Mod.TraceMsg("Toggling layer: " + target.Label.text);
		target.Settings.ShowLayer = !target.Settings.ShowLayer;
		target._parent.Config.NotifyChange("LayerSettings");
	}

	private function ConfigChanged(setting:String, newValue) {
	    // TODO: This is needlessly redundant, can I work out a way of triggering on more specific settings
		if (setting == "LayerSettings" || setting == undefined) {
			for (var i:Number = 0; i < LayerLabelTest.length; ++i) {
				if (LayerLabelTest[i].Settings.ShowLayer) {
					LayerLabelTest[i].Label.setTextFormat(LayerLabelFormat);
				} else {
					LayerLabelTest[i].Label.setTextFormat(HiddenLayerLabelFormat);
				}
			}
		}
	}

	private var Config:ConfigWrapper;

	private var LayerLabelTest:Array;
	private var LayerLabelFormat:TextFormat;
	private var HiddenLayerLabelFormat:TextFormat;
}
