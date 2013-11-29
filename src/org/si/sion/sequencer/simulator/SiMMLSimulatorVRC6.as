//----------------------------------------------------------------------------------------------------
// class for SID simulator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.SiMMLSimulatorBase;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelManager;
    
    
    /** @private */
    public class SiMMLModuleSimulatorVRC6 extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorVRC6()
        {
            super(MT_ALL, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(512, SiOPMTable.PG_SINE);
        }
    }
}

