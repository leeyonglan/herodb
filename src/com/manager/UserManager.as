package com.manager
{
	import com.gameElements.Hero;
	import com.gameElements.Item;
	import com.gameElements.Parts;
	import com.screens.AbstractScreen;
	import com.screens.InGame;
	
	import event.HeroEventDispatcher;
	
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import global.Global;
	
	import item.HeroVo;
	import item.ItemVo;
	import item.PartVo;
	
	import model.DataManager;
	import model.ResourceManager;
	
	import starling.events.Event;
	
	import util.ToolUtil;
	
	public class UserManager
	{
		private static var instance:UserManager
		public var token:String;
		
		private var heroDict:Vector.<Hero> = new Vector.<Hero>;
		private var itemDict:Vector.<Item> = new Vector.<Item>;
		private var ubHeroDict:Vector.<Hero> = new Vector.<Hero>;
		private var ubItemDict:Vector.<Item> = new Vector.<Item>;
		
		private var partDict:Dictionary = new Dictionary;
		
		private var gameId:String;
		private var mapId:String;
		
		private var tName:String;
		private var tNation:String;
		private var _userName:String = "jerry";
		
		private var resList:Array = new Array;
		
		private var elementModel:Array;
		private var itemModel:Array;
		private var heroModel:Array;
		private var ubItemModle:Array;
		private var ubHeroModle:Array;
		private var itemLoaderList:Array;
		private var heroLoaderList:Array;
		
		private var packItemModel:Dictionary;
		private var packHeroModel:Dictionary;
		
		private var _isMaster:Boolean;
		public function UserManager()
		{
		}
		
		public static function getInstance():UserManager
		{
			if(instance == null)
			{
				instance = new UserManager;
			}
			return instance;
		}
		
		public function setGameData(data:Object):void
		{
			this.gameId = data.game_id;
			this.mapId = data.map_id;
			this.tName = data.userb;
			this.tNation = data.ub_nation_id;
			if(this.userName == data.usera)
			{
				this._isMaster = true;
				itemLoaderList = data.ua_item_out;
				heroLoaderList = data.ua_unit_out;
			}
			else
			{
				itemLoaderList = data.ub_item_out;
				heroLoaderList = data.ub_unit_out;
				this._isMaster = false;
			}
			resList.push({id:"map_1",url:"map/1.jpg"});
			
			var elements:Array = ToolUtil.splitId(DataManager.getFieldMapById(this.mapId).map_element);
			this.elementModel = elements;
			for(var i:String in elements)
			{
				var idArr:Array = ToolUtil.spliteLine(elements[i]);
				var elment:PartVo = DataManager.getMapElementById(idArr[1]);
				if(ResourceManager.checkPartResource(elment.id))
				{
					continue;
				}
				var res:Object = {id:"element_"+elment.id,url:elment.imgid,cellid:idArr[0],oid:elements[i]};
				resList.push(res);
			}
			this.itemModel = itemLoaderList;
			if(data.hasOwnProperty("ubItemId"))
			{
				ubItemModle = data.ubItemId;
				itemLoaderList= itemLoaderList.concat(data.ubItemId);
				itemLoaderList = ToolUtil.unique(itemLoaderList);
			}
			for(var i:String in itemLoaderList)
			{
				var idArr:Array = ToolUtil.spliteLine(itemLoaderList[i]);
				var it:ItemVo =DataManager.getItemToolById(idArr[0]+"_"+idArr[1]);
				if(ResourceManager.checkToolResource(it.id))
				{
					continue;
				}
				var res:Object = {id:"tool_"+it.id,url:it.icon,oid:itemLoaderList[i]};
				resList.push(res);
			}
			// 对方
			if(data.hasOwnProperty("heroId"))
			{
				ubHeroModle = ToolUtil.unique(data.heroId);
				for(var i:String in ubHeroModle)
				{
					var idArr:Array = ToolUtil.spliteLine(ubHeroModle[i]);
					var h:HeroVo = DataManager.getHeroById(idArr[0]+"_"+idArr[1]);
					//如果自己是主场，则对方的要加载客场资源
					if(this._isMaster)
					{
						if(ResourceManager.checkHeroSlaveResource(h.id))
						{
							continue;
						}
						var res:Object = {id:"hero_"+h.id,url:h.animateslave,requireBytes:true,oid:ubHeroModle[i],isSlave:true};
					}
					else
					{
						if(ResourceManager.checkHeroResource(h.id))
						{
							continue;
						}
						var res:Object = {id:"hero_"+h.id,url:h.animate,requireBytes:true,oid:ubHeroModle[i],isSlave:false};
					}
					resList.push(res);
					var res1:Object = {id:"heroimg_"+h.id,url:h.icon};
					resList.push(res1);
				}
			}
			//自己
			this.heroModel = heroLoaderList;
			for(var i:String in heroLoaderList)
			{
				var idArr:Array = ToolUtil.spliteLine(heroLoaderList[i]);
				var h:HeroVo = DataManager.getHeroById(idArr[0]+"_"+idArr[1]);
				if(ResourceManager.checkHeroResource(h.id))
				{
					continue;
				}
				if(this._isMaster)
				{
					var res:Object = {id:"hero_"+h.id,url:h.animate,requireBytes:true,oid:heroLoaderList[i],isSlave:false};
				}
				else
				{
					var res:Object = {id:"hero_"+h.id,url:h.animateslave,requireBytes:true,oid:heroLoaderList[i],isSlave:true};
				}
				resList.push(res);
				var res1:Object = {id:"heroimg_"+h.id,url:h.icon};
				resList.push(res1);
			}
			LoaderManager.getInstance().load(resList,onItemComplete,onAllComplete);
		}
		
		public function loadPackage(data:Object):void
		{
			var spaceDict:Dictionary = ElementManager.getInstance().getSpaceDict();
			var packageList:Array = new Array;
			packHeroModel = new Dictionary;
			packItemModel = new Dictionary;
			for(var i:int=0;i<6;i++)
			{
				if(i<3)
				{
					if(spaceDict[i].content==null)
					{
						var idArr:Array = ToolUtil.spliteLine(data.unit_out[i]);
						var h:HeroVo = DataManager.getHeroById(idArr[0]+"_"+idArr[1]);
						packHeroModel[i] = data.unit_out[i];
						if(ResourceManager.checkHeroResource(h.id))
						{
							continue;
						}
						var res:Object = {id:"hero_"+h.id,url:h.animate,requireBytes:true,oid:data.unit_out[i]};
						packageList.push(res);
					}
				}
				if(i>=3)
				{
					if(spaceDict[i].content==null)
					{
						var idArr:Array = ToolUtil.spliteLine(data.items_out[i-3]);
						var it:ItemVo =DataManager.getItemToolById(idArr[0]+"_"+idArr[1]);
						packItemModel[i] = data.items_out[i-3];
						if(ResourceManager.checkToolResource(it.id))
						{
							continue;
						}
						var res:Object = {id:"tool_"+it.id,url:it.icon,oid:data.item_out[i]};
						packageList.push(res);
					}
				}
			}
			LoaderManager.getInstance().load(packageList,onItemComplete,onPackageAllComplete);
			packageList = null;
		}
		
		private function onItemComplete(it:Object, content:Object, domain:ApplicationDomain=null):void
		{
			if((it.id).indexOf("map_") == 0)
			{
				var idArr:Array = String(it.id).split("_");
				idArr.shift();
				ResourceManager.addMapResource(idArr.join("_"),content);
			}
			if((it.id).indexOf("element_") == 0)
			{
				var idArr:Array = String(it.id).split("_");
				idArr.shift();
				ResourceManager.addPartResource(idArr.join("_"),content);

			}
			if((it.id).indexOf("hero_") == 0)
			{	
				var idArr:Array = String(it.id).split("_");
				idArr.shift();
				if(it.isSlave)
				{
					ResourceManager.addHeroSlaveResource(idArr.join("_"),content);
				}
				else
				{
					ResourceManager.addHeroResource(idArr.join("_"),content);
				}
			}
			
			if((it.id).indexOf("heroimg_") ==0)
			{
				var idArr:Array = String(it.id).split("_");
				idArr.shift();
				ResourceManager.addHeroImgResource(idArr.join("_"),content);
			}
			
			if((it.id).indexOf("tool_") ==0)
			{
				var idArr:Array = String(it.id).split("_");
				idArr.shift();
				ResourceManager.addToolResource(idArr.join("_"),content);
			}
		}
		
		private function onAllComplete():void
		{
			//init element
			initObject();
			
			// init map
			var gameScreen:AbstractScreen = SceneManager.getInstance().getScence(Global.SCREEN_GAME);
			(gameScreen as InGame).update();

			//save fielddatabefor
			DataManager.setFieldDataBefor(DataManager.getFieldData());			
			SceneManager.getInstance().switchScence(Global.SCREEN_GAME);
			
			var evt:Event = new Event(Global.SOURCE_INIT_COMPELET,false);
			HeroEventDispatcher.getInstance().dispatchEvent(evt);
			
			while(this.resList.length>0)
			{
				this.resList.pop();
			}
		}
		
		private function onPackageAllComplete():void
		{
			var itemList:Vector.<Item> = new Vector.<Item>;
			for(var i:String in this.packItemModel)
			{
				var idArr:Array = ToolUtil.spliteLine(packItemModel[i]);
				var ite:Item = new Item(DataManager.getItemToolById(idArr[0]+"_"+idArr[1]).data);
				ite.updateView();
				ite.eid = packItemModel[i];
				itemList.push(ite);
			}
			ElementManager.getInstance().addItemToSpace(itemList);
			var heroList:Vector.<Hero> = new Vector.<Hero>;
			for(var i:String in this.packHeroModel)
			{
				var idArr:Array = ToolUtil.spliteLine(packHeroModel[i]);
				var h:Hero = new Hero(ResourceManager.getHeroResourceById(idArr[0]+"_"+idArr[1]) as ByteArray);
				h.setdata(DataManager.getHeroById(idArr[0]+"_"+idArr[1]).data);
				h.hid = packHeroModel[i];
				heroList.push(h);
			}
			ElementManager.getInstance().addHeroToSpace(heroList);
		}
		
		private function initObject():void
		{
			for(var i:String in this.elementModel)
			{
				var idArr:Array = ToolUtil.spliteLine(elementModel[i]);
				var part:Parts = new Parts(DataManager.getMapElementById(idArr[1]).data);
				part.updateView();
				partDict[idArr[0]] = part;
			}
			this.elementModel = null;
			for(var i:String in this.heroModel)
			{
				var idArr:Array = ToolUtil.spliteLine(heroModel[i]);
				if(this._isMaster)
				{
					var h:Hero = new Hero(ResourceManager.getHeroResourceById(idArr[0]+"_"+idArr[1]) as ByteArray);
				}
				else
				{
					var h:Hero = new Hero(ResourceManager.getHeroSlaveResourceById(idArr[0]+"_"+idArr[1]) as ByteArray);
				}
				h.setdata(DataManager.getHeroById(idArr[0]+"_"+idArr[1]).data);
				h.hid = heroModel[i];
				h.isMe = true;
				this.addHero(h);
			}
			this.heroModel = null;
			for(var i:String in this.itemModel)
			{
				var idArr:Array = ToolUtil.spliteLine(itemModel[i]);
				var ite:Item = new Item(DataManager.getItemToolById(idArr[0]+"_"+idArr[1]).data);
				ite.updateView();
				ite.eid = itemModel[i];
				this.addTool(ite);
			}
			this.itemModel = null;
			if(ubItemModle)
			{
				for(var i:String in this.ubItemModle)
				{
					var idArr:Array = ToolUtil.spliteLine(ubItemModle[i]);
					var ite:Item = new Item(DataManager.getItemToolById(idArr[0]+"_"+idArr[1]).data);
					ite.updateView();
					ite.eid = ubItemModle[i];
					ubItemDict.push(ite);
				}
				this.ubItemModle = null;
			}
			if(ubHeroModle)
			{
				for(var i:String in this.ubHeroModle)
				{
					var idArr:Array = ToolUtil.spliteLine(ubHeroModle[i]);
					if(this._isMaster)
					{
						var h:Hero = new Hero(ResourceManager.getHeroSlaveResourceById(idArr[0]+"_"+idArr[1]) as ByteArray);
					}
					else
					{
						var h:Hero = new Hero(ResourceManager.getHeroResourceById(idArr[0]+"_"+idArr[1]) as ByteArray);
					}
					h.setdata(DataManager.getHeroById(idArr[0]+"_"+idArr[1]).data);
					h.hid = ubHeroModle[i];
					h.isMe = false;
					ubHeroDict.push(h);
				}
				this.ubHeroModle = null;
			}
		}

		public function addHero(hero:Hero):void
		{
			heroDict.push(hero);
		}
		public function getHeroList():Vector.<Hero>
		{
			return this.heroDict;	
		}
		public function getUbHeroList():Vector.<Hero>
		{
			return this.ubHeroDict;
		}
		public function getUbItemList():Vector.<Item>
		{
			return this.ubItemDict;
		}
		public function getUbHeroById(id:String):Hero
		{
			var h:Hero;
			for(var i:String in this.ubHeroDict)
			{
				if(this.ubHeroDict[i].id == id)
				{
					h = this.ubHeroDict[i];
				}
			}
			return h;
		}
		public function getUbItemById(id:String):Item
		{
			var h:Item;
			for(var i:String in this.ubItemDict)
			{
				if(this.ubItemDict[i].id == id)
				{
					h = this.ubItemDict[i];
				}
			}
			return h;
		}
		public function addTool(it:Item):void
		{
			itemDict.push(it);
		}
		public function getToolList():Vector.<Item>
		{
			return this.itemDict; 
		}
		public function getPartList():Dictionary
		{
			return this.partDict;
		}
		public function getMapId():String
		{
			return this.mapId;
		}
		public function getGameId():String
		{
			return this.gameId;
		}
		public function set userName(name:String):void
		{
			this._userName = name;
		}
		public function get userName():String
		{
			return this._userName;
		}
		public function get isMaster():Boolean
		{
			return this._isMaster;
		}
		public function clear():void
		{
			this.gameId = null;
			this.mapId = null;
			this.userName = null;
			this.tName = null;
			this.tNation =null;
			while(this.heroDict.length>0)
			{
				heroDict.pop();
			}
			while(this.itemDict.length>0)
			{
				itemDict.pop();
			}
			while(this.ubHeroDict.length>0)
			{
				ubHeroDict.pop();
			}
			while(this.ubItemDict.length>0)
			{
				ubItemDict.pop();
			}
			while(this.partDict.length>0)
			{
				partDict.pop();
			}
		}
	}
}