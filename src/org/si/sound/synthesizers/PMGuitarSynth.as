// Physical Modeling Guitar Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.module.channels.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    
    
    /** Physical Modeling Guitar Synthesizer
     */
    public class PMGuitarSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] plunk velocity [0-1]. */
        protected var _plunkVelocity:Number;
        
        /** @private [protected] tl offset by attack rate. */
        protected var _tlOffsetByAR:Number;
        
        
        
    // properties
    //----------------------------------------
        /** string tensoin [0-1]. */
        public function get tensoin() : Number { return _voice.pmsTension * 0.015873015873015872; }
        public function set tensoin(t:Number) : void {
            _voice.pmsTension = t * 63;
            _voiceUpdateNumber++;
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelKS;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelKS;
                if (ch != null) ch.setAllReleaseRate(_voice.pmsTension);
            }
        }
        
        
        /** plunk velocity [0-1]. */
        public function get plunkVelocity() : Number { return _plunkVelocity; }
        public function set plunkVelocity(v:Number) : void {
            _plunkVelocity = (v<0) ? 0 : (v>1) ? 1 : v;
            _voice.channelParam.operatorParam[0].tl = (_plunkVelocity==0) ? 127 : (_plunkVelocity * 64 - _tlOffsetByAR);
            _voiceUpdateNumber++;
        }
        
        
        /** wave shape of plunk noise. @default 20 (SiOPMTable.PG_NOISE_PINK) */
        public function get seedWaveShape() : int { return _voice.channelParam.operatorParam[0].pgType; }
        public function set seedWaveShape(ws:int) : void { 
            _voice.channelParam.operatorParam[0].setPGType(ws);
            _voiceUpdateNumber++;
        }
        
        
        /** pitch of plunk noise. @default 68 */
        public function get seedPitch() : int { return _voice.channelParam.operatorParam[0].fixedPitch; }
        public function set seedPitch(p:int) : void { 
            _voice.channelParam.operatorParam[0].fixedPitch = p;
            _voiceUpdateNumber++;
        }
        
        
        /** attack time of plunk noise (0-1). */
        override public function get attackTime() : Number { 
            var iar:int = _voice.channelParam.operatorParam[0].ar;
            return  (iar > 48) ? 0 : (1 - (iar - 16)* 0.03125);
        }
        override public function set attackTime(n:Number) : void { 
            var iar:int = ((1 - n) * 32) + 16;
            _tlOffsetByAR = n * 16;
            _voice.channelParam.operatorParam[0].ar = iar;
            _voice.channelParam.operatorParam[0].tl = (_plunkVelocity==0) ? 127 : (_plunkVelocity * 64 - _tlOffsetByAR);
            _voiceUpdateNumber++;
        }
        
        
        /** release time of guitar synthesizer is equal to (1-tension). */
        override public function get releaseTime() : Number { return 1-_voice.pmsTension*0.015625; }
        override public function set releaseTime(n:Number) : void { 
            _voice.pmsTension = 64 - n*64;
            if (_voice.pmsTension<0) _voice.pmsTension = 0;
            else if (_voice.pmsTension>63) _voice.pmsTension = 63;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param tension sustain rate of the tone
         */
        function PMGuitarSynth(tension:Number=0.125)
        {
            super();
            _voice.setPMSGuitar(48, 48, 0, 68, 20, int(tension*63));
            attackTime = 0;
            plunkVelocity = 1;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** Set all parameters of phisical modeling synth guitar voice.
         *  @param ar attack rate of plunk energy
         *  @param dr decay rate of plunk energy
         *  @param tl total level of plunk energy
         *  @param fixedPitch plunk noise pitch
         *  @param ws wave shape of plunk
         *  @param tension sustain rate of the tone
         */
        public function setPMSGuitar(ar:int=48, dr:int=48, tl:int=0, fixedPitch:int=68, ws:int=20, tension:int=8) : PMGuitarSynth
        {
            _voice.setPMSGuitar(ar, dr, tl, fixedPitch, ws, tension);
            _voiceUpdateNumber++;
            return this;
        }
    }
}


