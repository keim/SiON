//----------------------------------------------------------------------------------------------------
// MML data class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import org.si.sion.module.SiOPMTable;
    
    
    /** MML data class. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has a"). */
    public class MMLData
    {
    // namespace
    //--------------------------------------------------
        use namespace _sion_sequencer_internal;
        
        
        
        
    // constants
    //--------------------------------------------------
        /** specify tcommand argument by BPM */
        static public const TCOMMAND_BPM:int = 0;
        /** specify tcommand argument by OPNA's TIMERB with 48ticks/beat */
        static public const TCOMMAND_TIMERB:int = 1;
        /** specify tcommand argument by frame count */
        static public const TCOMMAND_FRAME:int = 2;
        
        
        
    // valiables
    //--------------------------------------------------
        /** Sequence group */
        public var sequenceGroup:MMLSequenceGroup;
        /** Global sequence */
        public var globalSequence:MMLSequence;
        
        /** default FPS */
        public var defaultFPS:int;
        /** Title */
        public var title:String;
        /** Author */
        public var author:String;
        /** mode of t command */
        public var tcommandMode:int;
        /** resolution of t command */
        public var tcommandResolution:Number;
        /** default velocity command shift */
        public var defaultVCommandShift:int;
        /** default velocity mode */
        public var defaultVelocityMode:int;
        /** default expression mode */
        public var defaultExpressionMode:int;
        
        /** @private [sion sequencer internal] default BPM of this data */
        _sion_sequencer_internal var _initialBPM:BeatPerMinutes;
        /** @private [sion sequencer internal] system commands that can not be parsed by system */
        _sion_sequencer_internal var _systemCommands:Array;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** sequence count */
        public function get sequenceCount() : int { return sequenceGroup.sequenceCount; }
        
        
        /** Beat per minutes, set 0 when this data depends on driver's BPM. */
        public function set bpm(t:Number) : void {
            _initialBPM = (t>0) ? (new BeatPerMinutes(t, 44100)) : null;
        }
        public function get bpm() : Number {
            return (_initialBPM) ? _initialBPM.bpm : 0;
        }
                
        /** system commands that can not be parsed. Examples are for mml string "#ABC5{def}ghi;".<br/>
         *  the array elements are Object, and it has following properties.<br/>
         *  <ul>
         *  <li>command: command name. this always starts with "#". ex) command = "#ABC"</li>
         *  <li>number:  number after command. ex) number = 5</li>
         *  <li>content: content inside {...}. ex) content = "def"</li>
         *  <li>postfix: number after command. ex) postfix = "ghi"</li>
         *  </ul>
         */
        public function get systemCommands() : Array { return _systemCommands; }
        
        
        /** Get song length by tick count (1920 for wholetone). */
        public function get tickCount() : int { return sequenceGroup.tickCount; }
        
        
        /** does this song have all repeat comand ? */
        public function get hasRepeatAll() : Boolean { return sequenceGroup.hasRepeatAll; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        function MMLData()
        {
            sequenceGroup = new MMLSequenceGroup(this);
            globalSequence = new MMLSequence();
            
            _initialBPM = null;
            tcommandMode = TCOMMAND_BPM;
            tcommandResolution = 1;
            defaultVCommandShift = 4;
            defaultVelocityMode = 0;
            defaultExpressionMode = 0;
            defaultFPS = 60;
            title = "";
            author = "";
            _systemCommands = [];
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Clear all parameters and free all sequence groups. */
        public function clear() : void
        {
            var i:int, imax:int;
            
            sequenceGroup.free();
            globalSequence.free();
            
            _initialBPM = null;
            tcommandMode = TCOMMAND_BPM;
            tcommandResolution = 1;
            defaultVelocityMode = 0;
            defaultExpressionMode = 0;
            defaultFPS = 60;
            title = "";
            author = "";
            _systemCommands.length = 0;
            
            globalSequence.initialize();
        }
        
        
        /** Append new sequence.
         *  @param sequence event list for new sequence. when null, create empty sequence.
         *  @return created sequence
         */
        public function appendNewSequence(sequence:Vector.<MMLEvent> = null) : MMLSequence
        {
            var seq:MMLSequence = sequenceGroup.appendNewSequence();
            if (sequence) seq.fromVector(sequence);
            return seq;
        }
        
        
        /** Get sequence. 
         *  @param index The index of seuence
         */
        public function getSequence(index:int) : MMLSequence
        {
            return sequenceGroup.getSequence(index);
        }
        
        
        /** @private calculate bpm from t command paramater */
        _sion_sequencer_internal function _calcBPMfromTcommand(param:int) : Number
        {
            switch(tcommandMode) {
            case TCOMMAND_BPM:
                return param * tcommandResolution;
            case TCOMMAND_FRAME:
                return (param) ? (tcommandResolution / param) : 120;
            case TCOMMAND_TIMERB:
                return (param>=0 && param<256) ? (tcommandResolution / (256-param)) : 120;
            }
            return 0;
         }
    }
}


