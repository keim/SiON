//----------------------------------------------------------------------------------------------------
// Stream buffer class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.utils.ByteArray;
    import org.si.utils.SLLint;
    
    
    /** Stream buffer class */
    public class SiOPMStream {
        // valiables
        //--------------------------------------------------
        /** number of channels */
        public var channels:int = 2;
        /** stream buffer */
        public var buffer:Vector.<Number> = new Vector.<Number>();

        // coefficient of volume/panning
        private var _panTable:Vector.<Number>;
        private var _i2n:Number;

        
        
        
        // constructor
        //--------------------------------------------------
        /** constructor */
        function SiOPMStream()
        {
            var st:SiOPMTable = SiOPMTable.instance;
            _panTable = st.panTable;
            _i2n = st.i2n;
        }
        
        
        
        
        // operation
        //--------------------------------------------------
        /** clear buffer */
        public function clear() : void
        {
            var i:int, imax:int = buffer.length;
            for (i=0; i<imax; i++) {
                buffer[i] = 0;
            }
        }
        
        
        /** limit buffered signals between -1 and 1 */
        public function limit() : void
        {
            var n:Number, i:int, imax:int = buffer.length;
            for (i=0; i<imax; i++) {
                n = buffer[i];
                     if (n < -1) buffer[i] = -1;
                else if (n >  1) buffer[i] =  1;
            }
        }
        
        
        /** Quantize buffer by bit rate. */
        public function quantize(bitRate:int) : void
        {
            var i:int, imax:int = buffer.length,
                r:Number = 1<<bitRate, ir:Number = 2/r;
            for (i=0; i<imax; i++) {
                buffer[i] = ((buffer[i] * r) >> 1) * ir;
            }
        }
        
        
        /** write buffer by org.si.utils.SLLint */
        public function write(pointer:SLLint, start:int, len:int, vol:Number, pan:int) : void 
        {
            var i:int, n:Number, imax:int = (start + len)<<1;
            vol *= _i2n;
            if (channels == 2) {
                // stereo
                var volL:Number = _panTable[128-pan] * vol,
                    volR:Number = _panTable[pan] * vol;
                for (i=start<<1; i<imax;) {
                    n = Number(pointer.i);
                    buffer[i] += n * volL;  i++;
                    buffer[i] += n * volR;  i++;
                    pointer = pointer.next;
                }
            } else 
            if (channels == 1) {
                // monoral
                for (i=start<<1; i<imax;) {
                    n = Number(pointer.i) * vol;
                    buffer[i] += n; i++;
                    buffer[i] += n; i++;
                    pointer = pointer.next;
                }
            }
        }
        
        
        /** write stereo buffer by 2 pipes */
        public function writeStereo(pointerL:SLLint, pointerR:SLLint, start:int, len:int, vol:Number, pan:int) : void 
        {
            var i:int, n:Number, imax:int = (start + len)<<1;
            vol *= _i2n;

            if (channels == 2) {
                // stereo
                var volL:Number = _panTable[128-pan] * vol,
                    volR:Number = _panTable[pan] * vol;
                for (i=start<<1; i<imax;) {
                    buffer[i] += Number(pointerL.i) * volL;  i++;
                    buffer[i] += Number(pointerR.i) * volR;  i++;
                    pointerL = pointerL.next;
                    pointerR = pointerR.next;
                }
            } else 
            if (channels == 1) {
                // monoral
                vol *= 0.5;
                for (i=start<<1; i<imax;) {
                    n = Number(pointerL.i + pointerR.i) * vol;
                    buffer[i] += n; i++;
                    buffer[i] += n; i++;
                    pointerL = pointerL.next;
                    pointerR = pointerR.next;
                }
            }
        }
        
        
        /** write buffer by Vector.&lt;Number&gt; */
        public function writeVectorNumber(pointer:Vector.<Number>, startPointer:int, startBuffer:int, len:int, vol:Number, pan:int, sampleChannelCount:int) : void
        {
            var i:int, j:int, n:Number, jmax:int, volL:Number, volR:Number;
            
            if (channels == 2) {
                if (sampleChannelCount == 2) {
                    // stereo data to stereo buffer
                    volL = _panTable[128-pan] * vol;
                    volR = _panTable[pan]     * vol;
                    jmax = (startPointer + len)<<1;
                    for (j=startPointer<<1, i=startBuffer<<1; j<jmax;) {
                        buffer[i] += pointer[j] * volL; j++; i++;
                        buffer[i] += pointer[j] * volR; j++; i++;
                    }
                } else {
                    // monoral data to stereo buffer
                    volL = _panTable[128-pan] * vol * 0.707;
                    volR = _panTable[pan]     * vol * 0.707;
                    jmax = startPointer + len;
                    for (j=startPointer, i=startBuffer<<1; j<jmax; j++) {
                        n = pointer[j];
                        buffer[i] += n * volL;  i++;
                        buffer[i] += n * volR;  i++;
                    }
                }
            } else 
            if (channels == 1) {
                if (sampleChannelCount == 2) {
                    // stereo data to monoral buffer
                    jmax = (startPointer + len)<<1;
                    vol  *= 0.5;
                    for (j=startPointer<<1, i=startBuffer<<1; j<jmax;) {
                        n  = pointer[j]; j++;
                        n += pointer[j]; j++;
                        n *= vol;
                        buffer[i] += n; i++;
                        buffer[i] += n; i++;
                    }
                } else {
                    // monoral data to monoral buffer
                    jmax = startPointer + len;
                    for (j=startPointer, i=startBuffer<<1; j<jmax; j++) {
                        n = pointer[j] * vol;
                        buffer[i] += n; i++;
                        buffer[i] += n; i++;
                    }
                }
            }
        }
        
        
        /** write buffer by ByteArray (stereo only). */
        public function writeByteArray(bytes:ByteArray, start:int, len:int, vol:Number) : void
        {
            var i:int, n:Number, imax:int = (start + len)<<1;
            var initPosition:int = bytes.position;

            if (channels == 2) {
                for (i=start<<1; i<imax; i++) {
                    buffer[i] += bytes.readFloat() * vol;
                }
            } else 
            if (channels == 1) {
                // stereo data to monoral buffer
                vol  *= 0.6;
                for (i=start<<1; i<imax;) {
                    n = (bytes.readFloat() + bytes.readFloat()) * vol;
                    buffer[i] += n; i++;
                    buffer[i] += n; i++;
                }
            }
            
            bytes.position = initPosition;
        }
    }
}

