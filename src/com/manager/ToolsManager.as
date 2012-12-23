package com.manager
{
	import com.gameElements.Hero;

	public class ToolsManager
	{
		private static var instance:ToolsManager
		public function ToolsManager()
		{
		}
		public static function getInstance():ToolsManager
		{
			if(instance == null)
			{
				instance = new ToolsManager;
			}
			return instance;
		}
		
		/**
		 * 
		 * 
		 */
		public static function AC(h:Hero,data:String):void
		{
			
		}
	}
}