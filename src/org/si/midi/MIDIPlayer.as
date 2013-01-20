//----------------------------------------------------------------------------------------------------
// MIDI file player class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.midi {
    import org.si.sion.*;
    import org.si.sion.midi.*;
    import org.si.sion.events.*;
    
    
    /** MIDI player */
    public class MIDIPlayer
    {
    // variables
    //----------------------------------------
        static private var _cache:* = {};
        static private var _driver:SiONDriver = null;
        static private var _nextData:SMFData = null;
        static private var _fadeOut:Boolean = false;
        
        
        
    // properties
    //----------------------------------------
        /** Playing position [sec] */
        static public function get position() : Number { return driver.position * 0.001; }
        static public function set position(pos:Number) : void { driver.position = pos * 1000; }
        
        /** Playing volume [0-1] */
        public function get volume() : Number { return driver.volume; }
        public function set volume(v:Number) : void { driver.volume = v; }
        
        
        /** tempo */
        static public function get tempo() : Boolean { return driver.bpm; }
        
        /** CPU loading [%] */
        static public function get cpuLoading() : Number { return driver.processTime*0.1; }
        
        /** Is paused ? */
        static public function get isPaused() : Boolean { return driver.isPaused; }
        
        /** Is playing ? */
        static public function get isPlaying() : Boolean { return driver.isPlaying; }
        
        
        /** SiON driver to play */
        static public function get driver() : SiONDriver {
            if (!_driver) {
                _driver = SiONDriver.mutex || new SiONDriver(4096);
            }
            return _driver;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** @private */
        function MIDIPlayer() { }
        
        
        
        
    // operations
    //----------------------------------------
        /** play MIDI file
         *  @param url MIDI file's URL
         *  @param fadeInTime fade in time [second]
         *  @return SMFData object to play
         */
        static public function play(url:String, fadeInTime:Number = 0) : SMFData
        {
            var smfData:SMFData = load(url);
            if (smfData.isAvailable) _play(smfData);
            else smfData.addEventListener(Event.COMPLETE, _waitAndPlay);
            driver.fadeIn(fadeInTime);
        }
        
        
        /** stop
         *  @param fadeOutTime fade out time [second]
         */
        static public function stop(fadeOutTime:Number = 0) : void
        {
            if (fadeOutTime>0) {
                _fadeOut = true;
                driver.fadeOut(fadeOutTime);
                driver.addEventListener(SiONEvent.FADE_OUT_COMPLETE, _stopWithFadeOut);
            } else {
                driver.stop();
            }
        }
        
        
        /** pause
         *  @param fadeOutTime fade out time [second]
         */
        static public function pause(fadeOutTime:Number = 0) : void
        {
            if (fadeOutTime>0) {
                driver.fadeOut(fadeOutTime);
                driver.addEventListener(SiONEvent.FADE_OUT_COMPLETE, _pauseWithFadeOut);
            } else {
                driver.pause();
            }
        }
        
        
        /** resume pausing
         *  @param fadeInTime fade in time [second]
         */
        static public function resume(fadeInTime:Number = 0) : void
        {
            if (fadeInTime>0) driver.fadeIn(fadeInTime);
            driver.resume();
        }
        
        
        /** load MIDI file without sounding 
         *  @param url MIDI file's URL
         *  @return SMFData object to load
         */
        static public function load(url:String) : SMFData
        {
            var smfData:SMFData = _cache[url];
            if (!smfData) {
                smfData = new smfData();
                smfData.load(new URLRequest(url));
                _cache[url] = smfData;
            }
            return smfData;
        }
        
        
        
        
    // handler
    //----------------------------------------
        static private function _play(smfData:SMFData) : void
        {
            if (isPlaying && _fadeOut) {
                _nextData = smfData;
                driver.addEventListener(SiONEvent.STREAM_STOP, _playNextData);
            } else {
                driver.play(smfData);
            }
        }
        
        
        static private function _waitAndPlay(e:Event) : void
        {
            _play(e.target);
        }
        
        
        static private function _pauseWithFadeOut(e:SiONEvent) : void
        {
            driver.removeEventListener(SiONEvent.FADE_OUT_COMPLETE, _pauseWithFadeOut);
            driver.pause();
        }
        
        
        static private function _stopWithFadeOut(e:SiONEvent) : void
        {
            _fadeOut = false;
            driver.removeEventListener(SiONEvent.FADE_OUT_COMPLETE, _stopWithFadeOut);
            driver.stop();
        }
        
        
        static private function _playNextData(e:SiONEvent) : void
        {
            driver.removeEventListener(SiONEvent.STREAM_STOP, _playNextData);
            if (_nextData.isAvailable) _play(_nextData);
            else _nextData.addEventListener(Event.COMPLETE, _waitAndPlay);
            _nextData = null;
        }
    }
}

