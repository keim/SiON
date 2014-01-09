//----------------------------------------------------------------------------------------------------
// MIDI sound module
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.midi {
    import flash.utils.ByteArray;
    import org.si.sion.SiONData;
    import org.si.sion.sequencer.base.MMLEvent;
    
    
    /** Standard MIDI File converter */
    public class SiONDataConverterSMF extends SiONData
    {
    // variables
    //--------------------------------------------------------------------------------
        /** use MIDI modules effector */
        public var useMIDIModuleEffector:Boolean = true;
        
        private var _smfData:SMFData = null;
        private var _module:MIDIModule = null;
        private var _waitEvent:MMLEvent;
        private var _executors:Vector.<SMFExecutor> = new Vector.<SMFExecutor>();
        private var _resolutionRatio:Number = 1;
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** Standard MIDI file data to play */
        public function get smfData() : SMFData { return _smfData; }
        public function set smfData(data:SMFData) : void {
            _smfData = data;
            if (_smfData) {
                bpm = _smfData.bpm;
                _resolutionRatio = 1920 / _smfData.resolution;
            } else {
                bpm = 120;
                _resolutionRatio = 1;
            }
        }
        
        
        /** MIDI sound module object to play */
        public function get midiModule() : MIDIModule { return _module; }
        public function set midiModule(module:MIDIModule) : void { _module = module; }
        
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** Pass SMFData and MIDIModule */
        function SiONDataConverterSMF(smfData:SMFData=null, midiModule:MIDIModule=null)
        {
            super();
            _smfData = smfData;
            _module = midiModule;
            
            if (_smfData) {
                bpm = _smfData.bpm;
                _resolutionRatio = 1920 / _smfData.resolution;
            } else {
                bpm = 120;
                _resolutionRatio = 1;
            }
            
            globalSequence.initialize();
            globalSequence.appendNewCallback(_onMIDIInitialize, 0);
            globalSequence.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
            globalSequence.appendNewCallback(_onMIDIEventCallback, 0);
            _waitEvent = globalSequence.appendNewEvent(MMLEvent.GLOBAL_WAIT, 0, 0);
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        private function _onMIDIInitialize(data:int) : MMLEvent
        {
            var i:int, imax:int;
            
            // initialize module
            _module._initialize(useMIDIModuleEffector);
            
            // initialize executors
            _executors.length = imax = _smfData.tracks.length;
            for (i=0; i<imax; i++) {
                if (!_executors[i]) _executors[i] = new SMFExecutor();
                _executors[i]._initialize(_smfData.tracks[i], _module);
            }
            
            // initialize interval
            _waitEvent.length = 0;
            
            return null;
        }
        
        
        private function _onMIDIEventCallback(data:int) : MMLEvent
        {
            var i:int, imax:int = _executors.length, exec:SMFExecutor, seq:Vector.<SMFEvent>, 
                ticks:int, deltaTime:int, minDeltaTime:int;
            ticks = _waitEvent.length / _resolutionRatio;
            minDeltaTime = _executors[0]._execute(ticks);
            for (i=1; i<imax; i++) {
                deltaTime = _executors[i]._execute(ticks);
                if (minDeltaTime > deltaTime) minDeltaTime = deltaTime;
            }
            if (minDeltaTime == 65536) _module._onFinishSequence();
            _waitEvent.length = minDeltaTime * _resolutionRatio;
            return null;
        }
    }
}


