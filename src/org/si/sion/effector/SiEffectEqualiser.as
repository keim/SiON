//----------------------------------------------------------------------------------------------------
// SiOPM effect Stereo 3band equaliser
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Stereo 3band equaliser. */
    public class SiEffectEqualiser extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        // filter pipes
        private var f1p0L:Number, f1p1L:Number, f1p2L:Number, f1p3L:Number;
        private var f2p0L:Number, f2p1L:Number, f2p2L:Number, f2p3L:Number;
        private var sdm1L:Number, sdm2L:Number, sdm3L:Number;
        private var f1p0R:Number, f1p1R:Number, f1p2R:Number, f1p3R:Number;
        private var f2p0R:Number, f2p1R:Number, f2p2R:Number, f2p3R:Number;
        private var sdm1R:Number, sdm2R:Number, sdm3R:Number;

        // controls
        private var lf:Number, hf:Number;
        private var lg:Number, mg:Number, hg:Number;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor.
         *  @param lowGain low gain(0-1-..).
         *  @param midGain middle gain(0-1-..).
         *  @param highGain high gain(0-1-..).
         *  @param lowFreq frequency for LPF[Hz].
         *  @param highFreq frequency for HPF[Hz].
         */
        function SiEffectEqualiser(lowGain:Number=1, midGain:Number=1, highGain:Number=1, lowFreq:Number=880, highFreq:Number=5000) 
        {
            setParameters(lowGain, midGain, highGain, lowFreq, highFreq);
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set parameters
         *  @param lowGain low gain(0-1-..).
         *  @param midGain middle gain(0-1-..).
         *  @param highGain high gain(0-1-..).
         *  @param lowFreq frequency for LPF[Hz].
         *  @param highFreq frequency for HPF[Hz].
         */
        public function setParameters(lowGain:Number=1, midGain:Number=1, highGain:Number=1, lowFreq:Number=880, highFreq:Number=5000) : void
        {
          lg = lowGain;
          mg = midGain;
          hg = highGain;
          lf = 2 * Math.sin(lowFreq  * 0.00007123792865282977);    //3.141592653589793/44100
          hf = 2 * Math.sin(highFreq * 0.00007123792865282977);
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
            setParameters((!isNaN(args[0])) ? args[0]*0.01 : 1,
                          (!isNaN(args[1])) ? args[1]*0.01 : 1,
                          (!isNaN(args[2])) ? args[2]*0.01 : 1,
                          (!isNaN(args[3])) ? args[3] : 880,
                          (!isNaN(args[4])) ? args[4] : 5000);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            sdm1L = sdm2L = sdm3L = f2p0L = f2p1L = f2p2L = f2p3L = f1p0L = f1p1L = f1p2L = f1p3L = 0;
            sdm1R = sdm2R = sdm3R = f2p0R = f2p1R = f2p2R = f2p3R = f1p0R = f1p1R = f1p2R = f1p3R = 0;
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            var i:int, n:Number, l:Number, m:Number, h:Number, imax:int=startIndex+length;
            if (channels == 2) {
                for (i=startIndex; i<imax;) {
                    n = buffer[i];
                    f1p0L += (lf * (n - f1p0L)) + 2.3283064370807974e-10;
                    f1p1L += (lf * (f1p0L - f1p1L));
                    f1p2L += (lf * (f1p1L - f1p2L));
                    f1p3L += (lf * (f1p2L - f1p3L));
                    f2p0L += (hf * (n - f2p0L)) + 2.3283064370807974e-10;
                    f2p1L += (hf * (f2p0L - f2p1L));
                    f2p2L += (hf * (f2p1L - f2p2L));
                    f2p3L += (hf * (f2p2L - f2p3L));
                    l = f1p3L;
                    h = sdm3L - f2p3L;
                    m = sdm3L - (h + l);
                    sdm3L = sdm2L;
                    sdm2L = sdm1L;
                    sdm1L = n;
                    buffer[i] = l * lg + m * mg + h * hg;
                    i++;

                    n = buffer[i];
                    f1p0R += (lf * (n - f1p0R)) + 2.3283064370807974e-10;
                    f1p1R += (lf * (f1p0R - f1p1R));
                    f1p2R += (lf * (f1p1R - f1p2R));
                    f1p3R += (lf * (f1p2R - f1p3R));
                    f2p0R += (hf * (n - f2p0R)) + 2.3283064370807974e-10;
                    f2p1R += (hf * (f2p0R - f2p1R));
                    f2p2R += (hf * (f2p1R - f2p2R));
                    f2p3R += (hf * (f2p2R - f2p3R));
                    l = f1p3R;
                    h = (sdm3R - f2p3R);
                    m = (sdm3R - (h + l));
                    sdm3R = sdm2R;
                    sdm2R = sdm1R;
                    sdm1R = n;
                    buffer[i] = l * lg + m * mg + h * hg;
                    i++;
                }
            } else {
                for (i=startIndex; i<imax;) {
                    n = buffer[i];
                    f1p0L += (lf * (n - f1p0L)) + 2.3283064370807974e-10;
                    f1p1L += (lf * (f1p0L - f1p1L));
                    f1p2L += (lf * (f1p1L - f1p2L));
                    f1p3L += (lf * (f1p2L - f1p3L));
                    f2p0L += (hf * (n - f2p0L)) + 2.3283064370807974e-10;
                    f2p1L += (hf * (f2p0L - f2p1L));
                    f2p2L += (hf * (f2p1L - f2p2L));
                    f2p3L += (hf * (f2p2L - f2p3L));
                    l = f1p3L;
                    h = sdm3L - f2p3L;
                    m = sdm3L - (h + l);
                    sdm3L = sdm2L;
                    sdm2L = sdm1L;
                    sdm1L = n;
                    n = l * lg + m * mg + h * hg;
                    buffer[i] = n; i++;
                    buffer[i] = n; i++;
                }
            }
            return channels;
        }
    }
}

