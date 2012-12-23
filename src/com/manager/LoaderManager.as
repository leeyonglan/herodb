package com.manager
{
	import net.QueueLoader;

	public class LoaderManager
	{
		private static var instance:LoaderManager;
		private static var quequeLoader:QueueLoader;
		private static var resourceRoot:String = "res";
		public function LoaderManager()
		{
		}
		public static function getInstance():LoaderManager
		{
			if(instance == null)
			{
				instance = new LoaderManager;
				quequeLoader = new QueueLoader;
			}
			return instance;
		}
		public function load(loadList:Array, onItemComplete:Function=null, onAllComplete:Function=null, onProgress:Function=null,onItemFailed:Function=null):void
		{
			quequeLoader.startQueue(loadList, onItemComplete, onAllComplete, onProgress,onItemFailed);
		}
	}
}