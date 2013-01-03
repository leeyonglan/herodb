package com.manager
{
	import com.gameElements.Parts;
	
	import item.Cell;
	
	import starling.display.Sprite;

	public class PartsManager
	{
		private static var instance:PartsManager;
		private var _layer:Sprite;
		public function PartsManager()
		{
		}
		
		public static function getInstance():PartsManager
		{
			if(instance == null)
			{
				instance = new PartsManager;
			}
			return instance;
		}
		public function init(layer:Sprite):void
		{
			_layer = layer;
		}
		public function addParts(part:Parts,toCell:Cell):void
		{
			part.pivotX = part.width>>1;
			part.pivotY = part.height>>1;
			part.x = CellManager.getPartPosOncell(part,toCell).x;
			part.y = CellManager.getPartPosOncell(part,toCell).y;
			toCell.part = part
			this._layer.addChild(part);
		}
	}
}