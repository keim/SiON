//----------------------------------------------------------------------------------------------------
// class for physical modeling guitar simulator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.channels.SiOPMChannelManager;
    import org.si.sion.module.channels.SiOPMChannelBase;

    
    /** Physical modeling guitar simulator */
    public class SiMMLSimulatorKS extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorKS()
        {
            super(MT_KS, 1, false);
            /**/
        }
    }
}

