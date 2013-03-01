package com.manager
{
	import com.gameElements.CellLayer;
	import com.gameElements.Hero;
	
	import event.HeroEventDispatcher;
	
	import flash.geom.Point;
	
	import global.Global;
	
	import item.Cell;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import util.ToolUtil;

	public class CellManager
	{
		private static var instance:CellManager;
		private var _cellLayer:CellLayer;
		private var _cellList:Vector.<Cell>;
		private static const HELPER_POINT:Point = new Point();
		private static var TranslatePoint:Point = new Point();
		public function CellManager()
		{
		}
		public static function getInstance():CellManager
		{
			if(instance == null)
			{
				instance = new CellManager;
			}
			return instance;
		}
		public function init(cellLayer:CellLayer):void
		{
			this._cellLayer = cellLayer;
			this._cellList = this._cellLayer.getCellList();
			for(var i:String in this._cellList)
			{
				(this._cellList[i] as Cell).addEventListener(TouchEvent.TOUCH,touchHandler);
			}
		}

		private function touchHandler(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this._cellLayer.stage);
			if(touch == null) return;
			if(touch.phase == TouchPhase.ENDED)
			{			
				var cell:Cell = e.currentTarget as Cell;
				var evt:Event = new Event(Global.CELL_TOUCH,false,cell);
				HeroEventDispatcher.getInstance().dispatchEvent(evt);
			}
		}
		public function getTouchedCell(t:Touch):Cell
		{
			var c:Cell;
			for(var i:String in _cellList)
			{
				t.getLocation(_cellList[i], HELPER_POINT);
				if(_cellList[i].hitTest(HELPER_POINT,true))
				{
					c = _cellList[i];
					break;
				}
			}
			return c;
		}
		
		public function getCellById(id:int):Cell
		{
			var c:Cell = null;
			for(var i:String in this._cellList)
			{
				if((this._cellList[i] as Cell).__id == id)
				{
					c = this._cellList[i];
					break;
				}
			}
			return c;
		}
		
		public function showRang(ids:Vector.<int>):void
		{
			for(var i:String in this._cellList)
			{
				if(ids.indexOf((this._cellList[i] as Cell).__id) !=-1 )
				{
					(this._cellList[i] as Cell).alpha = .5;
				}
				else
				{
					(this._cellList[i] as Cell).alpha = 0;
				}
			}
		}
		public static function getHeroPosOncell(h:Hero,cell:Cell):Point
		{
			var x:Number = (cell.x + cell.width - h.w/2);
			var y:Number = (cell.y + cell.height - h.h/2 -5);
			if(h.co == 1)
			{
				x = x+Number(h.xpos);
			}
			if(h.co == -1)
			{
				//x = x-Number(h.xpos);
			}
			return new Point(x,y);
		}
		public static function getPartPosOnHero(cell:Cell,hero:Hero):Point
		{
			TranslatePoint = new Point;
			TranslatePoint.x = cell.x + (cell.width>>1);
			TranslatePoint.y = cell.y + (cell.height>>1);
			return ToolUtil.translate(TranslatePoint,cell.parent,hero);
		}
		public static function getPartPosOncell(display:DisplayObject,cell:Cell):Point
		{
			return new Point((cell.x + cell.width - display.width/2),(cell.y + cell.height - display.height/2));
		}
		public static function getCellMiddle(cell:Cell):Point
		{
			return new Point(cell.x + cell.width>>1,cell.y + cell.height>>1);
		}
		
		public  function hideRang():void
		{
			for(var i:String in this._cellList)
			{
				(this._cellList[i] as Cell).alpha = 0;
			}
		}
	}
}