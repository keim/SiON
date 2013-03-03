//----------------------------------------------------------------------------------------------------
// class for PSG Simulator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** @private */
    public class SiMMLModuleSimulatorPSG
    {
        function SiMMLModuleSimulatorPSG()
        {
            super(MT_PSG, 3);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(2);
            this._defaultVoiceSet.voices[0] = new SiMMLSimulatorVoice(SiOPMTable.PG_SQUARE,      SiOPMTable.PT_PSG);
            this._defaultVoiceSet.voices[1] = new SiMMLSimulatorVoice(SiOPMTable.PG_NOISE_PULSE, SiOPMTable.PT_PSG_NOISE);
        }
    }
}

