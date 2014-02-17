//----------------------------------------------------------------------------------------------------
// class for PCM module channel
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.channels.SiOPMChannelManager;
    
    
    /** Simple sampler simulator */
    public class SiMMLSimulatorSampler extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorSampler()
        {
            super(MT_SAMPLE, 1, false);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(SiOPMChannelManager.CT_CHANNEL_SAMPLER, 1, 0);
        }
    }
}

