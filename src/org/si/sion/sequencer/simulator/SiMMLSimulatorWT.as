//----------------------------------------------------------------------------------------------------
// class for Wave Table Sound Chip Simulator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.SiMMLSimulatorBase;
    import org.si.sion.module.SiOPMTable;
    
    
    /** @private */
    public class SiMMLModuleSimulatorWT extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorWT()
        {
            super(MT_CUSTOM, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(256, SiOPMTable.PG_CUSTOM);
        }
    }
}

