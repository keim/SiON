//----------------------------------------------------------------------------------------------------
// SiOPM filters based on RBJ cockbook
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** filters based on RBJ cockbook. */
    public class SiFilterBase extends SiEffectBase
    {
    // constant
    //------------------------------------------------------------
        static protected const THRESHOLD:Number = 0.0000152587890625;
        
        
        
        
    // variables
    //------------------------------------------------------------
        protected var _a1:Number, _a2:Number, _b0:Number, _b1:Number, _b2:Number;
        private var _in1L:Number, _in2L:Number, _out1L:Number, _out2L:Number;
        private var _in1R:Number, _in2R:Number, _out1R:Number, _out2R:Number;
        
        
        
        
    // Math calculation
    //------------------------------------------------------------
        /** hyperbolic sinh. */
        protected function sinh(n:Number) : Number {
            return (Math.exp(n) - Math.exp(-n)) * 0.5;
        }
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor */
        function SiFilterBase() {}
        
        
        
        
    // overrided funcitons
    //------------------------------------------------------------
        /** @private */
        override public function prepareProcess() : int
        {
            _in1L = _in2L = _out1L = _out2L = _in1R = _in2R = _out1R = _out2R = 0;
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            if (_out1L < THRESHOLD) _out2L = _out1L = 0;
            if (_out1R < THRESHOLD) _out2R = _out1R = 0;
            
            var i:int, input:Number, output:Number, imax:int=startIndex+length;
            if (channels == 2) {
                for (i=startIndex; i<imax;) {
                    input = buffer[i];
                    output = _b0*input + _b1*_in1L + _b2*_in2L - _a1*_out1L - _a2*_out2L;
                    if (output > 1) output = 1;
                    else if (output < -1) output = -1;
                    _in2L  = _in1L;  _in1L  = input;
                    _out2L = _out1L; _out1L = output;
                    buffer[i] = output; i++;
                    
                    input = buffer[i];
                    output = _b0*input + _b1*_in1R + _b2*_in2R - _a1*_out1R - _a2*_out2R;
                    if (output > 1) output = 1;
                    else if (output < -1) output = -1;
                    _in2R  = _in1R;  _in1R  = input;
                    _out2R = _out1R; _out1R = output;
                    buffer[i] = output; i++;
                }
            } else {
                for (i=startIndex; i<imax;) {
                    input = buffer[i];
                    output = _b0*input + _b1*_in1L + _b2*_in2L - _a1*_out1L - _a2*_out2L;
                    if (output > 1) output = 1;
                    else if (output < -1) output = -1;
                    _in2L  = _in1L;  _in1L  = input;
                    _out2L = _out1L; _out1L = output;
                    buffer[i] = output; i++;
                    buffer[i] = output; i++;
                }
            }
            return channels;
        }
    }
}

