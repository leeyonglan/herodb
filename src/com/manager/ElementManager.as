package com.manager
{
	import com.gameElements.ElementLayer;
	import com.gameElements.Hero;
	import com.gameElements.Item;
	import com.ui.BottomSprite;
	
	import dragonBones.events.AnimationEvent;
	
	import event.HeroEventDispatcher;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.media.Sound;
	
	import global.Global;
	
	import item.Cell;
	
	import model.DataManager;
	import model.SoundManager;
	
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.MovieClip;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import util.MapElementEffect;
	import util.PropEffect;
	import util.RangUtil;
	import util.SkillAttack;

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
		private static const HELPER_POINT:Point = new Point();
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
//				this._selectedItem = null;
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
			HeroEventDispatcher.getInstance().addListener(Global.CELL_TOUCH,cellTouchHandler);
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
				case Global.DATA_ACTION_USETOOL:
					if(UserManager.getInstance().isMaster && data.master == "1")
					{
						var hero:Hero = this.getHeroInStageById(data.id,true);
					}
					else
					{
						var hero:Hero = this.getHeroInStageById(data.id,false);
					}
					var it:Item = UserManager.getInstance().getUbItemById(data.params.tid);
					PropEffect.useTool(hero,it);
					
					var evt:Event = new Event(Global.ACTION_DATA_STEP);
					HeroEventDispatcher.getInstance().dispatchEvent(evt);
					break;
			}
		}
		/**
		 * 
		 * @param e
		 * 
		 */
		public function cellTouchHandler(e:Event):void
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
				else
				{
					this.cleardata();
				}
			}
			if(this._selectedSpaceHero)
			{
				if(((UserManager.getInstance().isMaster && touchCell.__backid == 1) || (!UserManager.getInstance().isMaster && touchCell.__backid == 9))
					&& touchCell.__part && touchCell.__part.isborn)
				{
					DataManager.setSave(true);
					this.addToStage(this._selectedSpaceHero,touchCell);
				}
				else
				{
					this.cleardata();
					this.switchSpaceStatus();
					return;
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
		private function getTouchedHero(t:Touch):Hero
		{
			var h:Hero;
			for(var i:String in heroPool)
			{
				t.getLocation(heroPool[i], HELPER_POINT);
				if(heroPool[i].hitTest(HELPER_POINT,true))
				{
					h = heroPool[i];
					break;
				}
			}
			return h;
		}
		/**
		 *	 
		 * @param e
		 * 
		 */
		private function touchHandler(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(Starling.current.stage);
			if(touch == null) return;
			if(touch.phase == TouchPhase.ENDED)
			{
				
				this._attackedHero = this.getTouchedHero(touch);
				if(this._attackedHero == null)
				{
					var c:Cell = CellManager.getInstance().getTouchedCell(touch);
					var evt:Event = new Event(Global.CELL_TOUCH,false,c);
					HeroEventDispatcher.getInstance().dispatchEvent(evt);
					return;
				}
				//判断双击查看
				if(touch.tapCount ==2)
				{
					PanelManager.getInstance().open(Global.PANEL_SOLDIERINFO);
					PanelManager.getInstance().getSoldierPanel().setData(this._attackedHero);
					return;
				}
				//判断攻击
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
				//判断使用道具
				if(this._selectedItem)
				{
					if(!this._attackedHero.__isMe)return;
					if(!DataManager.canOpt())return;
					PropEffect.useTool(this._attackedHero,this._selectedItem);
					var master:String = UserManager.getInstance().isMaster?"1":"0";
					DataManager.setdata(Global.SOURCETARGET_TYPE_TOOL,(this._attackedHero as Hero).id,Global.DATA_ACTION_USETOOL,master,{tid:this._selectedItem.id});
					var index:int = getSpaceIndex(this._selectedItem);
					spaceDict[index].content = null;
					this._selectedItem = null;
					return;
				}
			}
			if(touch.phase == TouchPhase.BEGAN && !this._selectedHero)
			{
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
//			
//			var evt:Event = new Event(Global.ACTION_DATA_STEP);
//			HeroEventDispatcher.getInstance().dispatchEvent(evt);
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
						SkillAttack.doAttack(h,h.toHero);
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
		
		private function touchAction(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(Starling.current.stage);
			if(touch == null)return;
			if(touch.phase == TouchPhase.BEGAN)
			{
				switchSpaceStatus();
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
			if(touch.phase == TouchPhase.ENDED)
			{
				if(e.currentTarget is Hero)
				{
					var c:Cell = CellManager.getInstance().getTouchedCell(touch);
					if(c == null)return;
					var evt:Event = new Event(Global.CELL_TOUCH,false,c);
					HeroEventDispatcher.getInstance().dispatchEvent(evt);
				}
				if(e.currentTarget is Item)
				{
					this.touchHandler(e);
				}
			}
		}
		
		private function switchStageStatus():void
		{
			for(var i:String in this.heroPool)
			{
				this.heroPool[i].selected = false;
			}
		}
		private function switchSpaceStatus():void
		{
			switchStageStatus();
			for(var i:int=0;i<6;i++)
			{
				if(spaceDict[i].content != null)
				{
					spaceDict[i].content.selected = false;
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
			for(var i:int=0;i<3;i++)
			{
				if(spaceDict[i+3].content == null)
				{
					if(!items.hasOwnProperty(i))continue;
					var h:Item = items[i];
					h.addEventListener(TouchEvent.TOUCH,touchAction);
					h.x = spaceDict[i+3].pos.x;
					h.y = spaceDict[i+3].pos.y;
					spaceDict[i+3].content = h;
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
		
		public function removeHero(h:Hero):void
		{
			var i:int = this.heroPool.indexOf(h);
			if(i!=-1)
			{
				this.heroPool.splice(i,1);
				h.cell = null;
				if(h.hasEventListener(TouchEvent.TOUCH))
				{
					h.removeEventListener(TouchEvent.TOUCH,touchHandler);
				}
				h.removeFromParent(true);
				h = null;
			}
		}
		
		public function reset():void
		{
			this.cleardata();
			EffectManager.getInstance().clear();
			DataManager.getInstance().clear();
			
			var heroStageList:Vector.<Hero> = UserManager.getInstance().getHeroStageList();
			var heroStageListB:Vector.<Hero> = UserManager.getInstance().getHeroStageListB();
			var heroStageModel:Array = UserManager.getInstance().getHeroStageModel();
			var heroStageModelB:Array = UserManager.getInstance().getHeroStageModelB();
			for(var i:String in heroStageList)
			{
				UserManager.setProperty(heroStageList[i],heroStageModel[i]);
				this.addHero(heroStageList[i],heroStageList[i].__cell,false);
			}
			
			for(var i:String in heroStageListB)
			{
				UserManager.setProperty(heroStageListB[i],heroStageModelB[i]);
				this.addHero(heroStageListB[i],heroStageListB[i].__cell,false);
			}
			var spaceHeroList:Vector.<Hero> = UserManager.getInstance().getHeroList();
			for(var i:String in spaceHeroList)
			{
				(spaceHeroList[i] as Hero).setdata(DataManager.getHeroById(spaceHeroList[i].confid).data);
				if((spaceHeroList[i] as Hero).hasEventListener(TouchEvent.TOUCH))
					{
						(spaceHeroList[i] as Hero).removeEventListener(TouchEvent.TOUCH,touchHandler);
						(spaceHeroList[i] as Hero).addEventListener(TouchEvent.TOUCH,touchAction);
					}
			}
			this.addHeroToSpace(spaceHeroList);
			this.addItemToSpace(UserManager.getInstance().getToolList());
		}
		
		public function clear():void
		{
			this.cleardata();
			DataManager.save = false;
			while(this.heroPool.length>0)
			{
				var h:Hero = this.heroPool.pop();
				h.cell = null;
				if(h.hasEventListener(TouchEvent.TOUCH))
				{
					h.removeEventListener(TouchEvent.TOUCH,touchHandler);
				}
				h.removeFromParent(true);
				h = null;
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
			BottomSprite.fullLine();
		}
	}
}