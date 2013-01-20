//----------------------------------------------------------------------------------------------------
// Sequencer class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.patterns {
    import org.si.sion.*;
    import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
    /** The Sequencer class provides simple one track pattern player. */
    public class Sequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** pattern note vector to play */
        public var pattern:Vector.<Note> = null;
        /** next pattern, the pattern property is replaced to this vector at the head of next segment @see pattern */
        public var nextPattern:Vector.<Note> = null;
        /** voice list referenced by Note.voiceIndex. @see org.si.sound.Note.voiceIndex */
        public var voiceList:Array = null;
        

        /** @private [internal use] callback on every notes. function(Sequencer) : void */
        _sound_object_internal var onEnterFrame:Function = null;
        /** @private [internal use] callback after every notes. function(Sequencer) : void */
        _sound_object_internal var onExitFrame:Function = null;
        /** @private [internal use] callback on first beat of every segments. function(Sequencer) : void */
        _sound_object_internal var onEnterSegment:Function = null;
        /** @private [internal use] Frame count in one segment */
        _sound_object_internal var segmentFrameCount:int;
        /** @private [internal use] Grid step in ticks */
        _sound_object_internal var gridStep:int;
        /** @private [internal use] portament */
        _sound_object_internal var portament:int;
        
        /** @private owner of this pattern sequencer */
        protected var _owner:SoundObject;
        /** @private controlled track */
        protected var _track:SiMMLTrack;
        /** @private MMLEvent.INTERNAL_WAIT. */
        protected var _waitEvent:MMLEvent;
        /** @private check number of synthsizer update */
        protected var _synthesizer_updateNumber:int;
        
        /** @private Frame counter */
        protected var _frameCounter:int;
        /** @private playing pointer on the pattern */
        protected var _sequencePointer:int;
        /** @private initial value of _sequencePointer */
        protected var _initialSequencePointer:int;
        
        /** @private Default note */
        protected var _defaultNote:int;
        /** @private Default velocity */
        protected var _defaultVelocity:int;
        /** @private Default length */
        protected var _defaultLength:int;
        /** @private Default gate time */
        protected var _defaultGateTime:int;
        /** @private Current note */
        protected var _currentNote:Note;
        /** @private Grid shift vectors */
        protected var _currentGridShift:int;
        /** @private Mute */
        protected var _mute:Boolean;
        
        /** @private [protected] Event trigger ID */
        protected var _eventTriggerID:int;
        /** @private [protected] note on trigger | (note off trigger &lt;&lt; 2) trigger type */
        protected var _noteTriggerFlags:int;
        
        /** @private Grid shift pattern */
        protected var _gridShiftPattern:Vector.<int>;
        
        
        
        
    // properties
    //----------------------------------------
        /** current frame count, -1 means waiting for start */
        public function get frameCount() : int { return _frameCounter; }
        
        
        /** sequence pointer, -1 means waiting for start */
        public function get sequencePointer() : int { return _sequencePointer; }
        public function set sequencePointer(p:int) : void {
            if (_track) {
                _sequencePointer = p - 1;
                _frameCounter = p % segmentFrameCount;
                if (_sequencePointer >= 0) {
                    if (_sequencePointer >= pattern.length) _sequencePointer %= pattern.length;
                    _currentNote = pattern[_sequencePointer];
                }
            } else {
                _initialSequencePointer = p - 1;
            }
        }
        
        
        /** mute */
        public function get mute() : Boolean { return _mute; }
        public function set mute(b:Boolean) : void { _mute = b; }
        
        
        /** curent note number (0-127) */
        public function get note() : int {
            if (_currentNote == null || _currentNote.note < 0) return _defaultNote;
            return _currentNote.note;
        }
        
        
        /** curent note's velocity (minimum:0 - maximum:255, the value over 128 makes distotion). */
        public function get velocity() : int {
            if (_currentNote == null || _mute) return 0;
            if (_currentNote.velocity < 0) return _defaultVelocity;
            return _currentNote.velocity;
        }
        
        
        /** curent note's gate time (0-1). */
        public function get gateTime() : Number {
            if (_currentNote == null || isNaN(_currentNote.gateTime)) return _defaultGateTime;
            return _currentNote.gateTime;
        }
        
        
        /** curent note's length. */
        public function get length() : Number {
            if (_currentNote == null || isNaN(_currentNote.length)) return _defaultLength;
            return _currentNote.length;
        }
        
        
        /** Track event trigger ID */
        public function get eventTriggerID() : int { return _eventTriggerID; }
        public function set eventTriggerID(id:int) : void { _eventTriggerID = id; }
        /** Track note on trigger type */
        public function get noteOnTriggerType() : int { return _noteTriggerFlags & 3; }
        /** Track note off trigger type */
        public function get noteOffTriggerType() : int { return _noteTriggerFlags >> 2; }
        
        
        /** default note (0-127), this value is refered when the Note's note property is under 0 (ussualy -1). */
        public function get defaultNote() : int { return _defaultNote; }
        public function set defaultNote(n:int) : void { _defaultNote = (n < 0) ? 0 : (n > 127) ? 127 : n; }
        
        
        /** default velocity (minimum:0 - maximum:255, the value over 128 makes distotion), this value is refered when the Note's velocity property is under 0 (ussualy -1). */
        public function get defaultVelocity() : int { return _defaultVelocity; }
        public function set defaultVelocity(v:int) : void { _defaultVelocity = (v < 0) ? 0 : (v > 255) ? 255 : v; }
        
        
        /** default length, this value is refered when the Note's length property is Number.NaN. */
        public function get defaultLength() : Number { return _defaultLength; }
        public function set defaultLength(l:Number) : void { _defaultLength = (l < 0) ? 0 : l; }
        
        
        /** default gate time, this value is refered when the Note's gate time property is Number.NaN. */
        public function get defaultGateTime() : Number { return _defaultGateTime; }
        public function set defaultGateTime(g:Number) : void { _defaultGateTime = (g < 0) ? 0 : (g > 1) ? 1 : g; }
        
        
        /** Frame divition of 1 measure. Set 16 to play notes in 16th beats. */
        public function get division() : int { 
            var step:int = int(1920 / segmentFrameCount);
            return (step == gridStep) ? segmentFrameCount : 0;
        }
        public function set division(d:int) : void {
            segmentFrameCount = d;
            gridStep = 1920 / d;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** @private constructor. you should not create new PatternSequencer in your own codes. */
        function Sequencer(owner:SoundObject, data:SiONData, defaultNote:int=60, defaultVelocity:int=128, defaultLength:Number=0, defaultGateTime:Number=0.75, gridShiftPattern:Vector.<int>=null)
        {
            _owner = owner;
            pattern = null;
            voiceList = null;
            onEnterSegment = null;
            onEnterFrame = null;
            
            // initialize
            segmentFrameCount = 16;    // 16 count in one segment
            gridStep = 120;            // 16th beat (1920/16)
            portament = 0;
            _frameCounter = -1;
            _sequencePointer = -1;
            _initialSequencePointer = -1;
            _defaultNote     = defaultNote;
            _defaultVelocity = defaultVelocity;
            _defaultLength   = defaultLength;
            _defaultGateTime = defaultGateTime;
            _currentNote = null;
            _currentGridShift = 0;
            _gridShiftPattern = gridShiftPattern;
            _mute = false;
            _eventTriggerID = 0;
            _noteTriggerFlags = 0;

            // create internal sequence
            var seq:MMLSequence = data.appendNewSequence();
            seq.initialize();
            seq.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
            seq.appendNewCallback(_onEnterFrame, 0);
            _waitEvent = seq.appendNewEvent(MMLEvent.INTERNAL_WAIT, 0, gridStep);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @private [internal use] */
        _sound_object_internal function play(track:SiMMLTrack) : SiMMLTrack
        {
            _synthesizer_updateNumber = _owner.synthesizer._synthesizer_internal::_voiceUpdateNumber;
            _track = track;
            _track.setPortament(portament);
            _track.setEventTrigger(_eventTriggerID, _noteTriggerFlags&3, _noteTriggerFlags>>2);
            _sequencePointer = _initialSequencePointer;
            _frameCounter = (_initialSequencePointer == -1) ? -1 : (_initialSequencePointer % segmentFrameCount);
            _currentGridShift = 0;
            if (pattern && pattern.length>0) _currentNote = pattern[0];
            return track;
        }
        
        
        /** @private [internal use] */
        _sound_object_internal function stop() : void
        {
        }
        
        
        /** @private [internal use] set portament */
        _sound_object_internal function setPortament(p:int) : int
        {
            portament = p;
            if (portament < 0) portament = 0;
            if (_track) _track.setPortament(portament);
            return portament;
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** @private internal callback on every beat */
        protected function _onEnterFrame(trackNumber:int) : MMLEvent
        {
            var vel:int, patternLength:int;
            
            // increment frame counter
            if (++_frameCounter == segmentFrameCount) _frameCounter = 0;
            
            // segment oprations
            if (_frameCounter == 0) _onEnterSegment();
            
            // pattern sequencer
            patternLength = (pattern) ? pattern.length : 0;
            
            if (patternLength > 0) {
                // increment pointer
                if (++_sequencePointer >= patternLength) _sequencePointer %= patternLength;
                
                // get current Note from pattern
                _currentNote = pattern[_sequencePointer];
                
                // callback on enter frame
                if (onEnterFrame != null) onEnterFrame(this);
                
                // get current velocity, note on when velocity > 0
                vel = velocity;
                if (vel > 0) {
                    // change voice
                    if (voiceList && _currentNote && _currentNote.voiceIndex >= 0) {
                        _owner.voice = voiceList[_currentNote.voiceIndex];
                    }
                    // update owners track voice when synthesizer is updated
                    if (_synthesizer_updateNumber != _owner.synthesizer._synthesizer_internal::_voiceUpdateNumber) {
                        _owner.synthesizer._synthesizer_internal::_voice.updateTrackVoice(_track);
                        _synthesizer_updateNumber = _owner.synthesizer._synthesizer_internal::_voiceUpdateNumber;
                    } 
                    
                    // change track velocity & gate time
                    _track.velocity = vel;
                    _track.quantRatio = gateTime;
                    
                    // note on
                    _track.setNote(note, SiONDriver.mutex.sequencer.calcSampleLength(length), (portament>0));
                }
                
                // set length of rest event 
                if (_gridShiftPattern) {
                    var diff:int = _gridShiftPattern[_frameCounter] - _currentGridShift;
                    _waitEvent.length = gridStep + diff;
                    _currentGridShift += diff;
                } else {
                    _waitEvent.length = gridStep;
                }
                
                // callback on exit frame
                if (onExitFrame != null) onExitFrame(this);
            }
            
            return null;
        }
        
        
        /** @private internal callback on first beat of every segments */
        protected function _onEnterSegment() : void
        {
            // callback on enter segment
            if (onEnterSegment != null) onEnterSegment(this);
            // replace pattern
            if (nextPattern) {
                pattern = nextPattern;
                nextPattern = null;
            }
        }
    }
}


