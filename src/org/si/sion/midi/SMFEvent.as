//----------------------------------------------------------------------------------------------------
// SMF event
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
    
    
    /** SMF event */
    public class SMFEvent
    {
    // constant
    //--------------------------------------------------------------------------------
        static public const NOTE_OFF:int = 0x80;
        static public const NOTE_ON:int = 0x90;
        static public const KEY_PRESSURE:int = 0xa0;
        static public const CONTROL_CHANGE:int = 0xb0;
        static public const PROGRAM_CHANGE:int = 0xc0;
        static public const CHANNEL_PRESSURE:int = 0xd0;
        static public const PITCH_BEND:int = 0xe0;
        static public const SYSTEM_EXCLUSIVE:int = 0xf0;
        static public const SYSTEM_EXCLUSIVE_SHORT:int = 0xf7;
        static public const META:int = 0xff;
        
        static public const META_SEQNUM:int = 0xff00;
        static public const META_TEXT:int = 0xff01;
        static public const META_AUTHOR:int = 0xff02;
        static public const META_TITLE:int = 0xff03;
        static public const META_INSTRUMENT:int = 0xff04;
        static public const META_LYLICS:int = 0xff05;
        static public const META_MARKER:int = 0xff06;
        static public const META_CUE:int = 0xff07;
        static public const META_PROGRAM_NAME:int = 0xff08;
        static public const META_DEVICE_NAME:int = 0xff09;
        static public const META_CHANNEL:int = 0xff20;
        static public const META_PORT:int = 0xff21;
        static public const META_TRACK_END:int = 0xff2f;
        static public const META_TEMPO:int = 0xff51;
        static public const META_SMPTE_OFFSET:int = 0xff54;
        static public const META_TIME_SIGNATURE:int = 0xff58;
        static public const META_KEY_SIGNATURE:int = 0xff59;
        static public const META_SEQUENCER_SPEC:int = 0xff7f;
        
        static public const CC_BANK_SELECT_MSB:int = 0;
        static public const CC_BANK_SELECT_LSB:int = 32;
        static public const CC_MODULATION:int = 1;
        static public const CC_PORTAMENTO_TIME:int = 5;
        static public const CC_DATA_ENTRY_MSB:int = 6;
        static public const CC_DATA_ENTRY_LSB:int = 38;
        static public const CC_VOLUME:int = 7;
        static public const CC_BALANCE:int = 8;
        static public const CC_PANPOD:int = 10;
        static public const CC_EXPRESSION:int = 11;
        static public const CC_SUSTAIN_PEDAL:int = 64;
        static public const CC_PORTAMENTO:int = 65;
        static public const CC_SOSTENUTO_PEDAL:int = 66;
        static public const CC_SOFT_PEDAL:int = 67;
        static public const CC_RESONANCE:int = 71;
        static public const CC_RELEASE_TIME:int = 72;
        static public const CC_ATTACK_TIME:int = 73;
        static public const CC_CUTOFF_FREQ:int = 74;
        static public const CC_DECAY_TIME:int = 75;
        static public const CC_PROTAMENTO_CONTROL:int = 84;
        static public const CC_REVERB_SEND:int = 91;
        static public const CC_CHORUS_SEND:int = 93;
        static public const CC_DELAY_SEND:int = 94;
        static public const CC_NRPN_LSB:int = 98;
        static public const CC_NRPN_MSB:int = 99;
        static public const CC_RPN_LSB:int = 100;
        static public const CC_RPN_MSB:int = 101;
        
        static public const RPN_PITCHBEND_SENCE:int = 0;
        static public const RPN_FINE_TUNE:int = 1;
        static public const RPN_COARSE_TUNE:int = 2;
        
        static private var _noteText:Vector.<String> = Vector.<String>(["c ","c+","d ","d+","e ","f ","f+","g ","g+","a ","a+","b "]);
        
        
        
    // variables
    //--------------------------------------------------------------------------------
        public var type:int = 0;
        public var value:int = 0;
        public var byteArray:ByteArray = null;
        
        public var deltaTime:uint = 0;
        public var time:uint = 0;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** channel */
        public function get channel() : int { return (type >= SYSTEM_EXCLUSIVE) ? 0 : (type & 0x0f); }
        
        /** note */
        public function get note() : int { return value >> 16; }
        
        /** velocity */
        public function get velocity() : int { return value & 0x7f; }
        
        /** text data */
        public function get text() : String { return (byteArray) ? byteArray.readUTF() : ""; }
        public function set text(str:String) : void {
            if (!byteArray) byteArray = new ByteArray();
            byteArray.writeUTF(str);
        }
        
        
        /** toString */
        public function toString() : String
        {
            if (type & 0xff00) {
                switch(type & 0xf0) {
                case META_TEMPO:
                    return "bpm(" + value.toString() + ")";
                }
            } else {
                var ret:String = "ch" + (type & 15).toString() + ":", n:int, v:int;
                switch(type & 0xf0) {
                case NOTE_ON:
                    return ret + "ON(" + note.toString() + ") " + velocity.toString();
                case NOTE_OFF:
                    return ret + "OF(" + note.toString() + ") " + velocity.toString();
                case CONTROL_CHANGE:
                    return ret + "CC(" + (value>>16).toString() + ") " + (value&0xffff).toString();
                case PROGRAM_CHANGE:
                    return ret + "PC(" + value.toString() + ") ";
                case SYSTEM_EXCLUSIVE:
                    var text:String = "SX:";
                    if (byteArray) {
                        byteArray.position = 0;
                        while (byteArray.bytesAvailable>0) {
                            text += byteArray.readUnsignedByte().toString(16)+" ";
                        }
                    }
                    return ret + text;
                }
            }

            return ret + "#" + type.toString(16) + "(" + value.toString() + ")";
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function SMFEvent(type:int, value:int, deltaTime:int, time:int) 
        {
            this.type = type;
            this.value = value;
            this.deltaTime = deltaTime;
            this.time = time;
        }
    }
}

