package com.manager 
{
 
    import flash.net.SharedObject;
    import flash.utils.Dictionary;
 
	/**
	 *  
	 *	 Usage Example
	 *   import SharedObjectManager;
	 *	 var _sharedOBJ:SharedObjectManager = new SharedObjectManager();
	 *	 _sharedOBJ.setupSharedObject ("test");
	 *	 set the data
	 *	 _sharedOBJ.setData ("lives",3);
	 *	get the data
	 *	 trace (_sharedOBJ.getData ("lives")); 
	 * 
	 */
    public class SharedObjectManager {
		public static const  SOUND_MUSIC:String = "SOUND_MUSIC"; // 游戏全局的背景音乐的开关
		public static const  SOUND_EFFECT:String = "SOUND_EFFECT";//游戏全局的背景音效的开关
		private static var _instance:SharedObjectManager
		public var so:SharedObject
		
        public function SharedObjectManager():void {
        }
        public function setupSharedObject(_string:String):void {
            // setup the shared object if it doesn't exist already
            so = SharedObject.getLocal (_string)
        }
        public function getData(_string:String):String {
            var _data:String = so.data[_string]
            return _data
        }
        public static function getInstance():SharedObjectManager {
        	if(_instance == null){
        		_instance = new SharedObjectManager();
        	}
            return _instance;
        }
        public function setData(_key:String,_val:*):void {
            so.data[_key] = _val
            save()
        }
        public function save():void {
            // save the shared object
            so.flush()
        }
         
    }
}