//----------------------------------------------------------------------------------------------------
// class for Sampler module channel
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.SiMMLSimulatorBase;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelManager;
    
    
    /** @private */
    public class SiMMLModuleSimulatorSampler extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorSampler()
        {
            super(MT_SAMPLER, 1, false);
            this._channelType = SiOPMChannelManager.CT_CHANNEL_PCM;
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(1, 0);
        }
    }
}

