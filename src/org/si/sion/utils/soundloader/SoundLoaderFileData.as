//----------------------------------------------------------------------------------------------------
// File Data class for SoundLoader
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils.soundloader {
    import flash.net.*;
    import flash.media.*;
    import flash.utils.*;
    import flash.system.*;
    import flash.events.*;
    import flash.display.*;
    import org.si.sion.module.ISiOPMWaveInterface;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWaveSamplerData;
    import org.si.sion.midi.SMFData;
    import org.si.utils.ByteArrayExt;
    import org.si.sion.utils.soundfont.*;
    import org.si.sion.utils.SoundClass;
    import org.si.sion.utils.PCMSample;
    
    
    // Dispatching events
    /** @eventType flash.events.Event.COMPLETE */
    [Event(name="complete", type="flash.events.Event")]
    /** @eventType flash.events.ErrorEvent.ERROR */
    [Event(name="error",    type="flash.events.ErrorEvent")]
    /** @eventType  flash.events.ProgressEvent.PROGRESS */
    [Event(name="progress", type="flash.events.ProgressEvent")]
    
    
    /** File Data class for SoundLoader */
    public class SoundLoaderFileData extends EventDispatcher
    {
    // valiables
    //----------------------------------------
        /** @private type converting table */
        static internal var _ext2typeTable:* = {
            "mp3" : "mp3",
            "wav" : "wav",
            "mp3bin" : "mp3bin",
            "mid" : "mid",
            "smf" : "mid",
            "swf" : "img",
            "png" : "img",
            "gif" : "img",
            "jpg" : "img",
            "img" : "img",
            "bin" : "bin",
            "txt" : "txt",
            "var" : "var",
            "ssf" : "ssf",
            "ssfpng" : "ssfpng",
            "b2snd" : "b2snd",
            "b2img" : "b2img"
        }
        
        
        private var _dataID:String;
        private var _content:*;
        private var _urlRequest:URLRequest;
        private var _type:String;
        private var _checkPolicyFile:Boolean;
        private var _bytesLoaded:int, _bytesTotal:int;
        private var _loader:Loader, _sound:Sound, _urlLoader:URLLoader, _fontLoader:SiONSoundFontLoader, _byteArray:ByteArray;
        private var _soundLoader:SoundLoader;
        
        
        
        
    // properties
    //----------------------------------------
        /** data id */
        public function get dataID() : String { return _dataID; }
        /** loaded data */
        public function get data() : * { return _content; }
        /** url string */
        public function get urlString() : String { return (_urlRequest) ? _urlRequest.url : null; }
        /** data type */
        public function get type() : String { return _type; }
        /** loaded bytes */
        public function get bytesLoaded() : int { return _bytesLoaded; }
        /** total bytes */
        public function get bytesTotal() : int { return _bytesTotal; }
        
        
        
        
    // functions
    //----------------------------------------
        /** @private */
        function SoundLoaderFileData(soundLoader:SoundLoader, id:String, urlRequest:URLRequest, byteArray:ByteArray, ext:String, checkPolicyFile:Boolean)
        {
            this._dataID = id;
            this._soundLoader = soundLoader;
            this._urlRequest = urlRequest;
            this._type = _ext2typeTable[ext];
            this._checkPolicyFile = checkPolicyFile;
            this._bytesLoaded = 0;
            this._bytesTotal = 0;
            this._content = null;
            this._sound = null;
            this._loader = null;
            this._urlLoader = null;
            this._byteArray = byteArray;
        }
        
        
        
        
    // private functions
    //----------------------------------------
        /** @private */
        internal function load() : Boolean
        {
            // already loaded
            if (_content) return false;
            
            switch (_type) {
            case "mp3":
                _addAllListeners(_sound = new Sound());
                _sound.load(_urlRequest, new SoundLoaderContext(1000, _checkPolicyFile));
                break;
            case "img":
            case "ssfpng":
                _loader = new Loader();
                _addAllListeners(_loader.contentLoaderInfo);
                _loader.load(_urlRequest, new LoaderContext(_checkPolicyFile));
                break;
            case "txt":
                _addAllListeners(_urlLoader = new URLLoader());
                _urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
                _urlLoader.load(_urlRequest);
                break;
            case "mp3bin":
            case "bin":
            case "wav":
            case "mid":
                _addAllListeners(_urlLoader = new URLLoader());
                _urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
                _urlLoader.load(_urlRequest);
                break;
            case "var":
                _addAllListeners(_urlLoader = new URLLoader());
                _urlLoader.dataFormat = URLLoaderDataFormat.VARIABLES;
                _urlLoader.load(_urlRequest);
                break;
            case "ssf":
                _addAllListeners(_fontLoader = new SiONSoundFontLoader());
                _fontLoader.load(_urlRequest);
                break;
            case "b2snd":
                SoundClass.loadMP3FromByteArray(_byteArray, __loadMP3FromByteArray_onComplete);
                break;
            case "b2img":
                _loader = new Loader();
                _addAllListeners(_loader.contentLoaderInfo);
                _loader.loadBytes(_byteArray);
                break;
            default:
                break;
            }
            
            return true;
        }
        
        
        /** @private */
        internal function listenLoadingStatus(target:*) : Boolean
        {
            _sound = target as Sound;
            _loader = target as Loader;
            _urlLoader = target as URLLoader;
            target = _sound || _urlLoader || (_loader && _loader.contentLoaderInfo);
            if (target) {
                if (target.bytesTotal != 0 && target.bytesTotal == target.bytesLoaded) {
                    _postProcess();
                } else {
                    _addAllListeners(target);
                }
                return true;
            }
            return false;
        }
        
        
        private function _addAllListeners(dispatcher:EventDispatcher) : void 
        {
            dispatcher.addEventListener(Event.COMPLETE, _onComplete, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(ProgressEvent.PROGRESS, _onProgress, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, _onError, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError, false, _soundLoader._eventPriority);
        }
        
        
        private function _removeAllListeners() : void 
        {
            var dispatcher:EventDispatcher = _sound || _urlLoader || _fontLoader || _loader.contentLoaderInfo;
            dispatcher.removeEventListener(Event.COMPLETE, _onComplete);
            dispatcher.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
            dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, _onError);
            dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
        }
        
        
        private function _onProgress(e:ProgressEvent) : void
        {
            dispatchEvent(e.clone());
            _soundLoader._onProgress(this, e.bytesLoaded - _bytesLoaded, e.bytesTotal - _bytesTotal);
            _bytesLoaded = e.bytesLoaded;
            _bytesTotal = e.bytesTotal;
        }
        
        
        private function _onComplete(e:Event) : void
        {
            _removeAllListeners();
            _soundLoader._onProgress(this, e.target.bytesLoaded - _bytesLoaded, e.target.bytesTotal - _bytesTotal);
            _bytesLoaded = e.target.bytesLoaded;
            _bytesTotal = e.target.bytesTotal;
            _postProcess();
        }
        
        
        private function _postProcess() : void 
        {
            var currentBICID:String, pcmSample:PCMSample, smfData:SMFData;
            
            switch (_type) {
            case "mp3":
                _content = _sound;
                _soundLoader._onComplete(this);
                break;
            case "wav":
                currentBICID = PCMSample.basicInfoChunkID;
                PCMSample.basicInfoChunkID = "acid";
                pcmSample = new PCMSample().loadWaveFromByteArray(_urlLoader.data); 
                PCMSample.basicInfoChunkID = currentBICID;
                _content = pcmSample;
                _soundLoader._onComplete(this);
                break;
            case "mid":
                smfData = new SMFData().loadBytes(_urlLoader.data);
                _content = smfData;
                _soundLoader._onComplete(this);
                break;
            case "mp3bin":
                SoundClass.loadMP3FromByteArray(_urlLoader.data, __loadMP3FromByteArray_onComplete);
                break;
            case "ssf":
                _content = _fontLoader.soundFont;
                _soundLoader._onComplete(this);
                break;
            case "ssfpng":
                _convertBitmapDataToSoundFont(Bitmap(_loader.content).bitmapData as BitmapData);
                break;
                
            // for ordinary purpose
            case "img":
            case "b2img":
                _content = _loader.content;
                _soundLoader._onComplete(this);
                break;
            case "txt":
            case "bin":
            case "var":
                _content = _urlLoader.data;
                _soundLoader._onComplete(this);
                break;
            }
        }
        
        
        private function _onError(e:ErrorEvent) : void
        {
            _removeAllListeners();
            __errorCallback(e);
        }
        
        
        private function __loadMP3FromByteArray_onComplete(sound:Sound) : void
        {
            _content = sound;
            _soundLoader._onComplete(this);
        }
        
        
        private function _convertBitmapDataToSoundFont(bitmap:BitmapData) : void
        {
            var bitmap2bytes:ByteArrayExt = new ByteArrayExt(); // convert BitmapData to ByteArray
            _loader = null;
            _fontLoader = new SiONSoundFontLoader();            // convert ByteArray to SWF and SWF to soundList
            _fontLoader.addEventListener(Event.COMPLETE, __convertB2SF_onComplete);
            _fontLoader.addEventListener(IOErrorEvent.IO_ERROR, __errorCallback);
            _fontLoader.loadBytes(bitmap2bytes.fromBitmapData(bitmap));
        }
        
        
        private function __convertB2SF_onComplete(e:Event) : void
        { 
            _content = _fontLoader.soundFont;
            _soundLoader._onComplete(this);
        }
        
        
        private function __errorCallback(e:ErrorEvent) : void
        {
            _soundLoader._onError(this, e.toString());
        }
    }
}


