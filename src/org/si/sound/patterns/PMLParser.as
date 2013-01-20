//----------------------------------------------------------------------------------------------------
// PML (Pattern/Primitive Macro Language) parser
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.patterns {
    /** PML (Pattern/Primitive Macro Language) parser, this class provides quite simple pattern generator. 
@example The PML string is translated by rule property's key to Note instance. The letter "^" extends previous Note's length and the letter "[...]n" is translated as a loop. The letters not included in the rule property are translated to rest.
<listing version="3.0">
var pp:PMLParser = new PMLParser();
pp.rule = {"A":new Note(60), "B":new Note(72)}; // set rule. letter "A" as Note(60) and letter "B" as Note(72).
var pat1:Vector.&lt;Note&gt; = pp.parse("A B AABB");  // generate pattern. The PML "A B AABB" is simply translated by rule.
                                                // The whitespaces are translated to rest.
for (var i:int=0; i&lt;pat1.length; i++) {
    trace(pat1[i].note);                        // output "60 -1  72 -1  60  60  72  72" (rest's note property is -1)
}
var pat2:Vector.&lt;Note&gt; = pp.parse("A B A^^^");  // generate pattern. The letter "^" extends previous Note's length.
var pat3:Vector.&lt;Note&gt; = pp.parse("[A B ]2");   // generate pattern. The letter "[...]n" is translated as a loop. you cannot nest loops.
</listing>
     */
    public class PMLParser
    {
    // variables
    //----------------------------------------
        /** parsing rule. */
        public var rule:*;
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function PMLParser(rule:* = null)
        {
            this.rule = rule || {};
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** generate pattern from PML.
         *  @param pml pattern as string.
         */
        public function parse(pml:String) : Array
        {
            pml = pml.replace(/\[(.+?)\](\d*)/, function() : String { 
                var rep:int = int(arguments[2]), text:String="";
                for (var i:int=rep||2; i>0; --i) text += arguments[1];
                return text;
            });
            var imax:int = pml.length;
            var pattern:Array = new Array(imax);
            var i:int, l:String, org:Note, prev:Note = null;
            for (i=0; i<imax; i++) {
                l = pml.charAt(i);
                org = rule[l] as Note;
                if (org) {
                    pattern[i] = (new Note()).copyFrom(org);
                    prev = pattern[i];
                } else if (l == "^" && prev != null && !isNaN(prev.length)) {
                    prev.length += 1;
                }
            }
            
            return pattern;
        }
    }
}


