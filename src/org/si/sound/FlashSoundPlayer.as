//----------------------------------------------------------------------------------------------------
// Flash Media Sound player class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.media.Sound;
    import flash.media.SoundLoaderContext;
    import org.si.sion.*;
    //import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.synthesizers.*;
    import org.si.sound.events.FlashSoundPlayerEvent;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
    /** @eventType flash.events.Event */
    [Event(name="fspComplete", type="org.si.sound.events.FlashSoundPlayerEvent")]
    /** @eventType flash.events.Event */
    [Event(name="open",     type="flash.events.Event")]
    /** @eventType flash.events.Event */
    [Event(name="id3",      type="flash.events.Event")]
    /** @eventType flash.events.IOErrorEvent */
    [Event(name="ioError",  type="flash.events.IOErrorEvent")]
    /** @eventType flash.events.ProgressEvent */
    [Event(name="progress", type="flash.events.ProgressEvent")]
     
    
    /** FlashSoundPlayer provides advanced operations of Sound class (in flash media package). */
    public class FlashSoundPlayer extends PatternSequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] sound instance to play */
        protected var _soundData:Sound = null;
        
        /** @private [protected] is sound data available to play ? */
        protected var _isSoundDataAvailable:Boolean;
        
        /** @private [protected] synthsizer to play sound */
        protected var _flashSoundOperator:SamplerSynth;
        
        /** @private [protected] playing mode, 0=stopped, 1=wait for loading, 2=play as single note, 3=play by pattern sequencer */
        protected var _playingMode:int;
        
        /** @private [protected] waiting loading event count */
        protected var _createdEventCount:int;
        
        /** @private [protected] completed loading event count */
        protected var _completedEventCount:int;
        
        
        
    // properties
    //----------------------------------------
        /** the Sequencer instance belonging to this PatternSequencer, where the sequence pattern appears. */
        public function get soundData() : Sound { return _soundData; }
        public function set soundData(s:Sound) : void {
            _soundData = s;
            if (_soundData == null || (_soundData.bytesTotal > 0 && _soundData.bytesLoaded == _soundData.bytesTotal)) _setSoundData(_soundData);
            else _addLoadingJob(_soundData);
        }
        
        /** is playing ? */
        override public function get isPlaying() : Boolean { return (_playingMode != 0); }
        
        /** is sound data available to play ? */
        public function get isSoundDataAvailable() : Boolean { return _isSoundDataAvailable; }
        
        
        /** Voice data to play, You cannot change the voice of this sound object. */
        override public function get voice() : SiONVoice { return _synthesizer._synthesizer_internal::_voice; }
        override public function set voice(v:SiONVoice) : void { 
            throw new Error("FlashSoundPlayer; You cannot change voice of this sound object.");
        }
        
        
        /** Synthesizer to generate sound, You cannot change the synthesizer of this sound object */
        override public function get synthesizer() : VoiceReference { return _synthesizer; }
        override public function set synthesizer(s:VoiceReference) : void {
            throw new Error("FlashSoundPlayer; You cannot change synthesizer of this sound object.");
        }
        
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param soundData flash.media.Sound instance to control.
         */
        function FlashSoundPlayer(soundData:Sound = null)
        {
            super(68, 128, 0);
            name = "FlashSoundPlayer";
            _isSoundDataAvailable = false;
            _playingMode = 0;
            _flashSoundOperator = new SamplerSynth();
            _synthesizer = _flashSoundOperator;
            _createdEventCount = 0;
            _completedEventCount = 0;
            this.soundData = soundData;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** start sequence */
        override public function play() : void
        {
            _playingMode = 1;
            if (_isSoundDataAvailable) _playSound();
        }
        
        
        /** stop sequence */
        override public function stop() : void
        {
            switch (_playingMode) {
            case 2:
                if (_track) {
                    _synthesizer._unregisterTracks(_track);
                    _track.setDisposable();
                    _track = null;
                    _noteOff(-1, false);
                }
                _stopEffect();
                break;
            case 3:
                super.stop();
                break;
            }
            _playingMode = 0;
        }
        
        
        /** load sound from url, this method is the simplificaion of setSoundData(new Sound(url, context)).
         *  @private url same as Sound.load
         *  @private context same as Sound.load
         */
        public function load(url:URLRequest, context:SoundLoaderContext=null) : void
        {
            _soundData = new Sound(url, context);
            _addLoadingJob(_soundData);
        }
        
        
        /** Set flash sound instance with key range.
         *  @param sound Sound instance to assign
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at. -1 to set only at the key of argument "keyRangeFrom".
         *  @param startPoint slicing point to start data.
         *  @param endPoint slicing point to end data. The negative value plays whole data.
         *  @param loopPoint slicing point to repeat data. -1 means no repeat
         */
        public function setSoundData(sound:Sound, keyRangeFrom:int=0, keyRangeTo:int=127, startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : void
        {
            if (sound.bytesLoaded == sound.bytesTotal) _setSoundData(sound, keyRangeFrom, keyRangeTo, startPoint, endPoint, loopPoint);
            else _addLoadingJob(sound, keyRangeFrom, keyRangeTo, startPoint, endPoint, loopPoint);
        }
        
        
        
        
    // internal
    //----------------------------------------
        private function _setSoundData(sound:Sound, keyRangeFrom:int=0, keyRangeTo:int=127, startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : void
        {
            _isSoundDataAvailable = true;
            _flashSoundOperator.setSample(sound, false, keyRangeFrom, keyRangeTo).slice(startPoint, endPoint, loopPoint);
            if (_createdEventCount  == _completedEventCount && _playingMode == 1) _playSound();
        }
        
        
        private function _playSound() : void
        {
            if (_sequencer.pattern != null) {
                // play by PatternSequencer
                _playingMode = 3;
                super.play();
            } else {
                // play as single note
                _playingMode = 2;
                stop();
                _track = _noteOn(_note, false);
                if (_track) _synthesizer._registerTrack(_track);
            }
        }
        
        
        private function _addLoadingJob(sound:Sound, keyRangeFrom:int=0, keyRangeTo:int=127, startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : void
        {
            var event:FlashSoundPlayerEvent = new FlashSoundPlayerEvent(sound, _onComplete, _onError, keyRangeFrom, keyRangeTo, startPoint, endPoint, loopPoint);
            _createdEventCount++;
            sound.addEventListener(Event.ID3, _onID3);
            sound.addEventListener(Event.OPEN, _onOpen);
            sound.addEventListener(ProgressEvent.PROGRESS, _onProgress);
        }
        
        
        private function _removeAllEventListeners(event:FlashSoundPlayerEvent) : void
        {
            _completedEventCount++;
            event._sound.removeEventListener(Event.ID3, _onID3);
            event._sound.removeEventListener(Event.OPEN, _onOpen);
            event._sound.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
        }
        
        
        private function _onComplete(event:FlashSoundPlayerEvent) : void
        {
            _removeAllEventListeners(event);
            dispatchEvent(event);
            _setSoundData(event._sound, event._keyRangeFrom, event._keyRangeTo, event._startPoint, event._endPoint, event._loopPoint);
        }
        
        
        private function _onError(event:FlashSoundPlayerEvent) : void
        {
            _removeAllEventListeners(event);
            dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "IOError during loading Sound."));
        }
        
        
        private function _onID3(event:Event) : void
        {
            dispatchEvent(new Event(Event.ID3));
        }
        
        
        private function _onOpen(event:Event) : void
        {
            dispatchEvent(new Event(Event.OPEN));
        }
        
        
        private function _onProgress(event:ProgressEvent) : void
        {
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _completedEventCount, _createdEventCount));
        }
    }
}

