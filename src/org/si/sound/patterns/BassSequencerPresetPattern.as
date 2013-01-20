//----------------------------------------------------------------------------------------------------
// Preset patterns for BassSequencer
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.patterns {
    /** Preset patterns for BassSequencer */
    public dynamic class BassSequencerPresetPattern
    {
    // variables
    //----------------------------------------
        /** categoly list. */
        public var categolies:Array = [];
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function BassSequencerPresetPattern()
        {
            _categoly("bass");
            _pattern("bass1", "A^--A^--A^--A^--");
            _pattern("bass2", "A^--A^--A^--A^AA");
            _pattern("bass3", "A^A^--A^--A^--A^");
            _pattern("bass4", "--A^--A^--A^--A^");
            _pattern("bass5", "A-A-A^^^A^^^A^^^");
            _pattern("bass6", "A^A^----A^A^----");
            _pattern("bass7", "A^A^-A^-A^A^-A^-");
            _pattern("bass8", "A^^A^^--A^^A^^--");
            _pattern("bass9", "A--A-A^aA^A^A^--");
            _pattern("bass10", "A^-AA-A^A-A^A^A^");
            _pattern("bass11", "A^aaA^a-AAA--A--");
            _pattern("bass12", "A^aaA^a-AA----aa");
            _pattern("bass13", "A^H^A^H^A^H^A^H^");
            _pattern("bass14", "A^H-A^H-A^H-A^H-");
            _pattern("bass15", "AAH^AAH^AAH^AAH^");
            _pattern("bass16", "AAH^AAHaAAH^AAHa");
            _pattern("bass17", "AA^AA^AA^AA^A^AA");
            _pattern("bass18", "AA-AA-A-AA-AA-A-");
            _pattern("bass19", "AA^AA-A-AA^AA-A-");
            _pattern("bass20", "AA^AA^A^AA^AA^A^");
            _pattern("bass21", "AAaaAAaaAAaaAAaa");
            _pattern("bass22", "AAAAAAAAAAAAAAAA");
            _pattern("bass23", "A^^A--A^^^------");
            _pattern("bass24", "A^-A^-A^--------");
            _pattern("bass25", "A^-A^-A-A^------");
            _pattern("bass26", "--A^-A^^--A^-A^^");
            _pattern("bass27", "--A^^A--A^^A^^A-");
            _pattern("bass28", "--A^-A^-A^-A^-A^");
            _pattern("bass29", "-AA^--A^-AA^--A^");
            _pattern("bass30", "A^A^------------");
            _pattern("bass31", "A^A^-----------a");
        }
        
        
        
        
    // internals
    //----------------------------------------
        // set pattern
        private var _pp:PMLParser = new PMLParser({
            "A":new Note(33,128, 1), "a":new Note(33, 64, 1),
            "H":new Note(45,128, 1), "h":new Note(45, 64, 1)
        });
        private function _pattern(key:String, pml:String) : void {
            var pattern:Array = _pp.parse(pml);
            _categolyList.push(pattern);
            this[key] = pattern;
        }
        
        
        // register categoly
        private var _categolyList:Array;
        private function _categoly(key:String) : void {
            _categolyList = [];
            _categolyList["name"] = key;
            categolies.push(_categolyList);
            this[key] = _categolyList;
        }
    }
}

