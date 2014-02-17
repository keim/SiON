//----------------------------------------------------------------------------------------------------
// class for PCM module channel
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.channels.SiOPMChannelManager;
    
    
    /** PCM sound module simulator */
    public class SiMMLSimulatorPCM extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorPCM()
        {
            super(MT_PCM, 1, false);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(SiOPMChannelManager.CT_CHANNEL_PCM, 1, SiOPMTable.PG_PCM);
        }
    }
}

