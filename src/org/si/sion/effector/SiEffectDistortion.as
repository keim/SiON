//----------------------------------------------------------------------------------------------------
// SiOPM effect Hard Distortion
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Hard Distortion. */
    public class SiEffectDistortion extends SiEffectBase
    {
    // constant
    //------------------------------------------------------------
        static protected const THRESHOLD:Number = 0.0000152587890625;
        
        
        
        
    // variables
    //------------------------------------------------------------
        private var _preScale:Number, _limit:Number, _filterEnable:Boolean;
        private var _a1:Number, _a2:Number, _b0:Number, _b1:Number, _b2:Number;
        private var _in1:Number, _in2:Number, _out1:Number, _out2:Number;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor
         *  @param preGain PreGain (dB).
         *  @param postGain PostGain (dB).
         *  @param lpfFreq Low pass filter frequency (Hz).
         *  @param lpfSlope Low pass filter slope (oct/6dB).
         */
        function SiEffectDistortion(preGain:Number=-60, postGain:Number=18, lpfFreq:Number=2400, lpfSlope:Number=1) 
        {
            setParameters(preGain, postGain);
        }        
        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set parameters
         *  @param preGain PreGain (dB).
         *  @param postGain PostGain (dB).
         *  @param lpfFreq Low pass filter frequency (Hz).
         *  @param lpfSlope Low pass filter slope (oct/6dB).
         */
        public function setParameters(preGain:Number=-60, postGain:Number=18, lpfFreq:Number=2400, lpfSlope:Number=1) : void
        {
            var postScale:Number = Math.pow(2, -postGain/6);
            _preScale = Math.pow(2, -preGain/6) * postScale;
            _limit = postScale;
            _filterEnable = (lpfFreq > 0);
            if (_filterEnable) {
                var omg:Number = lpfFreq * 0.00014247585730565955, // 2*pi/44100
                    cos:Number = Math.cos(omg), sin:Number = Math.sin(omg),
                    ang:Number = 0.34657359027997264 * lpfSlope * omg / sin,
                    alp:Number = sin * (Math.exp(ang) - Math.exp(-ang)) * 0.5, // log(2)*0.5
                    ia0:Number = 1 / (1+alp);
                _a1 = -2*cos * ia0;
                _a2 = (1-alp) * ia0;
                _b1 = (1-cos) * ia0;
                _b2 = _b0 = _b1 * 0.5;
            }
        }
        
        
        
        
    // overrided funcitons
    //------------------------------------------------------------
        /** @private */
        override public function initialize() : void
        {
            setParameters();
        }
        

        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
            setParameters((!isNaN(args[0])) ? args[0] : -60,
                          (!isNaN(args[1])) ? args[1] : 18,
                          (!isNaN(args[2])) ? args[2] : 2400,
                          (!isNaN(args[3])) ? args[3] : 1);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            _in1 = _in2 = _out1 = _out2 = 0;
            return 1;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            if (_out1 < THRESHOLD) _out2 = _out1 = 0;
            var i:int, n:Number, out:Number, imax:int=startIndex+length;
            if (_filterEnable) {
                for (i=startIndex; i<imax; i++) {
                    n = buffer[i];
                    n *= _preScale;
                    if (n < -_limit) n = -_limit;
                    else if (n > _limit) n = _limit;
                    out = _b0*n + _b1*_in1 + _b2*_in2 - _a1*_out1 - _a2*_out2;
                    _in2  = _in1;  _in1  = n;
                    _out2 = _out1; _out1 = out;
                    buffer[i] = out; i++;
                    buffer[i] = out;
                }
            } else {
                for (i=startIndex; i<imax; i++) {
                    n = buffer[i];
                    n *= _preScale;
                    if (n < -_limit) n = -_limit;
                    else if (n > _limit) n = _limit;
                    buffer[i] = n; i++;
                    buffer[i] = n;
                }
            }
            return 1;
        }
    }
}

