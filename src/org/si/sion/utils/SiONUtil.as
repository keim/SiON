//----------------------------------------------------------------------------------------------------
// SiON Utilities
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    import flash.media.*;
    import flash.utils.ByteArray;
    //import mx.utils.Base64Decoder;
    import org.si.utils.SLLNumber;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMWaveTable;
    
    
    /** Utilities for SiON */
    public class SiONUtil {
    // PCM data transformation (for PCM Data %7)
    //--------------------------------------------------
        /** logarithmical transformation of Sound data. The transformed datas type is Vector.&lt;int&gt;. This data is used for PCM sound module (%7).
         *  @param src The Sound data transforming from. 
         *  @param dst The Vector.&lt;int&gt; instance to put result. You can pass null to create new Vector.&lt;int&gt; inside.
         *  @param dstChannelCount channel count of destination samples. 0 sets same with srcChannelCount
         *  @param sampleMax The maximum sample count to transforme. The length of transformed data is limited by this value.
         *  @param startPosition Start position to extract. -1 to set extraction continuously.
         *  @param maximize maximize input sample
         *  @return logarithmical transformed data.
         */
        static public function logTrans(data:Sound, dst:Vector.<int>=null, dstChannelCount:int=2, sampleMax:int=1048576, startPosition:int=0, maximize:Boolean=true) : Vector.<int>
        {
            var wave:ByteArray = new ByteArray();
            var samples:int = data.extract(wave, sampleMax, startPosition);
            return logTransByteArray(wave, dst, dstChannelCount, maximize);
        }
        
        
        /** logarithmical transformation of Vector.&lt;Number&gt; wave data. The transformed datas type is Vector.&lt;int&gt;. This data is used for PCM sound module (%7).
         *  @param src The Vector.&lt;Number&gt; wave data transforming from. This ussualy comes from SiONDriver.render().
         *  @param srcChannelCount channel count of source samples.
         *  @param dst The Vector.&lt;int&gt; instance to put result. You can pass null to create new Vector.&lt;int&gt; inside.
         *  @param dstChannelCount channel count of destination samples. 0 sets same with srcChannelCount
         *  @return logarithmical transformed data.
         */
        static public function logTransVector(src:Vector.<Number>, srcChannelCount:int=2, dst:Vector.<int>=null, dstChannelCount:int=0, maximize:Boolean=true) : Vector.<int>
        {
            var i:int, j:int, n:Number, imax:int, logmax:int = SiOPMTable.LOG_TABLE_BOTTOM;
            if (dst == null) dst = new Vector.<int>();
            if (srcChannelCount == dstChannelCount || dstChannelCount == 0) {
                imax = src.length;
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = SiOPMTable.calcLogTableIndex(src[i]);
                    if (dst[i] < logmax) logmax = dst[i];
                }
            } else
            if (srcChannelCount == 2) { // dstChannelCount = 1
                imax = src.length>>1;
                dst.length = imax;
                for (i=0, j=0; i<imax; i++) {
                    n =  src[j]; j++;
                    n += src[j]; j++;
                    dst[i] = SiOPMTable.calcLogTableIndex(n*0.5);
                    if (dst[i] < logmax) logmax = dst[i];
                }
            } else { // srcChannelCount=1 > dstChannelCount=2
                imax = src.length;
                dst.length = imax<<1;
                for (i=0, j=0; i<imax; i++, j+=2) {
                    dst[j+1] = dst[j] = SiOPMTable.calcLogTableIndex(src[i]);
                    if (dst[j] < logmax) logmax = dst[j];
                }
            }
            if (maximize && logmax > 1) _amplifyLogData(dst, logmax);
            return dst;
        }
        
        
        /** logarithmical transformation of ByteArray wave data. The transformed datas type is Vector.&lt;int&gt;. This data is used for PCM sound module (%7).
         *  @param src The ByteArray wave data transforming from. This is ussualy from Sound.extract().
         *  @param dst The Vector.&lt;int&gt; instance to put result. You can pass null to create new Vector.&lt;int&gt; inside.
         *  @param dstChannelCount channel count of destination samples. 0 sets same with srcChannelCount
         *  @return logarithmical transformed data.
         */
        static public function logTransByteArray(src:ByteArray, dst:Vector.<int>=null, dstChannelCount:int=2, maximize:Boolean=true) : Vector.<int>
        {
            var i:int, imax:int, logmax:int = SiOPMTable.LOG_TABLE_BOTTOM;
            
            src.position = 0;
            if (dstChannelCount == 2) {
                imax = src.length >> 2;
                if (dst == null) dst = new Vector.<int>();
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = SiOPMTable.calcLogTableIndex(src.readFloat());
                    if (dst[i] < logmax) logmax = dst[i];
                }
            } else {
                imax = src.length >> 3;
                if (dst == null) dst = new Vector.<int>();
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = SiOPMTable.calcLogTableIndex((src.readFloat()+src.readFloat())*0.5);
                    if (dst[i] < logmax) logmax = dst[i];
                }
            }
            
            if (maximize && logmax > 1) _amplifyLogData(dst, logmax);
            return dst;
        }
        
        
        // amplift log data
        static private function _amplifyLogData(src:Vector.<int>, gain:int) : void
        {
            var i:int, imax:int = src.length;
            gain &= ~1;
            for (i=0; i<imax; i++) src[i] -= gain;
        }
        
        
        
        
        
    // wave data
    //--------------------------------------------------
        /** put Sound.extract() result into Vector.&lt;Number&gt;. This data is used for sampler module (%10).
         *  @param src The Sound data extracting from. 
         *  @param dst The Vector.&lt;Number&gt; instance to put result. You can pass null to create new Vector.&lt;Number&gt; inside.
         *  @param dstChannelCount channel count of extracted data. 1 for monoral, 2 for stereo.
         *  @param length The maximum sample count to extract. The length of returning vector is limited by this value.
         *  @param startPosition Start position to extract. -1 to set extraction continuously.
         *  @return extracted data.
         */
        static public function extract(src:Sound, dst:Vector.<Number>=null, dstChannelCount:int=1, length:int=1048576, startPosition:int=-1) : Vector.<Number>
        {
            var wave:ByteArray = new ByteArray(), i:int, imax:int;
            src.extract(wave, length, startPosition);
            if (dst == null) dst = new Vector.<Number>();
            wave.position = 0;
            
            if (dstChannelCount == 2) {
                // stereo
                imax = wave.length >> 2;
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = wave.readFloat();
                }
            } else {
                // monoral
                imax = wave.length >> 3;
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = (wave.readFloat() + wave.readFloat()) * 0.6;
                }
            }
            return dst;
        }
        
        
        /** extract 2a03's DPCM data.<br/>
         * DPCM frequency table = [
         * 0=k14o2e,
         * 1=k18o2f+,
         * 2=k13o2g+,
         * 3=k16o2a,
         * 4=k13o2b,
         * 5=k16o3c+,
         * 6=k17o3d+,
         * 7=k14o3e,
         * 8=k18o3f+,
         * 9=k16o3a,
         * 10=k20o3b,
         * 11=k7o4c+,
         * 12=k24o4e,
         * 13=k13o4g+,
         * 14=k5o4b,
         * 15=k4o5e]
         *  @param src The DPCM ByteArray data extracting from.
         *  @param initValue initial value of $4011.
         *  @param dst The Vector.&lt;Number&gt; instance to put result. You can pass null to create new Vector.&lt;Number&gt; inside.
         *  @param dstChannelCount channel count of extracted data. 1 for monoral, 2 for stereo.
         *  @return extracted data.
         */
        static public function extractDPCM(src:ByteArray, initValue:int=0, dst:Vector.<Number>=null, dstChannelCount:int=1) : Vector.<Number>
        {
            var data:int, i:int, imax:int, j:int, sample:Number, output:int;
            
            imax = src.length * dstChannelCount * 8;
            if (dst == null) dst = new Vector.<Number>();
            dst.length = imax;
            
            output = initValue;
            src.position = 0;
            for (i=0; i<imax;) {
                data = src.readUnsignedByte();
                for (j=7; j>=0; --j) {
                    if ((data >> j) & 1) if (output<126) output += 2;
                    else                 if (output>1)   output -= 2;
                    sample = (output - 64) * 0.015625;
                    dst[i] = sample; i++;
                    if (dstChannelCount == 2) { dst[i] = sample; i++; }
                }
            }
            
            return dst;
        }
        
        
        /** extract ADPCM data (YM2151). this algorism is from x68ksound.dll's source code.
         *  _freqTable:Array = [26, 31, 38, 43, 50];
         *  @param src The ADPCM ByteArray data extracting from. 
         *  @param dst The Vector.&lt;Number&gt; instance to put result. You can pass null to create new Vector.&lt;Number&gt; inside.
         *  @param dstChannelCount channel count of extracted data. 1 for monoral, 2 for stereo.
         *  @return extracted data.
         */
        static public function extractYM2151ADPCM(src:ByteArray, dst:Vector.<Number>=null, dstChannelCount:int=1) : Vector.<Number>
        {
            var data:int, r:int, i:int, imax:int, pcm:int=0, sample:Number, 
                InpPcm:int=0, InpPcm_prev:int=0, scale:int=0, output:int=0;
        
            // chaging ratio table
            var crTable:Vector.<int> = Vector.<int>([1,3,5,7,9,11,13,15,-1,-3,-5,-7,-9,-11,-13,-15]);
            // from x68ksound.dll source
            var dltLTBL:Vector.<int> = Vector.<int>([ 16, 17, 19, 21, 23, 25, 28, 31,  34, 37, 41, 45, 50, 55, 60, 66,
                                                      73, 80, 88, 97,107,118,130,143, 157,173,190,209,230,253,279,307, 
                                                     337,371,408,449,494,544,598,658, 724,796,876,963,1060,1166,1282,1411,1552]);
            var DCT:Vector.<int> = Vector.<int>([-1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8]);

            imax = src.length * dstChannelCount * 2;
            if (dst == null) dst = new Vector.<Number>();
            dst.length = imax;
            
            for (i=0; i<imax;) {
                data = src.readUnsignedByte();

                r = data & 0x0f;
                pcm += (dltLTBL[scale] * crTable[r]) >> 3;
                scale += DCT[r];
                if (pcm < -2048) pcm = -2048;
                else if (pcm > 2047) pcm = 2047;
                if (scale < 0) scale = 0;
                else if (scale  > 48) scale = 48;
                InpPcm = (pcm & 0xfffffffc) << 8;
                output = ((InpPcm<<9) - (InpPcm_prev<<9) + 459*output) >> 9;
                InpPcm_prev = InpPcm;
                sample = output * 0.0000019073486328125;
                dst[i] = sample; i++;
                if (dstChannelCount == 2) { dst[i] = sample; i++; }
                
                r = (data >> 4) & 0x0f;
                pcm += (dltLTBL[scale] * crTable[r]) >> 3;
                scale += DCT[r];
                if (pcm < -2048) pcm = -2048;
                else if (pcm > 2047) pcm = 2047;
                if (scale < 0) scale = 0;
                else if (scale  > 48) scale = 48;
                InpPcm = (pcm & 0xfffffffc) << 8;
                output = ((InpPcm<<9) - (InpPcm_prev<<9) + 459*output) >> 9;
                InpPcm_prev = InpPcm;
                sample = output * 0.0000019073486328125;
                dst[i] = sample; i++;
                if (dstChannelCount == 2) { dst[i] = sample; i++; }
            }
            
            return dst;
        }
        
        
        /** extract ADPCM data (YM2608)
         *  @param src The ADPCM ByteArray data extracting from. 
         *  @param dst The Vector.&lt;Number&gt; instance to put result. You can pass null to create new Vector.&lt;Number&gt; inside.
         *  @param dstChannelCount channel count of extracted data. 1 for monoral, 2 for stereo.
         *  @return extracted data.
         */
        static public function extractYM2608ADPCM(src:ByteArray, dst:Vector.<Number>=null, dstChannelCount:int=1) : Vector.<Number>
        {
            var data:int, r0:int, r1:int, i:int, imax:int, sample:Number, 
                predRate:int = 127, output:int = 0;
        
            // chaging ratio table
            var crTable:Vector.<int> = Vector.<int>([1,3,5,7,9,11,13,15,-1,-3,-5,-7,-9,-11,-13,-15]);
            // prediction updating table
            var puTable:Vector.<int> = Vector.<int>([57,57,57,57,77,102,128,153,57,57,57,57,77,102,128,153]);
            
            imax = src.length * dstChannelCount * 2;
            if (dst == null) dst = new Vector.<Number>();
            dst.length = imax;
            
            for (i=0; i<imax;) {
                data = src.readUnsignedByte();
                r0 = data & 0x0f;
                r1 = (data >> 4) & 0x0f;
                
                predRate *= crTable[r0];
                predRate >>= 3;
                output += predRate;
                sample = output * 0.000030517578125;
                dst[i] = sample; i++;
                if (dstChannelCount == 2) { dst[i] = sample; i++; }
                predRate *= puTable[r0]
                predRate >>= 6;
                if (predRate>0) {
                         if (predRate < 127)   predRate = 127;
                    else if (predRate > 24576) predRate = 24576;
                } else {
                         if (predRate > -127)   predRate = -127;
                    else if (predRate < -24576) predRate = -24576;
                }
                
                predRate *= crTable[r1];
                predRate >>= 3;
                output += predRate;
                sample = output * 0.000030517578125;
                dst[i] = sample; i++;
                if (dstChannelCount == 2) { dst[i] = sample; i++; }
                predRate *= puTable[r1];
                predRate >>= 6;
                if (predRate>0) {
                         if (predRate < 127)   predRate = 127;
                    else if (predRate > 24576) predRate = 24576;
                } else {
                         if (predRate > -127)   predRate = -127;
                    else if (predRate < -24576) predRate = -24576;
                }
            }
            
            for (i=0; i<imax; i++) {
                if (dst[i] < -1) dst[i] = -1;
                else if (dst[i] > 1) dst[i] = 1;
            }
            
            return dst;
        }
        
        
        
        
    // calculation
    //--------------------------------------------------
        /** Calculate sample length from 16th beat. 
         *  @param bpm Beat per minuits.
         *  @param beat16 Count of 16th beat.
         *  @return sample length.
         */
        static public function calcSampleLength(bpm:Number, beat16:Number=4) : Number
        {
            // 661500 = 44100*60/4
            return beat16 * 661500 / bpm;
        }
        
        
        
        /** Check silent length at the head of Sound.
         *  @param src source Sound
         *  @param rmsThreshold threshold level to detect sound.
         *  @return silent length in sample count.
         */
        static public function getHeadSilence(src:Sound, rmsThreshold:Number = 0.01) : int
        {
            var wave:ByteArray = new ByteArray(), i:int, imax:int, extracted:int, l:Number, r:Number, ms:Number, sp:int=0;
            var msWindow:SLLNumber = SLLNumber.allocRing(22); // 0.5ms
            
            rmsThreshold *= rmsThreshold;
            rmsThreshold *= 22;
            
            imax = 1152;
            ms = 0;
            for (extracted=0; imax==1152; extracted+=1152) {
                wave.length = 0;
                imax = src.extract(wave, 1152, sp);
                wave.position = 0;
                for (i=0; i<imax; i++) {
                    l = wave.readFloat();
                    r = wave.readFloat();
                    ms -= msWindow.n
                    msWindow = msWindow.next;
                    msWindow.n = l * l + r * r;
                    ms += msWindow.n;
                    if (ms >= rmsThreshold) return extracted + i - 22;
                }
                sp = -1;
            }
            
            SLLNumber.freeRing(msWindow);
            
            return extracted;
        }
        
        
        /** Get end gap of Sound
         *  @param src source Sound
         *  @param rmsThreshold threshold level to detect sound.
         *  @param maxLength maximum length to search [sample count]. ussually mp3's end gap is less than 1152.
         *  @return silent length in sample count.
         */
        static public function getEndGap(src:Sound, rmsThreshold:Number=0.01, maxLength:int=1152) : int
        {
            var wave:ByteArray = new ByteArray(), ms:Vector.<Number> = new Vector.<Number>(1152),
                i:int, imax:int, extracted:int, l:Number, r:Number, sp:int;
            
            rmsThreshold *= rmsThreshold;
            sp = int(src.length * 44.1) - 1152;
            
            for (extracted=0; extracted<maxLength; extracted+=imax) {
                imax = src.extract(wave, 1152, sp);
                wave.position = 0;
                for (i=0; i<imax; i++) {
                    l = wave.readFloat();
                    r = wave.readFloat();
                    ms[i] = l * l + r * r;
                }
                for (i=imax-1; i>=0; --i) {
                    if (ms[i] >= rmsThreshold) {
                        extracted += i;
                        trace(extracted);
                        return (extracted < maxLength) ? extracted : maxLength;
                    }
                }
                sp -= 1152;
                if (sp < 0) break;
            }
            
            return maxLength;
        }
        

        /** Detect distance[ms] of 2 peaks, [estimated bpm] = 60000/getPeakDistance().
         *  @param sample stereo samples, the length must be grater than 59136*2(stereo).
         *  @return distance[ms] of 2 peaks.
         */
        static public function getPeakDistance(sample:Vector.<Number>) : Number
        {
            var i:int, j:int, k:int, idx:int, n:Number, m:Number, envAccum:Number;
            
            // 461.9375 = 59128/128, 59128 = length for 2 beats on bpm=89.5
            if (!_envelop) _envelop = new Vector.<Number>(462);
            if (!_xcorr)   _xcorr   = new Vector.<Number>(113);

            // calculate envelop
            m = envAccum = 0;
            for (i=0, idx=0; i<462; i++) {
                for (n=0, j=0; j<128; j++, idx+=2) n += sample[idx];
                m += n;
                envAccum *= 0.875;
                envAccum += m * m;
                _envelop[i] = envAccum;
                m = n;
            }
            
            // calculate cross correlation and find peak index
            for (i=0, idx=0; i<113; i++) {
                for (n=0, j=0, k=113+i; j<226; j++, k++) n += _envelop[j]*_envelop[k];
                _xcorr[i] = n;
                if (_xcorr[idx] < n) idx = i;
            }
            
            // caluclate bpm 2.9024943310657596 = 128/44.1
            return (113 + idx) * 2.9024943310657596;
        }
        static private var _envelop:Vector.<Number> = null;
        static private var _xcorr:Vector.<Number> = null;
        
        
        
        
    // wave table
    //--------------------------------------------------
        /** create Wave table Vector from wave color.
         *  @param color wave color value
         *  @param waveType wave type (the voice number of '%5')
         *  @param dst returning Vector.&lt;Number&gt;. if null, allocate new Vector inside.
         */
        static public function waveColor(color:uint, waveType:int=0, dst:Vector.<Number>=null) : Vector.<Number>
        {
            if (dst == null) dst = new Vector.<Number>(SiOPMTable.SAMPLING_TABLE_SIZE);
            var len:int, bits:int=0;
            for (len=dst.length>>1; len!=0; len>>=1) bits++;
            dst.length = 1<<bits;
            bits = SiOPMTable.PHASE_BITS - bits;
            
            var i:int, imax:int, j:int, gain:int, mul:int, n:Number, nmax:Number, 
                bars:Vector.<Number> = new Vector.<Number>(7),
                barr:Vector.<int> = Vector.<int>([1,2,3,4,5,6,8]),
                log:Vector.<int> = SiOPMTable.instance.logTable,
                waveTable:SiOPMWaveTable = SiOPMTable.instance.getWaveTable(waveType + (color>>>28)),
                wavelet:Vector.<int> = waveTable.wavelet, fixedBits:int = waveTable.fixedBits,
                filter:int = SiOPMTable.PHASE_FILTER, envtop:int = (-SiOPMTable.ENV_TOP)<<3,
                index:int, step:int = SiOPMTable.PHASE_MAX >> bits;
            
            for (i=0; i<7; i++, color>>=4) bars[i] = (color & 15) * 0.0625;

            imax = SiOPMTable.PHASE_MAX;
            nmax = 0;
            
            for (i=0; i<imax; i+=step) {
                j = i>>bits;
                dst[j] = 0;
                for (mul=0; mul<7; mul++) {
                    index = (((i * barr[mul]) & filter) >> fixedBits);
                    gain = wavelet[index] + envtop;
                    dst[j] += log[gain] * bars[mul];
                }
                n = (dst[j]<0) ? -dst[j] : dst[j];
                if (nmax < n) nmax = n;
            }

            if (nmax < 8192) nmax = 8192
            n = 1/nmax;
            imax = dst.length;
            for (i=0; i<imax; i++) dst[i] *= n;
            return dst;
        }
    }
}

