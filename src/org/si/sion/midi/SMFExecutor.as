//----------------------------------------------------------------------------------------------------
// Standard MIDI File player class
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.midi {
    import flash.utils.ByteArray;
    import org.si.sion.SiONDriver;
    
    
    /** Standard MIDI File executor */
    public class SMFExecutor
    {
    // variables
    //--------------------------------------------------------------------------------
        private var _pointer:int = 0;
        private var _residueTicks:int = 0;
        private var _track:SMFTrack = null;
        private var _module:MIDIModule = null;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function SMFExecutor()
        {
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** @private */
        internal function _initialize(track:SMFTrack, module:MIDIModule) : void
        {
            _track = track;
            _module = module;
            _pointer = 0;
            _residueTicks = (_track.sequence.length > 0) ? _track.sequence[0].deltaTime : -1;
        }
        
        
        /** @private */
        internal function _execute(ticks:int) : int
        {
            if (_residueTicks == -1) return 65536;
            
            var event:SMFEvent = _track.sequence[_pointer], channel:int, v:int;
            
            while (ticks >= _residueTicks) {
                ticks -= _residueTicks;
                channel = event.type & 15;
                
                if (event.type & 0xff00) {
                    // META event
                    switch (event.type) {
                    case SMFEvent.META_TEMPO:
                        SiONDriver.mutex.bpm = event.value;
                        break;
                    case SMFEvent.META_PORT:
                        _module.portNumber = event.value;
                        break;
                    case SMFEvent.META_TRACK_END:
                        _residueTicks = -1;
                        return 65536;
                    }
                } else {
                    // MIDI event
                    switch (event.type & 0xf0) {
                    case SMFEvent.PROGRAM_CHANGE:
                        _module.programChange(channel, event.value);
                        break;
                    case SMFEvent.CHANNEL_PRESSURE:
                        _module.channelAfterTouch(channel, event.value);
                        break;
                    case SMFEvent.NOTE_OFF:
                        _module.noteOff(channel, event.note, event.velocity);
                        break;
                    case SMFEvent.NOTE_ON:
                        v = event.velocity;
                        if (v > 0) _module.noteOn(channel, event.note, v);
                        else _module.noteOff(channel, event.note, v);
                        break;
                    //case SMFEvent.KEY_PRESSURE:
                    case SMFEvent.CONTROL_CHANGE:
                        _module.controlChange(channel, event.value>>16, event.value&0x7f);
                        break;
                    case SMFEvent.PITCH_BEND:
                        _module.pitchBend(channel, event.value);
                        break;
                    case SMFEvent.SYSTEM_EXCLUSIVE:
                        _module.systemExclusive(channel, event.byteArray);
                        break;
                    }
                }
                
                // increment pointer
                if (++_pointer == _track.sequence.length) {
                    _residueTicks = -1;
                    return 65536;
                }
                event = _track.sequence[_pointer];
                _residueTicks = event.deltaTime;
            }
            
            _residueTicks -= ticks;
            return _residueTicks;
        }
    }
}


