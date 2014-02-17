//----------------------------------------------------------------------------------------------------
// class for Simulator of ramp waveform single operator sound generator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** Simulator of ramp waveform single operator sound generator */
    public class SiMMLSimulatorRamp extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorRamp()
        {
            super(MT_RAMP, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(128, SiOPMTable.PG_RAMP);
        }
    }
}

