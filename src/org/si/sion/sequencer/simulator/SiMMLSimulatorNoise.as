//----------------------------------------------------------------------------------------------------
// class for Noise simulator generator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** Noise generator simulator */
    public class SiMMLSimulatorNoise extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorNoise()
        {
            super(MT_NOISE, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(16, SiOPMTable.PG_NOISE_WHITE);
        }
    }
}

