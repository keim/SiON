//----------------------------------------------------------------------------------------------------
// class for Simulator of pulse waveform single operator sound generator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** Simulator of pulse waveform single operator sound generator */
    public class SiMMLSimulatorPulse extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorPulse()
        {
            super(MT_PULSE, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(32, SiOPMTable.PG_PULSE);
        }
    }
}

