package net
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	public class QueueLoader
	{
		private static const _swfContext:LoaderContext=new LoaderContext(false, ApplicationDomain.currentDomain);

		private var loadList:Array;
		private var urlLoader:URLLoader;
		private var loader:Loader;

		private var currentItem:Object;
		private var totalCount:int;

		private var onItemCompleteCallBack:Function;
		private var onAllCompleteCallBack:Function;
		private var onProgressCallBack:Function;
		private var onItemFailedCallBack:Function;

		public function startQueue(loadList:Array, onItemComplete:Function=null, onAllComplete:Function=null, onProgress:Function=null,onItemFailed:Function=null):void
		{
			if (!urlLoader)
			{
				urlLoader=new URLLoader();
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIO_Error);
				urlLoader.addEventListener(ProgressEvent.PROGRESS, progressHandler)
				urlLoader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
				urlLoader.dataFormat=URLLoaderDataFormat.BINARY;
			}
			else
			{
				try
				{
					urlLoader.close()
				}
				catch (e:Error)
				{
				}
			}
			if (!loader)
			{
				loader=new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onDecoded);
			}
			else
			{
				try
				{
					loader.close()
				}
				catch (e:Error)
				{
				}
			}

			this.loadList=loadList;
			this.onItemCompleteCallBack=onItemComplete;
			this.onAllCompleteCallBack=onAllComplete;
			this.onProgressCallBack=onProgress;
			this.onItemFailedCallBack = onItemFailed;

			totalCount=loadList.length;

			loadNxt();
		}

		private function loadNxt():void
		{
			if (loadList.length == 0)
			{
				onAllComplete();
				return;
			}
			currentItem=loadList.shift();
			trace(currentItem.url);
			var request:URLRequest=new URLRequest(currentItem.url);
			urlLoader.load(request);
		}

		private function loaderCompleteHandler(e:Event):void
		{
			var data:ByteArray = urlLoader.data;
			if (currentItem.hasOwnProperty("requireBytes") && !(currentItem.requireBytes == true))
			{
				this.onItemCompleteCallBack(currentItem,data,loader.contentLoaderInfo.applicationDomain);
				this.loadNxt();
			}
			else
			{
				loader.loadBytes(data, currentItem.isCode ? _swfContext : null);
			}
		}

		private function onDecoded(e:Event):void
		{
			onComplete(currentItem, loader.content, loader.contentLoaderInfo.applicationDomain);
			loadNxt();
		}

		private function progressHandler(e:ProgressEvent):void
		{
			onProgress(totalCount, totalCount - loadList.length, e.bytesTotal, e.bytesLoaded);
		}


		protected function onComplete(item:Object, content:Object, domain:ApplicationDomain):void
		{
			if (onItemCompleteCallBack != null)
			{
				onItemCompleteCallBack(item, content, domain);
			}
		}

		protected function onProgress(totalCount:int, loadedCount:int, bytesTotal:int, bytesLoaded:int):void
		{
			if (onProgressCallBack != null)
			{
				onProgressCallBack(totalCount, loadedCount, bytesTotal, bytesLoaded, currentItem)
			}
		}

		protected function onAllComplete():void
		{
			if (onAllCompleteCallBack != null)
			{
				onAllCompleteCallBack();
			}
		}

		protected function onSecurityError(e:SecurityError):void
		{
			if(onItemFailedCallBack == null)
			{
				throw new Error(e.toString())
			}
			else
			{
				onItemFailedCallBack(currentItem);
			}
			
			loadNxt();
		}

		protected function onIO_Error(e:IOErrorEvent):void
		{
			trace(currentItem.id);			
			if(onItemFailedCallBack == null)
			{
			}
			else
			{
				onItemFailedCallBack(currentItem,e.text);
			}		
			loadNxt();
		}

	}
}