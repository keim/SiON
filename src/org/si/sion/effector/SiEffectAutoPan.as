//----------------------------------------------------------------------------------------------------
// SiOPM effect stereo auto pan
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    import org.si.utils.SLLNumber;
    
    
    /** Stereo auto pan. */
    public class SiEffectAutoPan extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        private var _stereo:Boolean;
        
        private var _lfoStep:int;
        private var _lfoResidueStep:int;
        private var _pL:SLLNumber, _pR:SLLNumber;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor
         *  @param frequency rotation frequency(Hz).
         *  @param width stereo width(0-1). 0 sets as auto pan with keeping stereo.
         */
        function SiEffectAutoPan(frequency:Number=1, width:Number=1)
        {
            _pL = SLLNumber.allocRing(256);
            _lfoResidueStep = 0;
            setParameters(frequency, width);
        }
        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set parameter
         *  @param frequency rotation frequency(Hz).
         *  @param width stereo width(0-1). 0 sets as auto pan with keeping stereo.
         */
        public function setParameters(frequency:Number=1, width:Number=1) : void 
        {
            var i:int;
            frequency *= 0.5;
            _lfoStep = int(172.265625/frequency);   //44100/256
            if (_lfoStep <= 4) _lfoStep = 4;
            _stereo = false
            if (width == 0) {
                width = 1;
                _stereo = true;
            }
            
            // volume table
            width *= 0.01227184630308513; // pi/256
            for (i=-128; i<128; i++) {
                _pL.n = Math.sin(1.5707963267948965+i*width); 
                _pL = _pL.next;
            }
            // _pR phase shift
            _pR = _pL;
            for (i=0; i<128; i++) _pR = _pR.next;
        }
        
        
        // overrided funcitons
        //------------------------------------------------------------
        /** @private */
        override public function initialize() : void
        {
            _lfoResidueStep = 0;
            setParameters();
        }
        

        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
            setParameters((!isNaN(args[0])) ? args[0] : 1, 
                          (!isNaN(args[1])) ? args[1]*0.01 : 1);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            return (_stereo) ? 2 : 1;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            
            var i:int, imax:int, istep:int, c:Number, s:Number, l:Number, r:Number,
                proc:Function = (_stereo) ? processLFOstereo : processLFOmono;
            istep = _lfoResidueStep;
            imax = startIndex + length;
            for (i=startIndex; i<imax-istep;) {
                proc(buffer, i, istep);
                i += istep;
                istep = _lfoStep<<1;
            }
            proc(buffer, i, imax-i);
            _lfoResidueStep = istep - (imax - i);
            return 2;
        }
        
        
        /** @private */
        public function processLFOmono(buffer:Vector.<Number>, startIndex:int, length:int) : void
        {
            var c:Number = _pL.n, s:Number = _pR.n,
                i:int, l:Number, imax:int = startIndex + length;
            for (i=startIndex; i<imax;) {
                l = buffer[i];
                buffer[i] = l * c; i++;
                buffer[i] = l * s; i++;
            }
            _pL = _pL.next;
            _pR = _pR.next;
        }
        
        
        public function processLFOstereo(buffer:Vector.<Number>, startIndex:int, length:int) : void
        {
            var c:Number = _pL.n, s:Number = _pR.n,
                i:int, l:Number, r:Number, imax:int = startIndex + length;
            for (i=startIndex; i<imax; i+=2) {
                l = buffer[i];
                r = buffer[i+1];
                buffer[i]   = l * c - r * s;
                buffer[i+1] = l * s + r * c;
            }
            _pL = _pL.next;
            _pR = _pR.next;
        }
    }
}

