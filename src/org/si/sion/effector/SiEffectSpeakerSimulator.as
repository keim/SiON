//----------------------------------------------------------------------------------------------------
// Piezoelectric speaker simulator
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Piezoelectric speaker simulator. */
    public class SiEffectSpeakerSimulator extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        private var _springCoef:Number = 0.96;
        private var _diaphragmPosL:Number, _diaphragmPosR:Number;
        private var _prevL:Number, _prevR:Number;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor. 
         *  @param hardness hardness of diaphragm (0-1). 0 sets no effect. 1 sets hardest.
         */
        function SiEffectSpeakerSimulator(hardness:Number=0.2) 
        {
            setParameters(hardness);
        }
        
                
        /** set parameter
         *  @param hardness hardness of diaphragm (0-1). 0 sets no effect. 1 sets hardest.
         */
        public function setParameters(hardness:Number=0.2) : void 
        {
            _springCoef = 1 - hardness * hardness;
            if (_springCoef < 0.1) _springCoef = 0.1;
        }

        
        
        
    // callback functions
    //------------------------------------------------------------
        /** @private */
        override public function initialize() : void
        {
            setParameters();
        }
        
        
        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
            setParameters((!isNaN(args[0])) ? args[0]*0.01 : 0.2);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            _prevL = _prevR = _diaphragmPosL = _diaphragmPosR = 0;
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            var i:int, d:Number, imax:int=startIndex+length;
            for (i=startIndex; i<imax;) {
                d = buffer[i] - _prevL;
                _diaphragmPosL *= _springCoef;
                _diaphragmPosL += d;
                _prevL = buffer[i];
                buffer[i] = _diaphragmPosL; i++;
                
                d = buffer[i] - _prevR;
                _diaphragmPosR *= _springCoef;
                _diaphragmPosR += d;
                _prevR = buffer[i];
                buffer[i] = _diaphragmPosR; i++;
            }
            return channels;
        }
    }
}

