//----------------------------------------------------------------------------------------------------
// class for Single operator of MA3 wavelet
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    
    
    /** Simulrator of single operaotr sound generator of YAMAHA MA3 waveforms */
    public class SiMMLSimulatorMA3WaveTable extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorMA3WaveTable()
        {
            super(MT_MA3, 1);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(32, SiOPMTable.PG_MA3_WAVE);
        }
    }
}

