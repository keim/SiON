// Programmable Sound Generator Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMOperatorParam
    import org.si.sion.module.channels.SiOPMChannelFM;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    
    
    /** Programmable Sound Generator Synthesizer 
     */
    public class PSGSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** PSG channel mode (0=mute, 1=PSG, 2=noise, 3=PSG+noise). */
        protected var _channelMode:int;
        /** PSG channel gain (*2db) (0=0db, 7=14db, 15=mute) */
        protected var _channelTL:int;
        /** SSG envelop controling rate */
        protected var _evelopRate:int;
        /** operator parameter for op0 */
        protected var _opp0:SiOPMOperatorParam;
        /** operator parameter for op1 */
        protected var _opp1:SiOPMOperatorParam;
        
        
        
    // properties
    //----------------------------------------
        /** PSG channel number */
        public function get channelNumber() : int { return _voice.channelNum; }
        
        /** PSG channel mode (0=mute, 1=PSG, 2=noise, 3=PSG+noise). */
        public function get channelMode() : int { return _channelMode; }
        public function set channelMode(mode:int) : void {
            _opp0.mute = ((mode & 1) == 1);
            _opp1.mute = ((mode & 2) == 2);
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[0].mute = _opp0.mute;
                    ch.operator[1].mute = _opp1.mute;
                }
            }
        }
        
        
        /** noise frequency */
        public function get noiseFreq() : int { return _opp1.fixedPitch >> 6; }
        public function set noiseFreq(nf:int) : void {
            _opp1.fixedPitch = (nf << 6) + 1;
            if (!_opp1.mute) {
                var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
                for (i=0; i<imax; i++) {
                    ch = _tracks[i].channel as SiOPMChannelFM;
                    if (ch != null) ch.operator[1].fixedPitchIndex = _opp1.fixedPitch;
                }
            }
        }
        
        
        /** PSG channel gain (*2db) (0=0db, 7=14db, 15=mute) */
        public function get channelGain() : int { return (_channelTL>37) ? 15 : int(_channelTL * 0.375 + 0.5); }
        public function set channelGain(g:int) : void {
            _channelTL = (g>=15) ? 127 : int(g * 2.6666666666666667 + 0.5);
            _opp1.tl = _opp0.tl = _channelTL;
            if (_opp0.ssgec == 0) {
                var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
                for (i=0; i<imax; i++) {
                    ch = _tracks[i].channel as SiOPMChannelFM;
                    if (ch != null) {
                        ch.operator[0].tl = _opp0.tl;
                        ch.operator[1].tl = _opp0.tl;
                    }
                }
            }
        }

        
        /** SSG Envelop control mode, only 8-17 are valiable, 0-7 set as no envelop. The ssgec number of 16th and 17th are the extention of SiOPM. */
        public function get envelopControlMode() : int { return _opp0.ssgec; }
        public function set envelopControlMode(ecm:int) : void {
            if (ecm < 8) { // no envelop
                _opp1.ssgec = _opp0.ssgec = 0;
                _opp1.dr = _opp0.dr = 0;
                _opp1.tl = _opp0.tl = _channelTL;
            } else { // envelop control
                _opp1.ssgec = _opp0.ssgec = ecm;
                _opp1.dr = _opp0.dr = _evelopRate;
                _opp1.tl = _opp0.tl = 0;
            }
            _voiceUpdateNumber++;
        }
        
        
        /** envelop frequency ... currently dishonesty. */
        public function get envelopFreq() : int { return _evelopRate << 2; }
        public function set envelopFreq(ef:int) : void {
            _evelopRate = ef >> 2;
            if (_opp0.ssgec != 0) {
                _opp1.dr = _opp0.dr = _evelopRate;
                _voiceUpdateNumber++;
            }
        }
        
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param channelNumber pseudo channel number.
         */
        function PSGSynth(channelNumber:int = 0)
        {
            super(0, channelNumber);
            _opp0 = _voice.channelParam.operatorParam[0];
            _opp1 = _voice.channelParam.operatorParam[1];
            _voice.channelParam.opeCount = 2;
            _voice.channelParam.alg = 1;
            _opp0.pgType = SiOPMTable.PG_SQUARE;
            _opp0.ptType = SiOPMTable.PT_PSG;
            _opp1.pgType = SiOPMTable.PG_NOISE;
            _opp1.ptType = SiOPMTable.PT_PSG_NOISE;
            _opp1.fixedPitch = 1;
            _opp1.mute = true;
        }
    }
}


