//----------------------------------------------------------------------------------------------------
// MIDI sound module operator
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.midi {
    import org.si.sion.sequencer.SiMMLTrack;
    
    
    /** @private MIDI sound module operator */
    internal class MIDIModuleOperator
    {
    // variables
    //--------------------------------------------------------------------------------
        internal var next:MIDIModuleOperator, prev:MIDIModuleOperator;
        internal var sionTrack:SiMMLTrack = null;
        internal var length:int = 0;
        internal var programNumber:int;
        internal var channel:int;
        internal var note:int;
        internal var isNoteOn:Boolean;
        internal var drumExcID:int;
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function MIDIModuleOperator(sionTrack:SiMMLTrack)
        {
            this.sionTrack = sionTrack;
            next = prev = this;
            programNumber = -1;
            channel = -1;
            note = -1;
            isNoteOn = false;
            drumExcID = -1;
        }
        
        
        
        
    // list operation
    //--------------------------------------------------------------------------------
        internal function clear() : void
        {
            prev = next = this;
            length = 0;
        }
        
        
        internal function push(ope:MIDIModuleOperator) : void
        {
            ope.prev = prev;
            ope.next = this;
            prev.next = ope;
            prev = ope;
            length++;
        }
        
        
        internal function pop() : MIDIModuleOperator
        {
            if (prev == this) return null;
            var ret:MIDIModuleOperator = prev;
            prev = prev.prev;
            prev.next = this;
            ret.prev = ret.next = ret;
            length--;
            return ret;
        }
        
        
        internal function unshift(ope:MIDIModuleOperator) : void
        {
            ope.prev = this;
            ope.next = next;
            next.prev = ope;
            next = ope;
            length++;
        }
        
        
        internal function shift() : MIDIModuleOperator
        {
            if (next == this) return null;
            var ret:MIDIModuleOperator = next;
            next = next.next;
            next.prev = this;
            ret.prev = ret.next = ret;
            length--;
            return ret;
        }
        
        
        internal function remove(ope:MIDIModuleOperator) : void
        {
            ope.prev.next = ope.next;
            ope.next.prev = ope.prev;
            ope.prev = ope.next = this;
            length--;
        }
    }
}

