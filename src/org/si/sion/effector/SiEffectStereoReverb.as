//----------------------------------------------------------------------------------------------------
// SiOPM effect stereo reverb
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Stereo reverb effector. */
    public class SiEffectStereoReverb extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        static private const DELAY_BUFFER_BITS:int = 13;
        static private const DELAY_BUFFER_FILTER:int = (1<<DELAY_BUFFER_BITS)-1;
        
        private var _delayBufferL:Vector.<Number>, _delayBufferR:Vector.<Number>;
        private var _pointerRead0:int, _pointerRead1:int, _pointerRead2:int;
        private var _pointerWrite:int;
        private var _feedback0:Number, _feedback1:Number, _feedback2:Number;
        private var _wet:Number;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor
         *  @param delay1 long delay(0-1).
         *  @param delay2 short delay(0-1).
         *  @param feedback feedback decay(-1-1). Negative value to invert phase.
         *  @param wet mixing level(0-1).
         */
        function SiEffectStereoReverb(delay1:Number=0.7, delay2:Number=0.4, feedback:Number=0.8, wet:Number=0.3)
        {
            _delayBufferL = new Vector.<Number>(1<<DELAY_BUFFER_BITS);
            _delayBufferR = new Vector.<Number>(1<<DELAY_BUFFER_BITS);
            setParameters(delay1, delay2, feedback, wet);
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set parameters
         *  @param delay1 long delay(0-1).
         *  @param delay2 short delay(0-1).
         *  @param feedback feedback decay(-1-1). Negative value to invert phase.
         *  @param wet mixing level(0-1).
         */
        public function setParameters(delay1:Number=0.7, delay2:Number=0.4, feedback:Number=0.8, wet:Number=0.3) : void
        {
            if (delay1<0.01) delay1=0.01;
            else if (delay1>0.99) delay1=0.99;
            if (delay2<0.01) delay2=0.01;
            else if (delay2>0.99) delay2=0.99;
            _pointerWrite = (_pointerRead0 + DELAY_BUFFER_FILTER) & DELAY_BUFFER_FILTER;
            _pointerRead1 = (_pointerRead0 + DELAY_BUFFER_FILTER*(1-delay1)) & DELAY_BUFFER_FILTER;
            _pointerRead2 = (_pointerRead0 + DELAY_BUFFER_FILTER*(1-delay2)) & DELAY_BUFFER_FILTER;
            if (feedback>0.99) feedback=0.99;
            else if (feedback<-0.99) feedback=-0.99;
            _feedback0 = feedback*0.2;
            _feedback1 = feedback*0.3;
            _feedback2 = feedback*0.5;
            _wet = wet;
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
            setParameters((!isNaN(args[0])) ? (args[0]*0.01) : 0.7,
                          (!isNaN(args[1])) ? (args[1]*0.01) : 0.4,
                          (!isNaN(args[2])) ? (args[2]*0.01) : 0.8,
                          (!isNaN(args[3])) ? (args[3]*0.01) : 1);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            var i:int, imax:int = 1<<DELAY_BUFFER_BITS;
            for (i=0; i<imax; i++) _delayBufferL[i] = _delayBufferR[i] = 0;
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            var i:int, n:Number, m:Number, imax:int = startIndex + length,
                dry:Number = 1-_wet;
            for (i=startIndex; i<imax;) {
                n  = _delayBufferL[_pointerRead0] * _feedback0;
                n += _delayBufferL[_pointerRead1] * _feedback1;
                n += _delayBufferL[_pointerRead2] * _feedback2;
                _delayBufferL[_pointerWrite] = buffer[i] - n;
                buffer[i] *= dry;
                buffer[i] += n * _wet; i++;
                n  = _delayBufferR[_pointerRead0] * _feedback0;
                n += _delayBufferR[_pointerRead1] * _feedback1;
                n += _delayBufferR[_pointerRead2] * _feedback2;
                _delayBufferR[_pointerWrite] = buffer[i] - n;
                buffer[i] *= dry;
                buffer[i] += n * _wet; i++;
                _pointerWrite = (_pointerWrite + 1) & DELAY_BUFFER_FILTER;
                _pointerRead0 = (_pointerRead0 + 1) & DELAY_BUFFER_FILTER;
                _pointerRead1 = (_pointerRead1 + 1) & DELAY_BUFFER_FILTER;
                _pointerRead2 = (_pointerRead2 + 1) & DELAY_BUFFER_FILTER;
            }
            return channels;
        }
    }
}

