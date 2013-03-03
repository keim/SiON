//----------------------------------------------------------------------------------------------------
// Track for SiMMLSequencer.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.utils.SLLint;
    import org.si.sion.module.channels.SiOPMChannelBase;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.sequencer.base.MMLData;
    import org.si.sion.sequencer.base.MMLEvent;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.sequencer.base.MMLExecutor;
    import org.si.sion.sequencer.base.BeatPerMinutes;
    import org.si.sion.sequencer.base._sion_sequencer_internal;
    import org.si.sion.namespaces._sion_internal;
    
    
    /** Track for SiMMLSequencer. <br/>
     *  There are 2 types of SiMMLTrack. One is "sequence track", and another is "controlable track". 
     *  The "sequence track" plays a sequence in the mml data, and the "controlable track" plays interavtive sound.
     */
    public class SiMMLTrack
    {
    // namespace
    //--------------------------------------------------
        use namespace _sion_sequencer_internal;
        
        
        
        
    // constants
    //--------------------------------------------------
        /** sweep step finess */
        static private const SWEEP_FINESS:int = 128;
        /** Fixed decimal bits. */
        static private const FIXED_BITS:int = 16;
        /** Maximum value of _sweep */
        static private const SWEEP_MAX:int = 8192<<FIXED_BITS;
        
        // track id type
        /** @private [internal use] track id filter */
        static _sion_internal const TRACK_ID_FILTER:int = 0xffff;
        /** @private [internal use] track type filter */
        static _sion_internal const TRACK_TYPE_FILTER:int = 0xff0000;
        
        /** Track Type ID for main MML tracks */
        static public const MML_TRACK:int = 0x10000;
        /** Track Type ID for MIDI tracks */
        static public const MIDI_TRACK:int = 0x20000;
        /** Track Type ID for tracks created by SiONDriver.noteOn() or SiONDriver.playSound() */
        static public const DRIVER_NOTE:int = 0x30000;
        /** Track Type ID for tracks created by SiONDriver.sequenceOn() */
        static public const DRIVER_SEQUENCE:int = 0x40000;
        /** Track Type ID for SiONDriver's background sound tracks */
        static public const DRIVER_BACKGROUND:int = 0x50000;
        /** Track Type ID for user controlled tracks */
        static public const USER_CONTROLLED:int = 0x60000;
        
        // mask bits for eventMask and @mask command
        /** no event mask */
        static public const NO_MASK:int = 0;
        /** mask all volume commands (v,x,&#64;v,"(",")") */
        static public const MASK_VOLUME:int = 1;
        /** mask all panning commands (p,&#64;p) */
        static public const MASK_PAN:int = 2;
        /** mask all quantize commands (q,&#64;q) */
        static public const MASK_QUANTIZE:int = 4;
        /** mask all operator setting commands (s,&#64;al,&#64;fb,i,&#64;,&#64;rr,&#64;tl,&#64;ml,&#64;st,&#64;ph,&#64;fx,&#64;se,&#64;er) */
        static public const MASK_OPERATOR:int = 8;
        /** mask all table envelop commands (&#64;&#64;,na,np,nt,nf,_&#64;&#64;,_na,_np,_nt,_nf) */
        static public const MASK_ENVELOP:int = 16;
        /** mask all modulation commands (ma,mp) */
        static public const MASK_MODULATE:int = 32;
        /** mask all slur and pitch-bending commands (&amp;,&amp;&amp;,*) */
        static public const MASK_SLUR:int = 64;
        
        // _processMode
        static private const NORMAL  :int = 0;
        static private const ENVELOP :int = 2;

        
        
        
    // valiables
    //--------------------------------------------------
        /** Sound module's channel controlled by this track. */
        public var channel:SiOPMChannelBase;

        /** MML sequence executor */
        public var executor:MMLExecutor;
        
        /** note shift, set by kt command.  */
        public var noteShift:int = 0;
        /** detune, set by k command.  */
        public var pitchShift:int = 0;
        /** key on delay, set by 2nd argument of &#64;q command.  */
        public var keyOnDelay:int = 0;
        /** quantize ratio, set by q command, the value is between 0-1.  */
        public var quantRatio:Number = 0;
        /** quantize count, set by &#64;q command. */
        public var quantCount:int = 0;
        /** Event mask, set by &#64;mask command. */
        public var eventMask:int = 0;
        
        // call back function before noteOn/noteOff
        private var _callbackBeforeNoteOn:Function = null;
        private var _callbackBeforeNoteOff:Function = null;
        internal var _callbackUpdateRegister:Function = _defaultUpdateRegister;
        
        // event trriger
        private var _eventTriggerOn:Function = null;
        private var _eventTriggerOff:Function = null;
        private var _eventTriggerID:int;
        private var _eventTriggerTypeOn:int;
        private var _eventTriggerTypeOff:int;
        
        // track ID number
        _sion_sequencer_internal var _internalTrackID:int;
        _sion_sequencer_internal var _trackNumber:int;

        // internal use
        private var _mmlData:SiMMLData;     // mml data. To get bpm from sequenceOn()s track, or only for reference in other cases.
        private var _table:SiMMLTable;      // table
        private var _keyOnCounter:int;      // key on counter
        private var _keyOnLength:int;       // key on length
        private var _flagNoKeyOn:Boolean;   // key on flag
        private var _processMode:int;       // processing mode
        private var _trackStartDelay:int;   // track delay to start
        private var _trackStopDelay:int;    // track delay to stop
        private var _stopWithReset:Boolean; // stop with reset
        private var _isDisposable:Boolean;  // flag disposable track
        private var _priority:int;          // track priority

        // settings
        private var _channelModuleSetting:SiMMLChannelSetting;          // selected module's setting
        private var _channelModuleRestriction:SiMMLChannelRestriction;  // module restriction type
        private var _velocityMode:int;   // velocity mode 
        private var _expressionMode:int; // expression mode
        private var _velocity:int;       // velocity[0-256-512]
        private var _expression:int;     // expression[0-128]
        private var _pitchIndex:int;     // current pitch index
        private var _pitchBend:int;      // pitch bend
        private var _voiceIndex:int;     // tone number
        private var _note:int;           // note number
        private var _defaultFPS:int;     // default fps
        /** @private [internal] channel number. */
        internal var _channelNumber:int; 
        /** @private [internal] vcommand shift. */
        _sion_sequencer_internal var _vcommandShift:int;  // vcommand shift
        
        // setting
        private var _set_processMode:Vector.<int>;

        // envelop settings
        private var _set_env_exp:Vector.<SLLint>;
        private var _set_env_voice:Vector.<SLLint>;
        private var _set_env_note:Vector.<SLLint>;
        private var _set_env_pitch:Vector.<SLLint>;
        private var _set_env_filter:Vector.<SLLint>;
        private var _set_exp_offset:Vector.<Boolean>;
        private var _pns_or:Vector.<Boolean>;
        
        private var _set_cnt_exp:Vector.<int>;
        private var _set_cnt_voice:Vector.<int>;
        private var _set_cnt_note:Vector.<int>;
        private var _set_cnt_pitch:Vector.<int>;
        private var _set_cnt_filter:Vector.<int>;
        
        private var _table_env_ma:Vector.<SLLint>;
        private var _table_env_mp:Vector.<SLLint>;
        private var _set_sweep_step:Vector.<int>;
        private var _set_sweep_end:Vector.<int>;
        private var _env_internval:int;
        
        // executing envelop
        private var _env_exp:SLLint;
        private var _env_voice:SLLint;
        private var _env_note:SLLint;
        private var _env_pitch:SLLint;
        private var _env_filter:SLLint;
        
        private var _cnt_exp:int,    _max_cnt_exp:int;
        private var _cnt_voice:int,  _max_cnt_voice:int;
        private var _cnt_note:int,   _max_cnt_note:int;
        private var _cnt_pitch:int,  _max_cnt_pitch:int;
        private var _cnt_filter:int, _max_cnt_filter:int;
        
        private var _env_mp:SLLint;
        private var _env_ma:SLLint;
        private var _sweep_step:int;
        private var _sweep_end:int;
        private var _sweep_pitch:int;
        private var _env_exp_offset:int;
        private var _env_pitch_active:Boolean;
        
        private var _residue:int;   // residue of previous envelop process 
        
        // zero table
        static private var _env_zero_table:SLLint = SLLint.allocRing(1);
        
        
        
        
    // properties
    //--------------------------------------------------
        /** track number, this value is unique and set by system, the lower numbered track processes sound first. */
        public function get trackNumber() : int { return _trackNumber; }
        /** track ID, this value is specifyed by user. */
        public function get trackID() : int { return _internalTrackID & _sion_internal::TRACK_ID_FILTER; }
        /** track type, this value shows what this track starts by. */
        public function get trackTypeID() : int { return _internalTrackID & _sion_internal::TRACK_TYPE_FILTER; }

        /** event trigger ID. eventTriggerID=-1 means tigger not set. */
        public function get eventTriggerID() : int { return _eventTriggerID; }
        /** Note on event trigger type. eventTriggerTypeOn=0 means tigger not set. */
        public function get eventTriggerTypeOn() : int { return _eventTriggerTypeOn; }
        /** Note off event trigger type. eventTriggerTypeOff=0 means tigger not set. */
        public function get eventTriggerTypeOff() : int { return _eventTriggerTypeOff; }
        
        /** Note number */
        public function get note() : int { return _note; }
        
        /** Start delay in sample count. Ussualy this returns 0 except after SiONDriver.noteOn. */
        public function get trackStartDelay() : int { return _trackStartDelay; }
        /** Stop delay in sample count. Ussualy this returns 0 except after SiONDriver.noteOff. */
        public function get trackStopDelay() : int { return _trackStopDelay; }
        
        /** Is activate ? This function always returns true from not-disposable track. (isActive = !isDisposable || !isFinished) */
        public function get isActive() : Boolean { return !_isDisposable || executor.pointer != null || !channel.isIdling; }
        /** Is this track disposable ? Disposable track will free automatically when finished rendering. */
        public function get isDisposable() : Boolean { return _isDisposable; }
        /** Is playing sequence ? */
        public function get isPlaySequence() : Boolean { return ((_internalTrackID & _sion_internal::TRACK_TYPE_FILTER) != DRIVER_NOTE && executor.pointer != null); }
        /** Is finish to rendering ? */
        public function get isFinished() : Boolean { return (executor.pointer == null && channel.isIdling); }
        
        /** velocity(0-256). linked to operator's total level. */
        public function get velocity()        : int  { return _velocity; }
        public function set velocity(v:int)   : void { 
            _velocity = (v<0) ? 0 : (v>512) ? 512 : v;
            channel.offsetVolume(_expression, _velocity);
        }
        
        /** expression(0-128). linked to operator's total level. */
        public function get expression()      : int  { return _expression; }
        public function set expression(x:int) : void { 
            _expression = (x<0) ? 0 : (x>128) ? 128 : x;
            channel.offsetVolume(_expression, _velocity);
        }
        
        /** master volume(0-128). simple wrapper of channel.masterVolume. */
        public function get masterVolume() : int { return channel.masterVolume; }
        public function set masterVolume(v:int) : void { 
            channel.masterVolume = v;
        }
        
        /** effect send level for slot1 (0-128). simple wrapper of channel.setStreamSend. */
        public function get effectSend1() : int { return channel.getStreamSend(1); }
        public function set effectSend1(s:int) : void {
            channel.setStreamSend(1, (s<0) ? 0 : (s>128) ? 1 : s*0.0078125);
        }
        
        /** effect send level for slot2 (0-128). simple wrapper of channel.setStreamSend. */
        public function get effectSend2() : int { return channel.getStreamSend(2); }
        public function set effectSend2(s:int) : void {
            channel.setStreamSend(2, (s<0) ? 0 : (s>128) ? 1 : s*0.0078125);
        }
        
        /** effect send level for slot3 (0-128). simple wrapper of channel.setStreamSend. */
        public function get effectSend3() : int { return channel.getStreamSend(3); }
        public function set effectSend3(s:int) : void {
            channel.setStreamSend(3, (s<0) ? 0 : (s>128) ? 1 : s*0.0078125);
        }
        
        /** effect send level for slot4 (0-128). simple wrapper of channel.setStreamSend. */
        public function get effectSend4() : int { return channel.getStreamSend(4); }
        public function set effectSend4(s:int) : void {
            channel.setStreamSend(4, (s<0) ? 0 : (s>128) ? 1 : s*0.0078125);
        }
        
        /** mute */
        public function get mute() : Boolean { return channel.mute; }
        public function set mute(b:Boolean) : void {
            channel.mute = b;
        }
        
        /** pannning (-64 - +64)*/
        public function get pan() : int { return channel.pan; }
        public function set pan(p:int) : void { channel.pan = p; }
        
        /** pitch bend */
        public function get pitchBend() : int { return _pitchBend; }
        public function set pitchBend(p:int) : void {
            _pitchBend = p;
            channel.pitch = _pitchIndex + _pitchBend;
        }
        
        /** callback function when update register event appears. */
        public function get onUpdateRegister() : Function { return _callbackUpdateRegister; }
        public function set onUpdateRegister(func:Function) : void { _callbackUpdateRegister = func || _defaultUpdateRegister; }
        
        /** velocity table mode */
        public function get velocityMode() : int { return _velocityMode; }
        public function set velocityMode(mode:int) : void {
            var tlTables:Vector.<Vector.<int>> = SiOPMTable.instance.eg_tlTables;
            _velocityMode = (mode>=0 && mode<SiOPMTable.VM_MAX) ? mode : SiOPMTable.VM_LINEAR;
            channel.setVolumeTables(tlTables[_velocityMode], tlTables[_expressionMode]);
        }
        
        /** expression table mode */
        public function get expressionMode() : int { return _expressionMode; }
        public function set expressionMode(mode:int) : void {
            var tlTables:Vector.<Vector.<int>> = SiOPMTable.instance.eg_tlTables;
            _expressionMode = (mode>=0 && mode<SiOPMTable.VM_MAX) ? mode : SiOPMTable.VM_LINEAR;
            channel.setVolumeTables(tlTables[_velocityMode], tlTables[_expressionMode]);
        }

        
        /** Channel number, set by 2nd argument of % command. Usually same as programNumber (except for APU). @see programNumber */
        public function get channelNumber() : int { return _channelNumber; }
        /** Program number, set by 2nd argument of % command and 1st arg. of &#64; command. Usually same as channelNumber (except for APU). @see channelNumber */
        public function get programNumber() : int { return _voiceIndex; }
        
        /** output level = &#64;v * v * x. */
        public function get outputLevel() : Number {
            var vol:int = channel.masterVolume;
            if (vol == 0) return _velocity * _expression * 0.0000152587890625; // 0.5/(128*256);
            return vol * _velocity * _expression * 2.384185791015625e-7;       // 1/(128*128*256)
        }
        
        /** mml data to play. this value only is available in the track playing mml sequence */
        public function get mmlData() : SiMMLData { return _mmlData; }
        
        /** module restriction type @see SiMMLChannelRestriction */
        public function get channelModuleRestriction() : int { return _channelModuleRestriction.type; }
        
        /** @private [internal] bpm setting. refer from SiMMLSequencer */
        internal function get _bpmSetting() : BeatPerMinutes { 
            return ((_internalTrackID & _sion_internal::TRACK_TYPE_FILTER) != MML_TRACK && _mmlData) ? _mmlData._initialBPM : null;
        }
        
        /** @private [internal] priority number to overwrite when tracks are overflow. */
        public function get priority() : int {
            // not-disposable track or sequence playing track always returns highest priority
            if (!_isDisposable || isPlaySequence) return 0;
            return _priority;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLTrack() 
        {
            _table = SiMMLTable.instance;
            executor = new MMLExecutor();
            
            _mmlData = null;
            _set_processMode = new Vector.<int>(2, true);
            
            _set_env_exp    = new Vector.<SLLint>(2, true);
            _set_env_voice  = new Vector.<SLLint>(2, true);
            _set_env_note   = new Vector.<SLLint>(2, true);
            _set_env_pitch  = new Vector.<SLLint>(2, true);
            _set_env_filter = new Vector.<SLLint>(2, true);
            _pns_or         = new Vector.<Boolean>(2, true);
            _set_exp_offset = new Vector.<Boolean>(2, true);
            _set_cnt_exp    = new Vector.<int>(2, true);
            _set_cnt_voice  = new Vector.<int>(2, true);
            _set_cnt_note   = new Vector.<int>(2, true);
            _set_cnt_pitch  = new Vector.<int>(2, true);
            _set_cnt_filter = new Vector.<int>(2, true);
            _set_sweep_step = new Vector.<int>(2, true);
            _set_sweep_end  = new Vector.<int>(2, true);
            _table_env_ma   = new Vector.<SLLint>(2, true);
            _table_env_mp   = new Vector.<SLLint>(2, true);
        }
        
        
        
        
    // interfaces for intaractive operations
    //--------------------------------------------------
        /** Set track callback function. The callback functions are called at the timing of streaming before SiOPMEvent.STREAM event.
         *  @param noteOn Callback function before note on. This function refers this track instance and new pitch (0-8191) as an arguments. When the function returns false, noteOn will be canceled.<br/>
         *  function callbackNoteOn(track:SiMMLTrack) : Boolean { return true; }
         *  @param noteOff Callback function before note off. This function refers this track instance as an argument. When the function returns false, noteOff will be canceled.<br/>
         *  function callbackNoteOff(track:SiMMLTrack) : Boolean { return true; }
         */
        public function setTrackCallback(noteOn:Function=null, noteOff:Function=null) : SiMMLTrack
        {
            _callbackBeforeNoteOn  = noteOn;
            _callbackBeforeNoteOff = noteOff;
            return this;
        }
        
        
        /** key on. SiONDriver.noteOn() calls this internally.
         *  @param note Note number
         *  @param tickLength note length in tick count.
         *  @param sampleDelay note delay in sample count.
         */
        public function keyOn(note:int, tickLength:int=0, sampleDelay:int=0) : SiMMLTrack
        {
            _trackStartDelay = sampleDelay;
            executor.singleNote(note, tickLength);
            return this;
        }
        
        
        /** Force key off. SiONDriver.noteOff() calls this internally.
         *  @param sampleDelay Delay time (in sample count).
         *  @param stopWithReset Stop with channel resetting.
         */
        public function keyOff(sampleDelay:int=0, stopWithReset:Boolean=false) : SiMMLTrack
        {
            _stopWithReset = stopWithReset;
            if (sampleDelay) {
                _trackStopDelay = sampleDelay;
            } else {
                _keyOff();
                _note = -1;
                if (_stopWithReset) channel.reset();
            }
            return this;
        }
        
        
        /** dispatch EventTrigger 
         *  @param noteOn noteOn event or noteOff event
         *  @return returns false when the event is prevented
         */
        public function dispatchEventTrigger(noteOn:Boolean) : Boolean
        {
            if (noteOn) {
                if (_callbackBeforeNoteOn  != null) return _callbackBeforeNoteOn(this);
            } else {
                if (_callbackBeforeNoteOff != null) return _callbackBeforeNoteOff(this);
            }
            return false;
        }
        
        
        /** Play sequence.
         *  @param seq Sequence to play.
         *  @param sampleLength sequence playing time.
         *  @param sampleDelay Delaying time (in sample count).
         */
        public function sequenceOn(seq:MMLSequence, sampleLength:int=0, sampleDelay:int=0) : SiMMLTrack
        {
            _trackStartDelay = sampleDelay;
            _trackStopDelay = sampleLength;
            _mmlData = (seq) ? (seq._owner as SiMMLData) : null;
            executor.initialize(seq);
            return this;
        }
        
        
        /** Force stop sequence.
         *  @param sampleDelay Delay time (in sample count).
         *  @param stopWithReset Stop with channel resetting.
         */ 
        public function sequenceOff(sampleDelay:int=0, stopWithReset:Boolean=false) : SiMMLTrack
        {
            _stopWithReset = stopWithReset;
            if (sampleDelay) {
                _trackStopDelay = sampleDelay;
            } else {
                executor.clear();
                if (_stopWithReset) channel.reset();
            }
            return this;
        }
        
        
        /** Limit key on length. 
         *  @param stopDelay delay to key-off.
         */
        public function limitLength(stopDelay:int) : void
        {
            var length:int = stopDelay - _trackStartDelay;
            if (length < _keyOnLength) {
                _keyOnLength = length;
                _keyOnCounter = _keyOnLength;
            }
        }
        
        
        /** Set this track disposable. */
        public function setDisposable() : void 
        {
            _isDisposable = true;
        }
        
        
        /** restrict channel module type 
         *  @param restrictionModule module restriction type, defined in SiMMLChannelRestriction
         *  @param channelNum channel number
         *  @see SiMMLChannelRestriction
         */
        public function restrictModule(restrictionModule:int, channelNum:int) : void
        {
            _channelModuleRestriction = _table.channelModuleRestriction[restrictionModule];
            // same as setChannelModuleType()
            _channelModuleSetting = _table.channelModuleSetting[_channelModuleRestriction._moduleType];
            _voiceIndex = _channelModuleSetting.initializeTone(this, channelNum, channel.bufferIndex);
        }

        
        
        
        
    // interfaces for mml command
    //--------------------------------------------------
        /** Set note immediately. 
         *  The calling path : SiONDriver.noteOn() -> SiMMLTrack.keyOn() -> executor.singleNote() ->(waiting for MMLEvent.DRIVER_NOTE)
         *  -> SiMMLSequencer._onDriverNoteOn() -> SiMMLTrack.setNote() -> SiMMLTrack._mmlKeyOn().
         *  @param note note number.
         *  @param sampleLength length in sample count. 0 sets no key off (=weak slur).
         *  @param slur set as slur.
         */
        public function setNote(note:int, sampleLength:int, slur:Boolean=false) : void
        {
            // play with key off when quantRatio == 0 or sampleLength != 0
            if ((quantRatio == 0 || sampleLength > 0) && !slur) {
                _keyOnLength = int(sampleLength * quantRatio) - quantCount - keyOnDelay;
                if (_keyOnLength < 1) _keyOnLength = 1;
            } else {
                // no key off
                _keyOnLength = 0;
            }
            _mmlKeyOn(note);
            _flagNoKeyOn = slur;
        }
        
        
        /** Set pitch bending.
         *  @param noteFrom Note number bending from.
         *  @param tickLength length of pitch bending.
         */
        public function setPitchBend(noteFrom:int, tickLength:int) : void
        {
            executor.bendingFrom(noteFrom, tickLength);
        }
        
        
        /** Channel module type (%) and select tone (1st argument of '_&#64;').
         *  @param type Channel module type
         *  @param channelNum Channel number. For %2-11, this value is same as 1st argument of '_&#64;'. channel number of -1 ignores all voice settings by selectVoice.
         *  @param toneNum Tone number. Ussualy, this argument is used only in %0;PSG and %1;APU.
         */
        public function setChannelModuleType(type:int, channelNum:int=int.MIN_VALUE, toneNum:int=int.MIN_VALUE) : void
        {
            // check restriction
            if (_channelModuleRestriction.type != NO_RESTRICTION) return;
            
            // change module type
            _channelModuleSetting = _table.channelModuleSetting[type];
            
            // reset operator pgType, set SiMMLTrack._channelNumber inside
            _voiceIndex = _channelModuleSetting.initializeTone(this, channelNum, channel.bufferIndex);
            
            // select tone
            if (toneNum >= 0) {
                _voiceIndex = toneNum;
                _channelModuleSetting.selectTone(this, toneNum);
            }
        }
        
        
        /** portament (po).
         *  @param frame portament changing time in frame count.
         */
        public function setPortament(frame:int) : void
        {
            _set_sweep_step[1] = frame;
            if (frame) {
                _pns_or[1] = true;
                _envelopOn(1);
            } else {
                _envelopOff(1);
            }
        }
        
        
        /** set event trigger (%t) 
         *  @param id Event trigger ID of this track. This value can be refered from SiONTrackEvent.eventTriggerID.
         *  @param noteOnType Dispatching event type at note on. 0=no events, 1=NOTE_ON_FRAME, 2=NOTE_ON_STREAM, 3=both.
         *  @param noteOffType Dispatching event type at note off. 0=no events, 1=NOTE_OFF_FRAME, 2=NOTE_OFF_STREAM, 3=both.
         *  @see org.si.sion.events.SiONTrackEvent
         */
        public function setEventTrigger(id:int, noteOnType:int=1, noteOffType:int=0) : void
        {
            _eventTriggerID = id;
            _eventTriggerTypeOn  = noteOnType;
            _eventTriggerTypeOff = noteOffType;
            _callbackBeforeNoteOn = (noteOnType) ? _eventTriggerOn : null;
            _callbackBeforeNoteOff = (noteOffType) ? _eventTriggerOff : null;
        }
        
        
        /** dispatch note on event once (%e) 
         *  @param id Event trigger ID of this track. This value can be refered from SiONTrackEvent.eventTriggerID.
         *  @param noteOnType Dispatching event type at note on. 0=no events, 1=NOTE_ON_FRAME, 2=NOTE_ON_STREAM, 3=both.
         *  @see org.si.sion.events.SiONTrackEvent
         */
        public function dispatchNoteOnEvent(id:int, noteOnType:int=1) : void
        {
            if (noteOnType) {
                var currentTID:int  = _eventTriggerID, 
                    currentType:int = _eventTriggerTypeOn;
                _eventTriggerID = id;
                _eventTriggerTypeOn = noteOnType;
                _eventTriggerOn(this);
                _eventTriggerID = currentTID;
                _eventTriggerTypeOn = currentType;
            }
        }
        
        
        /** set envelop step (&#64;fps) 
         *  @param fps Frame par second
         */
        public function setEnvelopFPS(fps:int) : void
        {
            _env_internval = SiOPMTable.instance.rate / fps;
        }
        
        
        /** release sweep (2nd argument of "s")
         *  @param sweep sweeping speed
         */
        public function setReleaseSweep(sweep:int) : void
        {
            _set_sweep_step[0] = sweep << FIXED_BITS;
            _set_sweep_end[0]  = (sweep<0) ? 0 : SWEEP_MAX;
            if (sweep) {
                _pns_or[0] = true;
                _envelopOn(0);
            } else {
                _envelopOff(0);
            }
        }
        
        
        /** amplitude/pitch modulation envelop (ma, mp) 
         *  @param isPitchMod The command is 'ma' or 'mp'.
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         */
        public function setModulationEnvelop(isPitchMod:Boolean, depth:int, end_depth:int, delay:int, term:int) : void
        {
            // select table
            var table:Vector.<SLLint> = (isPitchMod) ? _table_env_mp : _table_env_ma;
            
            // free previous table
            if (table[1]) SLLint.freeList(table[1]);

            if ((0<=depth && depth<end_depth) || (depth<0 && depth>end_depth)) {
                // make table and envelop on
                table[1] = _makeModulationTable(depth, end_depth, delay, term);
                _envelopOn(1);
            } else {
                // free table and envelop off
                table[1] = null;
                if (isPitchMod) channel.setPitchModulation(depth);
                else            channel.setAmplitudeModulation(depth);
                _envelopOff(1);
            }
        }
        
        
        /** set tone envelop (&#64;&#64;, _&#64;&#64;) 
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setToneEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_voice[noteOn] = null;
                _envelopOff(noteOn);
            } else {
                _set_env_voice[noteOn] = table.head;
                _set_cnt_voice[noteOn] = step;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set amplitude envelop (na, _na) 
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         *  @param offset true for relative control (!na command), false for absolute control.
         */
        public function setAmplitudeEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int, offset:Boolean = false) : void
        {
            if (table==null || step==0) {
                _set_env_exp[noteOn] = null;
                _envelopOff(noteOn);
            } else {
                _set_env_exp[noteOn] = table.head;
                _set_cnt_exp[noteOn] = step;
                _set_exp_offset[noteOn] = offset;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set filter envelop (nf, _nf)
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setFilterEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_filter[noteOn] = null;
                _envelopOff(noteOn);
            } else {
                _set_env_filter[noteOn] = table.head;
                _set_cnt_filter[noteOn] = step;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set pitch envelop (np, _np)
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setPitchEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_pitch[noteOn] = _env_zero_table;
                _envelopOff(noteOn);
            } else {
                _set_env_pitch[noteOn] = table.head;
                _set_cnt_pitch[noteOn] = step;
                _pns_or[noteOn]        = true;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set note envelop (nt, _nt)
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setNoteEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_note[noteOn] = _env_zero_table;
                _envelopOff(noteOn);
            } else {
                _set_env_note[noteOn] = table.head;
                _set_cnt_note[noteOn] = step;
                _pns_or[noteOn]       = true;
                _envelopOn(noteOn);
            }
        }
        
        
        
        
    //====================================================================================================
    // Internal uses
    //====================================================================================================
    // initialize / reset
    //--------------------------------------------------
        /** @private [internal] initialize track. [NOTE] Have to call reset() after this. */
        internal function _initialize(seq:MMLSequence, fps:int, internalTrackID:int, eventTriggerOn:Function, eventTriggerOff:Function, isDisposable:Boolean) : SiMMLTrack
        {
            _internalTrackID = internalTrackID;
            _isDisposable = isDisposable;
            _defaultFPS = fps;
            _eventTriggerOn = eventTriggerOn;
            _eventTriggerOff = eventTriggerOff;
            _eventTriggerID = -1;
            _eventTriggerTypeOn = 0;
            _eventTriggerTypeOff = 0;
            _mmlData = (seq) ? (seq._owner as SiMMLData) : null;
            executor.initialize(seq);
            
            return this;
        }
        
        
        /** @private [internal] reset track. */
        internal function _reset(bufferIndex:int) : void
        {
            var i:int;
            
            // channel module setting
            _channelModuleSetting = _table.channelModuleSetting[SiMMLTable.MT_PSG];
            _channelModuleRestriction = _table.channelModuleRestriction[NO_RESTRICTION];
            _channelNumber = 0;
            
            // initialize channel by _channelModuleSetting
            if (_mmlData) {
                _vcommandShift = _mmlData.defaultVCommandShift;
                _velocityMode = _mmlData.defaultVelocityMode;
                _expressionMode = _mmlData.defaultExpressionMode;
            } else {
                _vcommandShift = 4;
                _velocityMode = SiOPMTable.VM_LINEAR;
                _expressionMode = SiOPMTable.VM_LINEAR;
            }
            _velocity = 256;
            _expression = 128;
            _pitchBend = 0;
            _note = -1;
            channel = null;
            _voiceIndex = _channelModuleSetting.initializeTone(this, int.MIN_VALUE, bufferIndex);
            var tlTables:Vector.<Vector.<int>> = SiOPMTable.instance.eg_tlTables;
            channel.setVolumeTables(tlTables[_velocityMode], tlTables[_expressionMode]);
            
            // initialize parameters
            noteShift = 0;
            pitchShift = 0;
            _keyOnCounter = 0;
            _keyOnLength = 0;
            _flagNoKeyOn = false;
            _processMode = NORMAL;
            _trackStartDelay = 0;
            _trackStopDelay = 0;
            _stopWithReset = false;
            keyOnDelay = 0;
            quantRatio = 1;
            quantCount = 0;
            eventMask = NO_MASK;
            _env_pitch_active = false;
            _pitchIndex = 0;
            _sweep_pitch = 0;
            _env_exp_offset = 0;
            setEnvelopFPS(_defaultFPS);
            _callbackBeforeNoteOn = null;
            _callbackBeforeNoteOff = null;
            _callbackUpdateRegister = _defaultUpdateRegister;
            _residue = 0;
            _priority = 0;
            _env_exp    = null;
            _env_voice  = null;
            _env_note   = _env_zero_table;
            _env_pitch  = _env_zero_table;
            _env_filter = null;
            _env_ma = null;
            _env_mp = null;
            
            // reset envelop tables
            for (i=0; i<2; i++) {
                _set_processMode[i] = NORMAL;
                _set_env_exp[i]    = null;
                _set_env_voice[i]  = null;
                _set_env_note[i]   = _env_zero_table;
                _set_env_pitch[i]  = _env_zero_table;
                _set_env_filter[i] = null;
                _pns_or[i]         = false;
                _set_exp_offset[i] = false;
                _set_cnt_exp[i]    = 1;
                _set_cnt_voice[i]  = 1;
                _set_cnt_note[i]   = 1;
                _set_cnt_pitch[i]  = 1;
                _set_cnt_filter[i] = 1;
                _set_sweep_step[i] = 0;
                _set_sweep_end[i]  = 0;
                _table_env_ma[i]   = null;
                _table_env_mp[i]   = null;
            }
            
            // reset pointer
            executor.resetPointer();
        }
        
        
        /** @private [internal] reset volume offset. */
        internal function _resetVolumeOffset() : void
        {
            channel.offsetVolume(_expression, _velocity);
        }
        
        
        
        
    // processing
    //--------------------------------------------------
        /** @private [internal] prepare buffer. this is called from SiMMLSequencer.process()/dummyProcess(). */
        internal function _prepareBuffer(bufferingLength:int) : int
        {
            // register all tables
            if (_mmlData) _mmlData._registerAllTables();
            else { // clear all stencil tables
                SiOPMTable._instance.samplerTables[0].stencil = null;
                SiOPMTable._instance._sion_internal::_stencilCustomWaveTables = null;
                SiOPMTable._instance._sion_internal::_stencilPCMVoices        = null;
                _table._stencilEnvelops = null;
                _table._stencilVoices   = null;
            }
            
            // no delay, usually
            if (_trackStartDelay == 0) {
                return bufferingLength;
            }

            // wait for starting sound
            if (bufferingLength <= _trackStartDelay) {
                _trackStartDelay -= bufferingLength;
                return 0;
            }
            
            // start sound in this frame
            var len:int = bufferingLength - _trackStartDelay;
            channel.nop(_trackStartDelay);
            _trackStartDelay = 0;
            
            _priority++;
            
            return len;
        }
        
        
        /** @private [internal] buffering */
        internal function _buffer(length:int) : void
        {
            // check track stopping
            var trackStop:Boolean = false, trackStopResume:int = 0;
            if (_trackStopDelay > 0) {
                if (_trackStopDelay > length) {
                    _trackStopDelay -= length;
                } else {
                    trackStopResume = length - _trackStopDelay;
                    trackStop = true;
                    length = _trackStopDelay;
                    _trackStopDelay = 0;
                }
            }
            
            // buffeirng
            if (_keyOnCounter == 0) {
                // no status changing
                $(length);
            } else 
            if (_keyOnCounter > length) {
                // decrement _keyOnCounter
                $(length);
                _keyOnCounter -= length;
            } else {
                // process -> toggle key -> process
                length -= _keyOnCounter;
                $(_keyOnCounter);
                _toggleKey();
                if (length>0) $(length);
            }
            
            // track stopped
            if (trackStop) {
                if (executor.pointer) {
                    executor.stop();
                    if (_stopWithReset) {
                        _keyOff();
                        _note = -1;
                        channel.reset();
                    }
                } else if (channel.isNoteOn) {
                    _keyOff();
                    _note = -1;
                    if (_stopWithReset) {
                        channel.reset();
                    }
                }
                if (trackStopResume>0) $(trackStopResume);
            }
            
            // processing inside
            function $(procLen:int) : void {
                switch(_processMode) {
                case NORMAL:    channel.buffer(procLen);                       break;
                case ENVELOP:   _residue = _bufferEnvelop(procLen, _residue);  break;
                }
            }
        }
        
        
        // buffering with table envelops
        private function _bufferEnvelop(length:int, step:int) : int
        {
            var x:int;
            
            while (length >= step) {
                // processing
                if (step > 0) channel.buffer(step);
                
                // change expression
                if (_env_exp && --_cnt_exp == 0) {
                    x = _env_exp_offset + _env_exp.i;
                    if (x<0) {x=0;} else if (x>128) {x=128;}
                    channel.offsetVolume(x, _velocity);
                    _env_exp = _env_exp.next;
                    _cnt_exp = _max_cnt_exp;
                }
                
                // change pitch/note
                if (_env_pitch_active) {
                    channel.pitch = _env_pitch.i + (_env_note.i<<6) + (_sweep_pitch>>FIXED_BITS);
                    // pitch envelop
                    if (--_cnt_pitch == 0) {
                        _env_pitch = _env_pitch.next;
                        _cnt_pitch = _max_cnt_pitch;
                    }
                    // note envelop
                    if (--_cnt_note == 0) {
                        _env_note = _env_note.next;
                        _cnt_note = _max_cnt_note;
                    }
                    // sweep
                    _sweep_pitch += _sweep_step;
                    if (_sweep_step>0) {
                        if (_sweep_pitch > _sweep_end) {
                            _sweep_pitch = _sweep_end;
                            _sweep_step = 0;
                        }
                    } else {
                        if (_sweep_pitch < _sweep_end) {
                            _sweep_pitch = _sweep_end;
                            _sweep_step = 0;
                        }
                    }
                }
                
                // change filter
                if (_env_filter && --_cnt_filter == 0) {
                    channel.offsetFilter(_env_filter.i);
                    _env_filter = _env_filter.next;
                    _cnt_filter = _max_cnt_filter;
                }
                
                // change tone
                if (_env_voice && --_cnt_voice == 0) {
                    _channelModuleSetting.selectTone(this, _env_voice.i);
                    _env_voice = _env_voice.next;
                    _cnt_voice = _max_cnt_voice;
                }
                
                // change modulations
                if (_env_ma) {
                    channel.setAmplitudeModulation(_env_ma.i);
                    _env_ma = _env_ma.next;
                }
                if (_env_mp) {
                    channel.setPitchModulation(_env_mp.i);
                    _env_mp = _env_mp.next;
                }
                
                // index increment
                length -= step;
                step = _env_internval;
            }

            // rest process
            if (length > 0) channel.buffer(length);
            
            // next rest length
            return _env_internval - length;
        }
        
        
        
        
    // key on/off
    //--------------------------------------------------
        // toggle note
        private function _toggleKey() : void
        {
            if (channel.isNoteOn) {
                _keyOff();
            }else {
                _keyOn();
            }
        }
        
        
        // note on
        private function _keyOn() : void
        {
            // callback
            if (_callbackBeforeNoteOn != null) {
                if (!_callbackBeforeNoteOn(this)) return;
            }
            
            // change pitch
            var oldPitch:int = channel.pitch;
            _pitchIndex = ((_note + noteShift)<<6) + pitchShift;
            channel.pitch = _pitchIndex + _pitchBend;

            // note on
            if (!_flagNoKeyOn) {
                // reset previous envelop
                if (_processMode == ENVELOP) {
                    channel.offsetVolume(_expression, _velocity);
                    _channelModuleSetting.selectTone(this, _voiceIndex);
                    channel.offsetFilter(128);
                }
                // previous note off
                if (channel.isNoteOn) {
                    // callback
                    if (_callbackBeforeNoteOff != null) _callbackBeforeNoteOff(this);
                    channel.noteOff();
                }
                // update process
                _updateProcess(1);
                // note on
                channel.noteOn();
            } else {
                // portament
                if (_set_sweep_step[1]>0) {
                    channel.pitch = oldPitch;
                    _sweep_step  = ((_pitchIndex - oldPitch) << FIXED_BITS) / _set_sweep_step[1];
                    _sweep_end   = _pitchIndex << FIXED_BITS;
                    _sweep_pitch = oldPitch << FIXED_BITS;
                } else {
                    _sweep_pitch = channel.pitch << FIXED_BITS;
                }
                // try to set envelop off
                _envelopOff(1);
            }

            _flagNoKeyOn = false;
            
            // set key on counter
            _keyOnCounter = _keyOnLength;
        }
        
        
        // note off
        private function _keyOff() : void
        {
            // callback
            if (_callbackBeforeNoteOff != null) {
                if (!_callbackBeforeNoteOff(this)) return;
            }
            
            // note off
            channel.noteOff();
            // no key off after this
            _keyOnCounter = 0;
            // update process
            _updateProcess(0);
            // priority down
            _priority += 32;
        }
        
        
        private function _updateProcess(keyOn:int) : void
        {
            // prepare next process
            _processMode = _set_processMode[keyOn];
            
            if (_processMode == ENVELOP) {
                // set envelop tables
                _env_exp    = _set_env_exp[keyOn];
                _env_voice  = _set_env_voice[keyOn];
                _env_note   = _set_env_note[keyOn];
                _env_pitch  = _set_env_pitch[keyOn];
                _env_filter = _set_env_filter[keyOn];
                // set envelop counters
                _max_cnt_exp    = _set_cnt_exp[keyOn];
                _max_cnt_voice  = _set_cnt_voice[keyOn];
                _max_cnt_note   = _set_cnt_note[keyOn];
                _max_cnt_pitch  = _set_cnt_pitch[keyOn];
                _max_cnt_filter = _set_cnt_filter[keyOn];
                _cnt_exp    = 1;
                _cnt_voice  = 1;
                _cnt_note   = 1;
                _cnt_pitch  = 1;
                _cnt_filter = 1;
                // set modulation envelops
                _env_ma = _table_env_ma[keyOn];
                _env_mp = _table_env_mp[keyOn];
                // set sweep
                _sweep_step = (keyOn) ? 0 : _set_sweep_step[keyOn];
                _sweep_end  = (keyOn) ? 0 : _set_sweep_end[keyOn];
                // set pitch values
                _sweep_pitch = channel.pitch << FIXED_BITS;
                _env_exp_offset   = (_set_exp_offset[keyOn]) ? _expression : 0;
                _env_pitch_active = _pns_or[keyOn];
                // activate filter
                if (!channel.isFilterActive) channel.activateFilter(Boolean(_env_filter));
                // reset index
                _residue = 0;
            }
        }
        
        
        
        
    // event handlers
    //--------------------------------------------------
        /** @private [internal] handler for MMLEvent.REST. */
        internal function _onRestEvent() : void
        {
            _flagNoKeyOn = false;
        }
        

        /** @private [internal] handler for MMLEvent.NOTE. */
        internal function _onNoteEvent(note:int, length:int) : void
        {
            _keyOnLength = int(length * quantRatio) - quantCount - keyOnDelay;
            if (_keyOnLength < 1) _keyOnLength = 1;
            _mmlKeyOn(note);
        }
        

        /** @private [internal] Slur without next notes key on. This have to be called just after keyOn(). */
        internal function _onSlur() : void
        {
            _flagNoKeyOn = true;
            _keyOnCounter = 0;
        }

        
        /** @private [internal] Slur with next notes key on. This have to be called just after keyOn(). */
        internal function _onSlurWeak() : void
        {
            _keyOnCounter = 0;
        }
        
        
        /** @private [internal] Set pitch bend (and slur) immediately. This function called from pitchBend() and '*' command.
         *  @param nextNote The 2nd note to intergradate.
         *  @param term bending time in sample count.
         */
        internal function _onPitchBend(nextNote:int, term:int) : void
        {
            var startPitch:int = channel.pitch,
                endPitch  :int = (((nextNote + noteShift)<<6) || (startPitch & 63)) + pitchShift;
            _onSlur();
            if (startPitch == endPitch) return;
            
            _sweep_step = ((endPitch - startPitch) << FIXED_BITS) * _env_internval / term;
            _sweep_end  = endPitch << FIXED_BITS;
            _sweep_pitch = startPitch << FIXED_BITS;
            _env_pitch_active = true;
            _env_note  = _set_env_note[1];
            _env_pitch = _set_env_pitch[1];
            
            _processMode = ENVELOP;
        }
        
        
        /** @private [internal] change note length. call from SiMMLSequence._onSlur()/_onSlurWeek() when its masked. */
        internal function _changeNoteLength(length:int) : void
        {
            _keyOnCounter = int(length * quantRatio) - quantCount - keyOnDelay;
            if (_keyOnCounter < 1) _keyOnCounter = 1;
        }
        
        
        /** @praivate [internal use] Channel parameters (&#64;) */
        internal function _setChannelParameters(param:Vector.<int>) : MMLSequence
        {
            var ret:MMLSequence = null;
            if (param[0] != int.MIN_VALUE) {
                ret = _channelModuleSetting.selectTone(this, param[0]);
                _voiceIndex = param[0];
            }
            channel.setParameters(param);
            return ret;
        }
        
        /** @private [internal use] mml v command */
        internal function _mmlVCommand(v:int) : void 
        {
            velocity = v << _vcommandShift;
        }
        
        /** @private [internal use] mml v command */
        internal function _mmlVShift(v:int) : void 
        {
            velocity += v << _vcommandShift;
        }
        
        // update register
        private function _defaultUpdateRegister(addr:int, data:int) : void
        {
            channel.setRegister(addr, data);
        }
        
        
        // mml key on
        private function _mmlKeyOn(note:int) : void
        {
            _note = note;
            _trackStartDelay = 0;
            if (keyOnDelay) {
                _keyOff();
                _keyOnCounter = keyOnDelay;
            } else {
                _keyOn();   // if _keyOnLength=0 -> _keyOnCounter=0 -> No key off
            }
        }
        
        
    // internal functions
    //--------------------------------------------------
        // envelop off
        private function _envelopOff(noteOn:int) : void
        {
            // update (pitch || note || sweep)
            if (_set_sweep_step[noteOn] == 0  && 
                _set_env_pitch[noteOn] === _env_zero_table && 
                _set_env_note[noteOn]  === _env_zero_table)
            {
                _pns_or[noteOn] = false;
            }
            
            // all envelops are off -> update processMode
            if (!_pns_or[noteOn]         && 
                !_table_env_ma[noteOn]   && 
                !_table_env_mp[noteOn]   && 
                !_set_env_exp[noteOn]    && 
                !_set_env_filter[noteOn] && 
                !_set_env_voice[noteOn])
            {
                _set_processMode[noteOn] = NORMAL;
            }
        }
        
        
        // envelop on
        private function _envelopOn(noteOn:int) : void
        {
            _set_processMode[noteOn] = ENVELOP;
        }
        
        
        // make modulation table
        private function _makeModulationTable(depth:int, end_depth:int, delay:int, term:int) : SLLint
        {
            // initialize
            var list:SLLint = SLLint.allocList(delay + term + 1),
                i:int, elem:SLLint, step:int;
            
            // delay
            elem = list;
            if (delay) {
                for (i=0; i<delay; i++, elem=elem.next) {
                    elem.i = depth;
                }
            }
            // changing
            if (term) {
                depth <<= FIXED_BITS;
                step = ((end_depth<<FIXED_BITS) - depth) / term;
                for (i=0; i<term; i++, elem=elem.next) { 
                    elem.i = (depth >> FIXED_BITS);
                    depth += step;
                }
            }
            // last data
            elem.i = end_depth;
            
            return list;
        }
    }
}

