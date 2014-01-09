//----------------------------------------------------------------------------------------------------
// SiOPM HP filter
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** HPF. */
    public class SiFilterHighPass extends SiFilterBase
    {
    // constructor
    //------------------------------------------------------------
        /** constructor.
         *  @param freq cutoff frequency[Hz].
         *  @param band band width [oct].
         */
        public function SiFilterHighPass(freq:Number=5500, band:Number=1)
        {
            setParameters(freq, band);
        }
        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set parameters
         *  @param freq cutoff frequency[Hz].
         *  @param band band width [oct].
         */
        public function setParameters(freq:Number=5500, band:Number=1) : void
        {
            var omg:Number = freq * 0.00014247585730565955, // 2*pi/44100
                cos:Number = Math.cos(omg), sin:Number = Math.sin(omg),
                alp:Number = sin * sinh(0.34657359027997264 * band * omg / sin), // log(2)*0.5
                ia0:Number = 1 / (1+alp);
            _a1 = -2*cos * ia0;
            _a2 = (1-alp) * ia0;
            _b1 = -(1+cos) * ia0;
            _b2 = _b0 = -_b1 * 0.5;
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
            setParameters((!isNaN(args[0])) ? args[0] : 5500,
                          (!isNaN(args[1])) ? args[1] : 1);
        }
    }
}

