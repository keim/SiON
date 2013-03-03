//----------------------------------------------------------------------------------------------------
// MML event class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    /** MML event. */
    public class MMLEvent
    {
    // constants
    //--------------------------------------------------
        // event id for default mml commands
        static public const NOP          :int = 0;
        static public const PROCESS      :int = 1;
        static public const REST         :int = 2;
        static public const NOTE         :int = 3;
        //static public const LENGTH       :int = 4;
        //static public const TEI          :int = 5;
        //static public const OCTAVE       :int = 6;
        //static public const OCTAVE_SHIFT :int = 7;
        static public const KEY_ON_DELAY :int = 8;
        static public const QUANT_RATIO  :int = 9;
        static public const QUANT_COUNT  :int = 10;
        static public const VOLUME       :int = 11;
        static public const VOLUME_SHIFT :int = 12;
        static public const FINE_VOLUME  :int = 13;
        static public const SLUR         :int = 14;
        static public const SLUR_WEAK    :int = 15;
        static public const PITCHBEND    :int = 16;
        static public const REPEAT_BEGIN :int = 17;
        static public const REPEAT_BREAK :int = 18;
        static public const REPEAT_END   :int = 19;
        static public const MOD_TYPE     :int = 20;
        static public const MOD_PARAM    :int = 21;
        static public const INPUT_PIPE   :int = 22;
        static public const OUTPUT_PIPE  :int = 23;
        static public const REPEAT_ALL   :int = 24;
        static public const PARAMETER    :int = 25;
        static public const SEQUENCE_HEAD:int = 26;
        static public const SEQUENCE_TAIL:int = 27;
        static public const SYSTEM_EVENT :int = 28;
        static public const TABLE_EVENT  :int = 29;
        static public const GLOBAL_WAIT  :int = 30;
        static public const TEMPO        :int = 31;
        static public const TIMER        :int = 32;
        static public const REGISTER     :int = 33;
        static public const DEBUG_INFO   :int = 34;
        static public const INTERNAL_CALL:int = 35;
        static public const INTERNAL_WAIT:int = 36;
        static public const DRIVER_NOTE  :int = 37;
        
        
        /** Event id for the first user defined command. */
        static public const USER_DEFINE:int = 64;

        /** Maximum value of event id. */
        static public const COMMAND_MAX:int = 128;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** NOP event */
        static public var nopEvent:MMLEvent = (new MMLEvent()).initialize(MMLEvent.NOP, 0, 0);
        
        /** Event ID. */
        public var id:int = 0;
        /** Event data. */
        public var data:int = 0;
        /** Prcessing length. */
        public var length:int = 0;
        /** Next event pointer in an event chain. */
        public var next:MMLEvent;
        /** Pointer refered by repeating. */
        public var jump:MMLEvent;
        
        
        

    // functions
    //--------------------------------------------------
        /** Constructor */
        function MMLEvent(id:int=0, data:int=0, length:int=0)
        {
            if (id > 1) initialize(id, data, length);
        }
        
        
        /** Format as "#id; data" */
        public function toString() : String
        {
            return "#" + String(id) + "; " + String(data);
        }
        
        
        /** Initializes 
         *  @param id Event ID.
         *  @param data Event data. Recommend that the value &lt;= 0xffffff.
         */
        public function initialize(id:int, data:int, length:int) : MMLEvent
        {
            this.id     = id & 0x7f;
            this.data   = data;
            this.length = length;
            this.next = null;
            this.jump = null;
            return this;
        }
        
        
        /** Get parameters as an array. 
         *  @param param Reference to get parameters.
         *  @param length Max parameters count to get.
         *  @return The last parameter event.
         */
        public function getParameters(param:Vector.<int>, length:int) : MMLEvent
        {
            var i:int, e:MMLEvent = this;
            
            i = 0;
            while (i<length) {
                param[i] = e.data; i++;
                if (e.next == null || e.next.id != PARAMETER) break;
                e = e.next;
            }
            while (i<length) {
                param[i] = int.MIN_VALUE; i++;
            }
            return e;
        }

        
        /** free this event to reuse. */
        public function free() : void
        {
            if (next == null) MMLParser._freeEvent(this);
        }
        
        
        /** Pack to int. */
        public function pack() : int
        {
            return 0;
        }
        
        
        /** Unpack from int. */
        public function unpack(d:int) : void
        {
        }
    }
}


