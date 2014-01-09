//----------------------------------------------------------------------------------------------------
// Monophonic synthesizer class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.patterns.*;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers.*;
    
    
    /** Monophonic synthesizer class provides single voice synthesizer sounding on the beat.
     */
    public class MonophonicSynthesizer extends PatternSequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] note object to sound on the beat */
        private var _noteObject:Note;
        
        
        
        
    // properties
    //----------------------------------------
        /** current note in the sequence, you cannot change this property. */
        override public function get note() : int { return (_track) ? _track.note : _sequencer.note; }
        override public function set note(n:int) : void { _errorCannotChange("note"); }
        
        /** Synchronizing quantizing, uint in 16th beat. (0:No synchronization, 1:sync.with 16th, 4:sync.with 4th). @default 0. */
        override public function get quantize() : Number { return _quantize; }
        override public function set quantize(q:Number) : void {
            _quantize = q;
            _sequencer.gridStep = q * 120;
        }
        
        /** Sound delay, uint in 16th beat. @default 0. */
        override public function get delay() : Number { return _delay; }
        override public function set delay(d:Number) : void {
            _errorCannotChange("delay");
        }
        
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param synth synthesizer to play
         */
        function MonophonicSynthesizer(synth:VoiceReference = null)
        {
            super(60, 128, 0, synth);
            name = "MonophonicSynthesizer";
            _noteObject = new Note();
            _sequencer.pattern = Vector.<Note>([_noteObject]);
            _sequencer.onExitFrame = _onExitFrame;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** start streaming without any sounds */
        override public function play() : void
        {
            super.play();
        }
        
        
        /** stop streaming */
        override public function stop() : void
        {
            super.stop();
        }
        
        
        /** note on
         *  @param note note number (0-127)
         *  @param velocity velocity (0-128-255)
         *  @param length length (1 = 16th beat length)
         */
        public function noteOn(note:int, velocity:int=128, length:int=0) : void
        {
            _noteObject.setNote(note, velocity, length);
        }
        
        
        /** note off
         *  @param note note number to sound off (0-127)
         */
        public function noteOff() : void
        {
            if (_track) _track.keyOff(0, false);
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** @private [protected] */
        protected function _onExitFrame(seq:Sequencer) : void
        {
            _noteObject.setRest();
        }
    }
}

