package com.manager
{
	import com.gameElements.EffectLayer;
	import com.gameElements.Hero;
	
	import item.Cell;
	
	import starling.core.Starling;
	import starling.display.MovieClip;
	import starling.events.Event;
	
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
		/**
		 *	显示地形效果 
		 * @param id
		 * @param cell
		 * 
		 */
		public function showPartEffect(id:int,cell:Cell):void
		{
			var mc:MovieClip = Assets.getHeroEffectByKey("map_parts",id);
			mc.pivotX = mc.width>>1;
			mc.pivotY = mc.height>>1;
			mc.x = cell.x
			mc.y = cell.y;
			mc.loop = true;
			mc.fps = 18;
			//mc.addEventListener(Event.COMPLETE,effectComplete);
			this._effectLayer.addChild(mc);
			Starling.juggler.add(mc);
		}
		
		private function effectComplete(e:Event):void
		{
			if((e.currentTarget as MovieClip).parent)
			{
				(e.currentTarget as MovieClip).removeFromParent(true);
			}
		}
		
		/**
		 *	显示道具效果 
		 * @param id
		 * @param cell
		 * 
		 */
		public function showItemEffect(id:int,cell:Cell):void
		{
			
		}
		
		public function doActtct(hero:Hero,toHero:Hero):void
		{
			switch(hero.confid)
			{
				case "1_1":
					toHero.rang  = toHero.rang-1;
					break;
				case "1_2":
					break;
				case "1_3":
					break;
			}
		}
	}
}