package com.manager
{
	import com.gameElements.Hero;
	import com.gameElements.Item;
	import com.screens.AbstractScreen;
	import com.screens.InGame;
	
	import flash.system.ApplicationDomain;
	
	import global.Global;
	
	import item.HeroVo;
	import item.ItemVo;
	
	import model.DataManager;
	import model.ResourceManager;
	
	public class UserManager
	{
		private static var instance:UserManager
		public var token:String;
		private var heroDict:Vector.<Hero> = new Vector.<Hero>;
		private var itemDict:Vector.<Item> = new Vector.<Item>;
		private var gameId:String;
		private var mapId:String;
		private var userName:String;
		private var tName:String;
		private var tNation:String;
		private var toolResList:Vector.<String> = new Vector.<String>;
		private var resList:Vector.<String> = new Vector.<String>;
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
			for(var i:String in data.ua_in_items)
			{
				var it:ItemVo =DataManager.getItemToolById(data.ua_in_items[i]);
				var res:Object = {id:"tool_"+it.id,url:it.icon};
				resList.push(res);
			}
			for(var i:String in data.ua_in_units)
			{
				var h:HeroVo = DataManager.getHeroById(data.ua_in_units[i]);
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
			var gameScreen:AbstractScreen = SceneManager.getInstance().getScence(Global.SCREEN_GAME);
			(gameScreen as InGame).update();
			SceneManager.getInstance().switchScence(Global.SCREEN_GAME);
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
		public function getMapId():String
		{
			return this.mapId;
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
		}
	}
}