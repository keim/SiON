//----------------------------------------------------------------------------------------------------
// SiOPM effect Stereo expander
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Stereo expander. matrix transformation of stereo sound. */
    public class SiEffectStereoExpander extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        private var _l2l:Number, _r2l:Number, _l2r:Number, _r2r:Number;
        private var _monoralize:Boolean;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor
         *  @param phaseInvert invert r channel's phase.
         *  @param width stereo width (ussualy -1 ~ 2). 1=same as input, 0=monoral, 2=monoral with phase invertion, -1=swap channels.
         *  @param rotation rotate center. 1 for 90deg.
         */
        function SiEffectStereoExpander(width:Number=1, rotation:Number=0, phaseInvert:Boolean=false) : void
        {
            setParameters(width, rotation, phaseInvert);
        }        
        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set parameters
         *  @param width stereo width (ussualy -1 ~ 2). 1=same as input, 0=monoral, 2=monoral with phase invertion, -1=swap channels.
         *  @param rotation rotate center. 1 for 90deg.
         *  @param phaseInvert invert r channel's phase.
         */
        public function setParameters(width:Number=1.4, rotation:Number=0, phaseInvert:Boolean=false) : void
        {
            _monoralize = (width == 0 && rotation == 0 && !phaseInvert);
            var halfWidth:Number   = width * 0.7853981633974483,  // = pi()/4
                centerAngle:Number = (rotation + 0.5) * 1.5707963267948965,
                langle:Number = centerAngle - halfWidth,
                rangle:Number = centerAngle + halfWidth,
                invert:Number = (phaseInvert) ? -1 : 1,
                x:Number, y:Number, l:Number;
            _l2l = Math.cos(langle);
            _r2l = Math.sin(langle);
            _l2r = Math.cos(rangle) * invert;
            _r2r = Math.sin(rangle) * invert;
            x = _l2l + _l2r;
            y = _r2l + _r2r;
            l = Math.sqrt(x * x + y * y);
            if (l > 0.01) {
                l = 1 / l;
                _l2l *= l;
                _r2l *= l;
                _l2r *= l;
                _r2r *= l;
            }
        }
        
        
        
        
    // overrided funcitons
    //------------------------------------------------------------
        /** @private */
        override public function initialize() : void
        {
            setParameters();
        }
        

        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
            setParameters((!isNaN(args[1])) ? (args[1]*0.01) : 1.4,
                          (!isNaN(args[2])) ? (args[2]*0.01) : 0,
                          (!isNaN(args[0])) ? (args[0]!=0) : false);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            var i:int, l:Number, r:Number, imax:int=startIndex+length;
            if (_monoralize) {
                for (i=startIndex; i<imax;) {
                    l = buffer[i]; i++;
                    l += buffer[i]; --i;
                    l *= 0.7071067811865476;
                    buffer[i] = l; i++;
                    buffer[i] = l; i++;
                }
                return 1;
            }
            for (i=startIndex; i<imax;) {
                l = buffer[i]; i++;
                r = buffer[i]; --i;
                buffer[i] = l * _l2l + r * _r2l; i++;
                buffer[i] = l * _l2r + r * _r2r; i++;
            }
            return 2;
        }
    }
}

