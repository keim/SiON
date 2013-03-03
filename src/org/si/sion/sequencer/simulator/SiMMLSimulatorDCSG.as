//----------------------------------------------------------------------------------------------------
// class for DCSG Simulator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;

    
    /** @private */
    public class SiMMLModuleSimulatorDCSG extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorDCSG()
        {
            super(MT_PSG, 4);
            
            var i:int, toneVoiceSet:SiMMLSimulatorVoiceSet;
            
            // default voice set
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(3);
            this._defaultVoiceSet.voices[0] = new SiMMLSimulatorVoice(SiOPMTable.PG_SQUARE,      SiOPMTable.PT_PSG);
            this._defaultVoiceSet.voices[1] = new SiMMLSimulatorVoice(SiOPMTable.PG_NOISE_PULSE, SiOPMTable.PT_PSG_NOISE);
            this._defaultVoiceSet.voices[2] = new SiMMLSimulatorVoice(SiOPMTable.PG_PC_NZ_16BIT, SiOPMTable.PT_PSG);
            
            // voice set for channel 1-3
            toneVoiceSet = new SiMMLSimulatorVoiceSet(1);
            toneVoiceSet.voices[0] = new SiMMLSimulatorVoice(SiOPMTable.PG_SQUARE, SiOPMTable.PT_PSG);
            for (i=0; i<3; i++) this._channelVoiceSet[i] = toneVoiceSet;
            
            // voice set for channel 4
            toneVoiceSet = new SiMMLSimulatorVoiceSet(2);
            toneVoiceSet.voices[0] = new SiMMLSimulatorVoice(SiOPMTable.PG_NOISE_PULSE, SiOPMTable.PT_PSG_NOISE);
            toneVoiceSet.voices[1] = new SiMMLSimulatorVoice(SiOPMTable.PG_PC_NZ_16BIT, SiOPMTable.PT_PSG);
            this._channelVoiceSet[3] = toneVoiceSet;
        }
    }
}

