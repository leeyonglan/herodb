package com.manager
{
	import com.gameElements.EffectLayer;
	
	import item.Cell;
	
	import starling.core.Starling;
	import starling.display.MovieClip;
	
	public class EffectManager
	{
		private static var instance:EffectManager;
		private var _effectLayer:EffectLayer;
		public function EffectManager()
		{
		}
		public static function getInstance():EffectManager
		{
			if(instance == null)
			{
				instance = new EffectManager;
			}
			return instance;
		}
		
		public function init(effectLayer:EffectLayer):void
		{
			this._effectLayer = effectLayer;
		}

		public function removeSelect():void
		{
			while(this._effectLayer.numChildren > 0)
			{
				this._effectLayer.removeChildAt(0);
			}
		}
	}
}