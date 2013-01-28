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
	import starling.display.DisplayObject;
	import starling.display.MovieClip;
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
		/** 当前选中的在仓位的item**/
		private var _selectedItem:Item;
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
		
		private function cleardata():void
		{
			if(this._selectedHero)
			{
				this._selectedHero.selected = false;
				this._selectedHero = null;
			}
			if(_attackedHero)
			{
				this._attackedHero.selected = false;
				this._attackedHero = null;
			}
			if(_selectedItem)
			{
				this._selectedItem.selected = false;
				this._selectedItem = null;
			}
			if(this._rangIds)
			{
				CellManager.getInstance().hideRang();
				this._rangIds = null;
			}
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
					if(UserManager.getInstance().isMaster && data.master == "1")
					{
						var hero:Hero = this.getHeroInStageById(data.id,true);
					}
					else
					{
						var hero:Hero = this.getHeroInStageById(data.id,false);
					}
				
					var cell:Cell = CellManager.getInstance().getCellById(data.params.cid);
					this.moveHero(hero,cell);
					break;
				case Global.DATA_ACTION_ATTACK:
					if(data.master == "1")
					{
						if(UserManager.getInstance().isMaster)
						{
							var hero:Hero = this.getHeroInStageById(data.id,true);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,false);
						}
						else
						{
							var hero:Hero = this.getHeroInStageById(data.id,false);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,true);
						}
					}
					else
					{
						if(UserManager.getInstance().isMaster)
						{
							var hero:Hero = this.getHeroInStageById(data.id,false);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,true);
						}
						else
						{
							var hero:Hero = this.getHeroInStageById(data.id,true);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,false);
						}
					}
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
			if(!DataManager.canOpt())return;
			var touchCell:Cell = e.data as Cell;
			if(this._selectedHero)
			{
				if(this._rangIds.indexOf(touchCell.__id) != -1 && isEmpty(touchCell.__id))
				{
					if(this._selectedHero.__selected)
					{
						this._selectedHero.selected = false;
					}
					DataManager.setSave(true);
					this.moveHero(this._selectedHero,touchCell);
				}
			}
			if(this._selectedSpaceHero)
			{
				if(touchCell.__isBorn)
				{
					DataManager.setSave(true);
					this.addToStage(this._selectedSpaceHero,touchCell);
				}
				this._selectedSpaceHero = null;
			}
			this.removeSelectAttack();
		}
		public function addToStage(h:Hero,cell:Cell):void
		{
			var index:int = this.getSpaceIndex(h);
			this.spaceDict[index].content = null;
			
			h.selected = false;
			var onPos:Point = CellManager.getHeroPosOncell(h,cell);
			heroTweenUp = new Tween(h,.01);
			heroTweenUp.animate("x",onPos.x);
			heroTweenUp.animate("y",onPos.y);
			heroTweenUp.onComplete = upComplete;
			heroTweenUp.onCompleteArgs = [h,cell];
			h.switchStat(Hero.BORN);
			Starling.juggler.add(heroTweenUp);
		}
		
		private function upComplete(...arg):void
		{
			this.heroTweenUp = null;
			(arg[0] as Hero).removeEventListener(TouchEvent.TOUCH,touchAction);
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
			if(touch == null) return;
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
					if(!DataManager.canOpt())return;
					DataManager.setSave(true);
					this.attack(this._selectedHero,this._attackedHero);
					this.removeSelectAttack();
					return;
				}
				
				this.cleardata();
				for(var i:String in heroPool)
				{
					var item:Hero = heroPool[i] as Hero;
					if(item == e.currentTarget)
					{
						//if me
						if(!(item as Hero).__isMe)
						{
							return;
						}
						else
						{
							if(this._selectedItem)
							{
								
								return;
							}
							this._selectedHero = item;
							this._selectedSpaceHero = null;
							(item as Hero).switchStat(Hero.ACTIVATE);
							(item as Hero).selected = true;
							//step rang
							this._rangIds = CellManager.getRangCell((item as Hero).__cell,int((item as Hero).mov));
							CellManager.getInstance().showRang(this._rangIds);
							//attack rang
							var cids:Vector.<int> = CellManager.getRangCell(this._selectedHero.__cell,int((item as Hero).rang));
							_attackRangHero = this.getRangHero(cids,false);
							this.showSelectAttack(_attackRangHero);
						}
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
			hero.toHero = toHero;
			hero.addEventListener(Global.HERO_ACTION,actionHandler);
			hero.switchStat(Hero.ATTACK);
			if(this.needDisDir(hero,toHero.__cell))
			{
				hero.setDisDir();
			}
			var master:String = UserManager.getInstance().isMaster?"1":"0";
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,hero.id,Global.DATA_ACTION_ATTACK,master,{hid:toHero.id});
			
			var evt:Event = new Event(Global.ACTION_DATA_STEP);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
		}
		
		private function actionHandler(e:Event):void
		{
			switch(e.data.type)
			{
				case AnimationEvent.COMPLETE:
					if(e.data.stat == Hero.ATTACK)
					{
						var h:Hero = e.currentTarget as Hero;
						if(this.needDisDir(h,(h.toHero as Hero).__cell))
						{
							h.setDisDir();
						}
						h.switchStat(Hero.STAND);
					}
					this.cleardata();
					break;
				case Global.HERO_SHOWATTACKED:
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
			CellManager.getInstance().hideRang();
			
			var toPos:Point = CellManager.getHeroPosOncell(hero,toCell);
			
			if(toCell.__preid != hero.__cell.__preid)
			{
				this._elementLayer.addChild(hero);
			}
			if(this.needDisDir(hero,toCell))
			{
				hero.setDisDir();
			}
			hero.switchStat(Hero.MOVE);
			
			heroTween = new Tween(hero,.5);
			heroTween.animate("x",toPos.x);
			heroTween.animate("y",toPos.y);
			heroTween.onComplete = moveComplete;
			heroTween.onCompleteArgs = [hero,toCell];
			Starling.juggler.add(heroTween);
		}
		
		/**
		 *	是否需要转身 
		 * @param hero
		 * @param toCell
		 * @return 
		 * 
		 */
		private function needDisDir(hero:Hero,toCell):Boolean
		{
			if((hero.__direct == "R" && hero.__cell.__backid > toCell.__backid) || (hero.__direct == "L" && hero.__cell.__backid < toCell.__backid))
			{
				return true;
			}
			return false;
		}
		private function moveComplete(...arg):void
		{
			this.heroTween = null;
			(arg[0] as Hero).switchStat(Hero.STAND);
			if(this.needDisDir(arg[0],arg[1]))
			{
				(arg[0] as Hero).setDisDir();
			}
			(arg[0] as Hero).addTo(arg[1] as Cell);
			this.cleardata();
			var master:String = UserManager.getInstance().isMaster?"1":"0";
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,(arg[0] as Hero).id,Global.DATA_ACTION_MOVE,master,{cid:(arg[1] as Cell).__id});
			
			var evt:Event = new Event(Global.ACTION_DATA_STEP);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
		}
		
		public function addHero(hero:Hero,onCell:Cell,dispatchEvent:Boolean = true):void
		{
			hero.addTo(onCell);
			hero.status = Global.HERO_STATUS_STAGE;
			hero.addEventListener(TouchEvent.TOUCH,touchHandler);
			this._elementLayer.addChild(hero);
			this.heroPool.push(hero);
			if(dispatchEvent)
			{
				var evt:Event = new Event(Global.ACTION_DATA_STEP);
				HeroEventDispatcher.getInstance().dispatchEvent(evt);
			}
			var master:String = UserManager.getInstance().isMaster?"1":"0";
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,hero.id,Global.DATA_ACTION_ADD,master,{cid:onCell.__id});
		}
		//public function get
		private function touchAction(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this._elementLayer.stage,TouchPhase.ENDED);
			if(touch)
			{
				if(e.currentTarget is Hero)
				{
					_selectedSpaceHero = e.currentTarget as Hero;
					_selectedSpaceHero.selected = true;
					this._selectedHero = null;
					this._selectedItem = null;
				}
				if(e.currentTarget is Item)
				{
					this._selectedItem = e.currentTarget as Item;
					this._selectedItem.selected = true;
				}
			}
		}
		
		/**
		 *  
		 * @param items
		 * 
		 */
		public function addHeroToSpace(items:Object):void
		{
			for(var i:int=0;i<3;i++)
			{
				if(spaceDict[i].content == null)
				{
					if(!items.hasOwnProperty(i)) continue;
					var h:Hero = items[i];
					if(h == null) return;
					h.addEventListener(TouchEvent.TOUCH,touchAction);
					h.status = Global.HERO_STATUS_SPACE;
					h.isMe = true;
					h.x = spaceDict[i].pos.x;
					h.y = spaceDict[i].pos.y;
					trace("h.x is:"+h.x);
					trace("h.y is:"+h.y);
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
		public function addItemToSpace(items:Object):void
		{
			for(var i:int=3;i<6;i++)
			{
				if(spaceDict[i].content == null)
				{
					if(!items.hasOwnProperty(i-3))continue;
					var h:Item = items[i-3];
					h.addEventListener(TouchEvent.TOUCH,touchAction);
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
		
		public function getRangHero(ids:Vector.<int>,isme:Boolean):Vector.<Hero>
		{
			var list:Vector.<Hero> = new Vector.<Hero>;
			for(var i:String in heroPool)
			{
				if(ids.indexOf((heroPool[i] as Hero).__cell.__id)!=-1 && (heroPool[i] as Hero).__isMe == isme)
				{
					list.push(heroPool[i]);
				}
			}
			return list;
		}
		/**
		 * 根据类型获取范围内的对象实例 
		 * @param ids
		 * @param type
		 * @return 
		 * 
		 */
		public function getRangHeros(ids:Vector.<Vector.<int>>,type:int):Vector.<Hero>
		{
			var list:Vector.<Hero> = new Vector.<Hero>;
			var idss:Vector.<int> = RangUtil.vectorToList(ids);
			if(type ==3)
			{
				this.heroPool;
			}
			var isme:Boolean = (type ==1)?true:false;
			for(var i:String in heroPool)
			{
				if(idss.indexOf((heroPool[i] as Hero).__cell.__id)!=-1 && (heroPool[i] as Hero).__isMe == isme)
				{
					list.push(heroPool[i]);
				}
			}
			return list;
		}
		
		public function isEmpty(cid:int):Boolean
		{
			for(var i:String in heroPool)
			{
				if((heroPool[i] as Hero).__cell.__id == cid)
				{
					return false;
				}
			}
			return true;
		}
		public function showAttackItem(display:DisplayObject,hero:Hero,toHero:Hero):void
		{
			var mx:Number = toHero.x - hero.x;
			var my:Number = toHero.y - hero.y;
			var des:Number = Math.atan2(my,mx);
			display.pivotX = display.width>>1;
			display.pivotY = display.height>>1;
			display.rotation = des;
			display.x = hero.x;
			display.y = hero.y;
			
			var tween:Tween = new Tween(display,.2);
			tween.animate("x",toHero.x);
			tween.animate("y",toHero.y);
			tween.onComplete = attckComplete;
			tween.onCompleteArgs = [display,hero,toHero];
			this._elementLayer.addChild(display);
			(display as MovieClip).play();
			Starling.juggler.add(tween);
		}
		private function attckComplete(...arg):void
		{
			var dis:DisplayObject = arg[0];
			var hero:Hero = arg[1];
			var toHero:Hero = arg[2];
			if((hero._stat == Hero.ATTACK ||hero._prestat == Hero.ATTACK) && hero.atobjeffect == "1")
			{
				var mc:MovieClip = Assets.getHeroEffectByKey(hero.confid,Global.HERO_COMMON_ATTACKEFFECT);
				this.showAttackEffect(mc,toHero);
				if(hero.atharmanimate == "1")
				{
					toHero.switchStat(Hero.HURT);
				}
				else
				{
					toHero.switchStat(Hero.ENERGY_HURT);
				}
			}
			if((hero._stat == Hero.FINALATTACK || hero._prestat == Hero.FINALATTACK) && hero.finalobjeffect == "1")
			{
				var mc:MovieClip = Assets.getHeroEffectByKey(hero.confid,Global.HERO_FINAL_ATTACKEFFECT);
				this.showAttackEffect(mc,toHero);
				if(hero.atharmanimate == "1")
				{
					toHero.switchStat(Hero.HURT);
				}
				else
				{
					toHero.switchStat(Hero.ENERGY_HURT);
				}
			}
			dis.visible = false;
			(dis as MovieClip).stop();
			this._elementLayer.removeChild(dis,true);
		}
		public function showAttackEffect(mc:MovieClip,hero:Hero):void
		{
			mc.pivotX = mc.width>>1;
			mc.pivotY = mc.height>>1;
			mc.x = hero.x;
			mc.y = hero.y;
			mc.fps = 24;
			mc.addEventListener(Event.COMPLETE,effectComplete);
			this._elementLayer.addChild(mc);
			Starling.juggler.add(mc);
		}
		private function effectComplete(e:Event):void
		{
			var tmc:MovieClip = e.currentTarget as MovieClip
				tmc.visible = false;
				this._elementLayer.removeChild(tmc,true);
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
		
		public function clear():void
		{
			this.cleardata();
			DataManager.save = false;
			while(this.heroPool.length>0)
			{
				heroPool.pop().removeFromParent(true);
			}
			for(var i:int=0;i<6;i++)
			{
				if(spaceDict[i].content != null)
				{
					if(spaceDict[i].content.parent)
					{
						spaceDict[i].content.removeFromParent(true);
						spaceDict[i].content = null;
					}
				}
			}
		}
	}
}