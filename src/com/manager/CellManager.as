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

	public class CellManager
	{
		private static var instance:CellManager;
		private var _cellLayer:CellLayer;
		private var _cellList:Vector.<Cell>;
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
		/**
		 * get step rang 
		 * @param cell
		 * @param step
		 * @return 
		 * 
		 */
		public static function getRangCell(cell:Cell,step:uint = 2):Vector.<int>
		{
			var list:Vector.<int> = new Vector.<int>;
			var preId:int = cell.__preid;
			var backId:int = cell.__backid;
			var vstart:int = Math.max(1,(backId - step + 1));
			var vend:int = Math.min(9,(backId + step -1));
			var hstart:int = Math.max(1,(preId - step + 1));
			var hend:int = Math.min(5,(preId + step -1));
			for(var i:int = vstart;i <= vend;i++)
			{
				for(var j:int = hstart;j <= hend;j++)
				{
					list.push(String(j)+int(String(i)));
				}
			}
			
			if(vstart > 1)
			{
				list.push(int(String(preId)+String(backId - step)));
			}
			if(vend < 9)
			{
				list.push(int(String(preId)+String(backId + step)));
			}
			if(hstart > 1)
			{
				list.push(String(preId - step)+String(backId));
			}
			if(hstart < 5)
			{
				list.push(String(preId + step)+String(backId));
			}
			
			if(step == 3)
			{
				if(list.indexOf((cell.__preid+step-1)*10+cell.__backid-step+1)>0)
				{
					list.splice(list.indexOf((cell.__preid+step-1)*10+cell.__backid-step+1),1);
				}
				if(list.indexOf((cell.__preid+step-1)*10+cell.__backid+step-1)>0)
				{
					list.splice(list.indexOf((cell.__preid+step-1)*10+cell.__backid+step-1),1);
				}
				trace((cell.__preid-step+1)*10+cell.__backid-step+1);
				if(list.indexOf((cell.__preid-step+1)*10+cell.__backid-step+1)>0)
				{
					list.splice(list.indexOf((cell.__preid-step+1)*10+cell.__backid-step+1),1);
				}
				//trace((cell.__preid-step+1)*10+cell.__backid+step-1);
				if(list.indexOf((cell.__preid-step+1)*10+cell.__backid+step-1)>0)
				{
					list.splice(list.indexOf((cell.__preid-step+1)*10+cell.__backid+step-1),1);
				}
			}
			trace(list);
			return list;
		}
	}
}