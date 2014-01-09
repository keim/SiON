//----------------------------------------------------------------------------------------------------
// Preset patterns for DrumMachine
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.patterns {
    /** Preset patterns for DrumMachine */
    public dynamic class DrumMachinePresetPattern 
    {
    // variables
    //----------------------------------------
        /** categoly list. */
        public var categolies:Array = [];
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function DrumMachinePresetPattern()
        {
            _categoly("bass");
            _pattern("bass1", "0---0---0---0---");
            _pattern("bass2", "0---0---01--0---");
            _pattern("bass3", "0---0---0---0-1-");
            _pattern("bass4", "0---0---0---0--1");
            _pattern("bass5", "0---0---0---1111");
            _pattern("bass6", "0--10---0--10-1-");
            _pattern("bass7", "0-----0---------");
            _pattern("bass8", "0---1-0---------");
            _pattern("bass9", "0-----0---1-----");
            _pattern("bass10", "0-----0-----1---");
            _pattern("bass11", "0-----0-------1-");
            _pattern("bass12", "0-------0-------");
            _pattern("bass13", "0-------0-1-----");
            _pattern("bass14", "0-------0-----1-");
            _pattern("bass15", "0-------0-0--11-");
            _pattern("bass16", "0-------0--1--1-");
            _pattern("bass17", "0---------00----");
            _pattern("bass18", "0---------00--1-");
            _pattern("bass19", "00------00------");
            _pattern("bass20", "00------00---1--");
            _pattern("bass21", "00------00-1-11-");
            _pattern("bass22", "0-0---0---0---0-");
            _pattern("bass23", "0--0--0--0------");
            _pattern("bass24", "0--0--0--0---1--");
            _pattern("bass25", "0--0--0--0----1-");
            _pattern("bass26", "0--0--0--0-----1");
            _pattern("bass27", "0--0--0---0-----");
            _pattern("bass28", "0--0--0---0--1--");
            _pattern("bass29", "0--0--0---0---1-");
            _pattern("bass30", "0--0--0---0----1");
            _pattern("bass31", "0---------------");
            _pattern("bass32", "00--------------");
            
            _categoly("snare");
            _pattern("snare1", "----0-------0---");
            _pattern("snare2", "----0--1----0---");
            _pattern("snare3", "----0----1--0---");
            _pattern("snare4", "----0-------0--1");
            _pattern("snare5", "----0-----1-0---");
            _pattern("snare6", "----0-------0-1-");
            _pattern("snare7", "----0------10---");
            _pattern("snare8", "----0--1----0-0-");
            _pattern("snare9", "----0--1-1--0---");
            _pattern("snare10", "----0--1-1--0-0-");
            _pattern("snare11", "-1--0--1----0---");
            _pattern("snare12", "-1--0--1----0-0-");
            _pattern("snare13", "-1--0--1-1--0---");
            _pattern("snare14", "-1--0--1-1--0-0-");
            _pattern("snare15", "----0----0000000");
            _pattern("snare16", "----0--1-0000000");
            _pattern("snare17", "-1--0--1-0000000");
            _pattern("snare18", "-11-0-11-0000000");
            _pattern("snare19", "-000000000000000");
            
            _categoly("hihat");
            _pattern("hihat1", "0-1-0-1-0-1-0-1-");
            _pattern("hihat2", "0-1-0-1-001-0-1-");
            _pattern("hihat3", "0-1-0-1-0-1-001-");
            _pattern("hihat4", "001-0-1-001-0-1-");
            _pattern("hihat5", "001-001-001-001-");
            _pattern("hihat6", "0-000-000-000-00");
            _pattern("hihat7", "0-1-0-0-0-1-0-0-");
            _pattern("hihat8", "0-1-0-0-0-0-0-0-");
            _pattern("hihat9", "0-1-0--10-1-00-0");
            _pattern("hihat10", "0---0---0---0---");
            _pattern("hihat11", "0---0---0---1---");
            _pattern("hihat12", "1---1---1---1---");
            _pattern("hihat13", "--1---1---1---1-");
            _pattern("hihat14", "--1---1---1--01-");
            _pattern("hihat15", "--1---1---1-001-");
            _pattern("hihat16", "--0---0---0---0-");
            _pattern("hihat17", "--0---0---0--01-");
            _pattern("hihat18", "1-0---0---0---0-");
            
            _categoly("percus");
            _pattern("percus1", "-------0-------0");
            _pattern("percus2", "-----0-1-----0-1");
            _pattern("percus3", "-0---0-1-0---0-1");
            _pattern("percus4", "-0-0-0-1-0-0-0-1");
            _pattern("percus5", "-0--0--1-0--0---");
            _pattern("percus6", "-0--0--1-0--0--1");
            _pattern("percus7", "-0--1-1--0--1---");
            _pattern("percus8", "-0--1-1--0--1-1-");
            _pattern("percus9", "-0----1--0----1-");
        }
        
        
        
        
    // internals
    //----------------------------------------
        // set pattern
        private var _pp:PMLParser = new PMLParser({"0":new Note(-1,-1,Number.NaN,0), "1":new Note(-1,-1,Number.NaN,1)});
        private function _pattern(key:String, pml:String) : void {
            var pattern:Vector.<Note> = Vector.<Note>(_pp.parse(pml));
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

