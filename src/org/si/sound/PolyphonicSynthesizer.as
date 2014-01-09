//----------------------------------------------------------------------------------------------------
// Polyphonic synthesizer class
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
    
    
    /** Polyphonic synthesizer class provides synthesizer with multi tracks.
     */
    public class PolyphonicSynthesizer extends MultiTrackSoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        
        
        
        
    // properties
    //----------------------------------------
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param synth synthesizer to play
         */
        function PolyphonicSynthesizer(synth:VoiceReference = null)
        {
            super("PolyphonicSynthesizer", synth);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @private [protected] Reset */
        override public function reset() : void 
        {
            super.reset();
        }
        
        
        /** start streaming without any sounds */
        override public function play() : void
        {
            _stopAllTracks();
            _tracks = new Vector.<SiMMLTrack>();
        }
        
        
        /** stop all tracks */
        override public function stop() : void
        {
            _stopAllTracks();
        }
        
        
        /** note on 
         *  @param note note number (0-128)
         *  @param velocity velocity (0-128-255)
         *  @param length length (1 = 16th beat length)
         */
        public function noteOn(note:int, velocity:int=128, length:int=0) : void
        {
            if (_tracks) {
                _length = length;
                _note = note;
                _track = _noteOn(_note, false);
                if (_track) _synthesizer._registerTrack(_track);
                _track.velocity = velocity;
                _tracks.push(_track);
            }
        }
        
        
        /** note off 
         *  @param note note number to sound off (0-127)
         */
        public function noteOff(note:int, stopWithReset:Boolean = true) : void
        {
            var noteOffTracks:Vector.<SiMMLTrack> = _noteOff(note, stopWithReset);
            for each (var t:SiMMLTrack in noteOffTracks) {
                _synthesizer._unregisterTracks(t);
                t.setDisposable();
            }
        }
        
        
        
        
    // internal
    //----------------------------------------
    }
}

