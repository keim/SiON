//----------------------------------------------------------------------------------------------------
// SMF Track chunk
//  modified by keim.
//  This soruce code is distributed under BSD-style license (see org.si.license.txt).
//
// Original code
//  url; http://wonderfl.net/code/0aad6e9c1c5f5a983c6fce1516ea501f7ea7dfaa
//  Copyright (c) 2010 nemu90kWw All rights reserved.
//  The original code is distributed under MIT license.
//  (see http://www.opensource.org/licenses/mit-license.php).
//----------------------------------------------------------------------------------------------------


package org.si.sion.midi {
    import flash.utils.ByteArray;
    
    
    /** SMF Track chunk */
    public class SMFTrack
    {
    // variables
    //------------------------------------------------------------------------
        /** sequence */
        public var sequence:Vector.<SMFEvent> = new Vector.<SMFEvent>();
        /** total time in MIDI clock */
        public var totalTime:int;
        
        // parent SMFData
        private var _smfData:SMFData;
        // for exiting loop
        private var _exitLoop:Boolean;
        // track index (start from 1)
        private var _trackIndex:int
        
        
        
    // properties
    //------------------------------------------------------------------------
        /** track index (start from 1) */
        public function get trackIndex() : int { return _trackIndex; }
        
        /** toString */
        public function toString() : String
        {
            var text:String = totalTime + "\n";
            
            for(var i:int = 0; i < sequence.length; i++) {
                text += sequence[i].toString() + "\n";
            }
            
            return text;
        }
        
        
        
        
    // constructor
    //------------------------------------------------------------------------
        /** constructor */
        function SMFTrack(smfData:SMFData, index:int, bytes:ByteArray)
        {
            _trackIndex = index + 1;
            _smfData = smfData;
            
            var eventType:int, code:int, value:int;
            var deltaTime:int, time:int = 0;
            
            _exitLoop = false;
            eventType = -1;
            bytes.position = 0;

            while (bytes.bytesAvailable > 0 && !_exitLoop) {
                deltaTime = _readVariableLength(bytes);
                time += deltaTime;
                
                code = bytes.readUnsignedByte();
                if (!_readMetaEvent(code, bytes, deltaTime, time))
                if (!_readSystemExclusive(code, bytes, deltaTime, time))
                {
                    if (code & 0x80) {
                        eventType = code;
                    } else {
                        if (eventType == -1) throw _errorIncorrectData();
                        bytes.position--;
                    }
                    
                    switch (eventType & 0xf0) {
                    case SMFEvent.PROGRAM_CHANGE:
                    case SMFEvent.CHANNEL_PRESSURE:
                        value = bytes.readUnsignedByte();
                        break;
                    case SMFEvent.NOTE_OFF:
                    case SMFEvent.NOTE_ON:
                    case SMFEvent.KEY_PRESSURE:
                    case SMFEvent.CONTROL_CHANGE:
                        value = (bytes.readUnsignedByte()<<16) | bytes.readUnsignedByte();
                        break;
                    case SMFEvent.PITCH_BEND:
                        value = (bytes.readUnsignedByte() | (bytes.readUnsignedByte()<<7)) - 8192;
                        break;
                    }
                    
                    sequence.push(new SMFEvent(eventType, value, deltaTime, time));
                }
            }
            
            totalTime = time;
        }
        
        
        // read meta event
        private function _readMetaEvent(eventType:int, bytes:ByteArray, deltaTime:uint, time:uint) : Boolean
        {
            if (eventType != SMFEvent.META) return false;
            
            var event:SMFEvent, value:int, text:String, 
                metaEventType:int = bytes.readUnsignedByte() | 0xff00,
                len:uint = _readVariableLength(bytes);

            if ((metaEventType & 0x00f0) == 0) {
                // meta text data
                event = new SMFEvent(metaEventType, len, deltaTime, time);
                text = bytes.readMultiByte(len, "Shift-JIS");
                event.text = text;
                switch (metaEventType) {
                case SMFEvent.META_TEXT:   _smfData.text   = text; break;
                case SMFEvent.META_TITLE:  if (!_smfData.title)  _smfData.title  = text; break;
                case SMFEvent.META_AUTHOR: if (!_smfData.author) _smfData.author = text; break;
                }
                sequence.push(event);
            } else {
                switch (metaEventType) {
                case SMFEvent.META_TEMPO:
                    value = (bytes.readUnsignedByte()<<16) | bytes.readUnsignedShort();
                    // [usec/beat] => [beats/minute]
                    event = new SMFEvent(SMFEvent.META_TEMPO, 60000000 / value, deltaTime, time);
                    if (_smfData.bpm == 0) _smfData.bpm = event.value;
                    sequence.push(event);
                    break;
                case SMFEvent.META_TIME_SIGNATURE:
                    value = (bytes.readUnsignedByte()<<16) | (1<<bytes.readUnsignedByte());
                    event = new SMFEvent(SMFEvent.META_TIME_SIGNATURE, value, deltaTime, time);
                    if (_smfData.signature_d == 0) {
                        _smfData.signature_n = value>>16;
                        _smfData.signature_d = value & 0xffff;
                    }
                    bytes.position += 2;
                    sequence.push(event);
                    break;
                case SMFEvent.META_PORT:
                    value = bytes.readUnsignedByte();
                    break;
                case SMFEvent.META_TRACK_END:  
                    _exitLoop = true;
                    break;
                default:
                    bytes.position += len;
                    break;
                }
            }
            return true;
        }
        
        
        // read system exclusive data
        private function _readSystemExclusive(eventType:int, bytes:ByteArray, deltaTime:uint, time:uint) : Boolean
        {
            if (eventType != SMFEvent.SYSTEM_EXCLUSIVE && eventType != SMFEvent.SYSTEM_EXCLUSIVE_SHORT) return false;
            
            var i:int, b:int, event:SMFEvent = new SMFEvent(eventType, 0, deltaTime, time),
                len:uint = _readVariableLength(bytes);

            // read sysex bytes
            event.byteArray = new ByteArray();
            event.byteArray.writeByte(0xf0); // start
            for (i=0; i<len; i++) {
                b = bytes.readUnsignedByte();
                event.byteArray.writeByte(b);
            }
            
            sequence.push(event);
            
            return true;
        }
        
        
        // read variable length
        private function _readVariableLength(bytes:ByteArray, time:uint = 0) : uint
        {
            var t:int = bytes.readUnsignedByte();
            time += t & 0x7F;
            return (t & 0x80) ? _readVariableLength(bytes, time<<7) : time;
        }
        
        
        
        
    // error
    //------------------------------------------------------------------------
        private function _errorIncorrectData() : Error {
            return new Error("The SMF File is not good.");
        }
    }
}

