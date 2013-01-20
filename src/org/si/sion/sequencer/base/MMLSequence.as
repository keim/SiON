//----------------------------------------------------------------------------------------------------
// MML Sequence class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import flash.utils.ByteArray;
    
    
    /** Sequence of 1 sound channel. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has a"). */
    public class MMLSequence
    {
    // namespace
    //--------------------------------------------------
        use namespace _sion_sequencer_internal;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** First MMLEvent. The ID is always MMLEvent.SEQUENCE_HEAD. */
        public var headEvent:MMLEvent;
        /** Last MMLEvent. The ID is always MMLEvent.SEQUENCE_TAIL and lastEvent.next is always null. */
        public var tailEvent:MMLEvent;
        /** Is active ? The sequence is skipped to play when this value is false. */
        public var isActive:Boolean;
        
        // mml string
        private var _mmlString:String;
        // mml length in resolution unit
        private var _mmlLength:int;
        // flag for apearance of repeat all command (segno) 
        private var _hasRepeatAll:Boolean;
        
        // Previous sequence in the chain.
        private var _prevSequence:MMLSequence;
        // Next sequence in the chain.
        private var _nextSequence:MMLSequence;
        // Is terminal sequence.
        private var _isTerminal:Boolean;
        
        /** @private [sion seqiencer internal] callback functions for Event.INTERNAL_CALL */
        _sion_sequencer_internal var _callbackInternalCall:Array;
        /** @private [sion seqiencer internal] owner data */
        _sion_sequencer_internal var _owner:MMLData;
        
        
        
    // properties
    //--------------------------------------------------
        /** next sequence. */
        public function get nextSequence() : MMLSequence
        {
            return (!_nextSequence._isTerminal) ? _nextSequence : null;
        }
        
        /** MML String, if its cached when its compiling. */
        public function get mmlString() : String { return _mmlString; }
        
        /** MML length, in resolution unit (1920 = whole-tone in default). */
        public function get mmlLength() : int {
            if (_mmlLength == -1) _updateMMLLength();
            return _mmlLength;
        }
        
        /** flag for apearance of repeat all command (segno) */
        public function get hasRepeatAll() : Boolean {
            if (_mmlLength == -1) _updateMMLLength();
            return _hasRepeatAll;
        }
        
        
    // constructor
    //--------------------------------------------------
        /** Constructor. */
        function MMLSequence(term:Boolean = false)
        {
            _owner = null;
            headEvent = null;
            tailEvent = null;
            isActive = true;
            _mmlString = "";
            _mmlLength = -1;
            _hasRepeatAll = false;
            _prevSequence = (term) ? this : null;
            _nextSequence = (term) ? this : null;
            _isTerminal = term;
            _callbackInternalCall = [];
        }
        
        
        /** toString returns the event ids. */
        public function toString() : String
        {
            if (_isTerminal) return "terminator";
            var e:MMLEvent = headEvent.next;
            var str:String = "";
            for (var i:int=0; i<32; i++) {
                str += String(e.id) + " ";
                e = e.next;
                if (e == null) break;
            }
            return str;
        }
        
        
        /** Returns events as an Vector.&lt;MMLEvent&gt;. 
         *  @param lengthLimit maximum length of returning Vector. When this argument set to 0, the Vector includes all events.
         *  @param offset starting index of returning Vector.
         *  @param eventID event id to get. When this argument set to -1, the Vector includes all kind of events.
         */
        public function toVector(lengthLimit:int=0, offset:int=0, eventID:int=-1) : Vector.<MMLEvent>
        {
            if (headEvent == null) return null;
            var e:MMLEvent, i:int=0, result:Vector.<MMLEvent> = new Vector.<MMLEvent>();
            for (e=headEvent.next; e!=null && e.id!=MMLEvent.SEQUENCE_TAIL; e=e.next) {
                if (eventID == -1 || eventID == e.id) {
                    if (i >= offset) result.push(e);
                    if (lengthLimit > 0 && i >= lengthLimit) break;
                    i++;
                }
            }
            return result;
        }
        
        
        /** Create sequence from Vector.&lt;MMLEvent&gt;. 
         *  @param events event list of the sequence.
         */
        public function fromVector(events:Vector.<MMLEvent>) : MMLSequence
        {
            initialize();
            for each (var e:MMLEvent in events) push(e);
            return this;
        }
        
        
        
        
        
    // operations
    //--------------------------------------------------
        /** initialize. */
        public function initialize() : MMLSequence
        {
            if (!isEmpty()) {
                headEvent.jump.next = tailEvent;
                MMLParser._freeAllEvents(this);
                _callbackInternalCall = [];
            }
            headEvent = MMLParser._allocEvent(MMLEvent.SEQUENCE_HEAD, 0);
            tailEvent = MMLParser._allocEvent(MMLEvent.SEQUENCE_TAIL, 0);
            headEvent.next = tailEvent;
            headEvent.jump = headEvent;
            isActive = true;
            return this;
        }
        
        
        /** Free. */
        public function free() : void
        {
            if (headEvent) {
                // disconnect
                headEvent.jump.next = tailEvent;
                MMLParser._freeAllEvents(this);
                _prevSequence = null;
                _nextSequence = null;
            } else 
            if (_isTerminal) {
                _prevSequence = this;
                _nextSequence = this;
            }
            _mmlString = "";
        }
        
        
        /** is empty ? */
        public function isEmpty() : Boolean
        {
            return (headEvent == null);
        }
        
        
        /** Pack to ByteArray. */
        public function pack(seq:ByteArray) : void
        {
            // not available
        }
        
        
        /** Unpack from ByteArray. */
        public function unpack(seq:ByteArray) : void
        {
            // not available
        }
        
        
        /** Append new MMLEvent at tail 
         *  @param id MML event id.
         *  @param data MML event data.
         *  @param length MML event length.
         *  @see org.si.sion.sequencer.base.MMLEvent
         */
        public function appendNewEvent(id:int, data:int, length:int=0) : MMLEvent
        {
            return push(MMLParser._allocEvent(id, data, length));
        }
        
        
        /** Append new Callback function 
         *  @param func The function to call. (function(int) : MMLEvent)
         *  @param data The value to pass to the callback as an argument
         */
        public function appendNewCallback(func:Function, data:int) : MMLEvent
        {
            _callbackInternalCall.push(func);
            return push(MMLParser._allocEvent(MMLEvent.INTERNAL_CALL, _callbackInternalCall.length-1, data));
        }
        
        
        /** Prepend new MMLEvent at head
         *  @param id MML event id.
         *  @param data MML event data.
         *  @param length MML event length.
         *  @see org.si.sion.sequencer.base.MMLEvent
         */
        public function prependNewEvent(id:int, data:int, length:int=0) : MMLEvent
        {
            return unshift(MMLParser._allocEvent(id, data, length));
        }
        
        
        /** Add MMLEvent at tail.
         *  @param MML event to be pushed.
         *  @return added event, same as an argument.
         */
        public function push(e:MMLEvent) : MMLEvent
        {
            // connect event at tail
            headEvent.jump.next = e;
            e.next = tailEvent;
            headEvent.jump = e;
            return e;
        }
        
        
        /** Remove MMLEvent from tail.
         *  @return removed MML event. You should call MMLEvent.free() after using this event.
         */
        public function pop() : MMLEvent
        {
            if (headEvent.jump == headEvent) return null;
            for (var e:MMLEvent=headEvent.next; e!=null; e=e.next) {
                if (e.next == headEvent.jump) {
                    var ret:MMLEvent = e.next;
                    e.next = tailEvent;
                    headEvent.jump = e;
                    ret.next = null;
                    return ret;
                }
            }
            return null;
        }
        
        
        /** Add MMLEvent at head.
         *  @param MML event to be pushed.
         *  @return added event, same as an argument.
         */
        public function unshift(e:MMLEvent) : MMLEvent
        {
            // connect event at head
            e.next = headEvent.next;
            headEvent.next = e;
            if (headEvent.jump == headEvent) headEvent.jump = e;
            return e;
        }
        
        
        /** Remove MMLEvent from head.
         *  @return removed MML event. You should call MMLEvent.free() after using this event.
         */
        public function shift() : MMLEvent
        {
            if (headEvent.jump == headEvent) return null;
            var ret:MMLEvent = headEvent.next;
            headEvent.next = ret.next;
            ret.next = null;
            return ret;
        }
        
        
        /** connect 2 sequences temporarily, this function doesnt change tail pointer, so you have to call connectBefore(null) after using this connection. 
         *  @param secondHead head event of second sequence, null to set tail event as default.
         *  @return this instance
         */
        public function connectBefore(secondHead:MMLEvent) : MMLSequence
        {
            // simply connect first tail to second head.
            headEvent.jump.next = secondHead || tailEvent;
            return this;
        }
        
        
        /** is system command */
        public function isSystemCommand() : Boolean
        {
            return (headEvent.next.id == MMLEvent.SYSTEM_EVENT);
        }
        
        
        /** get system command */
        public function getSystemCommand() : String
        {
            return MMLParser._getSystemEventString(headEvent.next);
        }
        
        
        /** @private [sion sequencer internal] cutout MMLSequence */
        _sion_sequencer_internal function _cutout(head:MMLEvent) : MMLEvent
        {
            var last:MMLEvent = head.jump; // last event of this sequence
            var next:MMLEvent = last.next; // head of next sequence

            // cut out
            headEvent = head;
            tailEvent = MMLParser._allocEvent(MMLEvent.SEQUENCE_TAIL, 0);
            last.next = tailEvent;  // append tailEvent at last
            
            return next;
        }
        
        
        /** @private [internal] update mml string */
        internal function _updateMMLString() : void
        {
            if (headEvent.next.id == MMLEvent.DEBUG_INFO) {
                _mmlString = MMLParser._getSequenceMML(headEvent.next);
                headEvent.length = 0;
            }
        }
        
        
        /** @private [internal] insert before */
        internal function _insertBefore(next:MMLSequence) : void
        {
            _prevSequence = next._prevSequence;
            _nextSequence = next;
            _prevSequence._nextSequence = this;
            _nextSequence._prevSequence = this;
        }
        
        
        /** @private [internal] insert after */
        internal function _insertAfter(prev:MMLSequence) : void
        {
            _prevSequence = prev;
            _nextSequence = prev._nextSequence;
            _prevSequence._nextSequence = this;
            _nextSequence._prevSequence = this;
        }
        
        
        /** @private [sion sequencer internal] remove from chain. @return previous sequence. */
        _sion_sequencer_internal function _removeFromChain() : MMLSequence
        {
            var ret:MMLSequence = _prevSequence;
            _prevSequence._nextSequence = _nextSequence;
            _nextSequence._prevSequence = _prevSequence;
            _prevSequence = null;
            _nextSequence = null;
            return (ret === this) ? null : ret;
        }
        
        
        // calculate mml length
        private function _updateMMLLength() : void 
        {
            var exec:MMLExecutor = MMLSequencer._tempExecutor,
                e:MMLEvent = headEvent.next,
                length:int = 0;
            
            _hasRepeatAll = false;
            exec.initialize(this);
            while (e != null) {
                if (e.length) {
                    // note or rest
                    length += e.length;
                    e = e.next;
                } else {
                    // others
                    switch (e.id) {
                    case MMLEvent.REPEAT_BEGIN:  e = exec._onRepeatBegin(e);    break;
                    case MMLEvent.REPEAT_BREAK:  e = exec._onRepeatBreak(e);    break;
                    case MMLEvent.REPEAT_END:    e = exec._onRepeatEnd(e);      break;
                    case MMLEvent.REPEAT_ALL:    e = null; _hasRepeatAll=true;  break;
                    case MMLEvent.SEQUENCE_TAIL: e = null;                      break;
                    default:                     e = e.next;                    break;
                    }
                }
            }
            
            _mmlLength = length;
        }
    }
}


