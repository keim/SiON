//----------------------------------------------------------------------------------------------------
// MIDI sound module
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.midi {
    import org.si.sion.*;
    import org.si.sion.namespaces._sion_internal;
    import org.si.sion.effector.*;
    import org.si.sion.events.SiONMIDIEvent;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.module.channels.SiOPMChannelBase;
    import org.si.sion.utils.SiONPresetVoice;
    import flash.utils.ByteArray;
    
    
    /** MIDI sound module */
    public class MIDIModule
    {
    // constant
    //--------------------------------------------------------------------------------
        /** General MIDI mode */
        static public const GM_MODE:String = "GMmode";
        /** Roland GS system exclusive mode */
        static public const GS_MODE:String = "GSmode";
        /** YAMAHA XG system exclusive mode */
        static public const XG_MODE:String = "XGmode";
        
        
        
    // variables
    //--------------------------------------------------------------------------------
        /** voice set for GM 128 voices. */
        public var voiceSet:Vector.<SiONVoice>;
        /** voice set for drum track. */
        public var drumVoiceSet:Vector.<SiONVoice>;
        /** MIDI channels */
        public var midiChannels:Vector.<MIDIModuleChannel>;
        
        /** NRPN callback, should be function(channelNum:int, nrpn:int, dataEntry:int) : void. */
        public var onNRPN:Function = null;
        /** System exclusize callback, should be function(channelNum:int, bytes:ByteArray) : void. */
        public var onSysEx:Function = null;
        /** Finish sequence callback, should be function() : void. */
        public var onFinishSequence:Function = null;
        
        // core --------------------
        private var _sionDriver:SiONDriver = null;
        private var _polyphony:int;
        // operators --------------------
        private var _freeOperators:MIDIModuleOperator;
        private var _activeOperators:MIDIModuleOperator;
        // drum track related --------------------
        private var _drumExclusiveGroupID:Vector.<int>;
        private var _drumExclusiveOperator:Vector.<MIDIModuleOperator>;
        private var _drumNoteOffAvailable:Vector.<int>;
        // effector related --------------------
        private var _effectorSet:Vector.<Array>;
        // MIDI event related --------------------
        private var _dataEntry:int;
        private var _rpnNumber:int;
        private var _isNRPN:Boolean;
        private var _portOffset:int;
        private var _portNumber:int;
        private var _systemExclusiveMode:String;
        // others --------------------
        private var _dispatchFlags:int = 0;
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** polyphony */
        public function get polyphony() : int { return _polyphony; }
        public function set polyphony(poly:int) : void { 
            _polyphony = poly;
        }
        /** MIDI channel count, port number is reset when channel count is changed. */
        public function get midiChannelCount() : int { return midiChannels.length; }
        public function set midiChannelCount(count:int) : void {
            midiChannels.length = count;
            for (var ch:int=0; ch<count; ch++) {
                if (!midiChannels[ch]) midiChannels[ch] = new MIDIModuleChannel();
                midiChannels[ch].eventTriggerID = ch;
            }
            _portOffset = 0;
        }
        /** free operator count */
        public function get freeOperatorCount() : int { return _freeOperators.length; }
        /** active operator count */
        public function get activeOperatorCount() : int { return _activeOperators.length; }
        /** port number */
        public function get portNumber() : int { return _portNumber; }
        public function set portNumber(portNum:int) : void {
            _portNumber = portNum;
            if (midiChannels.length > (portNum<<4)+15) _portOffset = portNum<<4;
            else _portOffset = (midiChannels.length-15) >> 4;
        }
        /** System exclusive mode */
        public function get systemExclusiveMode() : String { return _systemExclusiveMode; }
        public function set systemExclusiveMode(mode:String) : void { 
            _systemExclusiveMode = mode;
        }
        
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** MIDI sound module emulator
         *  @param polyphony polyphony
         *  @param midiChannelCount MIDI channel count
         */
        function MIDIModule(polyphony:int=32, midiChannelCount:int=16, systemExclusiveMode:String="")
        {
            var slot:int, i:int;
            
            // allocation
            _systemExclusiveMode = systemExclusiveMode;
            _polyphony = polyphony;
            _freeOperators = new MIDIModuleOperator(null);
            _activeOperators = new MIDIModuleOperator(null);
            midiChannels = new Vector.<MIDIModuleChannel>();
            
            voiceSet = new Vector.<SiONVoice>(128);
            drumVoiceSet = new Vector.<SiONVoice>(128);
            _drumExclusiveGroupID = new Vector.<int>(128);
            _drumExclusiveOperator = new Vector.<MIDIModuleOperator>(16);
            _drumNoteOffAvailable = new Vector.<int>(128);
            _effectorSet = new Vector.<Array>(8, true);
            for (slot=0; slot<8; slot++) _effectorSet[slot] = null;
            
            // initialize
            _effectorSet[1] = [new SiEffectStereoReverb(0.7,0.4,0.8,1)];
            _effectorSet[2] = [new SiEffectStereoChorus(20,0.1,4,20,1)];
            _effectorSet[3] = [new SiEffectStereoDelay(250,0.25,false,1)];
            setDrumExclusiveGroup(1, [42,44,46]); // hi-hat group
            setDrumExclusiveGroup(2, [80,81]);    // triangle group
            enableDrumNoteOff([71, 72]);          // samba whistle
            
            // alloc channels
            this.midiChannelCount = midiChannelCount;
            
            // load preset voices
            var preset:SiONPresetVoice = SiONPresetVoice.mutex;
            if (!preset || !preset["svmidi"] || !preset["svmidi.drum"]) {
                preset = new SiONPresetVoice(SiONPresetVoice.INCLUDE_WAVETABLE | SiONPresetVoice.INCLUDE_SINGLE_DRUM);
            }
            for (i=0; i<128; i++) {
                voiceSet[i] = preset["svmidi"][i];
            }
            for (i=0; i<60; i++) {
                drumVoiceSet[i+24] = preset["svmidi.drum"][i];
            }
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** @private this function is called first of all sequences */
        internal function _initialize(useMIDIModuleEffector:Boolean) : Boolean
        {
            var i:int, ope:MIDIModuleOperator;
            _sionDriver = SiONDriver.mutex;
            if (!_sionDriver) return false;
            
            resetAllChannels();
            _freeOperators.clear();
            _activeOperators.clear();
            for (i=0; i<_polyphony; i++) {
                _freeOperators.push(new MIDIModuleOperator(_sionDriver.newUserControlableTrack(i)));
            }
            for (i=0; i<16; i++) {
                _drumExclusiveOperator[i] = null;
            }
            
            _dataEntry = 0;
            _rpnNumber = 0;
            _isNRPN = false;
            _portOffset = 0;
            
            if (useMIDIModuleEffector) {
                for (i=0; i<8; i++) {
                    if (_effectorSet[i]) _sionDriver.effector.setEffectorList(i, _effectorSet[i]);
                }
            }
            
            _dispatchFlags = _sionDriver._sion_internal::_checkMIDIEventListeners();
            
            return true;
        }
        
        
        /** Set drum voice by sampler table 
         *  @param table sampler table class, ussualy get from SiONSoundFont
         *  @see SiONSoundFont
         */
        public function setDrumSamplerTable(table:SiOPMWaveSamplerTable) : void
        {
            var voice:SiONVoice = new SiONVoice(), i:int;
            voice.setSamplerTable(table);
            for (i=0; i<128; i++) drumVoiceSet[i] = voice;
        }
        
        
        /** set exclusive drum voice. Voice that has same groupID stops each other when it sounds.
         *  @param groupID 0 means no group. 1-15 are available.
         *  @param voiceNumbers list of voice number that have same groupID
         */
        public function setDrumExclusiveGroup(groupID:int, voiceNumbers:Array) : void
        {
            for (var i:int=0; i<voiceNumbers.length; i++) _drumExclusiveGroupID[voiceNumbers[i]] = groupID;
        }
        
        
        /** set default effector set.
         *  @param slot slot to set
         *  @param effectorList Array of inherit class of SiEffectBase
         */
        public function setDefaultEffector(slot:int, effectorList:Array) : void 
        {
            _effectorSet[slot] = effectorList;
        }
        
        
        /** enable drum note off. default value is false
         *  @param voiceNumbers list of voice number that enables note off
         */
        public function enableDrumNoteOff(voiceNumbers:Array, enable:Boolean=true) : void
        {
            for (var i:int=0; i<voiceNumbers.length; i++) _drumNoteOffAvailable[voiceNumbers[i]] = (enable)?1:0;
        }
        
        
        /** reset all channels */
        public function resetAllChannels() : void
        {
            for (var ch:int=0; ch<midiChannels.length; ch++) {
                midiChannels[ch].reset();
                if ((ch & 15) == 9) midiChannels[ch].drumMode = 1;
            }
        }
        
        
        /** note on */
        public function noteOn(channelNum:int, note:int, velocity:int=64) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = midiChannels[channelNum], voice:SiONVoice, 
                ope:MIDIModuleOperator, track:SiMMLTrack, channel:SiOPMChannelBase,
                drumExcID:int = 0, 
                sionTrackNote:int = note;
            
            if (!midiChannel.mute) {
            
                // get operator
                if (midiChannel.activeOperatorCount >= midiChannel.maxOperatorCount) {
                    for (ope=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                        if (ope.channel == channelNum) {
                            _activeOperators.remove(ope);
                            break;
                        }
                    }
                } else {
                    ope = _freeOperators.shift() || _activeOperators.shift();
                }
                
                if (ope.isNoteOn) {
                    ope.sionTrack.dispatchEventTrigger(false);
                    midiChannels[ope.channel].activeOperatorCount--;
                }
                
                // voice setting
                if (midiChannel.drumMode == 0) {
                    if (ope.programNumber != midiChannel.programNumber) {
                        ope.programNumber = midiChannel.programNumber;
                        voice = voiceSet[ope.programNumber];
                        if (voice) {
                            ope.sionTrack.quantRatio = 1;
                            voice.updateTrackVoice(ope.sionTrack);
                        } else {
                            _freeOperators.push(ope);
                            return;
                        }
                    }
                } else {
                    ope.programNumber = -1;
                    voice = drumVoiceSet[note];
                    if (voice) {
                        drumExcID = _drumExclusiveGroupID[note];
                        sionTrackNote = (voice.preferableNote == -1) ? 60 : voice.preferableNote;
                        if (drumExcID > 0) {
                            var excOpe:MIDIModuleOperator = _drumExclusiveOperator[drumExcID];
                            if (excOpe && excOpe.drumExcID == drumExcID) {
                                if (excOpe.isNoteOn) _noteOffOperator(excOpe);
                                excOpe.sionTrack.keyOff(0, true);
                            }
                            _drumExclusiveOperator[drumExcID] = ope;
                        }
                        ope.sionTrack.quantRatio = 1;
                        voice.updateTrackVoice(ope.sionTrack);
                    } else {
                        _freeOperators.push(ope);
                        return;
                    }
                }
                
                // operator settings
                track = ope.sionTrack;
                channel = track.channel;
                
                track.noteShift = midiChannel.masterCoarseTune;
                track.pitchShift = midiChannel.masterFineTune;
                track.pitchBend = (midiChannel.pitchBend * midiChannel.pitchBendSensitivity) >> 7; //(*64/8192)
                track.setPortament(midiChannel.portamentoTime);
                track.setEventTrigger(midiChannel.eventTriggerID, midiChannel.eventTriggerTypeOn, midiChannel.eventTriggerTypeOff);
                track.velocity = (velocity * 1.5) + 64;
                channel.setAllStreamSendLevels(midiChannel._sionVolumes);
                channel.pan = midiChannel.pan;
                channel.setLFOCycleTime(midiChannel.modulationCycleTime);
                channel.setPitchModulation(midiChannel.modulation>>2);            // width = 32
                channel.setAmplitudeModulation(midiChannel.channelAfterTouch>>2); // width = 32
                track.keyOn(sionTrackNote);
                
                ope.isNoteOn = true;
                ope.note = note;
                ope.channel = channelNum;
                ope.drumExcID = drumExcID;
                _activeOperators.push(ope);
                midiChannel.activeOperatorCount++;
            } // if (!midiChannel.mute) 
            
            if (_dispatchFlags & midiChannel.sionMIDIEventType & SiONMIDIEventFlag.NOTE_ON) {
                _sionDriver._sion_internal::_dispatchMIDIEvent(SiONMIDIEvent.NOTE_ON, track, channelNum, note, velocity);
            }
        }
        
        
        /** note off */
        public function noteOff(channelNum:int, note:int, velocity:int=0) : void
        {
            channelNum += _portOffset;
            
            var ope:MIDIModuleOperator, i:int=0;
            for (ope=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                if (ope.note == note && ope.channel == channelNum && ope.isNoteOn) {
                    _noteOffOperator(ope);
                    return;
                }
            }
        }
        
        
        private function _noteOffOperator(ope:MIDIModuleOperator) : void
        {
            var channelNum:int = ope.channel, note:int = ope.note,
                midiChannel:MIDIModuleChannel = midiChannels[channelNum];
            if (!midiChannel.mute) {
                if (midiChannel.sustainPedal) ope.sionTrack.dispatchEventTrigger(false);
                else if (midiChannel.drumMode == 0 || _drumNoteOffAvailable[note]) ope.sionTrack.keyOff();
                ope.isNoteOn = false;
                ope.note = -1;
                ope.channel = -1;
                midiChannel.activeOperatorCount--;
                _activeOperators.remove(ope);
                _freeOperators.push(ope);
            }
            
            if (_dispatchFlags & midiChannel.sionMIDIEventType & SiONMIDIEventFlag.NOTE_OFF) {
                _sionDriver._sion_internal::_dispatchMIDIEvent(SiONMIDIEvent.NOTE_OFF, ope.sionTrack, channelNum, note, 0);
            }
        }
        
        
        /** program change */
        public function programChange(channelNum:int, programNumber:int) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = midiChannels[channelNum];
            midiChannel.programNumber = programNumber;
            
            if (_dispatchFlags & midiChannel.sionMIDIEventType & SiONMIDIEventFlag.PROGRAM_CHANGE) {
                _sionDriver._sion_internal::_dispatchMIDIEvent(SiONMIDIEvent.PROGRAM_CHANGE, null, channelNum, 0, programNumber);
            }
        }
        
        
        /** channel after touch */
        public function channelAfterTouch(channelNum:int, value:int) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = midiChannels[channelNum];
            midiChannel.channelAfterTouch = value;
            
            for (var ope:MIDIModuleOperator=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                if (ope.channel == channelNum) {
                    ope.sionTrack.channel.setAmplitudeModulation(midiChannel.channelAfterTouch>>2);
                }
            }
        }
        
        
        /** pitch bned */
        public function pitchBend(channelNum:int, bend:int) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = midiChannels[channelNum];
            midiChannel.pitchBend = bend;
            
            for (var ope:MIDIModuleOperator=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                if (ope.channel == channelNum) {
                    ope.sionTrack.pitchBend = (midiChannel.pitchBend * midiChannel.pitchBendSensitivity) >> 7; //(*64/8192)
                }
            }
            if (_dispatchFlags & midiChannel.sionMIDIEventType & SiONMIDIEventFlag.PITCH_BEND) {
                _sionDriver._sion_internal::_dispatchMIDIEvent(SiONMIDIEvent.PITCH_BEND, null, channelNum, 0, bend);
            }
        }
        
        
        /** control change */
        public function controlChange(channelNum:int, controlerNumber:int, data:int) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = midiChannels[channelNum];
            
            switch (controlerNumber) {
            case SMFEvent.CC_BANK_SELECT_MSB:
                midiChannel.bankNumber = (data & 0x7f) << 7;
                // XG USE_FOR_RYTHM_PART support
                if (_systemExclusiveMode == XG_MODE) {
                    if ((data & 0x7f) == 127) midiChannel.drumMode = 1;
                    else if (channelNum != 9) midiChannel.drumMode = 0;
                }
                break;
            case SMFEvent.CC_BANK_SELECT_LSB:
                midiChannel.bankNumber |= data & 0x7f;
                break;
                
            case SMFEvent.CC_MODULATION:
                midiChannel.modulation = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setPitchModulation(midiChannel.modulation>>2); });
                break;
            case SMFEvent.CC_PORTAMENTO_TIME:
                midiChannel.portamentoTime = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.setPortament(midiChannel.portamentoTime); });
                break;

            case SMFEvent.CC_VOLUME:
                midiChannel.masterVolume = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
            //case SMFEvent.CC_BALANCE:
            case SMFEvent.CC_PANPOD:
                midiChannel.pan = data - 64;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.pan = midiChannel.pan; });
                break;
            case SMFEvent.CC_EXPRESSION:
                midiChannel.expression = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
                
            case SMFEvent.CC_SUSTAIN_PEDAL:
                midiChannel.sustainPedal = (data > 64);
                break;
            case SMFEvent.CC_PORTAMENTO:
                midiChannel.portamento = (data > 64);
                break;
            //case SMFEvent.CC_SOSTENUTO_PEDAL:
            //case SMFEvent.CC_SOFT_PEDAL:
            //case SMFEvent.CC_RESONANCE:
            //case SMFEvent.CC_RELEASE_TIME:
            //case SMFEvent.CC_ATTACK_TIME:
            //case SMFEvent.CC_CUTOFF_FREQ:
            //case SMFEvent.CC_DECAY_TIME:
            //case SMFEvent.CC_PROTAMENTO_CONTROL:
            case SMFEvent.CC_REVERB_SEND:
                midiChannel.setEffectSendLevel(1, data);
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
            case SMFEvent.CC_CHORUS_SEND:
                midiChannel.setEffectSendLevel(2, data);
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
            case SMFEvent.CC_DELAY_SEND:
                midiChannel.setEffectSendLevel(3, data);
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
                
            case SMFEvent.CC_NRPN_MSB: _rpnNumber =  (data & 0x7f) << 7;  break;
            case SMFEvent.CC_NRPN_LSB: _rpnNumber |= (data & 0x7f); _isNRPN = true;  break;
            case SMFEvent.CC_RPN_MSB:  _rpnNumber  =  (data & 0x7f) << 7;  break;
            case SMFEvent.CC_RPN_LSB:  _rpnNumber  |= (data & 0x7f); _isNRPN = false; break;
            case SMFEvent.CC_DATA_ENTRY_MSB:
                _dataEntry = (data & 0x7f) << 7;
                if (!_isNRPN) _onRPN(midiChannel);
                else if (onNRPN != null) onNRPN(channelNum, _rpnNumber, _dataEntry);
                break;
            case SMFEvent.CC_DATA_ENTRY_LSB:
                _dataEntry |= (data & 0x7f);
                if (!_isNRPN) _onRPN(midiChannel);
                else if (onNRPN != null) onNRPN(channelNum, _rpnNumber, _dataEntry);
                break;
            }
            
            if (_dispatchFlags & midiChannel.sionMIDIEventType & SiONMIDIEventFlag.CONTROL_CHANGE) {
                _sionDriver._sion_internal::_dispatchMIDIEvent(SiONMIDIEvent.CONTROL_CHANGE, null, channelNum, controlerNumber, data);
            }
            
            function $(func:Function) : void {
                for (var ope:MIDIModuleOperator=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                    if (ope.channel == channelNum) func(ope);
                }
            }
        }
        
        
        /** system exclusive */
        public function systemExclusive(channelNum:int, bytes:ByteArray) : void
        {
                 if (checkByteArray(bytes, _GM_RESET, 0)) { _systemExclusiveMode = GM_MODE; resetAllChannels(); }
            else if (checkByteArray(bytes, _GS_RESET, 0)) { _systemExclusiveMode = GS_MODE; resetAllChannels(); } 
            else if (checkByteArray(bytes, _XG_RESET, 0)) { _systemExclusiveMode = XG_MODE; resetAllChannels(); }
            else if (checkByteArray(bytes, _GS_EXIT, 0)) { _systemExclusiveMode = ""; }
            // GS USE_FOR_RYTHM_PART support
            else if (_systemExclusiveMode == GS_MODE) {
                if (checkByteArray(bytes, _GS_UFRP_CMD, 0)) {
                    var trackNum:int = bytes.readUnsignedByte(),
                        c0x15:int    = bytes.readUnsignedByte(),
                        mapNum:int   = bytes.readUnsignedByte();
                    if ((trackNum & 0xf0) != 0x10 || c0x15 != 0x15 || mapNum > 2) return;
                    trackNum = (trackNum & 15) + _portOffset;
                    if (trackNum < midiChannels.length) midiChannels[trackNum].drumMode = mapNum;
                }
            }
            if (onSysEx != null) onSysEx(channelNum, bytes);
        }
        static private var _GM_RESET:Array    = [0xf0,0x7e,0x7f,0x09,0x01,0xf7];
        static private var _GS_RESET:Array    = [0xf0,0x41,0x10,0x42,0x12,0x40,0x00,0x7f,0x00,0x41,0xf7];
        static private var _GS_EXIT :Array    = [0xf0,0x41,0x10,0x42,0x12,0x40,0x00,0x7f,0x7f,0x41,0xf7];
        static private var _XG_RESET:Array    = [0xf0,0x43,0x10,0x4c,0x00,0x00,0x7e,0x00,0xf7];
        static private var _GS_UFRP_CMD:Array = [0xf0,0x41,0x10,0x42,0x12,0x40];
        
        
        /** check ByteArray pattern by usigned byte */
        static public function checkByteArray(bytes:ByteArray, checkPattern:Array, position:int=-1) : Boolean
        {
            if (position != -1) bytes.position = position;
            var i:int, imax:int = checkPattern.length;
            for (i=0; i<imax; i++) {
                var ch:int = bytes.readUnsignedByte();
                if (checkPattern[i] != ch) return false;
            }
            return true;
        }
        
        
        /** @private */
        internal function _onFinishSequence() : void 
        {
            if (onFinishSequence != null) onFinishSequence();
        }
        
        
        
        private function _onRPN(midiChannel:MIDIModuleChannel) : void
        {
            switch (_rpnNumber) {
            case SMFEvent.RPN_PITCHBEND_SENCE:
                midiChannel.pitchBendSensitivity = _dataEntry >> 7;
                break;
            case SMFEvent.RPN_FINE_TUNE:
                midiChannel.masterFineTune = (_dataEntry >> 7) - 64;
                break;
            case SMFEvent.RPN_COARSE_TUNE:
                midiChannel.masterCoarseTune = (_dataEntry >> 7) - 64;
                break;
            }
        }
    }
}

