//----------------------------------------------------------------------------------------------------
// Class for sound object playing MML
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
    /** MML Player provides sequence sound written by MML, and you can control all tracks during playing sequence. */
    public class MMLPlayer extends SoundObject
    {
    // variables
    //----------------------------------------
        /** @private [protected] mml text. */
        protected var _mml:String;
        
        /** @private [protected] sequence data. */
        protected var _data:SiONData;

        /** @private [protected] flag that mml text is compiled to data */
        protected var _compiled:Boolean
        
        /** @private [protected] current controling track number */
        protected var _controlTrackNumber:int;
        
        /** @private [protected] track muting status */
        protected var _trackMute:Vector.<Boolean>;
        
        /** @private [protected] solo track number */
        protected var _soloTrackNumber:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** MML text */
        public function get mml() : String { return _mml; }
        public function set mml(str:String) : void {
            _mml = str || "";
            _compiled = false;
            _compile();
        }
        
        
        /** sequence data to play */
        public function get data() : SiONData { return _data; }
        
        
        /** current controling track number */
        public function get controlTrackNumber() : int { return _controlTrackNumber; }
        public function set controlTrackNumber(n:int) : void {
            _controlTrackNumber = n;
            if (_tracks) {
                var trackNumber:int = _controlTrackNumber;
                if (trackNumber < 0) trackNumber = 0;
                else if (trackNumber >= _tracks.length) trackNumber = _tracks.length - 1;
                _track = _tracks[trackNumber];
            }
        }
        
        
        /** number of MML playing tracks */
        public function get trackCount() : int { return (_tracks) ? _tracks.length : 0; }
        
        
        /** Solo track number, this value reset when call start() method. -1 sets no solo tracks. @default -1 */
        public function get soloTrackNumber() : int { return _soloTrackNumber; }
        public function set soloTrackNumber(n:int) : void { 
            var i:int;
            if (_soloTrackNumber != n && _tracks) {
                _soloTrackNumber = n;
                if (_soloTrackNumber < 0) {
                    for (i=0; i<_tracks.length; i++) _track.channel.mute = _trackMute[i];
                } else {
                    for (i=0; i<_tracks.length; i++) {
                        _trackMute[i] = _track.channel.mute;
                        _track.channel.mute = (i != _soloTrackNumber);
                    }
                }
            }
        }
        
        
        /** @private */
        override public function get coarseTune() : int { return (_track) ? _track.noteShift : _noteShift; }
        /** @private */
        override public function get fineTune() : Number { return (_track) ? (_track.pitchShift * 0.015625) : _pitchShift; }
        /** @private */
        override public function get gateTime() : Number { return (_track) ? _track.quantRatio : _gateTime; }
        /** @private */
        override public function get eventMask() : int { return (_track) ? _track.eventMask : _eventMask; }
        
        /** @private */
        override public function get mute() : Boolean { return (_track) ? _track.channel.mute : _thisMute; }
        /** @private */
        override public function get volume() : Number { return (_track) ? _track.channel.masterVolume : _thisVolume; }
        /** @private */
        override public function get pan() : Number { return (_track) ? _track.channel.pan : _thisPan; }
        /** @private */
        override public function get effectSend1() : Number { return (_track) ? _track.channel.getStreamSend(1) : (_volumes[1] * 0.0078125); }
        /** @private */
        override public function get effectSend2() : Number { return (_track) ? _track.channel.getStreamSend(2) : (_volumes[2] * 0.0078125); }
        /** @private */
        override public function get effectSend3() : Number { return (_track) ? _track.channel.getStreamSend(3) : (_volumes[3] * 0.0078125); }
        /** @private */
        override public function get effectSend4() : Number { return (_track) ? _track.channel.getStreamSend(4) : (_volumes[4] * 0.0078125); }
        /** @private */
        override public function get pitchBend() : Number { return (_track) ? (_track.pitchBend * 0.015625) : _pitchBend; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function MMLPlayer(mml:String=null) {
            _data = new SiONData();
            this.mml = mml;
            super(_data.title);
            _controlTrackNumber = 0;
            _trackMute = new Vector.<Boolean>();
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play mml data. */
        override public function play() : void { 
            _compile();
            stop();
            _soloTrackNumber = -1;
            _tracks = _sequenceOn(_data, false);
            if (_tracks) {
                _trackMute.length = _tracks.length;
                for (var i:int=0; i<_tracks.length; i++) _trackMute[i] = false;
                _synthesizer._registerTracks(_tracks);
                var trackNumber:int = _controlTrackNumber;
                if (trackNumber < 0) trackNumber = 0;
                else if (trackNumber >= _tracks.length) trackNumber = _tracks.length - 1;
                _track = _tracks[trackNumber];
            }
        }
        
        
        /** Stop mml data. */
        override public function stop() : void {
            if (_tracks) {
                _synthesizer._unregisterTracks(_tracks[0], _tracks.length);
                for each (var t:SiMMLTrack in _tracks) t.setDisposable();
                _tracks = null;
                _sequenceOff(false);
            }
            _stopEffect();
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** @private [protected] call this after the update mml */
        protected function _compile() : void {
            if (!driver || _compiled) return;
            if (_mml != "") {
                driver.compile(_mml, _data);
                name = _data.title;
            } else {
                _data.clear();
                name = "";
            }
            _compiled = true;
        }
    }
}

