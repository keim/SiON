//----------------------------------------------------------------------------------------------------
// PCM Sample loader/saver
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sion.utils {
    import flash.events.*;
    import flash.utils.ByteArray;
    import org.si.utils.ByteArrayExt;
    //import org.si.sion.module.*;
    
    
    /** PCM sample loader/saver */
    public class PCMSample extends EventDispatcher {
    // variables
    //--------------------------------------------------
        /** You should not change this property into "acid" ! */
        static public var basicInfoChunkID:String = "sinf";
        /** extended chunk for SiON */
        static public var extendedInfoChunkID:String = "SiON";
        
        
        /** flags: 0x01 = oneshot, 0x02 = rootSet, 0x04 = stretch, 0x08 = diskbased */
        public var sampleType:int;    // int
        /** MIDI note number of base frequency */
        public var baseNote:int; // short
        /** beat count */
        public var beatCount:int;    // int
        /** denominator of time signature */
        public var timeSignatureDenominator:int;   // short
        /** number of time signature */
        public var timeSignatureNumber:int;   // short
        /** beat per minutes */
        public var bpm:Number;       // float

        
        /** chunks of wave data */
        protected var _waveDataChunks:* = null;
        /** wave data */
        protected var _waveData:ByteArrayExt = null;
        /** wave data format ID */
        protected var _waveDataFormatID:int;
        /** wave data sample rate */
        protected var _waveDataSampleRate:Number;
        /** wave data bit rate */
        protected var _waveDataBitRate:int;
        /** wave data channel count */
        protected var _waveDataChannels:int;
        
        
        /** converted sample cache */
        protected var _cache:Vector.<Number>;
        /** converted sample cache sample rate */
        protected var _cacheSampleRate:Number;
        /** converted sample cache channel count */
        protected var _cacheChannels:int;
        /** sample rate of output */
        protected var _outputSampleRate:Number;
        /** channel count of output */
        protected var _outputChannels:int;
        /** bit rate of wave file */
        protected var _outputBitRate:int;
        
        
        /** internal wave sample in 44.1kHz Number */
        protected var _samples:Vector.<Number>;
        /** channel count of internal wave sample */
        protected var _channels:int;
        /** sample rate of internal wave sample */
        protected var _sampleRate:int;
        
        
        /** append position */
        protected var _appendPosition:int;
        /** extract position */
        protected var _extractPosition:Number;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** samples in Vector.<Number> with properties of sampleRate and channels. */
        public function get samples() : Vector.<Number> { 
            if (_outputSampleRate == _sampleRate && _outputChannels == _channels) {
//trace("get sample from raw sample");
                return _samples;
            }
            if (_outputSampleRate == _cacheSampleRate && _outputChannels == _cacheChannels) {
//trace("get sample from cache");
                return _cache;
            }
            _cacheChannels = _outputChannels;
            _cacheSampleRate = _outputSampleRate;
            _convertSampleRate(_samples, _channels, _sampleRate, _cache, _cacheChannels, _cacheSampleRate, true);
//trace("get sample with convert");
            return _cache;
        }
        
        /** sample length */
        public function get sampleLength() : int {
            var sampleLength:int = _samples.length >> (_channels - 1);
            return int(sampleLength * _outputSampleRate / _sampleRate);
        }
        
        /** sample rate [Hz] */ 
        public function get sampleRate() : Number { return _outputSampleRate; }
        public function set sampleRate(rate:Number) : void {
            _outputSampleRate = (rate == 0) ? _sampleRate : rate;
        }

        /** channel count, 1 for monoral, 2 for stereo */ 
        public function get channels() : int { return _outputChannels; }
        public function set channels(count:int) : void {
            if (count != 1 && count != 2) throw new Error("channel count of 1 or 2 is only avairable.");
            _outputChannels = count;
        }
        
        /** bit rate, this function is used only for saveWaveByteArray, 8 or 16 is avairable. */ 
        public function get bitRate() : int { return _outputBitRate; }
        public function set bitRate(rate:int) : void {
            if (rate != 8 && rate != 16 && rate != 24 && rate != 32) throw new Error("bitRate of " + rate.toString() + " is not avairable.");
            _outputBitRate = rate;
        }
        
        
        /** chunks of wave file, this property is only available after loadWaveFromByteArray(). */
        public function get waveDataChunks() : * { return _waveDataChunks; }
        
        /** wave sample data of original wave file, this property is only available after loadWaveFromByteArray() or saveWaveAsByteArray(). */
        public function get waveData() : ByteArray { return _waveData; }
        
        /** sample rate of original wave file, this property is only available after loadWaveFromByteArray() or saveWaveAsByteArray(). */
        public function get waveDataSampleRate() : Number { return _waveDataSampleRate; }
        
        /** bit rate of original wave file, this property is only available after loadWaveFromByteArray() or saveWaveAsByteArray(). */
        public function get waveDataBitRate() : int { return _waveDataBitRate; }
        
        /** channel count of original wave file, this property is only available after loadWaveFromByteArray() or saveWaveAsByteArray(). */
        public function get waveDataChannels() : int { return _waveDataChannels; }
        
        
        /** sample rate of internal samples. */
        public function get internalSampleRate() : Number { return _sampleRate; }
        
        /** channel count of internal samples. */
        public function get internalChannels() : int { return _channels; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function PCMSample(channels:int=2, sampleRate:int=44100, samples:Vector.<Number>=null) 
        {
            this._channels = channels;
            this._sampleRate = sampleRate;
            this._samples = samples || new Vector.<Number>();
            this._cache = new Vector.<Number>();
            this._cacheSampleRate = 0;
            this._cacheChannels = 0;
            this._outputSampleRate = _sampleRate;
            this._outputChannels = _channels;
            this._outputBitRate = 16;
            this._waveDataChunks = null;
            this._waveData = null;
            this._waveDataFormatID = 1;
            this._waveDataSampleRate = 0;
            this._waveDataBitRate = 0;
            this._waveDataChannels = 0;
            this._extractPosition = 0;
            this._appendPosition = this._samples.length;
            this.sampleType = 0;
            this.baseNote = 69;
            this.beatCount = 0;
            this.timeSignatureDenominator = 4;
            this.timeSignatureNumber = 4;
            this.bpm = 0;
        }
        
        
        /** @private */
        override public function toString() : String 
        {
            var str:String = "[object PCMSample : ";
            str += "channels=" + _channels.toString();
            str += " / sampleRate=" + _sampleRate.toString();
            str += " / sampleLength=" + sampleLength.toString();
            str += " / baseNote=" + baseNote.toString();
            str += " / beatCount=" + beatCount.toString();
            str += " / bpm=" + bpm.toString();
            str += " / timeSignature=" + timeSignatureNumber.toString()+"/"+timeSignatureDenominator.toString();
            str += "]";
            return str;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** load sample from Vector.<Number> 
         *  @param src source vector of Number.
         *  @param channels channel count of source.
         *  @param sampleRate sample rate of source.
         *  @param linear exchange sampling rate by linear interpolation, set false to use samples nearest by.
         */
        public function loadFromVector(src:Vector.<Number>, srcChannels:int=2, srcSampleRate:Number=44100, linear:Boolean=true) : PCMSample
        {
            _convertSampleRate(src, srcChannels, srcSampleRate, _samples, _channels, _sampleRate, linear);
            return this;
        }
        
        
        /** append samples
         *  @param src buffering source. This should be same format as internalSampleRate and internalChannels
         *  @param sampleCount sample count to append. 0 appends all samples.
         *  @param srcOffset position (in samples) start appending from.
         */
        public function appendSamples(src:Vector.<Number>, sampleCount:int=0, srcOffset:int=0) : PCMSample
        {
            clearCache();
            var i:int=srcOffset * _channels, len:int = sampleCount * _channels, ptr:int, ptrMax:int;
            if ((len == 0) || ((i + len) > src.length)) len = src.length - i;
            ptrMax = _appendPosition + len;
            if (_samples.length < ptrMax) _samples.length = ptrMax;
            for (ptr=_appendPosition; ptr<ptrMax; ptr++, i++) _samples[ptr] = src[i];
            _appendPosition = ptrMax;
            return this;
        }
        
        
        /** append samples from ByteArray float (2ch/44.1kHz), The internal format should be 2ch/44.1kHz.
         *  @param bytes buffering source. The format should be float vector of 2ch/44.1kHz.
         *  @param sampleCount sample count to append. 0 appends all samples.
         */
        public function appendSamplesFromByteArrayFloat(bytes:ByteArray, sampleCount:int=0) : PCMSample
        {
            if (_channels != 2 || _sampleRate != 44100) throw new Error("The internal format should be 2ch/44.1kHz.");
            clearCache();
            var len:int = (bytes.length - bytes.position)>>3, ptr:int, ptrMax:int;
            if (sampleCount != 0 && len > sampleCount) len = sampleCount;
            ptrMax = _appendPosition + len*2;
            if (_samples.length < ptrMax) _samples.length = ptrMax;
            for (ptr=_appendPosition; ptr<ptrMax; ptr++) _samples[ptr] = bytes.readFloat();
            _appendPosition = ptrMax;
            return this;
        }
        
        
        /** extract to Vector.<Number> 
         *  @param dst 
         *  @param length 
         *  @param offset 
         *  @return 
         */
        public function extract(dst:Vector.<Number>=null, length:int=0, offset:int=-1) : Vector.<Number>
        {
            if (offset == -1) offset = _extractPosition;
            if (dst == null) dst = new Vector.<Number>();
            if (length == 0) length = 999999;
            
            var output:Vector.<Number> = this.samples;
            var i:int, imax:int=length*_outputChannels, j:int=offset*_outputChannels;
            if (imax + j > output.length) imax = output.length - j;
            for (i=0; i<imax; i++, j++) dst[i] = output[j];
            
            _extractPosition = j >> (_outputChannels - 1);
            return dst;
        }
        
        
        /** clear cache and waveData */
        public function clearCache() : PCMSample
        {
            _cache.length = 0;
            _cacheSampleRate = 0;
            _cacheChannels = 0;
            return this;
        }
        
        
        /** clear wave data cache */
        public function clearWaveDataCache() : PCMSample 
        {
            _waveDataChunks = null;
            _waveData = null;
            _waveDataFormatID = 1;
            _waveDataSampleRate = 0;
            _waveDataBitRate = 0;
            _waveDataChannels = 0;
            return this;
        }
        
        
        
        
    // wave file operations
    //--------------------------------------------------
        /** load from wave file byteArray.
         *  @param waveFile ByteArray of wave file.
         */
        public function loadWaveFromByteArray(waveFile:ByteArray) : PCMSample
        {
            var bae:ByteArrayExt = waveFile as ByteArrayExt, 
                content:ByteArrayExt = new ByteArrayExt(),
                fileSize:int, header:*, 
                chunkBAE:ByteArrayExt, sliceCount:int, i:int, pos:int;
            if (!bae) bae = new ByteArrayExt(waveFile);
            bae.endian = "littleEndian";
            bae.position = 0;
            header = bae.readChunk(content);
            if (header.chunkID != "RIFF" || header.listType != "WAVE") dispatchEvent(new ErrorEvent("Not good wave file"));
            else {
                fileSize = header.length;
                _waveDataChunks = content.readAllChunks();
                if (!(("fmt " in _waveDataChunks) && ("data" in _waveDataChunks))) dispatchEvent(new ErrorEvent("Not good wave file"));
                else {
                    chunkBAE = _waveDataChunks["fmt "];
                    _waveDataFormatID = chunkBAE.readShort();
                    _waveDataChannels = chunkBAE.readShort();
                    _waveDataSampleRate = chunkBAE.readInt();
                    chunkBAE.readInt();     // no ckeck for bytesPerSecond = _sampleRate*bytesPerSample
                    chunkBAE.readShort();   // no ckeck for bytesPerSample = _bitRate*_channels/8
                    _waveDataBitRate = chunkBAE.readShort();
                    _waveData = _waveDataChunks["data"];
                    
                    if (basicInfoChunkID in _waveDataChunks) {
                        chunkBAE = _waveDataChunks[basicInfoChunkID];
                        sampleType = chunkBAE.readInt();
                        baseNote = chunkBAE.readShort();
                        chunkBAE.readShort();   // _unknown1 = 0x8000
                        chunkBAE.readInt();     // _unknown2 = 0
                        beatCount = chunkBAE.readInt();
                        timeSignatureDenominator = chunkBAE.readShort();
                        timeSignatureNumber = chunkBAE.readShort();
                        bpm = chunkBAE.readFloat();
                    }
                    
                    _updateSampleFromWaveData();
                    dispatchEvent(new Event(Event.COMPLETE));
                }
            }
            return this;
        }
        
        
        /** save wave file as byteArray. 
         *  @return waveFile ByteArray of wave file.
         */
        public function saveWaveAsByteArray() : ByteArray
        {
            var bytesPerSample:int = (_outputBitRate * _outputChannels) >> 3, 
                waveFile:ByteArrayExt = new ByteArrayExt(),
                content:ByteArrayExt = new ByteArrayExt(), 
                fmt:ByteArray = new ByteArray();

            // convert sampling rate, channels and bitrate
            if (_waveDataChannels != _outputChannels || _waveDataSampleRate != _outputSampleRate || _waveDataBitRate != _outputBitRate) {
                _updateWaveDataFromSamples();
            }
            
            // write wave file
            fmt.endian = "littleEndian";
            fmt.writeShort(1);
            fmt.writeShort(_outputChannels);
            fmt.writeInt(_outputSampleRate);
            fmt.writeInt(_outputSampleRate * bytesPerSample);
            fmt.writeShort(bytesPerSample);
            fmt.writeShort(_outputBitRate);
            content.endian = "littleEndian";
            content.writeChunk("fmt ", fmt);
            content.writeChunk("data", _waveData);
            waveFile.endian = "littleEndian";
            waveFile.writeChunk("RIFF", content, "WAVE");
            return waveFile;
        }
        
        
        
        
    // utilities
    //--------------------------------------------------
        /** Try to read mysterious "strc" chunk.
         *  @param strcChunk strc chunk data.
         *  @return positions
         */
        static public function readSTRCChunk(strcChunk:ByteArray) : Array
        {
            if (strcChunk == null) return null;
            var i:int, imax:int, positions:Array = [];
            strcChunk.readInt(); // always 28
            imax = strcChunk.readInt();
            strcChunk.readInt(); // either 25 (0x19) or 65 (0x41)
            strcChunk.readInt(); // either 10 (0x0A) or 5 (0x05) linked to prev data ?
            strcChunk.readInt(); // always 1 (0x01)
            strcChunk.readInt(); // either 0, 1 or 10
            strcChunk.readInt(); // have seen values 2,3,4 and 5
            for (i=0; i<imax; i++) {
                strcChunk.readInt(); // either 0 or 2
                strcChunk.readInt(); // random?
                positions.push(strcChunk.readInt());
                strcChunk.readInt(); // sample position of this slice
                strcChunk.readInt();
                strcChunk.readInt(); // sp2?
                strcChunk.readInt(); // data3
                strcChunk.readInt(); // random?
            }
            return positions;
        }
        
        
        
        
    // privates
    //--------------------------------------------------
        // convert sampling rate and channel count
        private function _convertSampleRate(src:Vector.<Number>, srcch:int, srcsr:Number, dst:Vector.<Number>, dstch:int, dstsr:Number, linear:Boolean) : void
        {
            var flag:int, dstStep:Number = srcsr / dstsr;
            if (dstStep == 1) linear = false;
            
            dst.length = int(src.length * dstch * dstsr / (srcch * srcsr));
//trace("convertSampleRate:", srcch, srcsr, src.length, dstch, dstsr, dst.length);
            
            flag  = (srcch == 2) ? 1 : 0;
            flag |= (dstch == 2) ? 2 : 0;
            flag |= (linear)     ? 4 : 0;
            _lvfunctions[flag](src, dst, dstStep, 0);
        }
        
        private var _lvfunctions:Array = [_lvmmn,_lvsmn,_lvmsn,_lvssn,_lvmml,_lvsml,_lvmsl,_lvssl];
        private function _lvmmn(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length, iptr:int;
            for (i=0; i<imax; i++, ptr+=step) {
                iptr = int(ptr);
                dst[i] = src[iptr];
            }
        }
        private function _lvmsn(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length, iptr:int;
            for (i=0; i<imax; i++, ptr+=step) {
                iptr = int(ptr);
                dst[i] = src[iptr]; i++;
                dst[i] = src[iptr];
            }
        }
        private function _lvsmn(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length, iptr:int, n:Number;
            for (i=0; i<imax; i++, ptr+=step) {
                iptr = (int(ptr)) * 2;
                n = src[iptr];
                iptr++;
                n += src[iptr];
                dst[i] = n * 0.5;
            }
        }
        private function _lvssn(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length, iptr:int;
            for (i=0; i<imax; i++, ptr+=step) {
                iptr = (int(ptr)) * 2;
                dst[i] = src[iptr];
                iptr++;
                i++;
                dst[i] = src[iptr];
            }
        }
        private function _lvmml(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length - 1, istep:Number = 1/step, 
                iptr0:int, iptr1:int = int(ptr), t:Number;
            for (i=0; i<imax; i++) {
                iptr0 = iptr1;
                t = (ptr - iptr0) * istep;
                iptr1 = int(ptr += step);
                dst[i] = src[iptr0] * (1 - t) + src[iptr1] * t;
            }
            dst[imax] = src[iptr1]
        }
        private function _lvmsl(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length - 2, istep:Number = 1/step, 
                iptr0:int, iptr1:int = int(ptr), t:Number, n:Number;
            for (i=0; i<imax; i++) {
                iptr0 = iptr1;
                t = (ptr - iptr0) * istep;
                iptr1 = int(ptr += step);
                n = src[iptr0] * (1 - t) + src[iptr1] * t;
                dst[i] = n; i++;
                dst[i] = n;
            }
            dst[imax] = src[iptr1];
            dst[imax+1] = src[iptr1];
        }
        private function _lvsml(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length - 1, istep:Number = 0.5/step, 
                iptr0:int, iptr1:int = int(ptr), t:Number, n:Number, pl0:int, pl1:int;
            for (i=0; i<imax; i++) {
                iptr0 = iptr1;
                t = (ptr - iptr0) * istep;
                iptr1 = int(ptr += step);
                pl0 = iptr0 * 2;
                pl1 = iptr1 * 2;
                n = src[pl0] * (0.5 - t) + src[pl1] * t;
                pl0++;
                pl1++;
                n += src[pl0] * (0.5 - t) + src[pl1] * t;
                dst[i] = n;
            }
            dst[imax] = (src[pl1] + src[pl1-1]) * 0.5;
        }
        private function _lvssl(src:Vector.<Number>, dst:Vector.<Number>, step:Number, ptr:Number) : void {
            var i:int = 0, imax:int = dst.length - 2, istep:Number = 1/step, 
                iptr0:int, iptr1:int = int(ptr), t:Number, n:Number, pl0:int, pl1:int;
            for (i=0; i<imax; i++) {
                iptr0 = iptr1;
                t = (ptr - iptr0) * istep;
                iptr1 = int(ptr += step);
                pl0 = iptr0 * 2;
                pl1 = iptr1 * 2;
                dst[i] = src[pl0] * (1 - t) + src[pl1] * t;
                pl0++;
                pl1++;
                i++;
                dst[i] = src[pl0] * (1 - t) + src[pl1] * t;
            }
            dst[imax] = src[pl1-1];
            dst[imax+1] = src[pl1];
        }
        
        
        // update samples from wave data
        private function _updateSampleFromWaveData() : void {
//trace("_updateSampleFromWaveData");
            var byteRate:int = _waveDataBitRate>>3;
            if (_waveDataChannels == _channels && _waveDataSampleRate == _sampleRate) {
                _samples.length = _waveData.length / byteRate;
                _w2vfunctions[byteRate-1](_waveData, _samples);
            } else {
                _cache.length = _waveData.length / byteRate;
                _cacheChannels = _waveDataChannels;
                _cacheSampleRate = _waveDataSampleRate;
                _w2vfunctions[byteRate-1](_waveData, _cache);
                _convertSampleRate(_cache, _cacheChannels, _cacheSampleRate, _samples, _channels, _sampleRate, true);
                clearCache();
            }
        }
        
        // convert wave to vector
        private var _w2vfunctions:Array = [_w2v8, _w2v16, _w2v24, _w2v32];
        private function _w2v8(wav:ByteArray, dst:Vector.<Number>) : void {
            var unq:Number = 1 / (1<<(_waveDataBitRate-1)), imax:int = dst.length;
            for (var i:int=0; i<imax; i++) dst[i] = (wav.readUnsignedByte() - 128) * unq;
        }
        private function _w2v16(wav:ByteArray, dst:Vector.<Number>) : void {
            var unq:Number = 1 / (1<<(_waveDataBitRate-1)), imax:int = dst.length;
            for (var i:int=0; i<imax; i++) dst[i] = wav.readShort() * unq;
        }
        private function _w2v24(wav:ByteArray, dst:Vector.<Number>) : void {
            var unq:Number = 1 / (1<<(_waveDataBitRate-1)), imax:int = dst.length;
            for (var i:int=0; i<imax; i++) dst[i] = (_waveData.readByte() + (_waveData.readShort() << 8)) * unq;
        }
        private function _w2v32(wav:ByteArray, dst:Vector.<Number>) : void {
            var unq:Number = 1 / (1<<(_waveDataBitRate-1)), imax:int = dst.length;
            for (var i:int=0; i<imax; i++) dst[i] = _waveData.readInt() * unq;
        }
        
        
        // convert raw data to samples
        private function _updateWaveDataFromSamples() : void 
        {
//trace("_updateWaveDataFromSamples");
            var byteRate:int = _outputBitRate >> 3,
                output:Vector.<Number> = this.samples;
            _waveData = _waveData || new ByteArrayExt();
            _waveDataSampleRate = _outputSampleRate;
            _waveDataBitRate = _outputBitRate;
            _waveDataChannels = _outputChannels;
            
            // initialize
            _waveData.clear();
            _waveData.length = output.length * byteRate;
            _waveData.position = 0;
            
            // convert
            _v2wfunctions[byteRate-1](output, _waveData);
        }
        
        // convert vector tp wave
        private var _v2wfunctions:Array = [_v2w8, _v2w16, _v2w24, _v2w32];
        private function _v2w8(src:Vector.<Number>, wav:ByteArray) : void {
            var qn:Number = (1<<(_waveDataBitRate-1)) - 1, imax:int = src.length;
            for (var i:int=0; i<imax; i++) wav.writeByte(src[i] * qn + 128);
        }
        private function _v2w16(src:Vector.<Number>, wav:ByteArray) : void {
            var qn:Number = (1<<(_waveDataBitRate-1)) - 1, imax:int = src.length;
            for (var i:int=0; i<imax; i++) wav.writeShort(src[i] * qn);
        }
        private function _v2w24(src:Vector.<Number>, wav:ByteArray) : void {
            var n:Number, qn:Number = (1<<(_waveDataBitRate-1)) - 1, imax:int = src.length;
            for (var i:int=0; i<imax; i++) {
                n = src[i] * qn;
                wav.writeByte(n);
                wav.writeShort(n>>8);
            }
        }
        private function _v2w32(src:Vector.<Number>, wav:ByteArray) : void {
            var qn:Number = (1<<(_waveDataBitRate-1)) - 1, imax:int = src.length;
            for (var i:int=0; i<imax; i++) wav.writeInt(src[i] * qn);
        }
    } 
}

