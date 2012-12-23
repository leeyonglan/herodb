package com.manager
{
	import flash.utils.Dictionary;

	public class LangManager
	{
		private static var instance:LangManager;
		private  var dict:Dictionary = new Dictionary;
		public function LangManager()
		{
		}
		public static function getInstance():LangManager
		{
			if(instance == null)
			{
				instance = new LangManager;
			}
			return instance;
		}
		public  function init():void
		{
			dict['rank'] = "等级:";
		}
		
		public  function getLang(key:String):String
		{
			return dict[key];
		}
	}
}