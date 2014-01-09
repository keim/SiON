//----------------------------------------------------------------------------------------------------
// Down sampler
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Down sampler. */
    public class SiEffectDownSampler extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        private var _freqShift:int = 0;
        private var _bitConv0:Number = 1;
        private var _bitConv1:Number = 1;
        private var _channelCount:int = 2;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor. 
         *  @param freqShift frequency shift 0=44.1kHz, 1=22.05kHz, 2=11.025kHz.
         *  @param bitRate bit rate of the sample
         *  @param channelCount channel count 1=monoral, 2=stereo
         */
        function SiEffectDownSampler(freqShift:int=0, bitRate:int=16, channelCount:int=2) 
        {
            setParameters(freqShift, bitRate, channelCount);
        }
        
        
        /** set parameter
         *  @param freqShift frequency shift 0=44.1kHz, 1=22.05kHz, 2=11.025kHz.
         *  @param bitRate bit rate of the sample
         *  @param channelCount channel count 1=monoral, 2=stereo
         */
        public function setParameters(freqShift:int=0, bitRate:int=16, channelCount:int=2) : void 
        {
            _freqShift = freqShift;
            _bitConv0 = 1<<bitRate;
            _bitConv1 = 1/_bitConv0;
            _channelCount = channelCount;
        }
        
        
        
        
    // callback functions
    //------------------------------------------------------------
        /** @private */
        override public function initialize() : void
        {
            setParameters();
        }
        
        
        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
            setParameters((!isNaN(args[0])) ? args[0] : 0,
                          (!isNaN(args[1])) ? args[1] : 16,
                          (!isNaN(args[2])) ? args[2] : 2);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            var i:int, j:int, jmax:int, bc0:Number, l:Number, r:Number, imax:int=startIndex+length;
            if (_channelCount == 1) {
                switch (_freqShift) {
                case 0:
                    bc0 = 0.5 * _bitConv0;
                    for (i=startIndex; i<imax;) {
                        l =  buffer[i]; i++;
                        l += buffer[i]; i--;
                        l = (int(l * bc0)) * _bitConv1;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                    }
                    break;
                case 1:
                    bc0 = 0.25 * _bitConv0;
                    for (i=startIndex; i<imax;) {
                        l =  buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i-=3;
                        l = (int(l * bc0)) * _bitConv1;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                    }
                    break;
                case 2:
                    bc0 = 0.125 * _bitConv0;
                    for (i=startIndex; i<imax;) {
                        l =  buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i++;
                        l += buffer[i]; i-=7;
                        l = (int(l * bc0)) * _bitConv1;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                        buffer[i] = l; i++;
                    }
                    break;
                default:
                    jmax = 2<<_freqShift;
                    bc0 = (1/jmax) * _bitConv0;
                    for (i=startIndex; i<imax;) {
                        for (j=0, l=0; j<jmax; j++, i++) {
                            l += buffer[i];
                        }
                        i -= jmax;
                        l = (int(l * bc0)) * _bitConv1;
                        for (j=0; j<jmax; j++, i++) {
                            buffer[i] = l;
                        }
                    }
                    break;
                }
            } else {
                switch (_freqShift) {
                case 0:
                    for (i=startIndex; i<imax; i++) {
                        buffer[i] = (int(buffer[i] * _bitConv0)) * _bitConv1;
                    }
                    break;
                case 1:
                    bc0 = 0.5 * _bitConv0;
                    for (i=startIndex; i<imax;) {
                        l =  buffer[i]; i++;
                        r =  buffer[i]; i++;
                        l += buffer[i]; i++;
                        r += buffer[i]; i-=3;
                        l = (int(l * bc0)) * _bitConv1;
                        r = (int(r * bc0)) * _bitConv1;
                        buffer[i] = l; i++;
                        buffer[i] = r; i++;
                        buffer[i] = l; i++;
                        buffer[i] = r; i++;
                    }
                    break;
                case 2:
                    bc0 = 0.25 * _bitConv0;
                    for (i=startIndex; i<imax;) {
                        l =  buffer[i]; i++;
                        r =  buffer[i]; i++;
                        l += buffer[i]; i++;
                        r += buffer[i]; i++;
                        l += buffer[i]; i++;
                        r += buffer[i]; i++;
                        l += buffer[i]; i++;
                        r += buffer[i]; i-=7;
                        l = (int(l * bc0)) * _bitConv1;
                        r = (int(r * bc0)) * _bitConv1;
                        buffer[i] = l; i++;
                        buffer[i] = r; i++;
                        buffer[i] = l; i++;
                        buffer[i] = r; i++;
                        buffer[i] = l; i++;
                        buffer[i] = r; i++;
                        buffer[i] = l; i++;
                        buffer[i] = r; i++;
                    }
                    break;
                default:
                    jmax = 1<<_freqShift;
                    bc0 = (1/jmax) * _bitConv0;
                    for (i=startIndex; i<imax;) {
                        for (j=0, l=0, r=0; j<jmax; j++, i++) {
                            l += buffer[i];
                            r += buffer[i];
                        }
                        i -= jmax;
                        l = (int(l * bc0)) * _bitConv1;
                        r = (int(r * bc0)) * _bitConv1;
                        for (j=0; j<jmax; j++) {
                            buffer[i] = l; i++;
                            buffer[i] = r; i++;
                        }
                    }
                    break;
                }
            }
            return _channelCount;
        }
    }
}

