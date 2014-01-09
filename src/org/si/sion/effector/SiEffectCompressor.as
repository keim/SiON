//----------------------------------------------------------------------------------------------------
// SiOPM effect Compressor
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    import org.si.utils.SLLNumber;
    
    
    /** Compressor. */
    public class SiEffectCompressor extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        private var _windowRMSList:SLLNumber = null;
        private var _windowSamples:int;
        private var _windowRMSTotal:Number;
        private var _windwoRMSAveraging:Number;
        private var _threshold2:Number;  // threshold^2
        private var _attRate:Number;     // attack rate  (per sample decay)
        private var _relRate:Number;     // release rate (per sample decay)
        private var _maxGain:Number;     // max gain
        private var _mixingLevel:Number; // mixing level
        private var _gain:Number;        // gain
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor
         *  @param thres threshold(0-1).
         *  @param wndTime window to calculate gain[ms].
         *  @param attTime attack time [ms/6db].
         *  @param relTime release time [ms/-6db].
         *  @param maxGain max gain [db].
         */
        function SiEffectCompressor(thres:Number=0.7, wndTime:Number=50, attTime:Number=20, relTime:Number=20, maxGain:Number=-6, mixingLevel:Number=0.5)
        {
            setParameters(thres, wndTime, attTime, relTime, maxGain, mixingLevel);
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set parameters.
         *  @param thres threshold(0-1).
         *  @param wndTime window to calculate gain[ms].
         *  @param attTime attack time [ms/6db].
         *  @param relTime release time [ms/-6db].
         *  @param maxGain max gain [db].
         *  @param mixingLevel output level.
         */
        public function setParameters(thres:Number=0.7, wndTime:Number=50, attTime:Number=20, relTime:Number=20, maxGain:Number=-6, mixingLevel:Number=0.5) : void {
            _threshold2 = thres*thres;
            _windowSamples = int(wndTime * 44.1);
            _windwoRMSAveraging = 1/_windowSamples;
            _attRate = (attTime == 0) ? 0.5 : (Math.pow(2, -1/(attTime * 44.1)));
            _relRate = (relTime == 0) ? 2.0 : (Math.pow(2,  1/(relTime * 44.1)));
            _maxGain = Math.pow(2, -maxGain/6);
            _mixingLevel = mixingLevel;
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
            setParameters((!isNaN(args[0])) ? args[0]*0.01 : 0.7,
                          (!isNaN(args[1])) ? args[1] : 50,
                          (!isNaN(args[2])) ? args[2] : 20,
                          (!isNaN(args[3])) ? args[3] : 20,
                          (!isNaN(args[4])) ? -args[4] : -6,
                          (!isNaN(args[5])) ? args[5]*0.01 : 0.5);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            if (_windowRMSList) SLLNumber.freeRing(_windowRMSList);
            _windowRMSList = SLLNumber.allocRing(_windowSamples);
            _windowRMSTotal = 0;
            _gain = 2;
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            
            var i:int, imax:int = startIndex + length;
            var l:Number, r:Number, rms2:Number;
            for (i=startIndex; i<imax; i++) {
                l = buffer[i]; i++;
                r = buffer[i]; --i;
                _windowRMSList = _windowRMSList.next;
                _windowRMSTotal  -= _windowRMSList.n;
                _windowRMSList.n = l * l + r * r;
                _windowRMSTotal  += _windowRMSList.n;
                rms2 = _windowRMSTotal * _windwoRMSAveraging;
                _gain *= (rms2 > _threshold2) ? _attRate : _relRate;
                if (_gain > _maxGain) _gain = _maxGain;

                l *= _gain;
                r *= _gain;
                l = (l>1) ? 1 : (l<-1) ? -1 : l;
                r = (r>1) ? 1 : (r<-1) ? -1 : r;
                buffer[i] = l * _mixingLevel; i++;
                buffer[i] = r * _mixingLevel;
            }
            return channels;
        }
    }
}

