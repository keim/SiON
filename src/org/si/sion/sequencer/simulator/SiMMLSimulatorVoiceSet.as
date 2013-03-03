//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;

    /** @private */
    public class SiMMLSimulatorVoiceSet
    {
    // variables
    //--------------------------------------------------
        public var voices:Vector.<SiMMLSimulatorVoice>;
        public var initVoiceIndex:int;
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLSimulatorVoiceSet(length:int, offset:int=-1)
        {
            this.initVoiceIndex = 0;
            this.voices = new Vector.<SiMMLSimulatorVoice>(length, true);
            if (offset != -1) {
                var i:int, ptType:int;
                for (i=0; i<length; i++) {
                    ptType = SiOPMTable.instance.getWaveTable(i+offset).defaultPTType;
                    this.voices[i] = new SiMMLSimulatorVoice(i+offset, ptType);
                }
            }
        }
    }
}