//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.channels.SiOPMChannelManager;
    import org.si.sion.module.channels.SiOPMChannelBase;

    
    /** @private Channel restriction */
    public class SiMMLChannelRestriction
    {
    // constants
    //--------------------------------------------------

        
        
        
    // variables
    //--------------------------------------------------
        /** @private restriction type */
        public   var type:int;
        /** @private module type */
        internal var _moduleType:int;
        /** @private */
        internal var _waveTableLength:int;
        /** @private */
        internal var _waveTableBits:int;
        
        
        
    // constructor
    //--------------------------------------------------
        /** @private  */
        function SiMMLChannelRestriction(type:int, moduleType:int, waveTableLength:int=0, waveTableBits:int=0)
        {
            this.type = type;
            this._moduleType = moduleType;
            this._waveTableLength = waveTableLength;
            this._waveTableBits = waveTableBits;
        }
        
        
        
        
    // tone setting
    //--------------------------------------------------
    }
}

