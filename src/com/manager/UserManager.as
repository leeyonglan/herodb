package com.manager
{
	public class UserManager
	{
		private static var instance:UserManager
		public var token:String;
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
	}
}