//----------------------------------------------------------------------------------------------------
// Track of MDX data
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.utils.ByteArray;
    
    
    /** Track of MDX data */
    public class MDXTrack
    {
    // variables
    //--------------------------------------------------------------------------------
        /** sequence */
        public var sequence:Vector.<MDXEvent> = new Vector.<MDXEvent>();
        /** Return pointer of segno */
        public var segnoPointer:MDXEvent;
        /** timer B value to set */
        public var timerB:int;

        /** owner MDXData */
        public var owner:MDXData;
        /** channel number */
        public var channelNumber:int;
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** has no data. */
        public function get hasNoData() : Boolean {
            return (sequence.length <= 1);
        }
        
        /** to string. */
        public function toString():String
        {
            var text:String = "", i:int, imax:int = sequence.length;
            for (i=0; i<imax; i++) text += sequence[i] +"\n";
            return text;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function MDXTrack(owner:MDXData, channelNumber:int)
        {
            this.owner = owner;
            this.channelNumber = channelNumber;
            sequence = new Vector.<MDXEvent>();
            segnoPointer = null;
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : MDXTrack
        {
            sequence.length = 0;
            segnoPointer = null;
            timerB = -1;
            return this;
        }
        
        
        /** Load track from byteArray. */
        public function loadBytes(bytes:ByteArray) : MDXTrack
        {
            clear();
            
            var clock:int, code:int, v:int, pos:int, mem:Array=[], exitLoop:Boolean = false;
            
            while (!exitLoop && bytes.bytesAvailable>0) {
                pos = bytes.position;
                code = bytes.readUnsignedByte();
                if (code<0x80) { // rest
                    newEvent(MDXEvent.REST, 0, 0, code+1);
                    clock += code+1;
                } else
                if (code<0xe0) { // note
                    v = bytes.readUnsignedByte() + 1;
                    newEvent(MDXEvent.NOTE, code - 0x80, 0, v);
                    clock += v;
                } else {
                    switch(code) {
                    //----- 2 operands
                    case MDXEvent.REGISTER:
                    case MDXEvent.FADEOUT:
                        newEvent(code, bytes.readUnsignedByte(), bytes.readUnsignedByte());
                        break;
                    //----- 1 operand
                    case MDXEvent.VOICE:
                    case MDXEvent.PAN:
                    case MDXEvent.VOLUME:
                    case MDXEvent.GATE:
                    case MDXEvent.KEY_ON_DELAY:
                    case MDXEvent.FREQUENCY:
                    case MDXEvent.LFO_DELAY:
                    case MDXEvent.SYNC_SEND:
                        newEvent(code, bytes.readUnsignedByte());
                        break;
                    //----- no operands
                    case MDXEvent.VOLUME_DEC:
                    case MDXEvent.VOLUME_INC:
                    case MDXEvent.SLUR:
                    case MDXEvent.SET_PCM8:
                    case MDXEvent.SYNC_WAIT:
                        newEvent(code);
                        break;
                    //----- 1 WORD
                    case MDXEvent.DETUNE:
                    case MDXEvent.PORTAMENT:
                        newEvent(code, bytes.readShort()); //...short?
                        break;
                    //----- REPEAT
                    case MDXEvent.REPEAT_BEGIN:
                        newEvent(code, bytes.readUnsignedByte(), bytes.readUnsignedByte());
                        break;
                    case MDXEvent.REPEAT_END:
                        newEvent(code, pos+bytes.readShort());  // position of REPEAT_BEGIN
                        break;
                    case MDXEvent.REPEAT_BREAK:
                        newEvent(code, pos+bytes.readShort()+2); // position of REPEAT_END
                        break;
                    //----- others
                    case MDXEvent.TIMERB:
                        v = bytes.readUnsignedByte();
                        if (clock == 0) timerB = v;
                        newEvent(code, v);
                        break;
                    case MDXEvent.PITCH_LFO:
                    case MDXEvent.VOLUME_LFO:
                        v = bytes.readUnsignedByte();
                        if (v == 0x80 || v == 0x81) newEvent(code, v);
                        else newEvent(code, v | (bytes.readUnsignedShort()<<8), bytes.readShort());
                        break;
                    case MDXEvent.OPM_LFO:
                        v = bytes.readUnsignedByte();
                        if (v == 0x80 || v == 0x81) newEvent(code, v<<16);
                        else {
                            v = (v<<16) | (bytes.readUnsignedByte()<<8) | bytes.readUnsignedByte();
                            newEvent(code, v, bytes.readShort());
                        }
                        break;
                    case MDXEvent.DATA_END: // ...?
                        v = bytes.readShort();
                        newEvent(code, v);
                        if (v>0 && pos-v+3>=0) segnoPointer = mem[pos-v+3];
                        else if (v<0 && pos+v+3>=0) segnoPointer = mem[pos+v+3];
                        exitLoop = true;
                        break;
                    default:
                        newEvent(MDXEvent.DATA_END);
                        exitLoop = true;
                        break;
                    }
                }
            }
            
            
            function newEvent(type:int, data:int=0, data2:int=0, deltaClock:int=0) : MDXEvent {
                var inst:MDXEvent = new MDXEvent(type, data, data2, deltaClock);
                sequence.push(inst);
                mem[pos] = inst;
                return inst;
            }

//trace("------------------- ch", channelNumber, "-------------------");
//trace(String(this));
            return this;
        }
    }
}


