//----------------------------------------------------------------------------------------------------
// MDX data class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.events.*;
    import flash.utils.ByteArray;
    import flash.net.URLRequest;
    import org.si.sion.*;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMOperatorParam;
    import org.si.sion.sequencer.base.MMLEvent;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.utils.AbstructLoader;
    
    
    /** MDX data class */
    public class MDXData extends AbstructLoader
    {
    // variables
    //--------------------------------------------------------------------------------
        public var isPCM8:Boolean;
        public var bpm:Number = 0;
        public var title:String = null;
        public var pdxFileName:String = null;
        public var voices:Vector.<SiONVoice> = new Vector.<SiONVoice>(256, true);
        public var tracks:Vector.<MDXTrack> = new Vector.<MDXTrack>(16, true);
        public var executors:Vector.<MDXExecutor> = new Vector.<MDXExecutor>(16, true);
        
        private var _noiseVoice:SiONVoice;
        private var _noiseVoiceNumber:int;
        private var _currentBPM:Number;
        private var _globalSequence:MMLSequence;
        private var _globalPrevClock:uint;
        
        static private var _loadPDXDataAutomaticaly:Boolean = false;
        static private var _pdxDataStorage:PDXDataStorage;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** load PDXData automaticaly, if this flag is true, new PDXDataStorage instance is create internaly. */
        static public function get loadPDXDataAutomaticaly() : Boolean {
            return _loadPDXDataAutomaticaly;
        }
        static public function set loadPDXDataAutomaticaly(b:Boolean) : void {
            if (b && _pdxDataStorage == null) _pdxDataStorage = new PDXDataStorage();
            _loadPDXDataAutomaticaly = b;
        }
        
        
        /** Is avaiblable ? */
        public function isAvailable() : Boolean { return false; }
        
        
        /** to string. */
        override public function toString() : String
        {
            var text:String = "";
            return text;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** constructor */
        function MDXData(url:URLRequest=null)
        {
            for (var i:int=0; i<16; i++) executors[i] = new MDXExecutor();
            _noiseVoice = new SiONVoice(2, 1);
            _noiseVoice.channelParam.operatorParam[0].ptType = SiOPMTable.PT_OPM_NOISE;
            if (url != null) load(url);
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : MDXData
        {
            var i:int;
            isPCM8 = false;
            bpm = 0;
            title = null;
            pdxFileName = null;
            for (i=0; i<16; i++) tracks[i] = null;
            for (i=0; i<256; i++) voices[i] = null;
            _noiseVoiceNumber = -1;
            return this;
        }
        
        
        /** convert to SiONData 
         *  @param data SiONData to convert to, pass null to create new SiONData inside.
         *  @return converted SiONData
         */
        public function convertToSiONData(data:SiONData=null, pdxData:PDXData=null) : SiONData
        {
            if (SiONDriver.mutex == null) throw new Error("MDXData.convertToSiONData() : This function can be called after creating SiONDriver.");
            
            var i:int, imax:int;
            
            if (data == null) data = new SiONData();
            data.clear();
            data.bpm = bpm;
            _globalSequence = data.globalSequence;
            
            // set voice data
            imax = voices.length;
            for (i=0; i<imax; i++) data.fmVoices[i] = voices[i];
            
            // set adpcm data
            if (pdxData) {
                imax = 96;
                for (i=0; i<imax; i++) {
                    if (pdxData.extract(i)) data.setPCMData(i, pdxData.pcmData[i]);
                }
            }
            
            // construct mml sequences
            imax = (isPCM8) ? 16 : 9;
            for (i=0; i<imax; i++) {
                if (tracks[i].hasNoData) executors[i].initialize(null, tracks[i], _noiseVoiceNumber, isPCM8);
                else executors[i].initialize(data.appendNewSequence().initialize(), tracks[i], _noiseVoiceNumber, isPCM8);
            }

            var totalClock:uint=0, nextClock:uint, c:uint;
            _currentBPM = bpm;
            _globalPrevClock = 0;
            while (totalClock != uint.MAX_VALUE) {
                // sync
                for (i=0; i<imax; i++) {
                    executors[i].globalExec(totalClock, this);
                }
                // exec
                nextClock = uint.MAX_VALUE;
                for (i=0; i<imax; i++) {
                    c = executors[i].exec(totalClock, _currentBPM);
                    if (c < nextClock) nextClock = c;
                }
                totalClock = nextClock;
            }
            
            data.title = title;
            
            return data;
        }
        
        
        /** Load MDX data from byteArray. */
        public function loadBytes(bytes:ByteArray) : MDXData
        {
            _loadBytes(bytes);
            dispatchEvent(new Event(Event.COMPLETE));
            return this;
        }
        
        
        
        
    // handlers
    //--------------------------------------------------------------------------------
        /** @private */
        override protected function onComplete() : void
        {
            if (_loader.dataFormat == "binary") {
                _loadBytes(_loader.data as ByteArray);
                if (pdxFileName != null && _loadPDXDataAutomaticaly) {
                    addChild(_pdxDataStorage.load(new URLRequest(pdxFileName)));
                }
            }
        }
        
        
        
        
    // privates
    //--------------------------------------------------------------------------------
        // load from byte array
        private function _loadBytes(bytes:ByteArray) : void
        {
            var titleLength:int, pdxLength:int, dataPointer:int, voiceOffset:int, voiceLength:int,
                voiceCount:int, i:int, mmlOffsets:Array = new Array(16);
            
            // initialize
            clear();
            bytes.endian = "bigEndian";
            bytes.position = 0;
            
            // title
            while (true) { if (bytes.readByte() == 0x0d && bytes.readByte() == 0x0a && bytes.readByte() == 0x1a) break; }
            titleLength = bytes.position - 3;
            bytes.position = 0;
            title = bytes.readMultiByte(titleLength, "shift_jis"); //us-ascii
            bytes.position = titleLength + 3;
            
            // pdx file
            while (true) { if (bytes.readByte() == 0) break; }
            pdxLength = bytes.position - titleLength - 4;
            bytes.position = titleLength + 3;
            if (pdxLength != 0) {
                pdxFileName = bytes.readMultiByte(pdxLength, "shift_jis").toUpperCase(); //us-ascii
                if (pdxFileName.substr(-4,4) != ".PDX") pdxFileName += ".PDX";
            }
            bytes.position = titleLength + pdxLength + 4;
            
            // data offsets
            dataPointer = bytes.position;
            voiceOffset = bytes.readUnsignedShort();  // tone data
            for (i=0; i<16; i++) mmlOffsets[i] = dataPointer + bytes.readUnsignedShort();
            // check pcm8
            bytes.position = mmlOffsets[0];
            isPCM8 = (bytes.readUnsignedByte() == 0xe8);
            
            // load voices
            bytes.position = dataPointer + voiceOffset;
            voiceLength = (mmlOffsets[0] > voiceOffset) ? (mmlOffsets[0] - voiceOffset) : (bytes.length - dataPointer - voiceOffset);  // ...?
            _loadVoices(bytes, voiceLength);
            
            // load tracks
            _loadTracks(bytes, mmlOffsets);
        }
        
        
        // Load voice data from byteArray.
        private function _loadVoices(bytes:ByteArray, voiceLength:int) : void
        {
            var i:int, opi:int, v:int, voice:SiONVoice, voiceNumber:int, fbalg:int, mask:int, 
                opp:SiOPMOperatorParam, reg:Array = [], opia:Array = [3,1,2,0], dt2Table:Array = [0, 384, 500, 608];
            
            voiceLength /= 27;
            for (i=0; i<voiceLength; i++) {
                voiceNumber = bytes.readUnsignedByte();
                fbalg = bytes.readUnsignedByte();
                mask  = bytes.readUnsignedByte();
                for (opi=0; opi<6; opi++) { reg[opi] = bytes.readUnsignedInt(); }
                
                if (voices[voiceNumber] == null) voices[voiceNumber] = new SiONVoice();
                voice = voices[voiceNumber];
                voice.initialize();
                voice.chipType = SiONVoice.CHIPTYPE_OPM;
                voice.channelParam.opeCount = 4;
                
                voice.channelParam.fb  = (fbalg >> 3) & 7;
                voice.channelParam.alg = (fbalg) & 7;
                
                for (opi=0; opi<4; opi++) {
                    opp = voice.channelParam.operatorParam[opia[opi]];
                    opp.mute = (((mask >> opi) & 1) == 0);
                    v = (reg[0] >> (opi<<3)) & 255;
                    opp.dt1  = (v >> 4) & 7;
                    opp.mul  = v & 15;
                    opp.tl   = (reg[1] >> (opi<<3)) & 127;
                    v = (reg[2] >> (opi<<3)) & 255;
                    opp.ksr = (v >> 6) & 3;
                    opp.ar  = (v & 31) << 1;
                    v = (reg[3] >> (opi<<3)) & 255;
                    opp.ams = ((v >> 7) & 1) << 1;
                    opp.dr  = (v & 31) << 1;
                    v = (reg[4] >> (opi<<3)) & 255;
                    opp.detune = dt2Table[(v >> 6) & 3];
                    opp.sr     = (v & 31) << 1;
                    v = (reg[5] >> (opi<<3)) & 255;
                    opp.sl = (v >> 4) & 15;
                    opp.rr = (v & 15) << 2;
                }
                
//trace(voice.getMML(voiceNumber));
            }
            
            _noiseVoiceNumber = -1;
            for (i=255; i>=0; --i) {
                if (voices[i] == null) {
                    _noiseVoiceNumber = i;
                    voices[i] = _noiseVoice;
                    break;
                }
            }
        }
        
        
        // load mml tracks
        private function _loadTracks(bytes:ByteArray, mmlOffsets:Array) : void
        {
            var i:int, imax:int = (isPCM8) ? 16 : 9;
            // load tracks
            bpm = 0;
            for (i=0; i<imax; i++) {
                bytes.position = mmlOffsets[i];
                tracks[i] = new MDXTrack(this, i);
                tracks[i].loadBytes(bytes);
                if (tracks[i].timerB != -1 && bpm == 0) {
                    bpm = 4883/(256-tracks[i].timerB);
                }
            }
            if (bpm == 0) bpm = 87.19642857142857; // 4883/(256-200)
        }
        
        
        /** @private [internal] call from MDXExecutor.sync() */
        internal function onSyncSend(channelNumber:int, syncClock:uint) : void
        {
            executors[channelNumber & 15].sync(syncClock);
        }
        
        
        /** @private [internal] call from MDXExecutor.sync() */
        internal function onTimerB(timerB:int, syncClock:uint) : void
        {
            if (syncClock == 0) return;
            if (syncClock > _globalPrevClock) _globalSequence.appendNewEvent(MMLEvent.GLOBAL_WAIT, 0, (syncClock - _globalPrevClock)*10);
            _globalPrevClock = syncClock;
            _currentBPM = 4883/(256-timerB);
            _globalSequence.appendNewEvent(MMLEvent.TEMPO, _currentBPM);
        }
    }
}

