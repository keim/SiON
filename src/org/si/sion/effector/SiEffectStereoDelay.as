//----------------------------------------------------------------------------------------------------
// SiOPM effect stereo long delay
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Stereo long delay effector. The delay time is from 1[ms] to about 1.5[sec]. */
    public class SiEffectStereoDelay extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        static private const DELAY_BUFFER_BITS:int = 16;
        static private const DELAY_BUFFER_FILTER:int = (1<<DELAY_BUFFER_BITS)-1;
        
        private var _delayBuffer:Vector.<Vector.<Number>>;
        private var _pointerRead:int;
        private var _pointerWrite:int;
        private var _feedback:Number;
        private var _readBufferL:Vector.<Number>;
        private var _readBufferR:Vector.<Number>;
        private var _wet:Number;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor 
         *  @param delayTime delay time[ms]. maximum value is about 1500.
         *  @param feedback feedback decay(-1-1). Negative value to invert phase.
         *  @param isCross stereo crossing delay.
         *  @param wet mixing level(0-1).
         */
        function SiEffectStereoDelay(delayTime:Number=250, feedback:Number=0.25, isCross:Boolean=false, wet:Number=0.25)
        {
            _delayBuffer = new Vector.<Vector.<Number>>(2, true);
            _delayBuffer[0] = new Vector.<Number>(1<<DELAY_BUFFER_BITS);
            _delayBuffer[1] = new Vector.<Number>(1<<DELAY_BUFFER_BITS);
            setParameters(delayTime, feedback, isCross, wet);
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set parameters
         *  @param delayTime delay time[ms]. maximum value is about 1500.
         *  @param feedback feedback decay(-1-1). Negative value to invert phase.
         *  @param isCross stereo crossing delay.
         *  @param wet mixing level(0-1).
         */
        public function setParameters(delayTime:Number=250, feedback:Number=0.25, isCross:Boolean=false, wet:Number=0.25) : void
        {
            var offset:int = int(delayTime * 44.1),
                cross:int  = (isCross) ? 1 : 0;
            if (offset > DELAY_BUFFER_FILTER) offset = DELAY_BUFFER_FILTER;
            _pointerWrite = (_pointerRead + offset) & DELAY_BUFFER_FILTER;
            _feedback = (feedback>=1) ? 0.9990234375 : (feedback<=-1) ? -0.9990234375 : feedback;
            _readBufferL = _delayBuffer[cross];
            _readBufferR = _delayBuffer[1-cross];
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
            setParameters((!isNaN(args[0])) ? args[0] : 250,
                          (!isNaN(args[1])) ? (args[1]*0.01) : 0.25,
                          (args[2] == 1),
                          (!isNaN(args[3])) ? (args[3]*0.01) : 1);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            var i:int, imax:int = 1<<DELAY_BUFFER_BITS, 
                buf0:Vector.<Number> = _delayBuffer[0],
                buf1:Vector.<Number> = _delayBuffer[1];
            for (i=0; i<imax; i++) buf0[i] = buf1[i] = 0;
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            var i:int, n:Number, imax:int = startIndex + length,
                writeBufferL:Vector.<Number> = _delayBuffer[0],
                writeBufferR:Vector.<Number> = _delayBuffer[1],
                dry:Number = 1-_wet;
            for (i=startIndex; i<imax;) {
                n = _readBufferL[_pointerRead];
                writeBufferL[_pointerWrite] = buffer[i] - n * _feedback;
                buffer[i] *= dry;
                buffer[i] += n * _wet; i++;
                n = _readBufferR[_pointerRead];
                writeBufferR[_pointerWrite] = buffer[i] - n * _feedback;
                buffer[i] *= dry;
                buffer[i] += n * _wet; i++;
                _pointerWrite = (_pointerWrite+1) & DELAY_BUFFER_FILTER;
                _pointerRead  = (_pointerRead +1) & DELAY_BUFFER_FILTER;
            }
            return channels;
        }
    }
}

