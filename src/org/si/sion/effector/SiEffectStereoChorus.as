//----------------------------------------------------------------------------------------------------
// SiOPM effect stereo chorus
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Stereo chorus effector. */
    public class SiEffectStereoChorus extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        static private const DELAY_BUFFER_BITS:int = 12;
        static private const DELAY_BUFFER_FILTER:int = (1<<DELAY_BUFFER_BITS)-1;
        
        private var _delayBufferL:Vector.<Number>, _delayBufferR:Vector.<Number>;
        private var _pointerRead:int;
        private var _pointerWrite:int;
        private var _feedback:Number;
        private var _depth:Number;
        private var _wet:Number;
        
        private var _lfoPhase:int;
        private var _lfoStep:int;
        private var _lfoResidueStep:int;
        private var _phaseInvert:int;
        private var _phaseTable:Vector.<int>;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor.
         *  @param delayTime delay time[ms]. maximum value is about 94.
         *  @param feedback feedback ratio(0-1).
         *  @param frequency frequency of chorus[Hz].
         *  @param depth depth of chorus.
         *  @param wet wet mixing level(0-1).
         */
        function SiEffectStereoChorus(delayTime:Number=20, feedback:Number=0.2, frequency:Number=4, depth:Number=20, wet:Number=0.5, invertPhase:Boolean=true)
        {
            _delayBufferL = new Vector.<Number>(1<<DELAY_BUFFER_BITS);
            _delayBufferR = new Vector.<Number>(1<<DELAY_BUFFER_BITS);
            _phaseTable = new Vector.<int>();
            
            _lfoPhase = 0;
            _lfoResidueStep = 0;
            _pointerRead = 0;
            setParameters(delayTime, feedback, frequency, depth, wet, invertPhase);
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set parameter
         *  @param delayTime delay time[ms]. maximum value is about 94.
         *  @param feedback feedback ratio(0-1).
         *  @param frequency frequency of chorus[Hz].
         *  @param depth depth of chorus.
         *  @param wet wet mixing level(0-1).
         */
        public function setParameters(delayTime:Number=20, feedback:Number=0.2, frequency:Number=4, depth:Number=20, wet:Number=0.5, invertPhase:Boolean=true) : void {
            if (frequency == 0 || depth == 0 || delayTime == 0) throw new Error("SiEffectStereoChorus; frequency, depth or delay should not be 0.");
            var offset:int = int(delayTime * 44.1), tableSize:int, i:int, p:Number, dp:Number;
            if (offset > DELAY_BUFFER_FILTER) offset = DELAY_BUFFER_FILTER;
            _pointerWrite = (_pointerRead + offset) & DELAY_BUFFER_FILTER;
            _feedback = (feedback>=1) ? 0.9990234375 : (feedback<=-1) ? -0.9990234375 : feedback;
            _depth = (depth >= offset-4) ? (offset-4) : depth;
            tableSize = _depth * 6.283185307179586;
            if (tableSize*frequency > 11025) tableSize = 11025/frequency;
            if (_phaseTable.length != tableSize) _phaseTable.length = tableSize;
            dp = 6.283185307179586/tableSize;
            for (i=0, p=0; i<tableSize; i++, p+=dp) _phaseTable[i] = int(Math.sin(p) * _depth + 0.5);
            _lfoStep = int(44100/(tableSize*frequency));
            if (_lfoStep <= 4) _lfoStep = 4;
            _lfoResidueStep = _lfoStep<<1;
            _wet = wet;
            _phaseInvert = (invertPhase) ? -1 : 1;
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
            setParameters((!isNaN(args[0])) ? args[0] : 20,
                          (!isNaN(args[1])) ? (args[1]*0.01) : 0.2,
                          (!isNaN(args[2])) ? args[2] : 4,
                          (!isNaN(args[3])) ? args[3] : 20,
                          (!isNaN(args[4])) ? (args[4]*0.01) : 0.5,
                          (!isNaN(args[5])) ? (args[5]!=0) : true);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            _lfoPhase = 0;
            _lfoResidueStep = 0;
            _pointerRead = 0;
            var i:int, imax:int = 1<<DELAY_BUFFER_BITS;
            for (i=0; i<imax; i++) _delayBufferL[i] = _delayBufferR[i] = 0;
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            
            var i:int, imax:int, istep:int, c:Number, s:Number, l:Number, r:Number;
            istep = _lfoResidueStep;
            imax = startIndex + length;
            for (i=startIndex; i<imax-istep;) {
                _processLFO(buffer, i, istep);
                if (++_lfoPhase == _phaseTable.length) _lfoPhase = 0;
                i += istep;
                istep = _lfoStep<<1;
            }
            _processLFO(buffer, i, imax-i);
            _lfoResidueStep = istep - (imax - i);
            return channels;
        }
        
        
        // process inside
        private function _processLFO(buffer:Vector.<Number>, startIndex:int, length:int) : void
        {
            var i:int, n:Number, m:Number, p:int, imax:int = startIndex + length, 
                delayL:int=_phaseTable[_lfoPhase], delayR:int=_phaseTable[_lfoPhase] * _phaseInvert,
                dry:Number = 1-_wet;
            for (i=startIndex; i<imax;) {
                p = (_pointerRead + delayL) & DELAY_BUFFER_FILTER;
                n = _delayBufferL[p];
                m = buffer[i] - n * _feedback;
                _delayBufferL[_pointerWrite] = m;
                buffer[i] *= dry;
                buffer[i] += n * _wet; i++;
                p = (_pointerRead + delayR) & DELAY_BUFFER_FILTER;
                n = _delayBufferR[p];
                m = buffer[i] - n * _feedback;
                _delayBufferR[_pointerWrite] = m;
                buffer[i] *= dry;
                buffer[i] += n * _wet; i++;
                _pointerWrite = (_pointerWrite+1) & DELAY_BUFFER_FILTER;
                _pointerRead  = (_pointerRead +1) & DELAY_BUFFER_FILTER;
            }
        }
    }
}

