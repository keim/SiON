//----------------------------------------------------------------------------------------------------
// class for Pulse wave operator of SiOPM wavelet
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** @private */
    public class SiMMLModuleSimulatorPulse extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorPulse()
        {
            super(MT_PULSE, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(32, SiOPMTable.PG_PULSE);
        }
    }
}

