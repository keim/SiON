//----------------------------------------------------------------------------------------------------
// class for Ramp wave operator of SiOPM wavelet
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** @private */
    public class SiMMLModuleSimulatorRamp extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorRamp()
        {
            super(MT_RAMP, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(128, SiOPMTable.PG_RAMP);
        }
    }
}

