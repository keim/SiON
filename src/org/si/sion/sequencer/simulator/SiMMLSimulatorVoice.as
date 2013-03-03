//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    /** @private */
    public class SiMMLSimulatorVoice
    {
    // variables
    //--------------------------------------------------
        public var pgType:int;
        public var ptType:int;
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLSimulatorVoice(pgType:int, ptType:int)
        {
            this.pgType = pgType;
            this.ptType = ptType;
        }
    }
}