//----------------------------------------------------------------------------------------------------
// Arpeggiator class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.utils.Scale;
    import org.si.sound.patterns.Note;
    import org.si.sound.patterns.Sequencer;
    import org.si.sound.namespaces._sound_object_internal;
    
    /** @eventType org.si.sound.events.SoundObjectEvent.ENTER_FRAME */
    [Event(name="enterFrame",   type="org.si.sound.events.SoundObjectEvent")]
    /** @eventType org.si.sound.events.SoundObjectEvent.ENTER_SEGMENT */
    [Event(name="enterSegment", type="org.si.sound.events.SoundObjectEvent")]
    
    /** Arpeggiator provides monophonic arpeggio pattern sound. */
    public class Arpeggiator extends PatternSequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] Table of notes on scale */
        protected var _scale:Scale;
        /** @private [protected] scale index */
        protected var _scaleIndex:int;

        /** @private [protected] Current arpeggio pattern. */
        protected var _currentPattern:Array;
        /** @private [protected] Next arpeggio pattern to change while playing. */
        protected var _nextPattern:Array;
        /** @private [protected] Change bass line pattern at the head of segment. */
        protected var _changePatternOnSegment:Boolean;
        
                
        
        
    // properties
    //----------------------------------------
        /** change root note of the scale */
        override public function get note() : int {
            return _scale.rootNote;
        }
        override public function set note(n:int) : void {
            _scale.rootNote = n;
            _scaleIndexUpdated();
        }
        
        
        /** scale instance */
        public function get scale() : Scale { return _scale; }
        public function set scale(s:Scale) : void {
            _scale.copyFrom(s);
            _scaleIndexUpdated();
        }
        
        
        /** specify scale by name */
        public function get scaleName() : String { return _scale.name; }
        public function set scaleName(str:String) : void {
            _scale.name = str;
            _scaleIndexUpdated();
        }
        
        
        /** index on scale */
        public function get scaleIndex() : int { return _scaleIndex; }
        public function set scaleIndex(i:int) : void {
            _scaleIndex = i;
            _note = _scale.getNote(i);
            _scaleIndexUpdated();
        }
        
        
        /** note length in 16th beat. */
        public function get noteLength() : Number { return _sequencer.defaultLength; }
        public function set noteLength(l:Number) : void {
            if (l<0.25) l=0.25;
            else if (l>16) l=16;
            _sequencer.defaultLength = l;
            _sequencer.gridStep = l * 120;
        }
        
        
        /** Note index array of the arpeggio pattern. If the index is out of range, insert rest instead. */
        public function get pattern() : Array { return _currentPattern || _nextPattern; }
        public function set pattern(pat:Array) : void {
            if (isPlaying && _changePatternOnSegment) _nextPattern = pat;
            else _updateArpeggioPattern(pat);
        }
        
        
        /** True to change bass line pattern at the head of segment. @default true */
        public function get changePatternOnNextSegment() : Boolean { return _changePatternOnSegment; }
        public function set changePatternOnNextSegment(b:Boolean) : void { 
            _changePatternOnSegment = b;
        }
        
        
        /** [NOT RECOMENDED] Only for the compatibility before version 0.58, the getTime property can be used instead of this property. */
        public function get noteQuantize() : int { return gateTime * 8; }
        public function set noteQuantize(q:int) : void { gateTime = q * 0.125; }
        
                
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param scale Arpaggio scale, org.si.sion.utils.Scale instance, scale name String or null is suitable.
         *  @param noteLength length for each note
         *  @param pattern Note index array of the arpeggio pattern. If the index is out of range, insert rest instead.
         *  @see org.si.sion.utils.Scale
         */
        function Arpeggiator(scale:*=null, noteLength:Number=2, pattern:Array=null) 
        {
            super();
            name = "Arpeggiator";
            
            _scale = new Scale();
            if (scale is Scale) _scale.copyFrom(scale as Scale);
            else if (scale is String) _scale.name = scale as String;
            
            _nextPattern = null;
            _sequencer.defaultLength = 1;
            _sequencer.pattern = new Vector.<Note>();
            _sequencer.onEnterFrame = _onEnterFrame;
            _sequencer.onEnterSegment = _onEnterSegment;
            
            _updateArpeggioPattern(pattern);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @private */
        override public function reset() : void
        {
            super.reset();
            _scaleIndex = 0;
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** @private [protected] call this after the update of note or scale index */
        protected function _scaleIndexUpdated() : void {
            var i:int, imax:int = _sequencer.pattern.length;
            for (i=0; i<imax; i++) {
                _sequencer.pattern[i].note = _scale.getNote(_currentPattern[i] + _scaleIndex);
            }
        }
        
        
        // set arpeggio pattern
        private function _updateArpeggioPattern(indexPattern:Array) : void {
            var i:int, imax:int, note:int, pattern:Vector.<Note>;
            
            _currentPattern = indexPattern;
            if (_currentPattern) {
                imax = _currentPattern.length;
                _sequencer.pattern.length = imax;
                _sequencer.segmentFrameCount = imax;
                pattern = _sequencer.pattern;
                for (i=0; i<imax; i++) {
                    if (pattern[i] == null) pattern[i] = new Note();
                    note = _scale.getNote(_currentPattern[i] + _scaleIndex);
                    if (note >= 0 && note < 128) {
                        pattern[i].note = note;
                        pattern[i].velocity = -1;
                        pattern[i].length = Number.NaN;
                    } else {
                        pattern[i].setRest();
                    }
                }
            } else {
                _sequencer.pattern.length = 0;
                _sequencer.segmentFrameCount = 16;
            }
        }
        
        
        /** @private [protected] handler on enter segment */
        override protected function _onEnterSegment(seq:Sequencer) : void
        {
            if (_nextPattern != null) {
                _updateArpeggioPattern(_nextPattern);
                _nextPattern = null;
            }
            super._onEnterSegment(seq);
        }
    }
}

