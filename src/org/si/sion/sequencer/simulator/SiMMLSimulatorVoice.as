//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    /** @private vioce setting for SiMMLSimulators */
    public class SiMMLSimulatorVoice
    {
    // variables
    //--------------------------------------------------
        public var pgType:int;
        public var ptType:int;
        public var channelType:int;
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLSimulatorVoice(pgType:int, ptType:int, channelType:int = -1)
        {
            this.pgType = pgType;
            this.ptType = ptType;
            this.channelType = (channelType == -1) ? SiMMLChannelSetting.SELECT_TONE_FM : channelType;
        }
    }
}