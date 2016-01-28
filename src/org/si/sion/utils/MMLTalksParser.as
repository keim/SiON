package org.si.sion.utils {
    import flash.events.*;
    import flash.media.*;
    import flash.net.*;
    import flash.utils.*;
    import org.si.sion.*;
    import org.si.sion.sequencer.*;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.utils.soundloader.*;
    import org.si.sion.midi.SMFData;
    
    
    /** Add System command for MMLTalks (#LOADSOUND, #PRESET)
     */
    public class MMLTalksParser {
    // variables
    //--------------------------------------------------
        /** preset voice set to execute #PRESET */
        static public var presetVoices:SiONPresetVoice = null;
        /** allow to play MIDI file by #LOADSOUND */
        static public var allowMIDIFile:Boolean = false;
        
        static private var _sionDriver:SiONDriver = null;
        static private var _sionData:SiONData = null;
        static private var _smfData:SMFData = null;
        static private var _mmlString:String = null;
        static private var _soundLoader:SoundLoader = null;
        static private var _errorHandler:Function = null;
        static private var _completeHandler:Function = null;
        static private var _progressHandler:Function = null;
        
        
        
    // event handler
    //--------------------------------------------------
        static private function _onError(e:ErrorEvent) : void {
            if (_errorHandler != null) _errorHandler(e);
        }
        
        
        static private function _onProgress(e:ProgressEvent) : void {
            if (_progressHandler != null) _progressHandler(e);
        }


        

    // commands
    //--------------------------------------------------
        /** call this first after create new SiONDriver
         *  @param driver SiONDriver instance to play.
         *  @param onError compile or loading error event hondler
         *  @param onProgress loading progression event hondler
         */
        static public function initialize(driver:SiONDriver, onError:Function=null, onProgress:Function=null) : void
        {
            _sionDriver = driver;
            _soundLoader = new SoundLoader(0, false, true, true);
            _soundLoader.addEventListener(Event.COMPLETE, _onCompleteAllLoading);
            _soundLoader.addEventListener(ErrorEvent.ERROR, _onError);
            _soundLoader.addEventListener(ProgressEvent.PROGRESS, _onProgress);
            _errorHandler = onError;
            _progressHandler = onProgress;
        }


        /** set url to loading resource if needs.
         *  @param url URL of the resource to load
         */
        static public function setURL(url:String) : SoundLoaderFileData
        {
            return _soundLoader.setURL(new URLRequest(url));
        }
        
        
        /** compile MML. This function is asynchronous. You have to play data in onComplete function
         *  @param mml MML string
         *  @param onComplete compile complete event hondler, function(data:*):void
         *  @param data SiONData to receive compiled data
         */
        static public function compile(mml:String, onComplete:Function, data:SiONData=null) : void 
        {
            _mmlString = mml;
            _completeHandler = onComplete;
            _sionData = data;
            _parseMTSystemCommandBeforeCompile(mml);
        }


        
        
    // internals
    //--------------------------------------------------
        // callback while system command parsing. you have to copmle MML after all sound loaded.
        static private function _parseMTSystemCommandBeforeCompile(mml:String) : void {
            var cmds:Array = Translator.extractSystemCommand(mml), cmd:*, array:Array, ba:ByteArray, src:ByteArray, 
                i:int, url:String, fileData:SoundLoaderFileData;

            // list all Sound requires loading
            for (i=0; i<cmds.length; i++) {
                cmd = cmds[i];
                switch(cmd.command){
                case "#LOADSOUND":
                    //data
                    url = cmd.content;
                    fileData = _soundLoader.setURL(new URLRequest(url));
                    break;
                }
            }

            // load all
            _soundLoader.loadAll();
        }
        
        
        // analyze MMLTalks system commands.
        static private function _parseMTSystemCommandAfterCompile(data:SiONData) : void {
            var voice:SiONVoice, offset:int, i:int;
            
            for each (var cmd:* in data.systemCommands) {
                switch(cmd.command){
                case "#PRESET@":
                    if (!presetVoices) presetVoices = new SiONPresetVoice();
                    voice = presetVoices[cmd.content];
                    if (voice is SiONVoice) data.setVoice(cmd.number, voice);
                    break;
                }
            }
        }

        
        // on complete all
        static private function _onCompleteAllLoading(e:Event) : void {
            var key:String, i:int, data:SiONData;
            var soundHash:* = {};
             
            // construct sound hash table and font list
            _smfData = null;
            for (key in _soundLoader.hash) {
                if (_soundLoader.hash[key] is Sound) {
                    soundHash[key] = _soundLoader.hash[key];
                } else if (_soundLoader.hash[key] is SMFData) {
                    _smfData = _soundLoader.hash[key];
                }
            }

            // set sound hash & compile
            _sionDriver.setSoundReferenceTable(soundHash);
            _sionDriver.compile(_mmlString, _sionData);
            data = _sionData || _sionDriver.data;
            _parseMTSystemCommandAfterCompile(data);
            _mmlString = null;
            if (allowMIDIFile && _smfData) {
                _sionDriver.midiModule.resetVoiceSet();
                for (i=0; i<128; i++) {
                    if (data.fmVoices[i]) _sionDriver.midiModule.voiceSet[i].copyFrom(data.fmVoices[i]);
                }
                for (i=0; i<60; i++) {
                    if (data.fmVoices[i+128]) _sionDriver.midiModule.drumVoiceSet[i].copyFrom(data.fmVoices[i+128]);
                }
                _completeHandler(_smfData);
            } else {
                _completeHandler(data);
            }
        }
    }
}
