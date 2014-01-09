//----------------------------------------------------------------------------------------------------
// SiON effect basic class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Effector basic class. */
    public class SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        /** @private [internal] used by manager */
        internal var _isFree:Boolean = true;
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor. do nothing. */
        function SiEffectBase() {}
        
        
        
        
    // callback functions
    //------------------------------------------------------------
        /** Initializer. The system calls this when the instance is created. */
        public function initialize() : void
        {
        }
        
        
        /** Parameter setting by mml arguments. The sequencer calls this when "#EFFECT" appears.
         *  @param args The arguments refer from mml. The value of Number.NaN is put when its abbriviated.
         */
        public function mmlCallback(args:Vector.<Number>) : void
        {
        }
        
        
        /** Prepare processing. The system calls this before processing.
         *  @return requesting channels count.
         */
        public function prepareProcess() : int
        {
            return 1;
        }
        
        
        /** Process effect to stream buffer. The system calls this to process.
         *  @param channels Stream channel count. 1=monoral(same data in buffer[i*2] and buffer[i*2+1]). 2=stereo.
         *  @param buffer Stream buffer to apply effect. The order is same as wave format [L0,R0,L1,R1,L2,R2 ... ].
         *  @param startIndex startIndex to apply effect. You CANNOT use this index to the stream buffer directly. Should be doubled because its a stereo stream.
         *  @param length length to apply effect. You CANNOT use this length to the stream buffer directly. Should be doubled because its a stereo stream.
         *  @return output channels count.
         */
        public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            return channels;
        }
    }
}

