//----------------------------------------------------------------------------------------------------
// SiON sound font loader
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.utils.soundfont {
    import flash.media.Sound;
    import org.si.sion.namespaces._sion_internal;
    import org.si.sion.*;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.*;
    
    
    /** SiON Sound font class. */
    public class SiONSoundFont
    {
    // variables
    //--------------------------------------------------
        /** all loaded Sound instances, access them by id */
        public var sounds:*;
        
        /** all SiMMLEnvelopTable instances */
        public var envelopes:Vector.<SiMMLEnvelopTable> = new Vector.<SiMMLEnvelopTable>(SiMMLTable.ENV_TABLE_MAX, true);
        
        /** all SiOPMWaveTable inetances */
        public var waveTables:Vector.<SiOPMWaveTable> = new Vector.<SiOPMWaveTable>(SiOPMTable.WAVE_TABLE_MAX, true);
        
        /** all fm voice instances */
        public var fmVoices:Vector.<SiONVoice> = new Vector.<SiONVoice>(SiMMLTable.VOICE_MAX, true);
        
        /** all pcm voice instances */
        public var pcmVoices:Vector.<SiONVoice> = new Vector.<SiONVoice>(SiOPMTable.PCM_DATA_MAX, true);
        
        /** all sampler table instances */
        public var samplerTables:Vector.<SiOPMWaveSamplerTable> = new Vector.<SiOPMWaveSamplerTable>(SiOPMTable.SAMPLER_TABLE_MAX, true);
        
        /** default FPS */
        public var defaultFPS:Number = 60;
        /** default velocity mode */
        public var defaultVelocityMode:int = 0;
        /** default expression mode */
        public var defaultExpressionMode:int = 0;
        /** default v command shoft */
        public var defaultVCommandShift:int = 4;
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        public function SiONSoundFont(sounds:* = null)
        {
            this.sounds = sounds || {};
        }
        
        
        /** apply sound font to SiONData or SiONDriver.
         *  @param data SiONData to apply this font. null to set SiONDriver.
         *  @param pcmVoiceOffset index offset for pcmVoices
         *  @param samplerTableOffset index offset for samplerTable
         *  @param fmVoiceOffset index offset for fmVoices
         *  @param waveTableOffset index offset for waveTables
         *  @param envelopeOffset index offset for envelopes
         */
        public function apply(data:SiONData = null, pcmVoiceOffset:int = 0, samplerTableOffset:int = 0, fmVoiceOffset:int = 0, waveTableOffset:int = 0, envelopeOffset:int = 0) : void
        {
            var i:int;
            if (data) {
                for (i=0; i<pcmVoices.length;     i++) if (pcmVoices[i])     data.pcmVoices    [pcmVoiceOffset    +i] = pcmVoices[i];
                for (i=0; i<samplerTables.length; i++) if (samplerTables[i]) data.samplerTables[samplerTableOffset+i] = samplerTables[i];
                for (i=0; i<fmVoices.length;      i++) if (fmVoices[i])      data.fmVoices     [fmVoiceOffset     +i] = fmVoices[i];
                for (i=0; i<waveTables.length;    i++) if (waveTables[i])    data.waveTables   [waveTableOffset   +i] = waveTables[i];
                for (i=0; i<envelopes.length;     i++) if (envelopes[i])     data.envelopes    [envelopeOffset    +i] = envelopes[i];
                data.defaultFPS = defaultFPS;
                data.defaultVelocityMode = defaultVelocityMode;
                data.defaultExpressionMode = defaultExpressionMode;
                data.defaultVCommandShift = defaultVCommandShift;
            } else {
                var driver:SiONDriver = SiONDriver.mutex;
                if (driver) {
                    for (i=0; i<pcmVoices.length;     i++) if (pcmVoices[i])     driver.setPCMVoice(pcmVoiceOffset+i, pcmVoices[i]);
                    for (i=0; i<samplerTables.length; i++) if (samplerTables[i]) driver.setSamplerTable(samplerTableOffset+i, samplerTables[i]);
                    for (i=0; i<fmVoices.length;      i++) if (fmVoices[i])      driver.setVoice(fmVoiceOffset+i, fmVoices[i]);
                    for (i=0; i<waveTables.length;    i++) {
                        if (waveTables[i]) {
                            SiOPMTable._instance._sion_internal::registerWaveTable(waveTableOffset+i, new SiOPMWaveTable().copyFrom(waveTables[i]));
                        }
                    }
                    for (i=0; i<envelopes.length; i++) {
                        if (envelopes[i]) {
                            SiMMLTable.registerMasterEnvelopTable(envelopeOffset+i, new SiMMLEnvelopTable().copyFrom(envelopes[i]));
                        }
                    }
                }
            }
        }
    }
}

