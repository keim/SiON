//----------------------------------------------------------------------------------------------------
// class for Simulator of custom waveform single operator sound generator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** Simulator of custom waveform single operator sound generator */
    public class SiMMLSimulatorWT extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorWT()
        {
            super(MT_CUSTOM, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(256, SiOPMTable.PG_CUSTOM);
        }
    }
}

