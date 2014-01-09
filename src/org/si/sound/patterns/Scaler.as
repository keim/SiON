//----------------------------------------------------------------------------------------------------
// Pattern generator on scale
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.patterns {
    import org.si.sion.utils.Scale;
    
    
    /** Pattern generator on scale */
    public class Scaler extends Array
    {
    // variables
    //--------------------------------------------------
        /** scale instance */
        protected var _scale:Scale;
        /** pattern of scale indexes */
        protected var _scaleIndexPattern:Array;
        /** scale index shift */
        protected var _scaleIndexShift:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** pattern of scale indexes */
        public function get pattern() : Array { return _scaleIndexPattern; }
        public function set pattern(p:Array) : void {
            if (p == null) {
                this.length = 0;
                return;
            }
            _scaleIndexPattern = p;
            var i:int, imax:int = _scaleIndexPattern.length;
            if (this.length < imax) {
                for (i=this.length; i<imax; i++) {
                    this[i] = new Note();
                }
            }
            this.length = imax;
            for (i=0; i<imax; i++) {
                this[i].note = _scale.getNote(_scaleIndexPattern[i] + _scaleIndexShift);
            }
        }
        
        
        /** scale instance */
        public function get scale() : Scale { return _scale; }
        public function set scale(s:Scale) : void {
            if (_scale === s) return;
            _scale = s || new Scale();
            var i:int, imax:int = _scaleIndexPattern.length;
            for (i=0; i<imax; i++) {
                this[i].note = _scale.getNote(_scaleIndexPattern[i] + _scaleIndexShift);
            }
        }
        
        /** scale index shift */
        public function get scaleIndex() : int { return _scaleIndexShift; }
        public function set scaleIndex(s:int) : void {
            if (_scaleIndexShift == s) return;
            _scaleIndexShift = s;
            var i:int, imax:int = this.length;
            for (i=0; i<imax; i++) {
                this[i].note = _scale.getNote(_scaleIndexPattern[i] + _scaleIndexShift);
            }
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor
         *  @param scale Scale instance.
         */
        function Scaler(scale:Scale = null, pattern:Array = null)
        {
            super();
            _scaleIndexShift = 0;
            _scale = scale || new Scale();
            this.pattern = pattern;
        }
    }
}

