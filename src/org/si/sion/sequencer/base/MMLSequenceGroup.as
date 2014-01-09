//----------------------------------------------------------------------------------------------------
// MML Sequence group class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import flash.utils.ByteArray;
    
    
    /** Group of MMLSequences. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has a"). */
    public class MMLSequenceGroup
    {
    // namespace
    //--------------------------------------------------
        use namespace _sion_sequencer_internal;
        
        
        
        
    // valiables
    //--------------------------------------------------
        // terminator
        private var _term:MMLSequence;
        
        // owner data
        private var _owner:MMLData
        
        
        
        
    // properties
    //--------------------------------------------------
        /** Get sequence count. */
        public function get sequenceCount() : int
        {
            return _sequences.length;
        }
        
        
        /** head sequence pointer. */
        public function get headSequence() : MMLSequence
        {
            return _term.nextSequence;
        }
        

        /** Get song length by tick count (1920 for wholetone). */
        public function get tickCount() : int {
            var ml:int, tc:int = 0;
            for each (var seq:MMLSequence in _sequences) {
                ml = seq.mmlLength;
                if (ml > tc) tc = ml;
            }
            return tc;
        }
        

        /** does this song have all repeat comand ? */
        public function get hasRepeatAll() : Boolean {
            for each (var seq:MMLSequence in _sequences) {
                if (seq.hasRepeatAll) return true;
            }
            return false;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        function MMLSequenceGroup(owner:MMLData)
        {
            _owner = owner;
            _sequences = new Vector.<MMLSequence>();
            _term = new MMLSequence(true);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Create new sequence group. Why its not create() ???
         *  @param headEvent MMLEvnet returned from MMLParser.parse().
         */
        public function alloc(headEvent:MMLEvent) : void
        {
            // divied into sequences
            var seq:MMLSequence;
            while (headEvent!=null && headEvent.jump!=null) {
                if (headEvent.id != MMLEvent.SEQUENCE_HEAD) {
                    throw new Error("MMLSequence: Unknown error on dividing sequences. " + headEvent);
                }
                seq = appendNewSequence();          // push new sequence
                headEvent = seq._cutout(headEvent); // cutout sequence
                seq._updateMMLString();             // update mml string
                seq.isActive = true;                // activate
            }
        }
        
        
        /** Free all sequences */
        public function free() : void
        {
            for each (var seq:MMLSequence in _sequences) {
                seq.free();
                _freeList.push(seq);
            }
            _sequences.length = 0;
            _term.free();
        }
        
        
        /** get sequence
         *  @param index The index of sequence.
         */
        public function getSequence(index:int) : MMLSequence
        {
            if (index >= _sequences.length) return null;
            return _sequences[index];
        }
        
        
        
    // factory
    //--------------------------------------------------
        // allocated sequences
        private var _sequences:Vector.<MMLSequence>;
        // free list
        static private var _freeList:Array = [];
        
        
        /** append new sequence */
        public function appendNewSequence() : MMLSequence
        {
            var seq:MMLSequence = _newSequence();
            seq._insertBefore(_term);
            seq.isActive = false;   // inactivate
            return seq;
        }
        
        
        /** @private [internal] Allocate new sequence and push sequence chain. */
        internal function _newSequence() : MMLSequence
        {
            var seq:MMLSequence = _freeList.pop() || new MMLSequence();
            seq._owner = _owner;
            _sequences.push(seq);
            return seq;
        }
    }
}