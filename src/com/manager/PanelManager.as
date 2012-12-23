package com.manager
{
	import com.gameElements.PanelLayer;
	import com.panel.AbstractPanel;
	import com.panel.UserMsgPanel;
	
	import starling.core.Starling;

	public class PanelManager
	{
		private static var instance:PanelManager
		private var _layer:PanelLayer;
		private var _panelList:Vector.<AbstractPanel> = new Vector.<AbstractPanel>;
		private var _sodierInfo:UserMsgPanel;
		public function PanelManager()
		{
		}
		public static function getInstance():PanelManager
		{
			if(instance == null)
			{
				instance = new PanelManager;
			}
			return instance;
		}
		
		public function init(layer:PanelLayer):void
		{
			this._layer = layer;
		}
		
		public function initPanel():void
		{
			_sodierInfo = new UserMsgPanel("最多八汉字玩家名");
			this._panelList.push(_sodierInfo);
		}
		public function open(id:int):void
		{
			for(var i:String in this._panelList)
			{
				if((this._panelList[i] as AbstractPanel).id == id)
				{
					this._layer.addChild(this._panelList[i]);
					this._panelList[i].x = (Starling.current.stage.stageWidth - this._panelList[i].width)>>1;
					this._panelList[i].y = (Starling.current.stage.stageHeight - this._panelList[i].height)>>1;
				}
			}
		}
		public function close(id:int):void
		{
			for(var i:String in this._panelList)
			{
				if((this._panelList[i] as AbstractPanel).id == id)
				{
					if((this._panelList[i] as AbstractPanel).parent !=null)
					{
						(this._panelList[i] as AbstractPanel).parent.removeChild(this._panelList[i]);	
					}
					
				}
			}			
		}
	}
}