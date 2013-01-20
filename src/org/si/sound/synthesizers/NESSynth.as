// Nintendo Entertainment System (Family Computer) Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.utils.SLLint;
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLEnvelopTable;
    import org.si.sound.SoundObject;
    
    
    /** Nintendo Entertainment System (Family Computer) Synthesizer 
     */
    public class NESSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        
        
        
        
    // properties
    //----------------------------------------
        /** APU channel number */
        public function get channelNumber() : int { return _voice.channelNum; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function NESSynth(channelNumber:int = 0)
        {
            super(1, channelNumber);
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** set envelop table 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setEnevlop(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOnAmplitudeEnvelop = _constructEnvelopTable(_voice.noteOnAmplitudeEnvelop, table, loopPoint);
            _voice.noteOnAmplitudeEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        /** set pitch envelop table 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setPitchEnevlop(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOnPitchEnvelop = _constructEnvelopTable(_voice.noteOnPitchEnvelop, table, loopPoint);
            _voice.noteOnPitchEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        /** set note envelop table 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setNoteEnevlop(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOnNoteEnvelop = _constructEnvelopTable(_voice.noteOnNoteEnvelop, table, loopPoint);
            _voice.noteOnNoteEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        /** set tone envelop table 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setToneEnevlop(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOnToneEnvelop = _constructEnvelopTable(_voice.noteOnToneEnvelop, table, loopPoint);
            _voice.noteOnToneEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        /** set envelop table after note off 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setEnevlopNoteOff(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOffAmplitudeEnvelop = _constructEnvelopTable(_voice.noteOffAmplitudeEnvelop, table, loopPoint);
            _voice.noteOffAmplitudeEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        /** set pitch envelop table after note off 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setPitchEnevlopNoteOff(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOffPitchEnvelop = _constructEnvelopTable(_voice.noteOffPitchEnvelop, table, loopPoint);
            _voice.noteOffPitchEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        /** set note envelop table after note off 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setNoteEnevlopNoteOff(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOffNoteEnvelop = _constructEnvelopTable(_voice.noteOffNoteEnvelop, table, loopPoint);
            _voice.noteOffNoteEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        /** set tone envelop table after note off 
         *  @param table envelop table, null sets envelop off.
         *  @param loopPoint index of looping point, -1 sets loop at tail.
         *  @param step envelop changing step, 1 sets 60fps, 2 sets 30fps...
         */
        public function setToneEnevlopNoteOff(table:Array, loopPoint:int=-1, step:int=1) : void 
        {
            _voice.noteOffToneEnvelop = _constructEnvelopTable(_voice.noteOffToneEnvelop, table, loopPoint);
            _voice.noteOffToneEnvelopStep = step;
            _voiceUpdateNumber++;
        }
        
        
        
        
    // private functions
    //--------------------------------------------------
        private function _constructEnvelopTable(env:SiMMLEnvelopTable, table:Array, loopPoint:int) : SiMMLEnvelopTable {
            if (env != null) env.free();
            if (table == null) return null;
            
            var tail:SLLint, head:SLLint, loop:SLLint, i:int, imax:int = table.length;
            head = tail = SLLint.allocList(imax);
            loop = null;
            for (i=0; i<imax-1; i++) {
                if (loopPoint == i) loop = tail;
                tail.i = table[i];
                tail = tail.next;
            }
            tail.i = table[i];
            tail.next = loop;
            
            if (env == null) env = new SiMMLEnvelopTable();
            env.head = head;
            env.tail = tail;
            return env;
        }
    }
}


