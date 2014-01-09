//----------------------------------------------------------------------------------------------------
// SiON Effect Module
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMStream;
    import org.si.sion.namespaces._sion_internal;
    
    
    /** Effect Module. */
    public class SiEffectModule
    {
    // constant
    //--------------------------------------------------------------------------------
        
        
        
        
    // valiables
    //--------------------------------------------------------------------------------
        private var _module:SiOPMModule;
        private var _freeEffectStreams:Vector.<SiEffectStream>;
        private var _localEffects:Vector.<SiEffectStream>;
        private var _globalEffects:Vector.<SiEffectStream>;
        private var _masterEffect:SiEffectStream;
        private var _globalEffectCount:int;
        static private var _effectorInstances:* = {};
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** Number of global effect */
        public function get globalEffectCount() : int { return _globalEffectCount; }
        
        
        /** effector slot 0 */
        public function set slot0(list:Array) : void { setEffectorList(0, list); }
        
        /** effector slot 1 */
        public function set slot1(list:Array) : void { setEffectorList(1, list); }
        
        /** effector slot 2 */
        public function set slot2(list:Array) : void { setEffectorList(2, list); }
        
        /** effector slot 3 */
        public function set slot3(list:Array) : void { setEffectorList(3, list); }
        
        /** effector slot 4 */
        public function set slot4(list:Array) : void { setEffectorList(4, list); }
        
        /** effector slot 5 */
        public function set slot5(list:Array) : void { setEffectorList(5, list); }
        
        /** effector slot 6 */
        public function set slot6(list:Array) : void { setEffectorList(6, list); }
        
        /** effector slot 7 */
        public function set slot7(list:Array) : void { setEffectorList(7, list); }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** Constructor. */
        function SiEffectModule(module:SiOPMModule) 
        {
            _module = module;
            _freeEffectStreams = new Vector.<SiEffectStream>();
            _localEffects  = new Vector.<SiEffectStream>();
            _globalEffects = new Vector.<SiEffectStream>(SiOPMModule.STREAM_SEND_SIZE, true);
            _masterEffect  = new SiEffectStream(_module, _module.outputStream);
            _globalEffects[0] = _masterEffect;
            _globalEffectCount = 0;

            // initialize table
            var dummy:SiEffectTable = SiEffectTable.instance;
            
            // register default effectors
            register("ws",      SiEffectWaveShaper);
            register("eq",      SiEffectEqualiser);
            register("delay",   SiEffectStereoDelay);
            register("reverb",  SiEffectStereoReverb);
            register("chorus",  SiEffectStereoChorus);
            register("autopan", SiEffectAutoPan);
            register("ds",      SiEffectDownSampler);
            register("speaker", SiEffectSpeakerSimulator);
            register("comp",    SiEffectCompressor);
            register("dist",    SiEffectDistortion);
            register("stereo",  SiEffectStereoExpander);
            register("vowel",   SiFilterVowel);
            
            register("lf", SiFilterLowPass);
            register("hf", SiFilterHighPass);
            register("bf", SiFilterBandPass);
            register("nf", SiFilterNotch);
            register("pf", SiFilterPeak);
            register("af", SiFilterAllPass);
            register("lb", SiFilterLowBoost);
            register("hb", SiFilterHighBoost);
            
            register("nlf", SiCtrlFilterLowPass);
            register("nhf", SiCtrlFilterHighPass);
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Initialize all effectors. This function is called from SiONDriver.play() with the 2nd argment true. 
         *  When you want to connect effectors by code, you have to call this first, then call connect() and SiONDriver.play() with the 2nd argment false.
         */
        public function initialize() : void
        {
            var es:SiEffectStream, i:int;
            
            // local effects
            for each (es in _localEffects) {
                es.free();
                _freeEffectStreams.push(es);
            }
            _localEffects.length = 0;
            
            // global effects
            for (i=1; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                if (_globalEffects[i] != null) {
                    _globalEffects[i].free();
                    _freeEffectStreams.push(_globalEffects[i]);
                    _globalEffects[i] = null;
                }
            }
            _globalEffectCount = 0;
            
            // master effect
            _masterEffect.initialize(0);
            _globalEffects[0] = _masterEffect;
        }
        
        
        /** @private [sion internal] reset all buffers */
        _sion_internal function _reset() : void
        {
            var es:SiEffectStream, i:int;
            
            // local effects
            for each (es in _localEffects) es.reset();
            
            // global effects
            for (i=1; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                if (_globalEffects[i] != null) _globalEffects[i].reset();
            }
            
            // master effect
            _masterEffect.reset();
            _globalEffects[0] = _masterEffect;
        }
        
        
        /** @private [sion internal] prepare for processing. */
        _sion_internal function _prepareProcess() : void
        {
            var slot:int, channelCount:int, slotMax:int = _localEffects.length;
            
            // do nothing on local effect
           
            // global effect (slot1-slot7)
            _globalEffectCount = 0;
            for (slot=1; slot<SiOPMModule.STREAM_SEND_SIZE; slot++) {
                _module.streamSlot[slot] = null; // reset module's stream slot
                if (_globalEffects[slot]) {
                    channelCount = _globalEffects[slot].prepareProcess();
                    if (channelCount > 0) {
                        _module.streamSlot[slot] = _globalEffects[slot]._stream;
                        _globalEffectCount++;
                    }
                }
            }
            
            // master effect (slot0)
            _masterEffect.prepareProcess();
        }
        
        
        /** @private [sion internal] Clear output buffer. */
        _sion_internal function _beginProcess() : void
        {
            var slot:int, leLength:int=_localEffects.length;
            
            // local effect
            for (slot=0; slot<leLength; slot++) {
                _localEffects[slot]._stream.clear();
            }
            
            // global effect (slot1-slot7)
            for (slot=1; slot<SiOPMModule.STREAM_SEND_SIZE; slot++) {
                if (_globalEffects[slot]) _globalEffects[slot]._stream.clear();
            }
            
            // do nothing on master effect
        }
        
        
        /** @private [sion internal] processing. */
        _sion_internal function _endProcess() : void
        {
            var i:int, slot:int, leLength:int=_localEffects.length,
                buffer:Vector.<Number>, effect:SiEffectStream, 
                bufferLength:int = _module.bufferLength,
                output:Vector.<Number> = _module.output,
                imax:int = output.length;
            
            // local effect
            for (slot=0; slot<leLength; slot++) {
                _localEffects[slot].process(0, bufferLength);
            }
            
            // global effect (slot1-slot7)
            for (slot=1; slot<SiOPMModule.STREAM_SEND_SIZE; slot++) {
                effect = _globalEffects[slot];
                if (effect) {
                    if (effect._outputDirectly) {
                        effect.process(0, bufferLength, false);
                        buffer = effect._stream.buffer;
                        for (i=0; i<imax; i++) output[i] += buffer[i];
                    } else {
                        effect.process(0, bufferLength, true);
                    }
                }
            }
            
            // master effect (slot0)
            _masterEffect.process(0, bufferLength, false);
        }
        
        
        
        
    // effector instance manager
    //--------------------------------------------------------------------------------
        /** Register effector class
         *  @param name Effector name.
         *  @param cls SiEffectBase based class.
         */
        static public function register(name:String, cls:Class) : void
        {
            _effectorInstances[name] = new EffectorInstances(cls);
        }
        
        
        /** Get effector instance by name 
         *  @param name Effector name in mml.
         */
        static public function getInstance(name:String) : SiEffectBase
        {
            if (!(name in _effectorInstances)) return null;
            
            var effect:SiEffectBase, 
                factory:EffectorInstances = _effectorInstances[name];
            for each (effect in factory._instances) {
                if (effect._isFree) {
                    effect._isFree = false;
                    effect.initialize();
                    return effect;
                }
            }
            effect = new factory._classInstance();
            factory._instances.push(effect);
            
            effect._isFree = false;
            effect.initialize();
            return effect;
        }
        
        
        
        
    // effector connection
    //--------------------------------------------------------------------------------
        /** Clear effector slot. 
         *  @param slot Effector slot number.
         */
        public function clear(slot:int) : void
        {
            if (slot == 0) {
                _masterEffect.initialize(0);
            } else {
                if (_globalEffects[slot] != null) _freeEffectStreams.push(_globalEffects[slot]);
                _globalEffects[slot] = null;
            }
        }
        
        
        /** Get effector list of specifyed slot
         *  @param slot Effector slot number.
         *  @return Vector of Effector list.
         */
        public function getEffectorList(slot:int) : Vector.<SiEffectBase>
        {
            if (_globalEffects[slot] == null) return null;
            return _globalEffects[slot].chain;
        }
        
        
        /** Set effector list of specifyed slot
         *  @param slot Effector slot number.
         *  @param list Effector list to set
         */
        public function setEffectorList(slot:int, list:Array) : void
        {
            var es:SiEffectStream = _globalEffector(slot);
            es.chain = Vector.<SiEffectBase>(list);
            es.prepareProcess();
        }
        

        /** Connect effector to the global/master slot.
         *  @param slot Effector slot number.
         *  @param effector Effector instance.
         */
        public function connect(slot:int, effector:SiEffectBase) : void
        {
            _globalEffector(slot).chain.push(effector);
            effector.prepareProcess();
        }
        
        
        /** Parse MML for global/master effectors
         *  @param slot Effector slot number.
         *  @param mml MML string.
         *  @param postfix Postfix string.
         */
        public function parseMML(slot:int, mml:String, postfix:String) : void
        {
            _globalEffector(slot).parseMML(slot, mml, postfix);
        }
        
        
        /** Create new local effector connector. deeper effectors executes first. */
        public function newLocalEffect(depth:int, list:Vector.<SiEffectBase>) : SiEffectStream
        {
            var inst:SiEffectStream = _allocStream(depth);
            inst.chain = list;
            inst.prepareProcess();
            if (depth == 0) {
                _localEffects.push(inst);
                return inst;
            } else {
                for (var slot:int=_localEffects.length-1; slot>=0; --slot) {
                    if (_localEffects[slot]._depth >= depth) {
                        _localEffects.splice(slot, 0, inst);
                        return inst;
                    }
                }
            }
            _localEffects.unshift(inst);
            return inst;
        }
        
        
        /** Delete local effector connector */
        public function deleteLocalEffect(inst:SiEffectStream) : void
        {
            var i:int = _localEffects.indexOf(inst);
            if (i != -1) _localEffects.splice(i, 1);
            _freeEffectStreams.push(inst);
        }
        
        
        // get and alloc SiEffectStream if its null
        private function _globalEffector(slot:int) : SiEffectStream {
            if (_globalEffects[slot] == null) {
                var es:SiEffectStream = _allocStream(0);
                _globalEffects[slot] = es;
                _module.streamSlot[slot] = es._stream;
                _globalEffectCount++;
            }
            return _globalEffects[slot];
        }
        
        
        
        
    // functory
    //--------------------------------------------------------------------------------
        private function _allocStream(depth:int) : SiEffectStream
        {
            var es:SiEffectStream = _freeEffectStreams.pop() || new SiEffectStream(_module);
            es.initialize(depth);
            return es;
        }
    }
}




import org.si.sion.effector.SiEffectBase;
// effector instance manager
class EffectorInstances
{
    public var _instances:Array = [];
    public var _classInstance:Class;
    
    function EffectorInstances(cls:Class)
    {
        _classInstance = cls;
    }
}


