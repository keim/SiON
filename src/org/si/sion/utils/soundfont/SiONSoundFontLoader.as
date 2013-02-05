//----------------------------------------------------------------------------------------------------
// SiON sound font loader
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.utils.soundfont {
    import flash.events.*;
    import flash.net.*;
    import flash.display.Loader;
    import flash.system.LoaderContext;
    import flash.utils.ByteArray;
    import org.si.sion.*;
    import org.si.sion.utils.*;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.*;
    import org.si.utils.ByteArrayExt;
    
    /** Sound font loader. */
    public class SiONSoundFontLoader extends EventDispatcher
    {
    // variables
    //--------------------------------------------------
        /** SiONSoundFont instance. this instance is available after finish loading. */
        public var soundFont:SiONSoundFont;
        
        // loaders
        private var _binloader:URLLoader;
        private var _swfloader:Loader;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** loaded size. */
        public function get bytesLoaded() : Number 
        {
            return (_swfloader) ? _swfloader.contentLoaderInfo.bytesLoaded : (_binloader) ? _binloader.bytesLoaded : 0;
        }
        
        
        /** total size. */
        public function get bytesTotal() : Number 
        {
            return (_swfloader) ? _swfloader.contentLoaderInfo.bytesTotal : (_binloader) ? _binloader.bytesTotal : 0;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        public function SiONSoundFontLoader()
        {
            soundFont = null;
            _binloader = null;
            _swfloader = null;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** load sound font from url
         *  @param url requesting url
         *  @param loadAsBinary load soundfont swf as binary and convert to swf.
         *  @param checkPolicyFile check policy file. this argument is ignored when loadAsBinary is true.
         */
        public function load(url:URLRequest, loadAsBinary:Boolean=true, checkPolicyFile:Boolean=false) : void
        {
            if (loadAsBinary) {
                _addAllListeners(_binloader = new URLLoader());
                _binloader.dataFormat = URLLoaderDataFormat.BINARY;
                _binloader.load(url);
            } else {
                _swfloader = new Loader();
                _addAllListeners(_swfloader.contentLoaderInfo);
                _swfloader.load(url, new LoaderContext(checkPolicyFile));
            }
        }
        
        
        /** load sound font from binary 
         *  @param bytes ByteArray to load from.
         */
        public function loadBytes(bytes:ByteArray) : void {
            _binloader = null;
            var signature:uint = bytes.readUnsignedInt();
            if (signature == 0x0b535743) { // swf
                _swfloader = new Loader();
                _addAllListeners(_swfloader.contentLoaderInfo);
                _swfloader.loadBytes(bytes);
            } else if (signature == 0x04034b50) { // zip
                
            }
        }
        
        
        
        
    // event handling
    //--------------------------------------------------
        private function _addAllListeners(dispatcher:EventDispatcher) : void 
        {
            dispatcher.addEventListener(Event.COMPLETE, _onComplete);
            dispatcher.addEventListener(ProgressEvent.PROGRESS, _onProgress);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, _onError);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
        }
        
        
        private function _removeAllListeners() : void 
        {
            var dispatcher:EventDispatcher = _binloader || _swfloader.contentLoaderInfo;
            dispatcher.removeEventListener(Event.COMPLETE, _onComplete);
            dispatcher.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
            dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, _onError);
            dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
        }
        
        
        private function _onComplete(e:Event) : void
        {
            _removeAllListeners();
            if (_binloader) loadBytes(_binloader.data);
            else {
                _analyze();
                dispatchEvent(e.clone());
            }
        }
        
        
        private function _onProgress(e:Event) : void { dispatchEvent(e.clone()); }
        private function _onError(e:ErrorEvent) : void { _removeAllListeners(); dispatchEvent(e.clone()); }
        
        
        
        
    // internal functions
    //--------------------------------------------------
        private function _analyze() : void
        {
            var container:SiONSoundFontContainer = _swfloader.content as SiONSoundFontContainer;
            if (!container) _onError(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "The sound font file is not valid."));
            
            // create new sound font instance
            soundFont = new SiONSoundFont(container.sounds);
            
            // parse mml
            switch (container.version) {
            case "1":
                _compileSystemCommand(Translator.extractSystemCommand(container.mml));
                break;
            }
        }
        
        
        private function _analyzeZip(bytes:ByteArray) : void
        {
            var fileList:Vector.<ByteArrayExt> = new ByteArrayExt(bytes).expandZipFile();
            var i:int, imax:int = fileList.length, sounds:Array = {}, mml:String, snd:Sound, file:ByteArrayExt;
            for (i=0; i<imax; i++) {
                file = fileList[i];
                if (/\.mp3$/.test(file.name)) {
                    sounds[file.name] = snd = new Sound();
                    snd.loadCompressedDataFromByteArray(file, file.length);
                } else {
                    mml = file.readUTF();
                }
            }
            _compileSystemCommand(Translator.extractSystemCommand(mml));
        }
        
        
        // compile sound font from system commands
        private function _compileSystemCommand(systemCommands:Array) : void
        {
            var i:int, imax:int = systemCommands.length, cmd:*, num:int, dat:String, pfx:String, bank:int, 
                env:SiMMLEnvelopTable, voice:SiONVoice, samplerTable:SiOPMWaveSamplerTable, pcmTable:SiOPMWavePCMTable;
            
            for (i=0; i<imax; i++) {
                cmd = systemCommands[i];
                num = cmd.number;
                dat = cmd.content;
                pfx = cmd.postfix;
                
                switch (cmd.command) {
                // tone settings
                case '#@':    { __parseToneParam(Translator.parseParam);    break; }
                case '#OPM@': { __parseToneParam(Translator.parseOPMParam); break; }
                case '#OPN@': { __parseToneParam(Translator.parseOPNParam); break; }
                case '#OPL@': { __parseToneParam(Translator.parseOPLParam); break; }
                case '#OPX@': { __parseToneParam(Translator.parseOPXParam); break; }
                case '#MA@':  { __parseToneParam(Translator.parseMA3Param); break; }
                case '#AL@':  { __parseToneParam(Translator.parseALParam);  break; }
                    
                // parser settings
                case '#FPS':   { soundFont.defaultFPS = (num>0) ? num : ((dat == "") ? 60 : int(dat)); break; }
                case '#VMODE': { _parseVCommansSubMML(dat); break; }

                // tables
                case '#TABLE': {
                    if (num < 0 || num > 254) throw _errorParameterNotValid("#TABLE", String(num));
                    env = new SiMMLEnvelopTable().parseMML(dat, pfx);
                    if (!env.head) throw _errorParameterNotValid("#TABLE", dat);
                    soundFont.envelopes[num] = env;
                    break;
                }
                case '#WAV': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#WAV", String(num));
                    soundFont.waveTables[num] = _newWaveTable(Translator.parseWAV(dat, pfx));
                    break;
                }
                case '#WAVB': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#WAVB", String(num));
                    soundFont.waveTables[num] = _newWaveTable(Translator.parseWAVB((dat=="") ? pfx : dat));
                    break;
                }
        
                // pcm voice
                case '#SAMPLER': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#SAMPLER", String(num));
                    bank = (num>>SiOPMTable.NOTE_BITS) & (SiOPMTable.SAMPLER_TABLE_MAX-1);
                    num &= (SiOPMTable.NOTE_TABLE_SIZE-1);
                    if (!soundFont.samplerTables[bank]) soundFont.samplerTables[bank] = new SiOPMWaveSamplerTable();
                    samplerTable = soundFont.samplerTables[bank];
                    if (!Translator.parseSamplerWave(samplerTable, num, dat, soundFont.sounds)) _errorParameterNotValid("#SAMPLER", String(num));
                    break;
                }
                case '#PCMWAVE': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#PCMWAVE", String(num));
                    if (!soundFont.pcmVoices[num]) soundFont.pcmVoices[num] = new SiONVoice();
                    voice = soundFont.pcmVoices[num];
                    if (!(voice.waveData is SiOPMWavePCMTable)) voice.waveData = new SiOPMWavePCMTable();
                    pcmTable = voice.waveData as SiOPMWavePCMTable;
                    if (!Translator.parsePCMWave(pcmTable, dat, soundFont.sounds)) _errorParameterNotValid("#PCMWAVE", String(num));
                    break;
                }
                case '#PCMVOICE': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#PCMVOICE", String(num));
                    if (!soundFont.pcmVoices[num]) soundFont.pcmVoices[num] = new SiONVoice();
                    voice = soundFont.pcmVoices[num];
                    if (!Translator.parsePCMVoice(voice, dat, pfx, soundFont.envelopes)) _errorParameterNotValid("#PCMVOICE", String(num));
                    break;
                }
                default:
                    break;
                }
            }
            
            
            function __parseToneParam(func:Function) : void {
                voice = new SiONVoice();
                func(voice.channelParam, dat);
                if (pfx.length > 0) Translator.parseVoiceSetting(voice, pfx);
                soundFont.fmVoices[num] = voice;
            }
        }
        
        
        // Parse inside of #VMODE{...}
        private function _parseVCommansSubMML(dat:String) : void
        {
            var tcmdrex:RegExp = /(n88|mdx|psg|mck|tss|%[xv])(\d*)(\s*,?\s*(\d?))/g;
            var res:*, num:Number, i:int;
            while (res = tcmdrex.exec(dat)) {
                switch(String(res[1])) {
                case "%v":
                    i = int(res[2]);
                    soundFont.defaultVelocityMode = (i>=0 && i<SiOPMTable.VM_MAX) ? i : 0;
                    i = (res[4] != "") ? int(res[4]) : 4;
                    soundFont.defaultVCommandShift = (i>=0 && i<8) ? i : 0;
                    break;
                case "%x":
                    i = int(res[2]);
                    soundFont.defaultExpressionMode = (i>=0 && i<SiOPMTable.VM_MAX) ? i : 0;
                    break;
                case "n88": case "mdx":
                    soundFont.defaultVelocityMode = SiOPMTable.VM_DR32DB;
                    soundFont.defaultExpressionMode = SiOPMTable.VM_DR48DB;
                    break;
                case "psg":
                    soundFont.defaultVelocityMode = SiOPMTable.VM_DR48DB;
                    soundFont.defaultExpressionMode = SiOPMTable.VM_DR48DB;
                    break;
                default: // mck/tss
                    soundFont.defaultVelocityMode = SiOPMTable.VM_LINEAR;
                    soundFont.defaultExpressionMode = SiOPMTable.VM_LINEAR;
                    break;
                }
            }
        }
        
        
        // Set wave table data refered by %4
        private function _newWaveTable(data:Vector.<Number>) : SiOPMWaveTable
        {
            var i:int, imax:int=data.length, table:Vector.<int> = new Vector.<int>(imax);
            for (i=0; i<imax; i++) table[i] = SiOPMTable.calcLogTableIndex(data[i]);
            return SiOPMWaveTable.alloc(table);
        }
        
        
        private function _errorParameterNotValid(cmd:String, param:String) : Error
        {
            return new Error("SiMMLSequencer error : Parameter not valid. '" + param + "' in " + cmd);
        }
    }
}

