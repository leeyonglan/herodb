package com.manager
{
	import com.gameElements.ElementLayer;
	import com.gameElements.Hero;
	
	import dragonBones.events.AnimationEvent;
	
	import event.HeroEventDispatcher;
	
	import flash.geom.Point;
	
	import global.Global;
	
	import gs.TweenLite;
	
	import item.Cell;
	
	import model.DataManager;
	
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import util.RangUtil;
	public class ElementManager
	{
		private static var instance:ElementManager;
		private var _elementLayer:ElementLayer;
		
		/** 当前选中的hero **/
		private var _selectedHero:Hero;
		/** 当前选中的hero 准备受攻击的hero **/
		private var _attackedHero:Hero;
		/** 当前选中的hero 的移动范围 cell id **/
		private var _rangIds:Vector.<int>;
		/** 当前选中的hero 的攻击范围中的hero **/
		private var _attackRangHero:Vector.<Hero>;
		
		private var heroPool:Vector.<Hero> = new Vector.<Hero>();
		public function ElementManager()
		{
			
		}
		public static function getInstance():ElementManager
		{
			if(instance == null)
			{
				instance = new ElementManager;
			}
			return instance;
		}
		
		private function clear():void
		{
			this._selectedHero = null;
			this._attackedHero = null;
			this._rangIds = null;
			this._attackRangHero = null;
		}
		
		public function init(elementLayer:ElementLayer):void
		{
			this._elementLayer = elementLayer;
			HeroEventDispatcher.getInstance().addEventListener(Global.CELL_TOUCH,cellTouchHandler);
		}
		
		private function cellTouchHandler(e:Event):void
		{
			if(this._selectedHero)
			{
				var touchCell:Cell = e.data as Cell;
				if(this._rangIds.indexOf(touchCell.__id) != -1)
				{
					if(this._selectedHero.__selected)
					{
						this._selectedHero.selected = false;
					}
					this.moveHero(this._selectedHero,touchCell);
				}
			}
			this.removeSelectAttack();
		}
		
		/**
		 *	 
		 * @param e
		 * 
		 */
		private function touchHandler(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this._elementLayer.stage);
			if(touch.phase == TouchPhase.ENDED)
			{
				this._attackedHero = e.currentTarget as Hero;
				
				if(this._selectedHero && this._selectedHero.__selected && this._selectedHero.__isMe 
					&& !(this._attackedHero.__isMe) && this._attackRangHero!=null 
					&& this._attackRangHero.indexOf(this._attackedHero)!=-1)
				{
					this.attack(this._selectedHero,this._attackedHero);
					this.removeSelectAttack();
					return;
				}
				
				this.clear();
				for(var i:String in heroPool)
				{
					var item:Hero = heroPool[i] as Hero;
					if(item == e.currentTarget)
					{
						this._selectedHero = item;
						//if me
						if(!this._selectedHero.__isMe) return;
						
						(item as Hero).switchStat(Hero.ACTIVATE);
						(item as Hero).selected = true;
						//step rang
						this._rangIds = CellManager.getRangCell((item as Hero).__cell,2);
						CellManager.getInstance().showRang(this._rangIds);
						//attack rang
						var cids:Vector.<Vector.<int>> = RangUtil.closeCombat(this._selectedHero.__cell.__id);
						_attackRangHero = this.getRangHero(cids);
						this.showSelectAttack(_attackRangHero);
					}
					else
					{
						(item as Hero).selected = false;
						//item.switchStat(Hero.STAND);
					}
				}
			}
		}
		
		public function attack(hero:Hero,toHero:Hero):void
		{
			hero.selected = false;
			hero.addEventListener(Global.HERO_ACTION,actionHandler);
			hero.switchStat(Hero.ATTACK);
			if((hero.__direct == "R" && hero.__cell.__backid > toHero.__cell.__backid) || (hero.__direct == "L" && hero.__cell.__backid < toHero.__cell.__backid))
			{
				hero.scaleX = -1;
			}
		}
		
		private function actionHandler(e:Event):void
		{
			switch(e.data.type)
			{
				case AnimationEvent.COMPLETE:
					if(e.data.stat == Hero.ATTACK)
					{
						this._attackedHero.switchStat(Hero.HURT);
						if((e.currentTarget as Hero).scaleX == -1)
						{
							(e.currentTarget as Hero).scaleX = 1;
						}
					}
					this.clear();
					break;
			}
		}
		
		public function moveHero(hero:Hero,toCell:Cell):void
		{
			if(toCell === hero.__cell)
			{
				return;
			}
			if((hero.__direct == "R" && hero.__cell.__backid > toCell.__backid) || (hero.__direct == "L" && hero.__cell.__backid < toCell.__backid))
			{
				hero.scaleX = -1;
			}
			hero.switchStat(Hero.MOVE);
			
			CellManager.getInstance().hideRang();
			
			var toPos:Point = Hero.getHeroPosOncell(hero,toCell);
			
			if(toCell.__preid != hero.__cell.__preid)
			{
				this._elementLayer.addChild(hero);
			}
			TweenLite.to(hero,.5,{x:toPos.x,y:toPos.y,onComplete:moveComplete,onCompleteParams:[hero,toCell]});
		}
		
		private function moveComplete(...arg):void
		{
			(arg[0] as Hero).switchStat(Hero.STAND);
			(arg[0] as Hero).cell = (arg[1] as Cell);
			if((arg[0] as Hero).scaleX == -1)
			{
				(arg[0] as Hero).scaleX = 1;
			}
			this.clear();
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,(arg[0] as Hero).id,Global.DATA_ACTION_MOVE,(arg[1] as Cell).__id);
		}
		
		public function addHero(hero:Hero,onCell:Cell):void
		{
			hero.addTo(onCell);
			hero.addEventListener(TouchEvent.TOUCH,touchHandler);
			this._elementLayer.addChild(hero);
			this.heroPool.push(hero);
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,hero.id,Global.DATA_ACTION_ADD,onCell.__id);
		}
		
		public function get selectedHero():Hero
		{
			return this._selectedHero;
		}
		
		public function getRangHero(ids:Vector.<Vector.<int>>):Vector.<Hero>
		{
			var list:Vector.<Hero> = new Vector.<Hero>;
			var idss:Vector.<int> = RangUtil.vectorToList(ids);
			for(var i:String in heroPool)
			{
				if(idss.indexOf((heroPool[i] as Hero).__cell.__id)!=-1)
				{
					list.push(heroPool[i]);
				}
			}
			return list;
		}
		
		public function showSelectAttack(heros:Vector.<Hero>):void
		{
			for(var i:String in heros)
			{
				heros[i].showAttackEffect();
			}
		}
		
		public function removeSelectAttack():void
		{
			for(var i:String in heroPool)
			{
				heroPool[i].hideAttackEffect();
			}			
		}
		
		private function getIndex(id:int):int
		{
			return 1;
		}
	}
}