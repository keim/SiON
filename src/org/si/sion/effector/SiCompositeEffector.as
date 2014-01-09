//----------------------------------------------------------------------------------------------------
// SiON effect basic class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Composite effector class. */
    public class SiCompositeEffector extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        private var _effectorSlot:Vector.<Array> = null;
        private var _buffer:Vector.<Vector.<Number>> = null;
        private var _sendLevel:Vector.<Number> = null;
        private var _mixLevel:Vector.<Number> = null;
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** effector slot 0 */
        public function set slot0(list:Array) : void { _effectorSlot[0] = list; }
        
        /** effector slot 1 */
        public function set slot1(list:Array) : void { _effectorSlot[1] = list; }
        
        /** effector slot 2 */
        public function set slot2(list:Array) : void { _effectorSlot[2] = list; }
        
        /** effector slot 3 */
        public function set slot3(list:Array) : void { _effectorSlot[3] = list; }
        
        /** effector slot 4 */
        public function set slot4(list:Array) : void { _effectorSlot[4] = list; }
        
        /** effector slot 5 */
        public function set slot5(list:Array) : void { _effectorSlot[5] = list; }
        
        /** effector slot 6 */
        public function set slot6(list:Array) : void { _effectorSlot[6] = list; }
        
        /** effector slot 7 */
        public function set slot7(list:Array) : void { _effectorSlot[7] = list; }
        
        /** dry level*/
        public function set dry(n:Number) : void { _sendLevel[0] = n; }
        
        /** master output level */
        public function set masterVolume(n:Number) : void { _mixLevel[0] = n; }
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor. do nothing. */
        function SiCompositeEffector() {
        }
        
        
        
        
    // callback functions
    //------------------------------------------------------------
        /** set effect input/output level of one slot */
        public function setLevel(slotNum:int, inputLevel:Number, outputLevel:Number) : void 
        {
            _sendLevel[slotNum] = inputLevel;
            _mixLevel[slotNum] = outputLevel;
        }
        
        
        /** @private */
        override public function initialize() : void
        {
            _effectorSlot = new Vector.<Array>(8, true);
            _buffer = new Vector.<Vector.<Number>>(8, true);
            _sendLevel = new Vector.<Number>(8, true);
            _mixLevel  = new Vector.<Number>(8, true);
            for (var i:int=0; i<8; i++) {
                _effectorSlot[i] = null;
                _buffer[i] = Vector.<Number>();
                _mixLevel[i] = _sendLevel[i] = 1;
            }
        }
        
        
        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            var i:int, imax:int, slotNum:int, list:Array;
            for (slotNum=0; slotNum<8; slotNum++) {
                if (_effectorSlot[slotNum]) {
                    list = _effectorSlot[slotNum];
                    imax = list.length;
                    for (i=0; i<imax; i++) list[i].prepareProcess();
                }
            }
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            var i:int, j:int, imax:int, slotNum:int, list:Array, str:Vector.<Number>, ch:int, lvl:Number;
            for (slotNum=1; slotNum<8; slotNum++) {
                if (_effectorSlot[slotNum]) {
                    str = _buffer[slotNum];
                    lvl = _sendLevel[slotNum];
                    if (str.length < buffer.length) str.length = buffer.length;
                    for (i=0,j=startIndex; i<length; i++,j++) str[j] = buffer[j] * lvl;
                }
            }
            lvl = _sendLevel[0];
            for (i=0,j=startIndex; i<length; i++,j++) buffer[j] *= lvl;
            for (slotNum=1; slotNum<8; slotNum++) {
                if (_effectorSlot[slotNum]) {
                    ch = channels;
                    list = _effectorSlot[slotNum];
                    imax = list.length;
                    for (i=0; i<imax; i++) ch = list[i].process(ch, str[slotNum], startIndex, length);
                    lvl = _mixLevel[slotNum];
                    for (i=0,j=startIndex; i<length; i++,j++) buffer[j] += str[j] * lvl;
                }
            }
            if (_effectorSlot[0]) {
                list = _effectorSlot[0];
                imax = list.length;
                for (i=0; i<imax; i++) channels = list[i].process(channels, buffer, startIndex, length);
                if (_mixLevel[0] != 1) {
                    lvl = _mixLevel[0];
                    for (i=0,j=startIndex; i<length; i++,j++) buffer[j] *= lvl;
                }

            }

            return channels;
        }
    }
}

