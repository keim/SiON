//----------------------------------------------------------------------------------------------------
// Singly linked list of int
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.utils {
    /** Singly linked list of int. */
    public class SLLint
    {
    // valiables
    //------------------------------------------------------------
        /** int data */
        public var i:int = 0;
        /** Next pointer of list */
        public var next:SLLint = null;

        // free list
        static private var _freeList:SLLint = null;

        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor */
        function SLLint(i:int=0)
        {
            this.i = i;
        }
        
        
        
        
    // allocator
    //------------------------------------------------------------
        /** Allocator */
        static public function alloc(i:int=0) : SLLint
        {
            var ret:SLLint;
            if (_freeList) {
                ret = _freeList;
                _freeList = _freeList.next;
                ret.i = i;
                ret.next = null;
            } else {
                ret = new SLLint(i);
            }
            return ret;
        }
        
        /** Allocator of linked list */
        static public function allocList(size:int, defaultData:int=0) : SLLint
        {
            var ret:SLLint = alloc(defaultData),
                elem:SLLint = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc(defaultData);
                elem = elem.next;
            }
            return ret;
        }
        
        /** Allocator of ring-linked list */
        static public function allocRing(size:int, defaultData:int=0) : SLLint
        {
            var ret:SLLint = alloc(defaultData),
                elem:SLLint = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc(defaultData);
                elem = elem.next;
            }
            elem.next = ret;
            return ret;
        }
        
        /** Ring-linked list with initial values. */
        static public function newRing(...args) : SLLint
        {
            var size:int = args.length,
                ret:SLLint = alloc(args[0]),
                elem:SLLint = ret;
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
        static public function free(elem:SLLint) : void
        {
            elem.next = _freeList;
            _freeList = elem;
        }
        
        /** Deallocator of linked list */
        static public function freeList(firstElem:SLLint) : void
        {
            if (firstElem == null) return;
            var lastElem:SLLint = firstElem;
            while (lastElem.next) { lastElem = lastElem.next; }
            lastElem.next = _freeList;
            _freeList = firstElem;
        }
        
        /** Deallocator of ring-linked list */
        static public function freeRing(firstElem:SLLint) : void
        {
            if (firstElem == null) return;
            var lastElem:SLLint = firstElem;
            while (lastElem.next == firstElem) { lastElem = lastElem.next; }
            lastElem.next = _freeList;
            _freeList = firstElem;
        }
        
        
        
        
    // carete pager
    //------------------------------------------------------------
        /** Create pager of linked list */
        static public function createListPager(firstElem:SLLint, fixedSize:Boolean) : Vector.<SLLint>
        {
            if (firstElem == null) return null;
            var elem:SLLint, i:int, size:int;
            for (size = 1, elem = firstElem; elem.next != null; elem = elem.next) { size++; }
            var pager:Vector.<SLLint> = new Vector.<SLLint>(size, fixedSize);
            elem = firstElem;
            for (i=0; i<size; i++) { pager[i] = elem; elem = elem.next; }
            return pager;
        }

        /** Create pager of ring-linked list */
        static public function createRingPager(firstElem:SLLint, fixedSize:Boolean) : Vector.<SLLint>
        {
            if (firstElem == null) return null;
            var elem:SLLint, i:int, size:int;
            for (size = 1, elem = firstElem; elem.next != firstElem; elem = elem.next) { size++; }
            var pager:Vector.<SLLint> = new Vector.<SLLint>(size, fixedSize);
            elem = firstElem;
            for (i=0; i<size; i++) { pager[i] = elem; elem = elem.next; }
            return pager;
        }
    }
}

