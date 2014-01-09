//----------------------------------------------------------------------------------------------------
// MML Sequence executor class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import flash.utils.ByteArray;
    import org.si.utils.SLLint;
    
    
    /** MMLExecutor has MMLSequence and executing pointer. One track has one executor, and sequencer also has one for global sequence. */
    public class MMLExecutor
    {
    // namespace
    //--------------------------------------------------
        use namespace _sion_sequencer_internal;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** Current MMLEvent to process */
        public var pointer:MMLEvent;
        
        // MMLSequence to execute.
        private var _sequence:MMLSequence;
        // Repeating count by segno
        private var _endRepeatCounter:int;
        // Repeating point
        private  var _repeatPoint:MMLEvent;
        // event to process
        private  var _processEvent:MMLEvent;
        // pitchbend event
        private  var _bendFrom:MMLEvent;
        // pitchbend event
        private  var _bendEvent:MMLEvent;
        // note event
        private  var _noteEvent:MMLEvent;
        
        /** @private [internal] current position in tick count. */
        internal var _currentTickCount:int;
        /** @private [internal] the stac of counters to operate repeatings. refer from MMLSequencer. */
        internal var _repeatCounter:SLLint;
        /** @private [internal] the leftover of processing sample count. refer from MMLSequencer. */
        internal var _residueSampleCount:int;
        /** @private [internal] the decimal fraction part of processing sample count. */
        internal var _decimalFractionSampleCount:int;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** Repeating count by segno */
        public function get endRepeatCount() : int { return _endRepeatCounter; }
        
        /** Executing MMLSequence */
        public function get sequence() : MMLSequence { return _sequence; }
        
        /** Current event */
        public function get currentEvent() : MMLEvent { return (pointer === _processEvent) ? pointer.jump : pointer; }
        
        /** Note that wait for note on execution ? -1 for not waiting */
        public function get noteWaitingFor() : int { return (pointer === _noteEvent) ? _noteEvent.data : -1; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Constructor. */
        function MMLExecutor()
        {
            _sequence = null;
            pointer = null;
            _endRepeatCounter = 0;
            _repeatPoint = null;
            _processEvent = MMLParser._allocEvent(MMLEvent.PROCESS, 0);
            _noteEvent    = MMLParser._allocEvent(MMLEvent.DRIVER_NOTE, 0);
            _bendFrom     = MMLParser._allocEvent(MMLEvent.NOTE, 0);
            _bendEvent    = MMLParser._allocEvent(MMLEvent.PITCHBEND, 0);
            _bendFrom.next = _bendEvent;
            _bendEvent.next = _noteEvent;
            _repeatCounter = null;
            _currentTickCount = 0;
            _residueSampleCount = 0;
            _decimalFractionSampleCount = 0;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Initialize.
         *  @param seq Sequence to execute. Sets the pointer at the head of this sequence, when this argument is not null.
         */
        public function initialize(seq:MMLSequence) : void
        {
            clear();
            if (seq) {
                _sequence = seq;
                pointer  = seq.headEvent.next;
            }
        }
        
        
        /** Clear contents. */
        public function clear() : void
        {
            pointer = null;
            _sequence = null;
            _endRepeatCounter = 0;
            _repeatPoint = null;
            SLLint.freeList(_repeatCounter);
            _repeatCounter = null;
            _currentTickCount = 0;
            _residueSampleCount = 0;
            _decimalFractionSampleCount = 0;
        }
        
        
        /** Reset pointer to sequence head */
        public function resetPointer() : void
        {
            if (_sequence) {
                pointer = _sequence.headEvent.next;
                _endRepeatCounter = 0;
                _repeatPoint = null;
                SLLint.freeList(_repeatCounter);
                _repeatCounter = null;
                _currentTickCount = 0;
                _residueSampleCount = 0;
                _decimalFractionSampleCount = 0;
            }
        }
        

        /** stop execute sequence */
        public function stop() : void
        {
            if (pointer) {
                if (pointer === _processEvent) _processEvent.jump = MMLEvent.nopEvent;
                else pointer = null;
            }
        }
        
        
        /** execute single note.
         *  @param note Note number.
         *  @param thickLength length in tick count. The argument of 0 sets no key off.
         */
        public function singleNote(note:int, tickLength:int) : void
        {
            _noteEvent.next = null;
            _noteEvent.data = note;
            _noteEvent.length = tickLength;
            pointer = _noteEvent;
            
            _sequence = null;
            _endRepeatCounter = 0;
            _repeatPoint = null;
            SLLint.freeList(_repeatCounter);
            _repeatCounter = null;
            _currentTickCount = 0;
        }
        
        
        /** pitch bending, this function only is avilable after calling singleNote().
         *  @param note Note number bending to.
         *  @param tickLength length of bending.
         *  @param success or failure
         */
        public function bendingFrom(note:int, tickLength:int) : Boolean
        {
            if (pointer != _noteEvent || tickLength == 0) return false;
            if (_noteEvent.length != 0) {
                if (tickLength < _noteEvent.length) tickLength = _noteEvent.length - 1;
                _noteEvent.length -= tickLength;
            }
            _bendFrom.length = 0;
            _bendFrom.data = note;
            _bendEvent.length = tickLength;
            pointer = _bendFrom;
            return true;
        }
        
        
        /** @private [sion sequencer internal] Publish processing event. You should return this function's return in the event handler of NOTE and REST.
         *  @param e Current event
         */
        _sion_sequencer_internal function _publishProessingEvent(e:MMLEvent) : MMLEvent
        {
            if (e.length > 0) {
                //_processEvent.data   = 0;
                //_processEvent.next   = null;
                _currentTickCount += e.length;
                _processEvent.length = e.length;
                _processEvent.jump   = e;
                return _processEvent;
            }
            return e.next;
        }
        
        
        
        
        
    // callback
    //--------------------------------------------------
        /** @private [sion sequencer internal] callback onTempoChanged. */
        _sion_sequencer_internal function _onTempoChanged(changingRatio:Number) : void
        {
            if (_residueSampleCount < 0) changingRatio = 1 / changingRatio;
            _residueSampleCount         *= changingRatio;
            _decimalFractionSampleCount *= changingRatio;
        }
        
        
        /** @private [internal] callback onRepeatAll. */
        internal function _onRepeatAll(e:MMLEvent) : MMLEvent
        {
            _repeatPoint = e.next;
            return e.next;
        }
        
        
        /** @private [internal] callback onRepeatBegin. */
        internal function _onRepeatBegin(e:MMLEvent) : MMLEvent
        {
            var counter:SLLint = SLLint.alloc(e.data);
            counter.next = _repeatCounter;
            _repeatCounter = counter;
            return e.next;
        }
        
        
        /** @private [internal] callback onRepeatBreak. */
        internal function _onRepeatBreak(e:MMLEvent) : MMLEvent
        {
            if (_repeatCounter.i == 1) {
                var counter:SLLint = _repeatCounter.next;
                SLLint.free(_repeatCounter);
                _repeatCounter = counter;
                // Jump to repeatStart.repeatEnd.next
                return e.jump.jump.next;
            }
            return e.next;
        }
        
        
        /** @private [internal] callback onRepeatEnd. */
        internal function _onRepeatEnd(e:MMLEvent) : MMLEvent
        {
           if (--_repeatCounter.i == 0) {
                var counter:SLLint = _repeatCounter.next;
                SLLint.free(_repeatCounter);
                _repeatCounter = counter;
                return e.next;
            }
            // Jump to repeatStart.next
            return e.jump.next;
         }
        
        
        /** @private [internal] callback onSequenceTail. */
        internal function _onSequenceTail(e:MMLEvent) : MMLEvent
        {
            _endRepeatCounter++;
            return _repeatPoint;
         }
    }
}


