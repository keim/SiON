//----------------------------------------------------------------------------------------------------
// class for Single operator of SiOPM wavelet
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** @private */
    public class SiMMLModuleSimulatorSiOPM extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorSiOPM()
        {
            super(MT_ALL, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(512, SiOPMTable.PG_SINE);
        }
    }
}

