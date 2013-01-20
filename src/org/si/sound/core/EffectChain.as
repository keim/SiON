//----------------------------------------------------------------------------------------------------
// Effector chain class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.core {
    import org.si.sion.*;
    import org.si.sion.effector.*;
    import org.si.sion.module.SiOPMStream;
    import org.si.sound.namespaces._sound_object_internal;
    
    
    /** Effector chain class. This class manages local effector chain of SoundObject. */
    public class EffectChain
    {
    // variables
    //--------------------------------------------------
        /** Stream buffer of local effect */
        protected var _effectStream:SiEffectStream;
        /** Effect list */
        protected var _effectList:Array;
        
        
        
    // properties
    //--------------------------------------------------
        /** Is processing effect ? */
        public function get isActive() : Boolean { return (_effectStream != null); }
        
        
        /** effector list */
        public function get effectList() : Array { return _effectList; }
        public function set effectList(list:Array) : void {
            _effectList = list;
            if (_effectStream) {
                _effectStream.chain = Vector.<SiEffectBase>(_effectList);
            }
        }
        
        
        /** streaming buffer */
        public function get streamingBuffer() : SiOPMStream {
            return (_effectStream) ? _effectStream.stream : null;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** @private constructor, you should not create new EffectChain instance. */
        function EffectChain(...list)
        {
            _effectStream = null;
            _effectList = list || [];
        }

        
        
        
    // operations
    //--------------------------------------------------
        /** @private [internal] activate local effect. deeper effectors executes first. */
        _sound_object_internal function _activateLocalEffect(depth:int) : void
        {
            if (_effectStream) return;
            var driver:SiONDriver = SiONDriver.mutex;
            if (driver) {
                _effectStream = driver.effector.newLocalEffect(depth, Vector.<SiEffectBase>(_effectList));
            }
        }
        
        
        /** @private [internal] inactivate local effect */
        _sound_object_internal function _inactivateLocalEffect() : void
        {
            if (!_effectStream) return;
            var driver:SiONDriver = SiONDriver.mutex;
            if (driver) {
                driver.effector.deleteLocalEffect(_effectStream);
                _effectStream = null;
            }
        }
        
        
        /** set all stream send levels by Vector.&lt;int&gt;(8) (0-128) */
        public function setAllStreamSendLevels(volumes:Vector.<int>) : void
        {
            if (!_effectStream) return;
            _effectStream.setAllStreamSendLevels(volumes);
        }
        
        
        /** set stream send level by Number(0-1) */
        public function setStreamSend(slot:int, volume:Number) : void
        {
            if (!_effectStream) return;
            _effectStream.setStreamSend(slot, volume);
        }
        
        
        /** connect to another chain */
        public function connectTo(ec:EffectChain) : void
        {
            if (!_effectStream) return;
            _effectStream.connectTo(ec.streamingBuffer);
        }
        
        
        
    // factory
    //--------------------------------------------------
        static private var _freeList:Vector.<EffectChain> = new Vector.<EffectChain>();
        
        /** allocate new EffectChain */
        static public function alloc(effectList:Array) : EffectChain
        {
            if (effectList == null || effectList.length == 0) return null;
            var ec:EffectChain = _freeList.pop() || new EffectChain();
            ec.effectList = effectList;
            return ec;
        }
        
        
        /** delete this EffectChain */
        public function free() : void
        {
            effectList = [];
            _freeList.push(this);
        }
    }
}

