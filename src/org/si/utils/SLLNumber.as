//----------------------------------------------------------------------------------------------------
// Singly linked list of Number
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.utils {
    /** Singly linked list of Number. */
    public class SLLNumber
    {
    // valiables
    //------------------------------------------------------------
        /** Number data */
        public var n:Number = 0;
        /** Nest pointer of list */
        public var next:SLLNumber = null;

        // free list
        static private var _freeList:SLLNumber = null;

        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor */
        function SLLNumber(n:Number=0)
        {
            this.n = n;
        }
        
        
        
        
    // allocator
    //------------------------------------------------------------
        /** Allocator */
        static public function alloc(n:Number=0) : SLLNumber
        {
            var ret:SLLNumber;
            if (_freeList) {
                ret = _freeList;
                _freeList = _freeList.next;
                ret.n = n;
                ret.next = null;
            } else {
                ret = new SLLNumber(n);
            }
            return ret;
        }
        
        /** Allocator of linked list */
        static public function allocList(size:int, defaultData:Number=0) : SLLNumber
        {
            var ret:SLLNumber = alloc(defaultData),
                elem:SLLNumber = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc(defaultData);
                elem = elem.next;
            }
            return ret;
        }
        
        /** Allocator of ring-linked list */
        static public function allocRing(size:int, defaultData:Number=0) : SLLNumber
        {
            var ret:SLLNumber = alloc(defaultData),
                elem:SLLNumber = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc(defaultData);
                elem = elem.next;
            }
            elem.next = ret;
            return ret;
        }
        
        /** Ring-linked list with initial values. */
        static public function newRing(...args) : SLLNumber
        {
            var size:int = args.length,
                ret:SLLNumber = alloc(args[0]),
                elem:SLLNumber = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc(args[i]);
                elem = elem.next;
            }
            elem.next = ret;
            return ret;
        }
        
        
        
        
    // deallocator
    //------------------------------------------------------------
        /** Deallocator */
        static public function free(elem:SLLNumber) : void
        {
            elem.next = _freeList;
            _freeList = elem;
        }
        
        /** Deallocator of linked list */
        static public function freeList(firstElem:SLLNumber) : void
        {
            if (firstElem == null) return;
            var lastElem:SLLNumber = firstElem;
            while (lastElem.next) { lastElem = lastElem.next; }
            lastElem.next = _freeList;
            _freeList = firstElem;
        }
        
        /** Deallocator of ring-linked list */
        static public function freeRing(firstElem:SLLNumber) : void
        {
            if (firstElem == null) return;
            var lastElem:SLLNumber = firstElem;
            while (lastElem.next == firstElem) { lastElem = lastElem.next; }
            lastElem.next = _freeList;
            _freeList = firstElem;
        }
        
        
        
        
    // carete pager
    //------------------------------------------------------------
        /** Create pager of linked list */
        static public function createListPager(firstElem:SLLNumber, fixedSize:Boolean) : Vector.<SLLNumber>
        {
            if (firstElem == null) return null;
            var elem:SLLNumber, i:int, size:int;
            for (size = 1, elem = firstElem; elem.next != null; elem = elem.next) { size++; }
            var pager:Vector.<SLLNumber> = new Vector.<SLLNumber>(size, fixedSize);
            elem = firstElem;
            for (i=0; i<size; i++) { pager[i] = elem; elem = elem.next; }
            return pager;
        }

        /** Create pager of ring-linked list */
        static public function createRingPager(firstElem:SLLNumber, fixedSize:Boolean) : Vector.<SLLNumber>
        {
            if (firstElem == null) return null;
            var elem:SLLNumber, i:int, size:int;
            for (size = 1, elem = firstElem; elem.next != firstElem; elem = elem.next) { size++; }
            var pager:Vector.<SLLNumber> = new Vector.<SLLNumber>(size, fixedSize);
            elem = firstElem;
            for (i=0; i<size; i++) { pager[i] = elem; elem = elem.next; }
            return pager;
        }
    }
}

