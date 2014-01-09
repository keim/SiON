//----------------------------------------------------------------------------------------------------
// SiOPM Low booster
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Low booster. */
    public class SiFilterLowBoost extends SiFilterBase
    {
    // constructor
    //------------------------------------------------------------
        /** constructor.
         *  @param freq shelfing frequency[Hz].
         *  @param slope slope, 1 for steepest slope.
         *  @param gain gain [dB].
         */
        function SiFilterLowBoost(freq:Number=3000, slope:Number=1, gain:Number=6) 
        {
            setParameters(freq, slope, gain);
        }
        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set parameters
         *  @param freq shelfing frequency[Hz].
         *  @param slope slope, 1 for steepest slope.
         *  @param gain gain [dB].
         */
        public function setParameters(freq:Number=3000, slope:Number=1, gain:Number=6) : void {
            if (slope<1) slope = 1;
            var A:Number   = Math.pow(10, gain*0.025),
                omg:Number = freq * 0.00014247585730565955, // 2*pi/44100
                cos:Number = Math.cos(omg), sin:Number = Math.sin(omg),
                alp:Number = sin * 0.5 * Math.sqrt((A+1/A)*(1/slope-1)+2),  //sin(w0)/2 * sqrt( (A + 1/A)*(1/S - 1) + 2 )
                alpsA2:Number = alp * Math.sqrt(A) * 2,                     //2*sqrt(A)*alpha
                ia0:Number = 1 / ((A+1) + (A-1)*cos + alpsA2);
            _a1 =-2 * ((A-1) + (A+1)*cos)          * ia0;
            _a2 =     ((A+1) + (A-1)*cos - alpsA2) * ia0;
            _b0 =     ((A+1) - (A-1)*cos + alpsA2) * A * ia0;
            _b1 = 2 * ((A-1) - (A+1)*cos)          * A * ia0;
            _b2 =     ((A+1) - (A-1)*cos - alpsA2) * A * ia0;
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

