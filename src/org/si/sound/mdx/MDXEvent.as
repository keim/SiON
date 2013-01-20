//----------------------------------------------------------------------------------------------------
// MDX event class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.utils.ByteArray;
    
    
    /** MDX event */
    public class MDXEvent
    {
    // constant
    //--------------------------------------------------------------------------------
        static public const REST:int = 0x00;
        static public const NOTE:int = 0x80;
        static public const TIMERB:int = 0xff;
        static public const REGISTER:int = 0xfe;
        static public const VOICE:int = 0xfd;
        static public const PAN:int = 0xfc;
        static public const VOLUME:int = 0xfb;
        static public const VOLUME_DEC:int = 0xfa;
        static public const VOLUME_INC:int = 0xf9;
        static public const GATE:int = 0xf8;
        static public const SLUR:int = 0xf7;
        static public const REPEAT_BEGIN:int = 0xf6;
        static public const REPEAT_END:int = 0xf5;
        static public const REPEAT_BREAK:int = 0xf4;
        static public const DETUNE:int = 0xf3;
        static public const PORTAMENT:int = 0xf2;
        static public const DATA_END:int = 0xf1;
        static public const KEY_ON_DELAY:int = 0xf0;
        static public const SYNC_SEND:int = 0xef;
        static public const SYNC_WAIT:int = 0xee;
        static public const FREQUENCY:int = 0xed;
        static public const PITCH_LFO:int = 0xec;
        static public const VOLUME_LFO:int = 0xeb;
        static public const OPM_LFO:int = 0xea;
        static public const LFO_DELAY:int = 0xe9;
        static public const SET_PCM8:int = 0xe8;
        static public const FADEOUT:int = 0xe7;
        
        
        static private var _noteText:Vector.<String> = Vector.<String>(["c ","c+","d ","d+","e ","f ","f+","g ","g+","a ","a+","b "]);
        
        
        
        
    // variables
    //--------------------------------------------------------------------------------
        public var type:int = 0;
        public var data:int = 0;
        public var data2:int = 0;
        public var deltaClock:uint = 0;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** toString */
        public function toString() : String
        {
            var i:int;
            switch (type) {
            case REST: return "r ;"+String(deltaClock);
            case NOTE: 
                i = (data+15)%12;
                return "o"+String(((data+15)/12)>>0)+_noteText[i]+";"+String(deltaClock);
            case GATE:   return "q"+String(data);
            case DETUNE: return "k"+String(data>>8);
            case REPEAT_BEGIN: return "["+String(data);
            case REPEAT_BREAK: return "|";
            case REPEAT_END: return "]";
            case PORTAMENT: return "po";
            case SLUR: return "&";
            case VOICE: return "@"+String(data);
            case PAN: return "p"+String(data);
            case VOLUME: return (data<16) ? "v"+String(data) : "@v"+String(data&127);
            case LFO_DELAY:  return "LFO_delay"+String(data);
            case PITCH_LFO:  return "LFO"+(data&255).toString(16)+" mp"+(data>>8)+","+(data2);
            case VOLUME_LFO: return "LFO"+(data&255).toString(16)+" ma"+(data>>8)+","+(data2);
            case FREQUENCY:  return "FREQ"+String(data);
            case TIMERB:     return "TIMER_B "+String(data);
            case SET_PCM8:   return "PCM8";
            default:   return "#"+ type.toString(16) + "; " + String(data);
            }
            return "";
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function MDXEvent(type:int, data:int, data2:int, deltaClock:int) 
        {
            this.type = type;
            this.data = data;
            this.data2 = data2;
            this.deltaClock = deltaClock;
        }
    }
}

