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
		private var partDict:Vector.<Parts> = new Vector.<Parts>;
		private var mapPart:Dictionary = new Dictionary;
		private var gameId:String;
		private var mapId:String;
		private var userName:String;
		private var tName:String;
		private var tNation:String;
		private var resList:Array = new Array;

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
			resList.push({id:"map_1",url:"map/1.png"});
			
//			var elements:Array = ToolUtil.splitId(DataManager.getFieldMapById(this.mapId).map_element);
//			for(var i:String in elements)
//			{
//				var idArr:Array = ToolUtil.spliteLine(elements[i]);
//				mapPart[idArr[1]] = idArr[0];
//				var elment:PartVo = DataManager.getMapElementById(idArr[1]);
//				var res:Object = {id:"element_"+elment.id,url:elment.desc_icon};
//				resList.push(res);
//			}

			for(var i:String in data.ua_in_items)
			{
				var idArr:Array = ToolUtil.spliteLine(data.ua_in_items[i]);
				var it:ItemVo =DataManager.getItemToolById(idArr[0]+"_"+idArr[1]);
				var res:Object = {id:"tool_"+it.id,url:it.icon};
				resList.push(res);
			}
			for(var i:String in data.ua_in_units)
			{
				var idArr:Array = ToolUtil.spliteLine(data.ua_in_units[i]);
				var h:HeroVo = DataManager.getHeroById(idArr[0]+"_"+idArr[1]);
				var res:Object = {id:"hero_"+h.id,url:h.animate,requireBytes:true};
				resList.push(res);
				var res1:Object = {id:"heroimg_"+h.id,url:h.icon};
				resList.push(res1);
			}
			LoaderManager.getInstance().load(resList as Array,onItemComplete,onAllComplete);
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
				var part:Parts = new Parts(DataManager.getMapElementById(idArr.join("_")).data);
				part.updateView();
				partDict.push(part);
			}
			if((it.id).indexOf("hero_") == 0)
			{	
				var idArr:Array = String(it.id).split("_");
				idArr.shift();
				ResourceManager.addHeroResource(idArr.join("_"),content);
				var h:Hero = new Hero(ResourceManager.getHeroResourceById(idArr.join("_")) as ByteArray);
				h.setdata(DataManager.getHeroById(idArr.join("_")).data);
				this.addHero(h);
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
				var ite:Item = new Item(DataManager.getItemToolById(idArr.join("_")).data);
				ite.updateView();
				this.addTool(ite);
			}
			
		}
		private function onAllComplete():void
		{
			var gameScreen:AbstractScreen = SceneManager.getInstance().getScence(Global.SCREEN_GAME);
			(gameScreen as InGame).update();
			SceneManager.getInstance().switchScence(Global.SCREEN_GAME);
			while(this.resList.length>0)
			{
				this.resList.pop();
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
		public function addTool(it:Item):void
		{
			itemDict.push(it);
		}
		public function getToolList():Vector.<Item>
		{
			return this.itemDict; 
		}
		public function getPartList():Vector.<Parts>
		{
			return this.partDict;
		}
		public function getMapId():String
		{
			return this.mapId;
		}
		public function getMapPart():Dictionary
		{
			return this.mapPart;
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
				this.heroDict.pop();
			}
			while(this.itemDict.length>0)
			{
				this.itemDict.pop();
			}
			while(this.partDict.length>0)
			{
				this.partDict.pop();
			}
			while(this.mapPart.length>0)
			{
				this.mapPart.pop();
			}
		}
	}
}