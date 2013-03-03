//----------------------------------------------------------------------------------------------------
// class for PCM module channel
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelManager;
    
    
    /** @private */
    public class SiMMLModuleSimulatorPCM extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorPCM()
        {
            super(MT_PCM, 1, false);
            this._channelType = SiOPMChannelManager.CT_CHANNEL_PCM;
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(1, SiOPMTable.PG_PCM);
        }
    }
}

