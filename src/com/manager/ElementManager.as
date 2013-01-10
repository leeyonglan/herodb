package com.manager
{
	import com.gameElements.ElementLayer;
	import com.gameElements.Hero;
	import com.gameElements.Item;
	
	import dragonBones.events.AnimationEvent;
	
	import event.HeroEventDispatcher;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import global.Global;
	
	import item.Cell;
	
	import model.DataManager;
	
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import util.RangUtil;

	public class ElementManager
	{
		private static var instance:ElementManager;
		private var _elementLayer:ElementLayer;
		private var _spaceStartX:uint = 200;
		
		/** 当前选中的hero **/
		private var _selectedHero:Hero;
		/** 当前选中的在仓位的hero**/
		private var _selectedSpaceHero:Hero
		/** 当前选中的hero 准备受攻击的hero **/
		private var _attackedHero:Hero;
		/** 当前选中的hero 的移动范围 cell id **/
		private var _rangIds:Vector.<int>;
		/** 当前选中的hero 的攻击范围中的hero **/
		private var _attackRangHero:Vector.<Hero>;
		/** 已经在场上的hero **/
		private var heroPool:Vector.<Hero> = new Vector.<Hero>();
		
		private var spaceDict:Dictionary = new Dictionary;
		
		private var heroTween:Tween;
		private var heroTweenUp:Tween;
		
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
			
			for(var i:int=0;i<6;i++)
			{
				spaceDict[i] = {pos:new Point(this._spaceStartX+i*100,600),content:null};
			}
			HeroEventDispatcher.getInstance().addEventListener(Global.CELL_TOUCH,cellTouchHandler);
		}

		public function actionStep(data:Object):void
		{
			switch(data.action)
			{
				case Global.DATA_ACTION_ADD:
					var hero:Hero = UserManager.getInstance().getUbHeroById(data.id);
					var cell:Cell = CellManager.getInstance().getCellById(data.params.cid);
					this.addHero(hero,cell);
					break;
				case Global.DATA_ACTION_MOVE:
					var hero:Hero = this.getHeroInStageById(data.id,false);
					var cell:Cell = CellManager.getInstance().getCellById(data.params.cid);
					this.moveHero(hero,cell);
					break;
				case Global.DATA_ACTION_ATTACK:
					var hero:Hero = this.getHeroInStageById(data.id,false);
					var toHero:Hero = this.getHeroInStageById(data.params.id,true);
					this.attack(hero,toHero);
					break;
			}
		}
		/**
		 * 
		 * @param e
		 * 
		 */
		private function cellTouchHandler(e:Event):void
		{
			var touchCell:Cell = e.data as Cell;
			if(this._selectedHero)
			{
				if(this._rangIds.indexOf(touchCell.__id) != -1)
				{
					if(this._selectedHero.__selected)
					{
						this._selectedHero.selected = false;
					}
					this.moveHero(this._selectedHero,touchCell);
				}
			}
			if(this._selectedSpaceHero)
			{
				this.addToStage(this._selectedSpaceHero,touchCell);
				this._selectedSpaceHero = null;
			}
			this.removeSelectAttack();
		}
		
		private function addToStage(h:Hero,cell:Cell):void
		{
			if(cell.__isBorn)
			{
				h.selected = false;
				var onPos:Point = CellManager.getHeroPosOncell(h,cell);
				heroTweenUp = new Tween(h,.01);
				heroTweenUp.animate("x",onPos.x);
				heroTweenUp.animate("y",onPos.y);
				heroTweenUp.onComplete = upComplete;
				heroTweenUp.onCompleteArgs = [h,cell];
				Starling.juggler.add(heroTweenUp);
			}
		}
		private function upComplete(...arg):void
		{
			this.heroTweenUp = null;
			(arg[0] as Hero).removeEventListener(TouchEvent.TOUCH,touchAction);
			var index:int = this.getSpaceIndex(arg[0]);
			this.spaceDict[index].content = null;
			this.addHero(arg[0],arg[1]);
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
				if(touch.tapCount ==2)
				{
					PanelManager.getInstance().open(Global.PANEL_SOLDIERINFO);
					var data:Object = {name:this._attackedHero.hname,icon:this._attackedHero.icon,at:this._attackedHero.at,
						mat:this._attackedHero.mat,def:this._attackedHero.def,mdef:this._attackedHero.mdef,mov:this._attackedHero.mov,
						rang:this._attackedHero.rang,currenthp:300,hp:this._attackedHero.hp};
					PanelManager.getInstance().getSoldierPanel().setData(data);
					return;
				}
				trace("tapCount:"+touch.tapCount);
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
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,hero.id,Global.DATA_ACTION_ATTACK,{hid:toHero.id});
		}
		
		private function actionHandler(e:Event):void
		{
			switch(e.data.type)
			{
				case AnimationEvent.COMPLETE:
					if(e.data.stat == Hero.ATTACK)
					{
						if((e.currentTarget as Hero).scaleX == -1)
						{
							(e.currentTarget as Hero).scaleX = 1;
						}
					}
					this.clear();
					break;
				case Global.HERO_SHOWATTACKED:
					this._attackedHero.switchStat(Hero.HURT);
					var evt:Event = new Event(Global.ACTION_DATA_STEP);
					HeroEventDispatcher.getInstance().dispatchEvent(evt);
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
			
			var toPos:Point = CellManager.getHeroPosOncell(hero,toCell);
			
			if(toCell.__preid != hero.__cell.__preid)
			{
				this._elementLayer.addChild(hero);
			}

			heroTween = new Tween(hero,.5);
			heroTween.animate("x",toPos.x);
			heroTween.animate("y",toPos.y);
			heroTween.onComplete = moveComplete;
			heroTween.onCompleteArgs = [hero,toCell];
			Starling.juggler.add(heroTween);
		}
	
		private function moveComplete(...arg):void
		{
			this.heroTween = null;
			(arg[0] as Hero).switchStat(Hero.STAND);
			(arg[0] as Hero).cell = (arg[1] as Cell);
			if((arg[0] as Hero).scaleX == -1)
			{
				(arg[0] as Hero).scaleX = 1;
			}
			this.clear();
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,(arg[0] as Hero).id,Global.DATA_ACTION_MOVE,{cid:(arg[1] as Cell).__id});
			var evt:Event = new Event(Global.ACTION_DATA_STEP);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
		}
		
		public function addHero(hero:Hero,onCell:Cell):void
		{
			hero.switchStat(Hero.BORN);
			hero.addTo(onCell);
			hero.status = Global.HERO_STATUS_STAGE;
			hero.addEventListener(TouchEvent.TOUCH,touchHandler);
			this._elementLayer.addChild(hero);
			this.heroPool.push(hero);
			var evt:Event = new Event(Global.ACTION_DATA_STEP);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,hero.id,Global.DATA_ACTION_ADD,{cid:onCell.__id});
		}
		
		private function touchAction(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this._elementLayer.stage,TouchPhase.ENDED);
			if(touch)
			{
				_selectedSpaceHero = e.currentTarget as Hero;
				_selectedSpaceHero.selected = true;
			}
		}
		
		/**
		 *  
		 * @param items
		 * 
		 */
		public function addHeroToSpace(items:Vector.<Hero>):void
		{
			for(var i:int=0;i<3;i++)
			{
				if(spaceDict[i].content == null)
				{
					var h:Hero = items.pop();	
					h.addEventListener(TouchEvent.TOUCH,touchAction);
					h.status = Global.HERO_STATUS_SPACE;
					h.isMe = true;
					h.direct = "R";
//					h.scaleX = 0.9;
//					h.scaleY = 0.9;
					h.x = spaceDict[i].pos.x;
					h.y = spaceDict[i].pos.y;
					spaceDict[i].content = h;
					this._elementLayer.addChild(h);
				}
			}
		}
		/**
		 * 
		 * @param items
		 * 
		 */
		public function addItemToSpace(items:Vector.<Item>):void
		{
			for(var i:int=3;i<6;i++)
			{
				if(spaceDict[i].content == null)
				{
					var h:Item = items.pop();	
					h.x = spaceDict[i].pos.x;
					h.y = spaceDict[i].pos.y;
					spaceDict[i].content = h;
					this._elementLayer.addChild(h);
				}
			}
		}
		public function getHeroInSpaceById(id:String):Hero
		{
			var hero:Hero;
			for(var i:int=0;i<3;i++)
			{
				if(spaceDict[i].content != null)
				{
					if((spaceDict[i].content as Hero).id == id)
					{
						hero = spaceDict[i].content as Hero;
					}
				}
			}
			return hero
		}
		
		public function getHeroInStageById(id:String,isMe:Boolean = true):Hero
		{
			var hero:Hero;
			for(var i:String in this.heroPool)
			{
				if((heroPool[i] as Hero).id == id && (heroPool[i] as Hero).__isMe == isMe)
				{
					hero = heroPool[i];
				}
			}
			return hero;
		}
		public function getSpaceIndex(sp:Sprite):int
		{
			var index:int;
			for(var i:int=0;i<6;i++)
			{
				if(spaceDict[i].content == sp)
				{
					index = i;
				}
			}
			return index;
		}
		
		public function getSpaceDict():Dictionary
		{
			return this.spaceDict;
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
		public function getHerosPool():Vector.<Hero>
		{
			return this.heroPool;
		}
	}
}