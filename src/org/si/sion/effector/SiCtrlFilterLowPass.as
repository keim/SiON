//----------------------------------------------------------------------------------------------------
// SiOPM effect controlable LPF
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** controlable LPF. */
    public class SiCtrlFilterLowPass extends SiCtrlFilterBase
    {
        /** constructor. 
         *  @param cutoff cutoff(0-1).
         *  @param resonance resonance(0-1).
         */
        function SiCtrlFilterLowPass(cutoff:Number=1, resonance:Number=0)
        {
            initialize();
            control(cutoff, resonance);
        }
        
        
        /** @private */
        override protected function processLFO(buffer:Vector.<Number>, startIndex:int, length:int) : void
        {
            var i:int, n:Number, imax:int = startIndex + length,
                cut:Number = _table.filter_cutoffTable[_cutIndex],
                fb:Number = _res * _table.filter_feedbackTable[_cutIndex];
            for (i=startIndex; i<imax;) {
                _p0l += cut * (buffer[i] - _p0l + fb * (_p0l - _p1l));
                _p1l += cut * (_p0l - _p1l);
                buffer[i] = _p1l; i++;
                _p0r += cut * (buffer[i] - _p0r + fb * (_p0r - _p1r));
                _p1r += cut * (_p0r - _p1r);
                buffer[i] = _p1r; i++;
            }
        }
    }
}

