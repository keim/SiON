// Basic Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    
    
    /** Basic Synthesizer */
    public class BasicSynth extends VoiceReference
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** tracks to control */
        protected var _tracks:Vector.<SiMMLTrack>;
        
        
        
        
    // properties
    //----------------------------------------
        /** @private */
        override public function set voice(v:SiONVoice) : void {
            _voice.copyFrom(v); // copy from passed voice
            _voiceUpdateNumber++;
        }
        
        
        /** low-pass filter cutoff(0-1). */
        public function get cutoff() : Number { return _voice.channelParam.cutoff * 0.0078125; }
        public function set cutoff(c:Number) : void {
            var i:int, imax:int = _tracks.length, p:SiOPMChannelParam = _voice.channelParam;
            p.cutoff = (c<=0) ? 0 : (c>=1) ? 128 : int(c*128);
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setSVFilter(p.cutoff, p.resonance, p.far, p.fdr1, p.fdr2, p.frr, p.fdc1, p.fdc2, p.fsc, p.frc);
            }
        }
        
        
        /** low-pass filter resonance(0-1). */
        public function get resonance() : Number { return _voice.channelParam.resonance * 0.1111111111111111; }
        public function set resonance(r:Number) : void {
            var i:int, imax:int = _tracks.length, p:SiOPMChannelParam = _voice.channelParam;
            p.resonance = (r<=0) ? 0 : (r>=1) ? 9 : int(r*9);
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setSVFilter(p.cutoff, p.resonance, p.far, p.fdr1, p.fdr2, p.frr, p.fdc1, p.fdc2, p.fsc, p.frc);
            }
        }
        
        
        /** filter type (0:lowpass, 1:bandpass, 2:highpass) */
        public function get filterType() : int { return _voice.channelParam.filterType; }
        public function set filterType(t:int) : void {
            var i:int, imax:int = _tracks.length;
            _voice.channelParam.filterType = t;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.filterType = t;
            }
        }
        
        
        
        /** modulation (low-frequency oscillator) wave shape, 0=saw, 1=square, 2=triangle, 3=random. */
        public function get lfoWaveShape() : int { return _voice.channelParam.lfoWaveShape; }
        public function set lfoWaveShape(type:int) : void {
            _voice.channelParam.lfoWaveShape = type;
            _voiceUpdateNumber++;
        }
        
        /** modulation (low-frequency oscillator) cycle frames. */
        public function get lfoCycleFrames() : int { return _voice.channelParam.lfoFrame; }
        public function set lfoCycleFrames(frame:int) : void {
            _voice.channelParam.lfoFrame = frame;
            var i:int, imax:int = _tracks.length, ms:Number = frame*1000/60;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setLFOCycleTime(ms);
            }
        }
        
        /** amplitude modulation. */
        public function get amplitudeModulation() : int { return _voice.amDepth; }
        public function set amplitudeModulation(m:int) : void {
            _voice.channelParam.amd = _voice.amDepth = m;
            var i:int, imax:int = _tracks.length;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setAmplitudeModulation(m);
            }
        }
        
        
        /** pitch modulation. */
        public function get pitchModulation() : int { return _voice.pmDepth; }
        public function set pitchModulation(m:int) : void {
            _voice.channelParam.pmd = _voice.pmDepth = m;
            var i:int, imax:int = _tracks.length;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setPitchModulation(m);
            }
        }
        
        
        /** attack rate (0-1), lower value makes attack slow. */
        public function get attackTime() : Number { 
            var iar:int = _voice.channelParam.operatorParam[_voice.channelParam.opeCount-1].ar;
            return  (iar > 48) ? 0 : (1 - iar * 0.020833333333333332); 
        }
        public function set attackTime(n:Number) : void { 
            var flg:int = SiOPMTable.instance.final_oscilator_flags[_voice.channelParam.opeCount][_voice.channelParam.alg];
            var iar:int = (n == 0) ? 63 : ((1 - n) * 48);
            if (flg & 1) _voice.channelParam.operatorParam[0].ar = iar;
            if (flg & 2) _voice.channelParam.operatorParam[1].ar = iar;
            if (flg & 4) _voice.channelParam.operatorParam[2].ar = iar;
            if (flg & 8) _voice.channelParam.operatorParam[3].ar = iar;
            var i:int, imax:int = _tracks.length;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setAllAttackRate(iar);
            }
        }
        
        
        /** release rate (0-1), lower value makes release slow. */
        public function get releaseTime() : Number { 
            var irr:int = _voice.channelParam.operatorParam[_voice.channelParam.opeCount-1].rr;
            return  (irr > 48) ? 0 : (1 - irr * 0.020833333333333332); 
        }
        public function set releaseTime(n:Number) : void { 
            var flg:int = SiOPMTable.instance.final_oscilator_flags[_voice.channelParam.opeCount][_voice.channelParam.alg];
            var irr:int = (n == 0) ? 63 : ((1 - n) * 48);
            if (flg & 1) _voice.channelParam.operatorParam[0].rr = irr;
            if (flg & 2) _voice.channelParam.operatorParam[1].rr = irr;
            if (flg & 4) _voice.channelParam.operatorParam[2].rr = irr;
            if (flg & 8) _voice.channelParam.operatorParam[3].rr = irr;
            var i:int, imax:int = _tracks.length;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setAllReleaseRate(irr);
            }
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor.
         *  @param moduleType Module type. 1st argument of '%'.
         *  @param channelNum Channel number. 2nd argument of '%'.
         *  @param ar Attack rate (0-63).
         *  @param rr Release rate (0-63).
         *  @param dt pitchShift (64=1halftone).
         */
        function BasicSynth(moduleType:int=5, channelNum:int=0, ar:int=63, rr:int=63, dt:int=0)
        {
            _voice = new SiONVoice(moduleType, channelNum, ar, rr, dt);
            _tracks = new Vector.<SiMMLTrack>();
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** set filter envelop (same as '&#64;f' command in MML).
         *  @param cutoff LP filter cutoff (0-1)
         *  @param resonance LP filter resonance (0-1)
         *  @param far LP filter attack rate (0-63)
         *  @param fdr1 LP filter decay rate 1 (0-63)
         *  @param fdr2 LP filter decay rate 2 (0-63)
         *  @param frr LP filter release rate (0-63)
         *  @param fdc1 LP filter decay cutoff 1 (0-1)
         *  @param fdc2 LP filter decay cutoff 2 (0-1)
         *  @param fsc LP filter sustain cutoff (0-1)
         *  @param frc LP filter release cutoff (0-1)
         */
        public function setFilterEnvelop(filterType:int=0, cutoff:Number=1, resonance:Number=0, far:int=0, fdr1:int=0, fdr2:int=0, frr:int=0, fdc1:Number=1, fdc2:Number=0.5, fsc:Number=0.25, frc:Number=1) : void
        {
            _voice.setFilterEnvelop(filterType, cutoff*128, resonance*9, far, fdr1, fdr2, frr, fdc1*128, fdc2*128, fsc*128, frc*128);
            _voiceUpdateNumber++;
        }
        
        
        /** [Please use setFilterEnvelop instead of this function]. This function is for compatibility of old versions.
         *  @param cutoff LP filter cutoff (0-1)
         *  @param resonance LP filter resonance (0-1)
         *  @param far LP filter attack rate (0-63)
         *  @param fdr1 LP filter decay rate 1 (0-63)
         *  @param fdr2 LP filter decay rate 2 (0-63)
         *  @param frr LP filter release rate (0-63)
         *  @param fdc1 LP filter decay cutoff 1 (0-1)
         *  @param fdc2 LP filter decay cutoff 2 (0-1)
         *  @param fsc LP filter sustain cutoff (0-1)
         *  @param frc LP filter release cutoff (0-1)
         */
        public function setLPFEnvelop(cutoff:Number=1, resonance:Number=0, far:int=0, fdr1:int=0, fdr2:int=0, frr:int=0, fdc1:Number=1, fdc2:Number=0.5, fsc:Number=0.25, frc:Number=1) : void
        {
            setFilterEnvelop(0, cutoff, resonance, far, fdr1, fdr2, frr, fdc1, fdc2, fsc, frc);
        }
        
        
        /** Set amplitude modulation parameters (same as "ma" command in MML).
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         *  @return this instance
         */
        public function setAmplitudeModulation(depth:int=0, end_depth:int=0, delay:int=0, term:int=0) : void
        {
            _voice.setAmplitudeModulation(depth, end_depth, delay, term);
            _voiceUpdateNumber++;
        }
        
        
        /** Set amplitude modulation parameters (same as "mp" command in MML).
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         *  @return this instance
         */
        public function setPitchModulation(depth:int=0, end_depth:int=0, delay:int=0, term:int=0) : void
        {
            _voice.setPitchModulation(depth, end_depth, delay, term);
            _voiceUpdateNumber++;
        }
        
        
        
        
    // internals
    //----------------------------------------
        /** @private [synthesizer internal] register single track */
        override public function _registerTrack(track:SiMMLTrack) : void
        {
            _tracks.push(track);
        }
        
        
        /** @private [synthesizer internal] register prural tracks */
        override public function _registerTracks(tracks:Vector.<SiMMLTrack>) : void
        {
            var i0:int = _tracks.length, imax:int = tracks.length, i:int;
            _tracks.length = i0 + imax;
            for (i=0; i<imax; i++) _tracks[i0+i] = tracks[i];
        }
        
        
        /** @private [synthesizer internal] unregister tracks */
        override public function _unregisterTracks(firstTrack:SiMMLTrack, count:int=1) : void
        {
            var index:int = _tracks.indexOf(firstTrack);
            if (index >= 0) _tracks.splice(index, count);
        }
    }
}


