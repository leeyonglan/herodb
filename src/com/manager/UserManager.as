package com.manager
{
	import com.gameElements.Hero;
	import com.gameElements.Item;
	import com.gameElements.Parts;
	import com.screens.AbstractScreen;
	import com.screens.InGame;
	
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import global.Global;
	
	import item.HeroVo;
	import item.ItemVo;
	import item.PartVo;
	
	import model.DataManager;
	import model.ResourceManager;
	
	import util.ToolUtil;
	
	public class UserManager
	{
		private static var instance:UserManager
		public var token:String;
		
		private var heroDict:Vector.<Hero> = new Vector.<Hero>;
		private var itemDict:Vector.<Item> = new Vector.<Item>;
		private var partDict:Dictionary = new Dictionary;
		
		private var gameId:String;
		private var mapId:String;
		private var userName:String;
		private var tName:String;
		private var tNation:String;
		
		private var resList:Array = new Array;
		
		private var elementModel:Array;
		private var itemModel:Array;
		private var heroModel:Array;		
		private var packItemModel:Dictionary;
		private var packHeroModel:Dictionary;
		
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
			this.gameId = data.game;
			this.mapId = data.map_id;
			this.userName = data.ua;
			this.tName = data.ub;
			this.tNation = data.ub_nation;
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
			this.itemModel = data.ua_in_items;
			for(var i:String in data.ua_in_items)
			{
				var idArr:Array = ToolUtil.spliteLine(data.ua_in_items[i]);
				var it:ItemVo =DataManager.getItemToolById(idArr[0]+"_"+idArr[1]);
				if(ResourceManager.checkToolResource(it.id))
				{
					continue;
				}
				var res:Object = {id:"tool_"+it.id,url:it.icon,oid:data.ua_in_items[i]};
				resList.push(res);
			}
			this.heroModel = data.ua_in_units;
			for(var i:String in data.ua_in_units)
			{
				var idArr:Array = ToolUtil.spliteLine(data.ua_in_units[i]);
				var h:HeroVo = DataManager.getHeroById(idArr[0]+"_"+idArr[1]);
				if(ResourceManager.checkHeroResource(h.id))
				{
					continue;
				}
				var res:Object = {id:"hero_"+h.id,url:h.animate,requireBytes:true,oid:data.ua_in_units[i]};
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
						var res:Object = {id:"hero_"+h.id,url:h.animate,requireBytes:true,oid:data.ua_in_units[i]};
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
						var res:Object = {id:"tool_"+it.id,url:it.icon,oid:data.ua_in_items[i]};
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
				ResourceManager.addHeroResource(idArr.join("_"),content);
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
			initObject();
			var gameScreen:AbstractScreen = SceneManager.getInstance().getScence(Global.SCREEN_GAME);
			(gameScreen as InGame).update();
			//save fielddatabefor
			DataManager.setFieldDataBefor(DataManager.getFieldData());
			
			SceneManager.getInstance().switchScence(Global.SCREEN_GAME);
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
				var h:Hero = new Hero(ResourceManager.getHeroResourceById(idArr[0]+"_"+idArr[1]) as ByteArray);
				h.setdata(DataManager.getHeroById(idArr[0]+"_"+idArr[1]).data);
				h.hid = heroModel[i];
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
		}

		public function addHero(hero:Hero):void
		{
			heroDict.push(hero);
		}
		public function getHeroList():Vector.<Hero>
		{
			return this.heroDict;	
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
			while(this.partDict.length>0)
			{
				partDict.pop();
			}
		}
	}
}