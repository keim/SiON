//----------------------------------------------------------------------------------------------------
// Pattern sequencer class
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
    
    
    /** Pattern sequencer class provides simple one track pattern player. The sequence pattern is represented as Vector.&lt;Note&gt;.
@see org.si.sound.patterns.Note 
@example Simple usage
<listing version="3.0">
// create new instance
var ps:PatternSequencer = new PatternSequencer();
    
// set sequence pattern by Note vector
var pat:Vector.&lt;Note&gt; = new Vector.&lt;Note&gt;();
pat.push(new Note(60, 64, 1));  // note C
pat.push(new Note(62, 64, 1));  // note D
pat.push(new Note(64, 64, 2));  // note E with length of 2
pat.push(null);                 // rest; null means no operation
pat.push(new Note(62, 64, 2));  // note D with length of 2
pat.push(new Note().setRest()); // rest; Note.setRest() method set no operation

// PatternSequencer.sequencer is the sound player
ps.sequencer.pattern = pat;
    
// play sequence "l16 $cde8d8" in MML
ps.play();
</listing>
     */
    public class PatternSequencer extends SoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] Sequencer instance */
        protected var _sequencer:Sequencer;
        /** @private [protected] Sequence data */
        protected var _data:SiONData;

        /** @private [protected] */
        protected var _callbackEnterFrame:Function = null;
        /** @private [protected] */
        protected var _callbackEnterSegment:Function = null;
        
        
        
        
    // properties
    //----------------------------------------
        /** the Sequencer instance belonging to this PatternSequencer, where the sequence pattern appears. */
        public function get sequencer() : Sequencer { return _sequencer; }
        
        
        /** portament */
        public function get portament() : int { return _sequencer.portament; }
        public function set portament(p:int) : void { _sequencer.setPortament(p); }
        
        /** current note in the sequence, you cannot change this property. */
        override public function get note() : int { return _sequencer.note; }
        override public function set note(n:int) : void { _errorCannotChange("note"); }
        
        /** current length in the sequence, you cannot change this property. */
        override public function get length() : Number { return _sequencer.length; }
        override public function set length(l:Number) : void { _errorCannotChange("length"); }
        
        /** current length in the sequence, you cannot change this property. */
        override public function set gateTime(g:Number) : void { 
            _sequencer.defaultGateTime = _gateTime = (g<0) ? 0 : (g>1) ? 1 : g;
            //if (_track) _track.quantRatio = _gateTime;
        }
        
        
        /** callback on enter frame */
        public function get onEnterFrame() : Function { return _callbackEnterFrame; }
        public function set onEnterFrame(f:Function) : void {
            _callbackEnterFrame = f;
        }
        
        /** callback on enter segment */
        public function get onEnterSegment() : Function { return _callbackEnterSegment; }
        public function set onEnterSegment(f:Function) : void {
            _callbackEnterSegment = f;
        }
        
        /** callback on exit frame */
        public function get onExitFrame() : Function { return _sequencer.onExitFrame; }
        public function set onExitFrame(f:Function) : void {
            _sequencer.onExitFrame = f;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param defaultNote Default note, this value is referenced when Note.note property is -1.
         *  @param defaultVelocity Default velocity, this value is referenced when Note.velocity property is -1.
         *  @param defaultLength Default length, this value is referenced when Note.length property is Number.NaN.
         *  @param synth synthesizer to play
         */
        function PatternSequencer(defaultNote:int=60, defaultVelocity:int=128, defaultLength:Number=0, synth:VoiceReference = null)
        {
            super("PatternSequencer", synth);
            _data = new SiONData();
            _sequencer = new Sequencer(this, _data, defaultNote, defaultVelocity, defaultLength);
            _sequencer.onEnterFrame = _onEnterFrame;
            _sequencer.onEnterSegment = _onEnterSegment;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** start sequence */
        override public function play() : void
        {
            stop();
            var list:Vector.<SiMMLTrack> = _sequenceOn(_data, false, false);
            if (list.length > 0) {
                _track = _sequencer.play(list[0]);
                _synthesizer._registerTrack(_track);
            }
        }
        
        
        /** stop sequence */
        override public function stop() : void
        {
            if (_track) {
                _sequencer.stop();
                _synthesizer._unregisterTracks(_track);
                _track.setDisposable();
                _track = null;
                _sequenceOff(true);
            }
            _stopEffect();
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** @private [protected] handler on enter segment */
        override protected function _onEnterFrame(seq:Sequencer) : void
        {
            if (_callbackEnterFrame != null) _callbackEnterFrame(seq);
            super._onEnterFrame(seq);
        }
        
        
        /** @private [protected] handler on enter segment */
        override protected function _onEnterSegment(seq:Sequencer) : void
        {
            if (_callbackEnterSegment != null) _callbackEnterSegment(seq);
            super._onEnterSegment(seq);
        }
    }
}

