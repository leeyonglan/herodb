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
	import flash.utils.setTimeout;
	
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
				removeSelectAttack();
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
			Starling.current.stage.addEventListener(TouchEvent.TOUCH,stageTouchHandler);
			for(var i:int=0;i<6;i++)
			{
				spaceDict[i] = {pos:new Point(this._spaceStartX+i*100,600),content:null};
			}
			HeroEventDispatcher.getInstance().addListener(Global.CELL_TOUCH,cellTouchHandler);
			HeroEventDispatcher.getInstance().addListener(Global.SHIPPING_SPACE_COMPLETE,shipSpaceComplete);
		}
		
		private function stageTouchHandler(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(Starling.current.stage);
			if(touch == null) return;
			if(touch.phase == TouchPhase.ENDED)
			{
				if(touch.tapCount == 1)
				{
					PanelManager.getInstance().closeAll();
				}
				if(!CellManager.getInstance().getTouchedCell(touch) && this._selectedSpaceHero)
				{
					this.rebackToSpace(this._selectedSpaceHero);
				}
				if(!CellManager.getInstance().getTouchedCell(touch) && this._selectedItem)
				{
					var index:int = this.getSpaceIndex(this._selectedItem);
					var point:Point = this.spaceDict[index].pos;
					if(this._selectedItem.x == point.x && this._selectedItem.y == point.y)
					{
						return;
					}
					this.rebackToSpace(this._selectedItem);
				}
				for(var i:String in  this.heroPool)
				{
					this.heroPool[i].hideBlood();
				}
			}
			if(touch.phase == TouchPhase.BEGAN)
			{
				for(var i:String in  this.heroPool)
				{
					this.heroPool[i].showBlood();
				}
			}
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
					var hero:Hero = this.getHeroByFlag(data.master,data.id);
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
					var it:Item = UserManager.getInstance().getUbItemById(data.params.tid);
					if(data.params && data.params.hasOwnProperty("target") && data.params.target == "1")
					{
						var hero:Hero = this.getHeroByFlag(data.params.hmaster,data.id);
						var master:Boolean = data.master=="1"?true:false;
						PropEffect.useTool(hero,it,master);
					}
					else
					{
						var cell:Cell = CellManager.getInstance().getCellById(data.id);
						var master:Boolean = data.master=="1"?true:false;
						PropEffect.useToolOnCell(cell,it,master);
					}
					setTimeout(dispatchStep,700);
					break;
				case Global.DATA_ACTION_ADDGAIN:
					if(data.master == "1")
					{
						if(UserManager.getInstance().isMaster)
						{
							var hero:Hero = this.getHeroInStageById(data.id,true);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,true);
						}
						else
						{
							var hero:Hero = this.getHeroInStageById(data.id,false);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,false);
						}
					}
					else
					{
						if(UserManager.getInstance().isMaster)
						{
							var hero:Hero = this.getHeroInStageById(data.id,false);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,false);
						}
						else
						{
							var hero:Hero = this.getHeroInStageById(data.id,true);
							var toHero:Hero = this.getHeroInStageById(data.params.hid,true);
						}
					}
					SkillAttack.addGainValue(hero,toHero);
					setTimeout(dispatchStep,700);
					break;
			}
		}
		
		private function getHeroByFlag(flag:String,id:String):Hero
		{
			var hero:Hero;
			if(flag == "1")
			{
				if(UserManager.getInstance().isMaster)
				{
					hero = this.getHeroInStageById(id,true);
				}
				else
				{
					hero = this.getHeroInStageById(id,false);
				}
			}
			if(flag == "0")
			{
				if(UserManager.getInstance().isMaster)
				{
					hero = this.getHeroInStageById(id,false);
				}
				else
				{
					hero = this.getHeroInStageById(id,true);
				}
			}
			return hero;
		}
		/**
		 * 
		 * @param e
		 * 
		 */
		public function cellTouchHandler(e:Event):void
		{
			if(!DataManager.canOpt())
			{
				if(this._selectedSpaceHero) this.rebackToSpace(this._selectedSpaceHero);
				if(this._selectedItem) this.rebackToSpace(this._selectedItem);
				return;
			}
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
					rebackToSpace(this._selectedSpaceHero);
					this.cleardata();
					this.switchSpaceStatus();
					return;
				}
				this._selectedSpaceHero = null;
			}
			//TODO 判断道具是否可以用在格子上s
			if(this._selectedItem)
			{
				if(this._selectedItem.ground == "1")
				{
					toUseTool(touchCell);
				}
				else
				{
					this.rebackToSpace(this._selectedItem);
				}
			}
			this.removeSelectAttack();
		}
		
		/**
		 * 使用道具统一接口 
		 * @param obj
		 * 
		 */
		private function toUseTool(obj:DisplayObject):void
		{
			if(!DataManager.canOpt())
			{
				this.rebackToSpace(this._selectedItem);
				return;
			}
			DataManager.setSave(true);
			var id:String
			//使用对象，1兵，2格子
			var target:String
			//主场兵：1 客场兵:0
			var hmaster:String = "";
			if(obj is Hero)
			{
				PropEffect.useTool(obj as Hero,this._selectedItem,UserManager.getInstance().isMaster);
				id = (obj as Hero).id;
				target = "1";
				hmaster = this.getHeroFlag(obj as Hero);
			}
			if(obj is Cell)
			{
				PropEffect.useToolOnCell(obj as Cell,this._selectedItem,UserManager.getInstance().isMaster);
				id = String((obj as Cell).__id);
				target = "2";
			}
			var master:String = UserManager.getInstance().isMaster?"1":"0";
			DataManager.setdata(Global.SOURCETARGET_TYPE_TOOL,id,Global.DATA_ACTION_USETOOL,master,{tid:this._selectedItem.id,target:target,hmaster:hmaster});
			var index:int = getSpaceIndex(this._selectedItem);
			spaceDict[index].content = null;
			this._selectedItem = null;
		}
		private function getHeroFlag(h:Hero):String
		{
			var flag:String = "";
			if(UserManager.getInstance().isMaster)
			{
				flag = (h.__isMe)?"1":"0";
			}
			else
			{
				flag = (h.__isMe)?"0":"1";
			}
			return flag;
		}
		public function addToStage(h:Hero,cell:Cell):void
		{
			var index:int = this.getSpaceIndex(h);
			this.spaceDict[index].content = null;
			h.selected = false;
			h.zoomOut();
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
					if(c == null)
					{
						return;
					}
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
				
				//判断攻击、友军加血等
				if(this._selectedHero && this._selectedHero.__selected && this._selectedHero.__isMe 
					&& this._attackRangHero!=null 
					&& this._attackRangHero.indexOf(this._attackedHero)!=-1)
				{
					if(!DataManager.canOpt())return;
					DataManager.setSave(true);
					
					if(this._attackedHero.__isMe)
					{
						//辅助
						if(this._selectedHero.add_hp == "1" || this._selectedHero.add_shield == "1")
						{
							if(!(this._selectedHero.add_hp == "1" && this._attackedHero.isEnergy))
							{
								SkillAttack.addGainValue(this._selectedHero,this._attackedHero);
								var master:String = UserManager.getInstance().isMaster?"1":"0";
								DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,this._selectedHero.id,Global.DATA_ACTION_ADDGAIN,master,{hid:this._attackedHero.id});
							}
						}
						else
						{
							var flag:String = SkillAttack.getAttackDeadFlag(this._selectedHero,this._attackedHero);
							if(flag == Global.DEAD_ATTACK_TYPE)
							{
								this.attack(this._selectedHero,this._attackedHero);
							}
							else
							{
								this.moveHero(this._selectedHero,this._attackedHero.__cell);
							}
						}
					}
					else
					{
						var flag:String = SkillAttack.getAttackDeadFlag(this._selectedHero,this._attackedHero);
						if(flag == Global.DEAD_ATTACK_TYPE)
						{
							this.attack(this._selectedHero,this._attackedHero);
						}
						else
						{
							this.moveHero(this._selectedHero,this._attackedHero.__cell);
						}					
					}

					this.removeSelectAttack();
					this.cleardata();
					return;
				}
				//判断使用道具
				if(this._selectedItem)
				{
					
					if(PropEffect.canUse(this._selectedItem,this._attackedHero))
					{
						this.toUseTool(this._attackedHero);
					}
					else
					{
						this.rebackToSpace(this._selectedItem);
					}
					return;
				}
				if(this._attackedHero == this._selectedHero)return;
				this.cleardata();
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
						if(!(item as Hero).__isMe||(item as Hero).currenthp =="0")
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
							this._rangIds = RangUtil.getRangCell((item as Hero).__cell,int((item as Hero).mov));
							CellManager.getInstance().showRang(this._rangIds);
							//attack rang
							var cids:Vector.<int> = RangUtil.getRangCell(this._selectedHero.__cell,int((item as Hero).rang));
							//skill rang
							var skillRang:Vector.<int> = RangUtil.vectorToList(RangUtil.getKillRang(this._selectedHero));
							cids = cids.concat(skillRang);
							
							_attackRangHero = this.getRangHero(cids);

							var inx:int = _attackRangHero.indexOf(this._selectedHero); 
							if(inx!=-1)
							{
								_attackRangHero.splice(inx,1);
							}
							this.showSelectAttack(this._selectedHero,_attackRangHero);
						}
					}
					else
					{
						(item as Hero).selected = false;
					}
				}
			}
		}
		
		public function attack(hero:Hero,toHero:Hero):void
		{
			hero.selected = false;
			hero.toHero = toHero;
			hero.addEventListener(Global.HERO_ACTION,actionHandler);
			
			if(PropEffect.hasSuperKill(hero._equip))
			{
				hero.switchStat(Hero.FINALATTACK);
				EffectManager.processSuperSkillEffect(hero,toHero);
			}
			else
			{
				hero.switchStat(SkillAttack.getAttackFlag(hero,toHero));
			}
			if(this.needDisDir(hero,toHero.__cell))
			{
				hero.setDisDir();
			}
			var master:String = UserManager.getInstance().isMaster?"1":"0";
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,hero.id,Global.DATA_ACTION_ATTACK,master,{hid:toHero.id});
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
						if(h.toHero.shieldId =="")
						{
							SkillAttack.doAttack(h,h.toHero);
						}
						else
						{
							h.toHero.shieldId = "";
							EffectManager.removeShieldEffect(h.toHero);
						}
						h.switchStat(h.getStatus());
					}
					this.cleardata();
					var evt:Event = new Event(Global.ACTION_DATA_STEP);
					HeroEventDispatcher.getInstance().dispatchEvent(evt);
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
				this._elementLayer.addHero(toCell.__preid,hero);
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
			CellManager.getInstance().disableAllCell();
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
			(arg[0] as Hero).switchStat((arg[0] as Hero).getStatus());
			if(this.needDisDir(arg[0],arg[1]))
			{
				(arg[0] as Hero).setDisDir();
			}
			//踩尸体
			var deadHero:Hero = this.getHeroByCellId((arg[1] as Cell).__id);
			if(deadHero)
			{
				this.removeHero(deadHero);
				SkillAttack.processStepOnDead(arg[0],deadHero);
			}
			(arg[0] as Hero).addTo(arg[1] as Cell);
			(arg[0] as Hero).touchable = true;
			CellManager.getInstance().ableAllCell();
			
			this.cleardata();
			var master:String = UserManager.getInstance().isMaster?"1":"0";
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,(arg[0] as Hero).id,Global.DATA_ACTION_MOVE,master,{cid:(arg[1] as Cell).__id});
			
			var evt:Event = new Event(Global.ACTION_DATA_STEP);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
		}
		
		private function getHeroByCellId(id:int):Hero
		{
			var h:Hero
			for(var i:String in this.heroPool)
			{
				if(this.heroPool[i].__cell.__id == id)
				{
					h = this.heroPool[i];
				}
			}
			return h;
		}
		public function addHero(hero:Hero,onCell:Cell,dispatchEvent:Boolean = true):void
		{
			if(hero.__status != Global.HERO_STATUS_REMOED)
			{
				hero.addTo(onCell);
				hero.status = Global.HERO_STATUS_STAGE;
				hero.addEventListener(TouchEvent.TOUCH,touchHandler);
				this._elementLayer.addHero(onCell.__preid,hero);
			}
			this.heroPool.push(hero);
			if(dispatchEvent)
			{
				setTimeout(dispatchStep,700);
			}
			var master:String = UserManager.getInstance().isMaster?"1":"0";
			DataManager.setdata(Global.SOURCETARGET_TYPE_HERO,hero.id,Global.DATA_ACTION_ADD,master,{cid:onCell.__id});
		}
		/**
		 *仅用于召唤海兽 
		 * @param hero
		 * @param onCell
		 * 
		 */
		public function addSpicalHero(hero:Hero,onCell:Cell):void
		{
			hero.addTo(onCell);
			hero.status = Global.HERO_STATUS_STAGE;
			hero.addEventListener(TouchEvent.TOUCH,touchHandler);
			this._elementLayer.addHero(onCell.__preid,hero);
			this.heroPool.push(hero);
		}
		private function dispatchStep():void
		{
			var evt:Event = new Event(Global.ACTION_DATA_STEP);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
		}
		private  static const MOVEHELPPOINT = new Point;
		private  static var HELPX:Number;
		private  static var HELPY:Number;
		private function touchAction(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(Starling.current.stage);
			if(touch == null)return;
			
			if(touch.phase == TouchPhase.BEGAN)
			{
				HELPX = touch.globalX;
				HELPY = touch.globalY;
				this.cleardata();
				switchSpaceStatus();
				if(e.currentTarget is Hero)
				{
					_selectedSpaceHero = e.currentTarget as Hero;
					_selectedSpaceHero.selected = true;
					this._selectedHero = null;
					this._selectedItem = null;
					EffectManager.getInstance().bornCellColor(_selectedSpaceHero);
				}
				if(e.currentTarget is Item)
				{
					this._selectedItem = e.currentTarget as Item;
					this._selectedItem.selected = true;
					_selectedSpaceHero = null;
				}
			}
			if(touch.phase == TouchPhase.ENDED)
			{
				//判断双击查看
				if(touch.tapCount ==2)
				{
					if(e.currentTarget is Hero)
					{
						PanelManager.getInstance().open(Global.PANEL_SOLDIERINFO);
						PanelManager.getInstance().getSoldierPanel().setData(e.currentTarget as Hero);
					}
					if(e.currentTarget is Item)
					{
						PanelManager.getInstance().open(Global.PANEL_TOOLMSG);
						PanelManager.getInstance().getToolPanel().setData(e.currentTarget as Item);
					}
					return;
				}
				
				if(HELPX== touch.globalX && HELPY==touch.globalY)
				{
					e.stopPropagation();
				}
				else
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
			if(touch.phase == TouchPhase.MOVED)
			{
				touch.getLocation(this._elementLayer,MOVEHELPPOINT);
				if(e.currentTarget is Hero)
				{
					MOVEHELPPOINT.x = (MOVEHELPPOINT.x + (e.currentTarget as DisplayObject).width/4);
					MOVEHELPPOINT.y = (MOVEHELPPOINT.y + (e.currentTarget as DisplayObject).height/4);
				}
				(e.currentTarget as DisplayObject).x = MOVEHELPPOINT.x;
				(e.currentTarget as DisplayObject).y = MOVEHELPPOINT.y;
				e.currentTarget["zoomIn"]();
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
		private function checkAndDisselect():Boolean
		{
			if(this._selectedSpaceHero)
			{
				return false;
			}
			if(this._selectedItem)
			{
				return false;
			}
			return true;
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
					h.visible = false;
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
					h.visible = false;
					spaceDict[i+3].content = h;
					this._elementLayer.addChild(h);
				}
			}
		}
		
		public function shipSpaceComplete(e:Event):void
		{
			for(var i:int=0;i<6;i++)
			{
				if(spaceDict[i].content && spaceDict[i].content.visible == false)
				{
					var mc:MovieClip = Assets.getShippingSpaceEffectByKey("CharacterTransfer","CharacterTransfer");
					mc.x = spaceDict[i].pos.x;
					mc.y = spaceDict[i].pos.y;
					mc.addEventListener(Event.COMPLETE,showShipSpaceComplete);
					this._elementLayer.addChild(mc);
					Starling.juggler.add(mc);
					mc.play();
					break;
				}
			}
		}
		
		public function getSpaceDisByX(x:Number):DisplayObject
		{
			var dis:DisplayObject;
			for(var i:int=0;i<6;i++)
			{
				if(spaceDict[i].pos.x == x)
				{
					 dis = spaceDict[i].content;
				}
			}
			return dis;
		}
		public function showShipSpaceComplete(e:Event):void
		{
			(e.currentTarget as MovieClip).stop();
			var dis:DisplayObject = this.getSpaceDisByX((e.currentTarget as MovieClip).x);
			(e.currentTarget as MovieClip).removeFromParent();
			Starling.juggler.remove((e.currentTarget as MovieClip));
			Assets.reBackShipSpacemc(e.currentTarget as MovieClip);
			dis.visible = true;
			var evt:Event = new Event(Global.SHIPPING_SPACE_COMPLETE);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
		}
		
		public function rebackToSpace(dis:DisplayObject):void
		{
			for(var i:String in this.spaceDict)
			{
				if(this.spaceDict[i].content == dis)
				{
					dis.x = this.spaceDict[i].pos.x;
					dis.y = this.spaceDict[i].pos.y;
					dis['zoomOut']();
					break;
				}
			}
			this.cleardata();
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
					break;
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
		
		public function getRangHero(ids:Vector.<int>):Vector.<Hero>
		{
			var list:Vector.<Hero> = new Vector.<Hero>;
			for(var i:String in heroPool)
			{
				if(ids.indexOf((heroPool[i] as Hero).__cell.__id)!=-1)
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
		public function getRangHeros(ids:Vector.<Vector.<int>>,isme:Boolean):Vector.<Hero>
		{
			var list:Vector.<Hero> = new Vector.<Hero>;
			var idss:Vector.<int> = RangUtil.vectorToList(ids);
			for(var i:String in heroPool)
			{
				if(idss.indexOf((heroPool[i] as Hero).__cell.__id)!=-1 && (heroPool[i] as Hero).__isMe == isme)
				{
					list.push(heroPool[i]);
				}
			}
			return list;
		}
		
		public function switchResultHeros(isMe:Boolean,win:Boolean):void
		{
			for(var i:String in this.heroPool)
			{
				if(this.heroPool[i].__isMe == isMe)
				{
					if(win)
					{
						this.heroPool[i].switchStat(Hero.VICTORY);
					}
					else
					{
						this.heroPool[i].switchStat(Hero.LOST);
					}
				}
			}
			
			for(var j:int=0;j<3;j++)
			{
				if(spaceDict[j].content != null && ((spaceDict[j].content) as Hero).__isMe == isMe)
				{
					if(win)
					{
						((spaceDict[j].content) as Hero).switchStat(Hero.VICTORY);
					}
					else
					{
						((spaceDict[j].content) as Hero).switchStat(Hero.LOST);
					}
				}
			}
		}
		
		public function getHerosInStage(isMe:Boolean):Vector.<Hero>
		{
			var list:Vector.<Hero> = new Vector.<Hero>;
			for(var i:String in this.heroPool)
			{
				if(this.heroPool[i].__isMe == isMe)
				{
					list.push(this.heroPool[i]);
				}
			}
			return list;
		}
		
		public function isEmpty(cid:int):Boolean
		{
			for(var i:String in heroPool)
			{
				if((heroPool[i] as Hero).__cell.__id == cid && Number((heroPool[i] as Hero).currenthp)>0)
				{
					return false;
				}
			}
			return true;
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
		
		public function showSelectAttack(hero:Hero,heros:Vector.<Hero>):void
		{
			for(var i:String in heros)
			{
				EffectManager.showAttackEffects(hero,heros[i]);
			}
		}
		
		public function removeSelectAttack():void
		{
			for(var i:String in heroPool)
			{
				EffectManager.hideAttackEffect(this.heroPool[i]);
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
		/**
		 * 召唤 
		 * @param cell
		 * @return 
		 * 
		 */
		public function createHeroOnCell(cell:Cell,master:Boolean):void
		{
			var hero:Hero = UserManager.getInstance().getHeroObj("4_7",master);
			hero.hid = "4_7_1";
			if(UserManager.getInstance().isMaster == master)
			{
				hero.isMe = true;
			}
			else
			{
				hero.isMe = false;
			}
			this.addSpicalHero(hero,cell);
		}
		/**
		 *只是清除 
		 * @param h
		 * 
		 */
		public function removeHero(h:Hero):void
		{
			var i:int = this.heroPool.indexOf(h);
			if(i!=-1)
			{
				if(h.hasEventListener(TouchEvent.TOUCH))
				{
					h.removeEventListener(TouchEvent.TOUCH,touchHandler);
				}
				if(h.confid == "4_6")
				{
					this.resetAllVal(h.__isMe);
				}
				if(!DataManager.save)
				{
					h.status = Global.HERO_STATUS_REMOED;
				}
				h.removeFromParent(false);
			}
		}
		public function getMum(isMe:Boolean):Hero
		{
			for(var i:String in this.heroPool)
			{
				if(this.heroPool[i].__isMe == isMe && this.heroPool[i].confid == "4_6")
				{
					return this.heroPool[i];
					break;
				}
			}
			return null;
		}
		public function resetAllVal(isMe:Boolean):void
		{
			for(var i:String in this.heroPool)
			{
				if(this.heroPool[i].__isMe == isMe)
				{
					this.heroPool[i].resetVal();
				}
			}
		}
		public function reset():void
		{
			this.cleardata();
			this.clearHeroPool();
			EffectManager.getInstance().clear();
			DataManager.getInstance().clear();
			DataManager.setSave(false);
			var heroStageList:Vector.<Hero> = DataManager.heroListBefor;
			var actionList:Vector.<Hero> = DataManager.heroTa;
			
			if(heroStageList)
			{
				for(var i:String in heroStageList)
				{
					EffectManager.fasthideAttackEffect(heroStageList[i] as Hero);
					heroStageList[i].clear();
					UserManager.setProperty(heroStageList[i],DataManager.getHeroByFieldData(heroStageList[i].id,heroStageList[i].__isMe));
					this.addHero(heroStageList[i],heroStageList[i].__cell,false);
				}
			}
			
			for(var i:String in actionList)
			{
				if(heroStageList.indexOf(actionList[i])!=-1)continue;
				EffectManager.fasthideAttackEffect(actionList[i]);
				actionList[i].clear();
				UserManager.setProperty(actionList[i],DataManager.getHeroByFieldData(actionList[i].id,false));
				this.addHero(actionList[i],actionList[i].__cell,false);
				actionList[i].updatePos(true);
			}
			var spaceHeroList:Vector.<Hero> = UserManager.getInstance().getHeroList();
			for(var i:String in spaceHeroList)
			{
				(spaceHeroList[i] as Hero).setdata(DataManager.getHeroById(spaceHeroList[i].confid).data);
				(spaceHeroList[i] as Hero).removeEventListener(TouchEvent.TOUCH,touchHandler);
				(spaceHeroList[i] as Hero).switchStat(Hero.STAND);
				(spaceHeroList[i] as Hero).clear();
			}
			this.addHeroToSpace(spaceHeroList);
			this.addItemToSpace(UserManager.getInstance().getToolList());
			showAllSpaceDis();
		}
		
		private function clearHeroPool():void
		{
			while(this.heroPool.length>0)
			{
				var h:Hero = this.heroPool.pop();
				h.cell = null;
				if(h.hasEventListener(TouchEvent.TOUCH))
				{
					h.removeEventListener(TouchEvent.TOUCH,touchHandler);
				}
				h.removeFromParent(false);
			}		
		}
		public function clear():void
		{
			this.cleardata();
			DataManager.save = false;
			this.clearHeroPool();
			for(var i:int=0;i<6;i++)
			{
				if(spaceDict[i].content != null)
				{
					if(spaceDict[i].content.parent)
					{
						spaceDict[i].content.removeFromParent(true);
					}
					spaceDict[i].content = null;
				}
			}
			BottomSprite.fullLine();
		}
		
		/**
		 *	提交成功后禁止一些操作 
		 * 
		 */
		public function disableAll():void
		{
			for(var i:String in this.heroPool)
			{
				(this.heroPool[i] as Hero).removeEventListener(TouchEvent.TOUCH,touchHandler);
			}
			for(var j:int=0;j<6;j++)
			{
				if(spaceDict[j].content != null && (spaceDict[j].content as Sprite).hasEventListener(TouchEvent.TOUCH))
				{
					spaceDict[j].content.removeEventListener(TouchEvent.TOUCH,touchAction);
				}
			}
			GameManager.getInstance().getHud().bottomSprite.disable();
		}
		/**
		 * 
		 * 
		 */
		public function showAllSpaceDis():void
		{
			for(var i:int=0;i<6;i++)
			{
				if(spaceDict[i].content)
				{
					(spaceDict[i].content as DisplayObject).visible = true;
				}
			}
		}
		/**
		 * 进入游戏前恢复一些操作
		 * 
		 */
		public function ableAll():void
		{
			GameManager.getInstance().getHud().bottomSprite.able();
		}
		public function slowDownAll():void
		{
			for(var i:String in this.heroPool)
			{
				this.heroPool[i].slowdown();
			}
		}
		public function normalAll():void
		{
			for(var i:String in this.heroPool)
			{
				this.heroPool[i].normal();
			}			
		}
	}
}