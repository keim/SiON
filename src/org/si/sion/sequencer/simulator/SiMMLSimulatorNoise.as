//----------------------------------------------------------------------------------------------------
// class for Noise Simulator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** @private */
    public class SiMMLModuleSimulatorNoise extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorNoise()
        {
            super(MT_NOISE, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(16, SiOPMTable.PG_NOISE_WHITE);
        }
    }
}

