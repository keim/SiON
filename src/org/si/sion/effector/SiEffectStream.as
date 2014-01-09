//----------------------------------------------------------------------------------------------------
// SiON Effect serial connector
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMStream;
    
    
    /** SiON Effector stream. */
    public class SiEffectStream
    {
    // valiables
    //--------------------------------------------------------------------------------
        /** effector chain */
        public var chain:Vector.<SiEffectBase> = new Vector.<SiEffectBase>();
        
        /** @private [internal] streaming buffer */
        internal var _stream:SiOPMStream;
        /** @private [internal] depth. deeper stream execute first. */
        internal var _depth:int;
        
        // module
        private var _module:SiOPMModule;
        // panning
        private var _pan:int;
        // has effect send
        private var _hasEffectSend:Boolean;
        // streaming level
        private var _volumes:Vector.<Number> = new Vector.<Number>(SiOPMModule.STREAM_SEND_SIZE);
        // output streams
        private var _outputStreams:Vector.<SiOPMStream> = new Vector.<SiOPMStream>(SiOPMModule.STREAM_SEND_SIZE);
        
        
        
        
    // properties
    //----------------------------------------
        /** stream buffer */
        public function get stream() : SiOPMStream { return _stream; }
        
        
        /** panning of output (-64:L - 0:C - 64:R). */
        public function get pan() : int { return pan-64; }
        public function set pan(p:int) : void {
            _pan = p+64;
            if (_pan < 0) _pan = 0;
            else if (_pan > 128) _pan = 128;
        }
        
        
        /** @private [internal use] flag to write output stream directly */
        internal function get _outputDirectly() : Boolean {
            return (!_hasEffectSend && _volumes[0] == 1 && _pan == 64);
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** Constructor, you should not create new EffectStream, you may call SiEffectModule.newLocalEffect() for these purpose. */
        // the 2nd argument is for MasterEffect to operate master output.
        function SiEffectStream(module:SiOPMModule, stream:SiOPMStream = null) 
        {
            _depth = 0;
            _module = module;
            _stream = stream || new SiOPMStream();
        }
        
        
        
        
    // setting
    //--------------------------------------------------------------------------------
        /** set all stream send levels by Vector.&lt;int&gt;.
         *  @param param Vector.&lt;int&gt;(8) of all volumes[0-128].
         */
        public function setAllStreamSendLevels(param:Vector.<int>) : void
        {
            var i:int, imax:int = SiOPMModule.STREAM_SEND_SIZE, v:int;
            for (i=0; i<imax; i++) {
                v = param[i];
                _volumes[i] = (v != int.MIN_VALUE) ? (v * 0.0078125) : 0;
            }
            for (_hasEffectSend=false, i=1; i<imax; i++) {
                if (_volumes[i] > 0) _hasEffectSend = true;
            }
        }
        
        
        /** set stream send.
         *  @param streamNum stream number[0-7]. The streamNum of 0 means master volume.
         *  @param volume send level[0-1].
         */
        public function setStreamSend(streamNum:int, volume:Number) : void
        {
            _volumes[streamNum] = volume;
            if (streamNum == 0) return;
            if (volume > 0) _hasEffectSend = true;
            else {
                var i:int, imax:int = SiOPMModule.STREAM_SEND_SIZE;
                for (_hasEffectSend=false, i=1; i<imax; i++) {
                    if (_volumes[i] > 0) _hasEffectSend = true;
                }
            }
        }
        

        /** get stream send.
         *  @param streamNum stream number[0-7]. The streamNum of 0 means master volume.
         *  @return send level[0-1].
         */ 
        public function getStreamSend(streamNum:int) : Number
        {
            return _volumes[streamNum];
        }        
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** initialize, called when allocated */
        public function initialize(depth:int) : void
        {
            free();
            reset();
            for (var i:int=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                _volumes[i] = 0;
                _outputStreams[i] = null;
            }
            _volumes[0] = 1;
            _pan = 64;
            _hasEffectSend = false;
            _depth = depth;
        }
        
        
        /** reset all parameters except for effector chain, called when effector module is initialized */
        public function reset() : void
        {
            _stream.buffer.length = _module.bufferLength<<1;
            _stream.clear();
        }
        
        
        /** free all of effector chain, called when effector module is initialized */
        public function free() : void
        {
            for each (var e:SiEffectBase in chain) e._isFree = true;
            chain.length = 0;
        }
        
        
        /** connect to another stream
         *  @param output stream connect to.
         */
        public function connectTo(output:SiOPMStream = null) : void
        {
            _outputStreams[0] = output;
        }
        
        
        /** prepare for process */
        public function prepareProcess() : int
        {
            if (chain.length == 0) return 0;
            _stream.channels = chain[0].prepareProcess();
            for (var i:int=1; i<chain.length; i++) chain[i].prepareProcess();
            return _stream.channels;
        }
        
        
        /** processing */
        public function process(startIndex:int, length:int, writeInStream:Boolean=true) : int
        {
            var i:int, imax:int, effect:SiEffectBase, stream:SiOPMStream,
                buffer:Vector.<Number> = _stream.buffer, channels:int = _stream.channels;
            imax = chain.length;
            for (i=0; i<imax; i++) {
                channels = chain[i].process(channels, buffer, startIndex, length);
            }
            
            // write in stream buffer
            if (writeInStream) {
                if (_hasEffectSend) {
                    for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                        if (_volumes[i]>0) {
                            stream = _outputStreams[i] || _module.streamSlot[i];
                            if (stream) stream.writeVectorNumber(buffer, startIndex, startIndex, length, _volumes[i], _pan, 2);
                        }
                    }
                } else {
                    stream = _outputStreams[0] || _module.outputStream;
                    stream.writeVectorNumber(buffer, startIndex, startIndex, length, _volumes[0], _pan, 2);
                }
            }
            
            return channels;
        }
        
        
        
        
    // effector connection
    //--------------------------------------------------------------------------------
        /** Parse MML for effector 
         *  @param mml MML string.
         *  @param postfix Postfix string.
         */
        public function parseMML(slot:int, mml:String, postfix:String) : void
        {
            var res:*, i:int, cmd:String = "", argc:int = 0, args:Vector.<Number> = new Vector.<Number>(16, true),
                rexMML:RegExp = /([a-zA-Z_]+|,)\s*([.\-\d]+)?/g, 
                rexPost:RegExp = /(p|@p|@v|,)\s*([.\-\d]+)?/g;
                
                
            // clear
            initialize(0);
            _clearArgs();
            
            // parse mml
            res = rexMML.exec(mml);
            while (res) {
                if (res[1] == ",") {
                    args[argc++] = Number(res[2]);
                } else {
                    _connectEffect();
                    _clearArgs();
                    cmd = res[1];
                    args[0] = Number(res[2]);
                    argc = 1;
                }
                res = rexMML.exec(mml);
            }
            _connectEffect();
            _clearArgs();
            
            // parse postfix
            res = rexPost.exec(postfix);
            while (res) {
                if (res[1] == ",") {
                    args[argc++] = Number(res[2]);
                } else {
                    _setVolume();
                    _clearArgs();
                    cmd = res[1];
                    args[0] = Number(res[2]);
                    argc = 1;
                }
                res = rexPost.exec(postfix);
            }
            _setVolume();
            
            // connect new effector
            function _connectEffect() : void {
                if (argc == 0) return;
                var e:SiEffectBase = SiEffectModule.getInstance(cmd);
                if (e) {
                    e.mmlCallback(args);
                    chain.push(e);
                }
            }
            
            // set volumes
            function _setVolume() : void {
                var v:Number, i:int;
                if (argc == 0) return;
                switch (cmd) {
                case 'p':
                    pan = ((int(args[0]))<<4)-64;
                    break;
                case '@p':
                    pan = int(args[0]);
                    break;
                case '@v':
                    v = int(args[0]) * 0.0078125;
                    setStreamSend(0, (v < 0) ? 0 : (v > 1) ? 1 : v);
                    if (argc+slot >= SiOPMModule.STREAM_SEND_SIZE) argc = SiOPMModule.STREAM_SEND_SIZE - slot - 1;
                    for (i = 1; i < argc; i++) {
                        v = int(args[i]) * 0.0078125;
                        setStreamSend(i+slot, (v < 0) ? 0 : (v > 1) ? 1 : v);
                    }
                    break;
                }
            }
            
            // clear arguments
            function _clearArgs() : void {
                for (var i:int=0; i<16; i++) args[i]=Number.NaN;
                argc = 0;
            }
        }
    }
}

