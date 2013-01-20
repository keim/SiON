//----------------------------------------------------------------------------------------------------
// SiMMLTrack Envelop table
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.utils.SLLint;
    import org.si.sion.utils.Translator;
    import org.si.sion.namespaces._sion_internal;
    
    
    /** Tabel evnelope data. */
    public class SiMMLEnvelopTable
    {
    // variables
    //--------------------------------------------------------------------------------
        /** Head element of single linked list. */
        public var head:SLLint;
        /** Tail element of single linked list. */
        public var tail:SLLint;
        
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** constructor. 
         *  @param table envelop table vector.
         *  @param loopPoint returning point index of looping. -1 sets no loop.
         */
        function SiMMLEnvelopTable(table:Vector.<int>=null, loopPoint:int=-1)
        {
            if (table) {
                var loop:SLLint, i:int, imax:int = table.length;
                head = tail = SLLint.allocList(imax);
                loop = null;
                for (i=0; i<imax-1; i++) {
                    if (loopPoint == i) loop = tail;
                    tail.i = table[i];
                    tail = tail.next;
                }
                tail.i = table[i];
                tail.next = loop;
            } else {
                head = null;
                tail = null;
            }
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** convert to Vector.<int> */
        public function toVector(length:int, min:int=-65536, max:int=65536, dst:Vector.<int>=null) : Vector.<int>
        {
            if (!dst) dst = new Vector.<int>();
            dst.length = length;
            var i:int, n:int, ptr:SLLint=head;
            for (i=0; i<length; i++) {
                if (ptr) {
                    n = ptr.i;
                    ptr = ptr.next;
                } else {
                    n = 0;
                }
                if (n < min) n = min;
                else if (n > max) n = max;
                dst[i] = n;
            }
            return dst;
        }
        
        
        
        /** free */
        public function free() : void
        {
            if (head) {
                tail.next = null;
                SLLint.freeList(head);
                head = null;
                tail = null;
            }
        }
        
        
        /** copy 
         *  @return this instance
         */
        public function copyFrom(src:SiMMLEnvelopTable) : SiMMLEnvelopTable
        {
            free();
            if (src.head) {
                for (var pSrc:SLLint = src.head, pDst:SLLint = null; pSrc != src.tail; pSrc = pSrc.next) {
                    var p:SLLint = SLLint.alloc(pSrc.i);
                    if (pDst) {
                        pDst.next = p;
                        pDst = p;
                    } else {
                        head = p;
                        pDst = head;
                    }
                }
            }
            return this;
        }
        
        
        
        /** parse mml text 
         *  @param tableNumbers String of table numbers
         *  @param postfix String of postfix
         *  @param maxIndex maximum size of envelop table
         *  @return this instance
         */
        public function parseMML(tableNumbers:String, postfix:String, maxIndex:int=65536) : SiMMLEnvelopTable
        {
            var res:* = Translator.parseTableNumbers(tableNumbers, postfix, maxIndex);
            if (res.head) _sion_internal::_initialize(res.head, res.tail);
            return this;
        }
        
        
        
        
    // internal functions
    //--------------------------------------------------------------------------------
        /** @private [sion internal] set by pointers. */
        _sion_internal function _initialize(head_:SLLint, tail_:SLLint) : void
        {
            head = head_;
            tail = tail_;
            // looping last data
            if (tail.next == null) tail.next = tail;
        }
    }
}

