//----------------------------------------------------------------------------------------------------
// Multi track Sound object
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers.*;
    
    
    /** The MultiTrackSoundObject class is the base class for all objects that can control plural tracks. 
     */
    public class MultiTrackSoundObject extends SoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // valiables
    //----------------------------------------
        /** @private [protected] mask for tracks operation. */
        protected var _trackOperationMask:uint;
        
        
        
        
    // properties
    //----------------------------------------
        /** Returns the number of tracks. */
        public function get trackCount() : int { return (_tracks) ? _tracks.length : 0; }
        
        
        
        
    // properties
    //----------------------------------------
        /** @private */
        override public function get isPlaying() : Boolean { return (_tracks != null); }
        
        
        /** @private */
        override public function set coarseTune(n:int) : void {
            super.coarseTune = n;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                    if ((f&1)==0) _tracks[i].noteShift = _noteShift;
                }
            }
        }
        
        /** @private */
        override public function set fineTune(p:Number) : void {
            super.fineTune = p;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length, ps:int = _pitchShift*64;
                for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                    if ((f&1)==0) _tracks[i].pitchShift = ps;
                }
            }
        }
        
        /** @private */
        override public function set gateTime(g:Number) : void {
            super.gateTime = g;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                    if ((f&1)==0) _tracks[i].quantRatio = _gateTime;
                }
            }
        }
        
        /** @private */
        override public function set eventMask(m:int) : void {
            super.eventMask = m;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                    if ((f&1)==0) _tracks[i].eventMask = _eventMask;
                }
            }
        }
        
        /** @private */
        override public function set mute(m:Boolean) : void { 
            super.mute = m;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                    if ((f&1)==0) _tracks[i].channel.mute = _mute;
                }
            }
        }
        
        /** @private */
        override public function set pan(p:Number) : void {
            super.pan = p;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                    if ((f&1)==0) _tracks[i].channel.pan = _pan*64;
                }
            }
        }
        
        
        /** @private */
        override public function set pitchBend(p:Number) : void {
            super.pitchBend = p;
            if (_tracks) {
                var i:int, f:uint, pb:int = p*64, imax:int = _tracks.length;
                for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                    if ((f&1)==0) _tracks[i].pitchBend = pb;
                }
            }
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** @private [protected] constructor */
        function MultiTrackSoundObject(name:String = null, synth:VoiceReference = null) {
            super(name, synth);
            _tracks = null;
            _trackOperationMask = 0;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @private [protected] Reset */
        override public function reset() : void 
        {
            super.reset();
            _trackOperationMask = 0;
        }
        
        
        /** you cannot call play() in MultiTrackSoundObject. */
        override public function play() : void { 
            _errorNotAvailable("play()");
        }
        
        
        /** you cannot call stop() in MultiTrackSoundObject. */
        override public function stop() : void {
            _errorNotAvailable("stop()");
        }
        
        
        /** @private [protected] Stop all sound belonging to this sound object. */
        protected function _stopAllTracks() : void {
            if (_tracks) {
                for each (var t:SiMMLTrack in _tracks) {
                    _synthesizer._unregisterTracks(t);
                    t.setDisposable();
                }
                _tracks = null;
            }
            _stopEffect();
        }
        
        
        /** @private [protected] update stream send level */
        override protected function _updateStreamSend(streamNum:int, level:Number) : void {
            if (_tracks) {
                if (_effectChain) _effectChain.setStreamSend(streamNum, level);
                else {
                    var i:int, f:uint, imax:int = _tracks.length;
                    for (i=0, f=_trackOperationMask; i<imax; i++, f>>=1) {
                        if ((f&1)==0) _tracks[i].channel.setStreamSend(streamNum, level);
                    }
                }
            }
        }
    }
}

