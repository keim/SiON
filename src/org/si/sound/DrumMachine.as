//----------------------------------------------------------------------------------------------------
// Class for play drum tracks
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.SiONData;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers.DrumMachinePresetVoice;
    import org.si.sound.patterns.DrumMachinePresetPattern;
    import org.si.sound.patterns.Sequencer;
    import org.si.sound.patterns.Note;
    import org.si.sound.events.SoundObjectEvent;
    
    /** @eventType org.si.sound.events.SoundObjectEvent.ENTER_FRAME */
    [Event(name="enterFrame",   type="org.si.sound.events.SoundObjectEvent")]
    /** @eventType org.si.sound.events.SoundObjectEvent.ENTER_SEGMENT */
    [Event(name="enterSegment", type="org.si.sound.events.SoundObjectEvent")]
    
    /** Drum machinie provides independent bass drum, snare drum and hihat symbals tracks. */
    public class DrumMachine extends MultiTrackSoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // static variables
    //----------------------------------------
        static private var _presetVoice:DrumMachinePresetVoice = null;
        static private var _presetPattern:DrumMachinePresetPattern = null;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] bass drum pattern sequencer */
        protected var _bass:Sequencer;
        /** @private [protected] snare drum pattern sequencer */
        protected var _snare:Sequencer;
        /** @private [protected] hi-hat cymbal pattern sequencer */
        protected var _hihat:Sequencer;
        
        /** @private [protected] Sequence data */
        protected var _data:SiONData;

        /** @private [protected] bass drum pattern number */
        protected var _bassPatternNumber:int;
        /** @private [protected] snare drum pattern number */
        protected var _snarePatternNumber:int;
        /** @private [protected] hi-hat cymbal pattern number */
        protected var _hihatPatternNumber:int;
        /** @private [protected] bass drum voice number */
        protected var _bassVoiceNumber:int;
        /** @private [protected] snare drum voice number */
        protected var _snareVoiceNumber:int;
        /** @private [protected] hi-hat cymbal voice number */
        protected var _hihatVoiceNumber:int;
        /** @private [protected] Change bass line pattern at the head of segment. */
        protected var _changePatternOnSegment:Boolean;
        
        // preset pattern list
        static private var bassPatternList:Array;
        static private var snarePatternList:Array;
        static private var hihatPatternList:Array;
        static private var percusPatternList:Array;
        static private var bassVoiceList:Array;
        static private var snareVoiceList:Array;
        static private var hihatVoiceList:Array;
        static private var percusVoiceList:Array;
        
        
        
    // properties
    //----------------------------------------
        /** Preset voices */
        public function get presetVoice() : DrumMachinePresetVoice { return _presetVoice; }
        
        /** Preset patterns */
        public function get presetPattern() : DrumMachinePresetPattern { return _presetPattern; }
        
        /** maximum value of basePatternNumber */  public function get bassPatternNumberMax()  : int { return bassPatternList.length; }
        /** maximum value of snarePatternNumber */ public function get snarePatternNumberMax() : int { return snarePatternList.length; }
        /** maximum value of hihatPatternNumber */ public function get hihatPatternNumberMax() : int { return hihatPatternList.length; }
        /** maximum value of baseVoiceNumber */    public function get bassVoiceNumberMax()  : int { return bassVoiceList.length>>1; }
        /** maximum value of snareVoiceNumber */   public function get snareVoiceNumberMax() : int { return snareVoiceList.length>>1; }
        /** maximum value of hihatVoiceNumber */   public function get hihatVoiceNumberMax() : int { return hihatVoiceList.length>>1; }
        
        
        /** Sequencer object of bass drum */
        public function get bass()  : Sequencer { return _bass; }
        /** Sequencer object of snare drum */
        public function get snare() : Sequencer { return _snare; }
        /** Sequencer object of hihat symbal */
        public function get hihat() : Sequencer { return _hihat; }
        
        /** Sequence pattern of bass drum */
        public function get bassPattern()  : Vector.<Note> { return _bass.pattern || _bass.nextPattern; }
        public function set bassPattern(pat:Vector.<Note>)  : void {
            if (isPlaying && _changePatternOnSegment) _bass.nextPattern = pat;
            else _bass.pattern = pat;
        }
        /** Sequence pattern of snare drum */
        public function get snarePattern() : Vector.<Note> { return _snare.pattern || _snare.nextPattern; }
        public function set snarePattern(pat:Vector.<Note>) : void {
            if (isPlaying && _changePatternOnSegment) _snare.nextPattern = pat;
            else _snare.pattern = pat;
        }
        /** Sequence pattern of hihat symbal */
        public function get hihatPattern() : Vector.<Note> { return _hihat.pattern || _hihat.nextPattern; }
        public function set hihatPattern(pat:Vector.<Note>) : void {
            if (isPlaying && _changePatternOnSegment) _hihat.nextPattern = pat;
            else _hihat.pattern = pat;
        }
        
        /** bass drum pattern number. */
        public function get bassPatternNumber() : int { return _bassPatternNumber; }
        public function set bassPatternNumber(index:int) : void {
            if (index < 0 || index >= bassPatternList.length) return;
            _bassPatternNumber = index;
            bassPattern = bassPatternList[index];
        }
        
        
        /** snare drum pattern number. */
        public function get snarePatternNumber() : int { return _snarePatternNumber; }
        public function set snarePatternNumber(index:int) : void {
            if (index < 0 || index >= snarePatternList.length) return;
            _snarePatternNumber = index;
            if (_changePatternOnSegment) snare.nextPattern = snarePatternList[index];
            else snare.pattern = snarePatternList[index];
        }
        
        
        /** hi-hat cymbal pattern number. */
        public function get hihatPatternNumber() : int { return _hihatPatternNumber; }
        public function set hihatPatternNumber(index:int) : void {
            if (index < 0 || index >= hihatPatternList.length) return;
            _hihatPatternNumber = index;
            if (_changePatternOnSegment) hihat.nextPattern = hihatPatternList[index];
            else hihat.pattern = hihatPatternList[index];
        }
        
        
        /** bass drum pattern number. */
        public function get bassVoiceNumber() : int { return _bassVoiceNumber>>1; }
        public function set bassVoiceNumber(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= bassVoiceList.length) return;
            _bassVoiceNumber = index;
            bass.voiceList = [bassVoiceList[index], bassVoiceList[index+1]];
        }
        
        
        /** snare drum pattern number. */
        public function get snareVoiceNumber() : int { return _snareVoiceNumber>>1; }
        public function set snareVoiceNumber(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= snareVoiceList.length) return;
            _snareVoiceNumber = index;
            snare.voiceList = [snareVoiceList[index], snareVoiceList[index+1]];
        }
        
        
        /** hi-hat cymbal pattern number. */
        public function get hihatVoiceNumber() : int { return _hihatVoiceNumber>>1; }
        public function set hihatVoiceNumber(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= hihatVoiceList.length) return;
            _hihatVoiceNumber = index;
            hihat.voiceList = [hihatVoiceList[index], hihatVoiceList[index+1]];
        }
        
        /** bass drum volume (0-1) */
        public function get bassVolume() : Number { return _bass.defaultVelocity * 0.00392156862745098; }
        public function set bassVolume(n:Number) : void {
            if (n < 0) n = 0;
            else if (n > 1) n = 1;
            _bass.defaultVelocity = n * 255;
        }
        
        /** snare drum volume (0-1) */
        public function get snareVolume() : Number { return _snare.defaultVelocity * 0.00392156862745098; }
        public function set snareVolume(n:Number) : void {
            if (n < 0) n = 0;
            else if (n > 1) n = 1;
            _snare.defaultVelocity = n * 255;
        }
        
        /** hihat symbal volume (0-1) */
        public function get hihatVolume() : Number { return _hihat.defaultVelocity * 0.00392156862745098; }
        public function set hihatVolume(n:Number) : void {
            if (n < 0) n = 0;
            else if (n > 1) n = 1;
            _hihat.defaultVelocity = n * 255;
        }
        
        
        /** True to change bass line pattern at the head of segment. @default true */
        public function get changePatternOnNextSegment() : Boolean { return _changePatternOnSegment; }
        public function set changePatternOnNextSegment(b:Boolean) : void { 
            _changePatternOnSegment = b;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param bassPatternNumber bass drum pattern number
         *  @param snarePatternNumber snare drum pattern number
         *  @param hihatPatternNumber hihat symbal pattern number
         *  @param bassVoiceNumber bass drum voice number
         *  @param snareVoiceNumber snare drum voice number
         *  @param hihatVoiceNumber hihat symbal voice number
         */
        function DrumMachine(bassPatternNumber:int=0, snarePatternNumber:int=8, hihatPatternNumber:int=0, bassVoiceNumber:int=0, snareVoiceNumber:int=0, hihatVoiceNumber:int=0)
        {
            if (_presetVoice == null) {
                _presetVoice = new DrumMachinePresetVoice();
                _presetPattern = new DrumMachinePresetPattern();
                bassPatternList   = _presetPattern["bass"];
                snarePatternList  = _presetPattern["snare"];
                hihatPatternList  = _presetPattern["hihat"];
                percusPatternList = _presetPattern["percus"];
                bassVoiceList   = _presetVoice["bass"];
                snareVoiceList  = _presetVoice["snare"];
                hihatVoiceList  = _presetVoice["hihat"];
                percusVoiceList = _presetVoice["percus"];
            }
            
            super("DrumMachine");
            
            _data = new SiONData();
            _bass   = new Sequencer(this, _data, 36, 255, 1);
            _snare  = new Sequencer(this, _data, 68, 160, 1);
            _hihat  = new Sequencer(this, _data, 68, 128, 1);
            this.bassVoiceNumber = bassVoiceNumber;
            this.snareVoiceNumber = snareVoiceNumber;
            this.hihatVoiceNumber = hihatVoiceNumber;
            _changePatternOnSegment = true;
            
            setPatternNumbers(bassPatternNumber, snarePatternNumber, hihatPatternNumber);
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** play drum sequence */
        override public function play() : void
        {
            var tn:int, seq:Sequencer;
            
            stop();
            _tracks = _sequenceOn(_data, false, false);
            if (_tracks && _tracks.length == 3) {
                _synthesizer._registerTracks(_tracks);
                _bass.play(_tracks[0]);
                _snare.play(_tracks[1]);
                _hihat.play(_tracks[2]);
                if (_tracks[0].trackNumber < _tracks[1].trackNumber) {
                    tn = (_tracks[0].trackNumber < _tracks[2].trackNumber) ? 0 : 2;
                } else {
                    tn = (_tracks[1].trackNumber < _tracks[2].trackNumber) ? 1 : 2;
                }
                switch (tn) {
                case 0:  seq = _bass;  break;
                case 1:  seq = _snare; break;
                default: seq = _hihat; break;
                }
                seq.onEnterFrame   = _onEnterFrame;
                seq.onEnterSegment = _onEnterSegment;
            } else {
                throw new Error("unknown error");
            }
        }
        
        
        /** stop sequence */
        override public function stop() : void
        {
            if (_tracks) {
                _bass.stop();
                _snare.stop();
                _hihat.stop();
                _synthesizer._unregisterTracks(_tracks[0], _tracks.length);
                for each (var t:SiMMLTrack in _tracks) t.setDisposable();
                _tracks = null;
                _sequenceOff(false);
                _bass.onEnterFrame  = null;
                _snare.onEnterFrame = null;
                _hihat.onEnterFrame = null;
                _bass.onEnterSegment  = null;
                _snare.onEnterSegment = null;
                _hihat.onEnterSegment = null;
            }
            _stopEffect();
        }
        
        
        
        
    // configure
    //----------------------------------------
        /** Set all pattern indeces 
         *  @param bassPatternNumber bass drum pattern index
         *  @param snarePatternNumber snare drum pattern index
         *  @param hihatPatternNumber hihat symbal pattern index
         */
        public function setPatternNumbers(bassPatternNumber:int, snarePatternNumber:int, hihatPatternNumber:int) : DrumMachine
        {
            this.bassPatternNumber  = bassPatternNumber;
            this.snarePatternNumber = snarePatternNumber;
            this.hihatPatternNumber = hihatPatternNumber;
            return this;
        }
    }
}

