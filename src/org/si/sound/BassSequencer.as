//----------------------------------------------------------------------------------------------------
// Bass sequencer class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.utils.Chord;
    import org.si.sion.utils.Scale;
    import org.si.sound.patterns.Note;
    import org.si.sound.patterns.Sequencer;
    import org.si.sound.patterns.BassSequencerPresetPattern;
    import org.si.sound.namespaces._sound_object_internal;
    
    /** @eventType org.si.sound.events.SoundObjectEvent.ENTER_FRAME */
    [Event(name="enterFrame",   type="org.si.sound.events.SoundObjectEvent")]
    /** @eventType org.si.sound.events.SoundObjectEvent.ENTER_SEGMENT */
    [Event(name="enterSegment", type="org.si.sound.events.SoundObjectEvent")]
    
    /** Bass sequencer provides simple monophonic bass line. */
    public class BassSequencer extends PatternSequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // static variables
    //----------------------------------------
        static private var _presetPattern:BassSequencerPresetPattern = null;
        static private var bassPatternList:Array;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] chord instance */
        protected var _scale:Scale;
        /** @private [protected] Default chord instance, this is used when the name is specifyed */
        protected var _defaultChord:Chord = new Chord();

        /** @private [protected] pettern. */
        protected var _pattern:Vector.<Note>;
        /** @private [protected] Current length sequence pattern. */
        protected var _currentPattern:Array;
        /** @private [protected] Next length sequence pattern to change while playing. */
        protected var _nextPattern:Array;
        /** @private [protected] pettern number. */
        protected var _patternNumber:int;
        /** @private [protected] Change bass line pattern at the head of segment. */
        protected var _changePatternOnSegment:Boolean;
        
        
        
    // properties
    //----------------------------------------
        /** Preset voice list */
        //public function get presetVoice() : BassSequencerPresetVoice { return _presetVoice; }
        
        /** Preset pattern list */
        public function get presetPattern() : BassSequencerPresetPattern { return _presetPattern; }
        
        
        /** Bass note of chord  */
        override public function get note() : int { return _scale.bassNote; }
        override public function set note(n:int) : void {
            if (_scale !== _defaultChord) _defaultChord.copyFrom(_scale);
            _defaultChord.bassNote = n;
            _scale = _defaultChord;
            _updateBassNote();
        }
        
        
        /** chord instance */
        public function get scale() : Scale { return _scale; }
        public function set scale(s:Scale) : void {
            _scale = s || _defaultChord;
            _updateBassNote();
        }
        
        
        /** specify chord by name */
        public function get chordName() : String { return _scale.name; }
        public function set chordName(name:String) : void {
            _defaultChord.name = name;
            _scale = _defaultChord;
            _updateBassNote();
        }
        
        
        /** maximum limit of bass line Pattern number */
        public function get patternNumberMax() : int {
            return bassPatternList.length;
        }
        
        
        /** bass line Pattern number */
        public function get patternNumber() : int { return _patternNumber; }
        public function set patternNumber(n:int) : void {
            if (n < 0 || n >= bassPatternList.length) return;
            _patternNumber = n;
            pattern = bassPatternList[n];
        }
        
        
        /** Number Array of the sequence notes. If the value is 0, insert rest instead. */
        public function get pattern() : Array { return _currentPattern || _nextPattern; }
        public function set pattern(pat:Array) : void {
            if (isPlaying && _changePatternOnSegment) {
                _nextPattern = pat;
            } else {
                _currentPattern = pat;
                _updateBassNote();
            }
        }
        
        
        /** True to change bass line pattern at the head of segment. @default true */
        public function get changePatternOnNextSegment() : Boolean { return _changePatternOnSegment; }
        public function set changePatternOnNextSegment(b:Boolean) : void { 
            _changePatternOnSegment = b;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param scale Bassline scale or chord or chord name.
         *  @param patternNumber bass line pattern number
         *  @param changePatternOnSegment When this is true, pattern and chord are changed at the head of next segment.
         *  @see org.si.sion.utils.Scale
         */
        function BassSequencer(chord:*=null, patternNumber:int=6, changePatternOnSegment:Boolean=true) 
        {
            super();
            name = "BassSequencer";
            
            if (_presetPattern == null) {
                _presetPattern = new BassSequencerPresetPattern();
                bassPatternList = _presetPattern["bass"];
            }
            
            _pattern = new Vector.<Note>();
            
            _changePatternOnSegment = false;
            if (chord is String) this.chordName = chord as String;
            else this.scale = chord as Chord;
            this.patternNumber = patternNumber;
            _changePatternOnSegment = changePatternOnSegment;
            
            _sequencer.onEnterFrame = _onEnterFrame;
            _sequencer.onEnterSegment = _onEnterSegment;
        }
        
        
        /** @private [protected] */
        protected function _updateBassNote() : void
        {
            var i:int, imax:int, bn:int = _scale.bassNote;
            if (_currentPattern) {
                imax = _currentPattern.length;
                _pattern.length = imax;
                for (i=0; i<imax; i++) {
                    if (_pattern[i] == null) _pattern[i] = new Note();
                    if (_currentPattern[i]) {
                        _pattern[i].note     = _currentPattern[i].note - 33 + bn;
                        _pattern[i].velocity = _currentPattern[i].velocity;
                        _pattern[i].length   = _currentPattern[i].length;
                    } else {
                        _pattern[i].setRest();
                    }
                }
            } else {
                _pattern.length = 16;
                for (i=0; i<16; i++) {
                    if (_pattern[i] == null) _pattern[i] = new Note();                    
                    _pattern[i].setRest();
                }
            }
            _sequencer.pattern = _pattern;
        }
        
        
        /** @private [protected] enter segment handler */
        override protected function _onEnterSegment(seq:Sequencer) : void
        {
            if (_nextPattern) {
                _currentPattern = _nextPattern;
                _nextPattern = null;
                _updateBassNote();
            }
            super._onEnterSegment(seq);
        }
    }
}

