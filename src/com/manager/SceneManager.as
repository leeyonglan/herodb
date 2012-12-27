package com.manager
{
	import com.screens.AbstractScreen;
	
	import org.osmf.net.StreamingURLResource;
	
	import starling.display.Sprite;

	public class SceneManager
	{
		private static var instance:SceneManager
		private var _game:Game; 
		private var _sceneList:Vector.<Sprite>;
		public function SceneManager()
		{
		}
		public static function getInstance():SceneManager
		{
			if(instance == null)
			{
				instance = new SceneManager;
			}
			return instance;
		}
		
		public function init(game:Game):void
		{
			this._game = game;
			_sceneList = new Vector.<Sprite>;
		}
		public function addStage(scene:Sprite):void
		{
			if(scene.parent == this._game)
			{
				return ;
			}
			scene.visible = false;
			this._game.addChild(scene);
			this._sceneList.push(scene);
		}
		public function switchScence(stat:int):void
		{
			for(var i:String in this._sceneList)
			{
				if((this._sceneList[i] as AbstractScreen).stat == stat)
				{
					(this._sceneList[i] as AbstractScreen).visible = true;
				}
				else
				{
					(this._sceneList[i] as AbstractScreen).visible = false;
					
				}
			}
		}
		public function getScence(stat:int):AbstractScreen
		{
			for(var i:String in this._sceneList)
			{
				if((this._sceneList[i] as AbstractScreen).stat == stat)
				{
					return this._sceneList[i] as AbstractScreen;
				}
			}
			return null;
		}
	}
}