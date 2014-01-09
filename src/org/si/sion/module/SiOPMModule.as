//----------------------------------------------------------------------------------------------------
// SiOPM sound module 
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import org.si.utils.SLLNumber;
    import org.si.utils.SLLint;
    import org.si.sion.module.channels.*;
    import org.si.sion.namespaces._sion_internal;
    
    
    /** SiOPM sound module */
    public class SiOPMModule
    {
    // constants
    //--------------------------------------------------
        /** size of stream send */
        static public const STREAM_SEND_SIZE:int = 8;
        /** pipe size */
        static public const PIPE_SIZE:int = 5;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** Intial values for operator parameters */
        public var initOperatorParam:SiOPMOperatorParam;
        /** zero buffer */
        public var zeroBuffer:SLLint;
        /** output stream */
        public var outputStream:SiOPMStream;
        /** slot of global mixer */
        public var streamSlot:Vector.<SiOPMStream>;
        /** pcm module volume @default 4 */
        public var pcmVolume:Number;
        /** sampler module volume @default 2 */
        public var samplerVolume:Number;
        
        private var _bufferLength:int;  // buffer length
        private var _bitRate:int;       // bit rate
        
        // pipes
        private var _pipeBuffer:Vector.<SLLint>;
        private var _pipeBufferPager:Vector.<Vector.<SLLint>>;
        
        
    // properties
    //--------------------------------------------------
        /** Buffer count */
        public function get output() : Vector.<Number> { return outputStream.buffer; }
        /** Buffer channel count */
        public function get channelCount() : int { return outputStream.channels; }
        /** Bit rate */
        public function get bitRate() : int { return _bitRate; }
        /** Buffer length */
        public function get bufferLength() : int { return _bufferLength; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Default constructor
         *  @param busSize Number of mixing buses.
         */
        function SiOPMModule()
        {
            // initial values
            initOperatorParam = new SiOPMOperatorParam();
            
            // stream buffer
            outputStream = new SiOPMStream();
            streamSlot = new Vector.<SiOPMStream>(STREAM_SEND_SIZE, true);

            // zero buffer gives always 0
            zeroBuffer = SLLint.allocRing(1);
            
            // others
            _bufferLength = 0;
            _pipeBuffer = new Vector.<SLLint>(PIPE_SIZE, true);
            _pipeBufferPager = new Vector.<Vector.<SLLint>>(PIPE_SIZE, true);
            
            // call at once
            SiOPMChannelManager.initialize(this);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize module and all tone generators.
         *  @param channelCount ChannelCount
         *  @param bitRate bit rate 
         *  @param bufferLength Maximum buffer size processing at once.
         */
        public function initialize(channelCount:int, bitRate:int, bufferLength:int) : void
        {
            _bitRate = bitRate;
            
            var i:int, stream:SiOPMStream;

            // reset stream slot
            for (i=0; i<STREAM_SEND_SIZE; i++) streamSlot[i] = null;
            streamSlot[0] = outputStream;
            
            // reallocate buffer
            if (_bufferLength != bufferLength) {
                _bufferLength = bufferLength;
                outputStream.buffer.length = bufferLength<<1;
                for (i=0; i<PIPE_SIZE; i++) {
                    SLLint.freeRing(_pipeBuffer[i]);
                    _pipeBuffer[i] = SLLint.allocRing(bufferLength);
                    _pipeBufferPager[i] = SLLint.createRingPager(_pipeBuffer[i], true);
                }
            }
            
            pcmVolume = 4;
            samplerVolume = 2;
            
            // initialize all channels
            SiOPMChannelManager.initializeAllChannels();
        }
        
        
        /** Reset. */
        public function reset() : void
        {
            // reset all channels
            SiOPMChannelManager.resetAllChannels();
        }
        
        
        /** @private [sion internal] Clear output buffer. */
        _sion_internal function _beginProcess() : void
        {
            outputStream.clear();
        }
        
        
        /** @private [sion internal] Limit output level in the ranged between -1 ~ 1.*/
        _sion_internal function _endProcess() : void
        {
            outputStream.limit();
            if (_bitRate != 0) outputStream.quantize(_bitRate);
        }
        
        
        /** get pipe buffer */
        public function getPipe(pipeNum:int, index:int=0) : SLLint
        {
            return _pipeBufferPager[pipeNum][index];
        }
    }
}

