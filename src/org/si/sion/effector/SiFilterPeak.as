//----------------------------------------------------------------------------------------------------
// SiOPM Peaking filter
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Peaking EQ. */
    public class SiFilterPeak extends SiFilterBase
    {
    // constructor
    //------------------------------------------------------------
        /** constructor.
         *  @param freq cutoff frequency[Hz].
         *  @param band band width [oct].
         *  @param gain gain [dB].
         */
        function SiFilterPeak(freq:Number=3000, band:Number=1, gain:Number=6) 
        {
            setParameters(freq, band);
        }
        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set parameters
         *  @param freq cutoff frequency[Hz].
         *  @param band band width [oct].
         *  @param gain gain [dB].
         */
        public function setParameters(freq:Number=3000, band:Number=1, gain:Number=6) : void {
            var A:Number   = Math.pow(10, gain*0.025),
                omg:Number = freq * 0.00014247585730565955, // 2*pi/44100
                cos:Number = Math.cos(omg), sin:Number = Math.sin(omg),
                alp:Number = sin * sinh(0.34657359027997264 * band * omg / sin), // log(2)*0.5
                alpA:Number = alp * A, alpiA:Number = alp / A,
                ia0:Number = 1 / (1+alpiA);
            _b1 = _a1 = -2*cos * ia0;
            _a2 = (1-alpiA) * ia0;
            _b0 = (1+alpA) * ia0;
            _b2 = (1-alpA) * ia0;
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
            setParameters((!isNaN(args[0])) ? args[0] : 3000,
                          (!isNaN(args[1])) ? args[1] : 1,
                          (!isNaN(args[2])) ? args[2] : 6);
        }
    }
}

