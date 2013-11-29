//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.SiMMLSimulatorBase;
    

    /** @private */
    public class SiMMLSimulatorKS extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorKS()
        {
            super(SiMMLSimulatorBase.MT_KS, 1, false)
        }
    }
}

