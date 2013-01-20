//----------------------------------------------------------------------------------------------------
// Loader basic class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.utils {
    import flash.events.*;
    import flash.net.*;
    import flash.utils.ByteArray;
    
    
    /** Loader basic class. */
    public class AbstructLoader extends EventDispatcher
    {
    // valiables
    //------------------------------------------------------------
        /** loader */
        protected var _loader:URLLoader;
        /** total bytes */
        protected var _bytesTotal:Number;
        /** loaded bytes */
        protected var _bytesLoaded:Number;
        /** flag complete loading */
        protected var _isLoadCompleted:Boolean;
        /** child loaders */
        protected var _childLoaders:Array;
        /** event priority */
        protected var _eventPriority:int;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor */
        function AbstructLoader(priority:int = 0)
        {
            _loader = new URLLoader();
            _bytesTotal = 0;
            _bytesLoaded = 0;
            _isLoadCompleted = false;
            _childLoaders = [];
            _eventPriority = priority;
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** load */
        public function load(url:URLRequest) : void
        {
            _loader.close();
            _bytesTotal = 0;
            _bytesLoaded = 0;
            _isLoadCompleted = false;
            _addAllListeners();
            _loader.load(url);
        }
        
        
        /** add child loader */
        public function addChild(child:AbstructLoader) : void
        {
            _childLoaders.push(child);
            child.addEventListener(Event.COMPLETE, _onChildComplete);
        }
        
        
        
        
    // virtual function
    //------------------------------------------------------------
        /** overriding function when completes loading */
        protected function onComplete() : void { }
        
        
        
        
    // default handler
    //------------------------------------------------------------
        private function _onProgress(e:ProgressEvent) : void
        {
            _bytesTotal  = e.bytesTotal;
            _bytesLoaded = e.bytesLoaded;
            _isLoadCompleted = false;
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _bytesLoaded, _bytesTotal));
        }
        
        
        private function _onComplete(e:Event) : void
        {
            _removeAllListeners();
            _bytesLoaded = _bytesTotal;
            _isLoadCompleted = true;
            onComplete();
            if (_childLoaders.length == 0) {
                dispatchEvent(new Event(Event.COMPLETE));
            }
        }

    
        private function _onError(e:ErrorEvent) : void
        {
            _removeAllListeners();
            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.toString()));
        }
        
        
        private function _onChildComplete(e:Event) : void
        {
            var index:int = _childLoaders.indexOf(e.target);
            if (index == -1) throw new Error("AbstructLoader; unkown error, children mismatched.");
            _childLoaders.splice(index, 1);
            if (_childLoaders.length == 0 && _isLoadCompleted) {
                dispatchEvent(new Event(Event.COMPLETE));
            }
        }
        
        
        private function _addAllListeners() : void 
        {
            _loader.addEventListener(Event.COMPLETE, _onComplete, false, _eventPriority);
            _loader.addEventListener(ProgressEvent.PROGRESS, _onProgress, false, _eventPriority);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, _onError, false, _eventPriority);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError, false, _eventPriority);
        }
        
        
        private function _removeAllListeners() : void 
        {
            _loader.removeEventListener(Event.COMPLETE, _onComplete);
            _loader.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, _onError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
        }
    }
}

