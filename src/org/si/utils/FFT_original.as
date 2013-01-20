//----------------------------------------------------------------------------------------------------
// Fast Fourier Transform module
//  Ported and modified by keim.
//  This soruce code is distributed under BSD-style license (see org.si.license.txt).
//  
// Original code (written by c)
//  The original source code is free licensed.
//----- < Following text is from original code's readme.txt. > -----
//    Copyright(C) 1996-2001 Takuya OOURA
//    email: ooura@mmm.t.u-tokyo.ac.jp
//    download: http://momonga.t.u-tokyo.ac.jp/~ooura/fft.html
//    You may use, copy, modify this code for any purpose and 
//    without fee. You may distribute this ORIGINAL package.
//----- < up to here > -----
// [NOTES] Now the download site is moved to http://www.kurims.kyoto-u.ac.jp/~ooura/fft.html.
//         And the email address might be unavailable.
//----------------------------------------------------------------------------------------------------




package org.si.utils {
    /** Fast Fourier Transform module */
    public class FFT_original
    {
    // valiables
    //------------------------------------------------------------
        private var _length:int = 0;
        private var _waveTable:Vector.<Number> = new Vector.<Number>();
        private var _cosTable :Vector.<Number> = new Vector.<Number>();
        private var _bitrvTemp:Vector.<int> = new Vector.<int>(256);
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor, specify calculating data length first. */
        function FFT_original(length:int)
        {
            _initialize(length);
        }
        
        
        
        
    // calculation (original functions)
    //------------------------------------------------------------
        /** Complex Discrete Fourier Tranform
         *  @param isgn 1 for FFT, -1 for IFFT.
         *  @param src data to transform. The length must be same as you passed to constructor.
         */        public function cdft(isgn:int, src:Vector.<Number>) : void
        {
            if (isgn >= 0) {
                _bitrv2(src, _length);
                _cftfsub(src);
            } else {
                _bitrv2conj(src, _length);
                _cftbsub(src);
            }
        }
        
        
        /** Real Discrete Fourier Tranform
         *  @param isgn 1 for FFT, -1 for IFFT.
         *  @param src data to transform. The length must be same as you passed to constructor.
         */
        public function rdft(isgn:int, src:Vector.<Number>) : void
        {
            var xi:Number;
            
            if (isgn >= 0) {
                _bitrv2(src, _length);
                _cftfsub(src);
                _rftfsub(src);
                xi = src[0] - src[1];
                src[0] += src[1];
                src[1] = xi;
            } else {
                src[1] = 0.5 * (src[0] - src[1]);
                src[0] -= src[1];
                _rftbsub(src);
                _bitrv2(src, _length);
                _cftbsub(src);
            }
        }
        
        
        /** Discrete Cosine Tranform
         *  @param isgn [ATTENTION] -1 for DCT, 1 for IDCT. Opposite from FFT.
         *  @param src data to transform. The length must be same as you passed to constructor.
         */
        public function ddct(isgn:int, src:Vector.<Number>) : void
        {
            var j:int, xr:Number;
            
            if (isgn < 0) {
                xr = src[_length - 1];
                for (j = _length - 2; j >= 2; j -= 2) {
                    src[j+1] = src[j] - src[j - 1];
                    src[j] += src[j - 1];
                }
                src[1] = src[0] - xr;
                src[0] += xr;
                _rftbsub(src);
                _bitrv2(src, _length);
                _cftbsub(src);
                _dctsub(src);
            } else {
                _dctsub(src);
                _bitrv2(src, _length);
                _cftfsub(src);
                _rftfsub(src);
                xr = src[0] - src[1];
                src[0] += src[1];
                for (j = 2; j < _length; j += 2) {
                    src[j - 1] = src[j] - src[j+1];
                    src[j] += src[j+1];
                }
                src[_length - 1] = xr;
            }
        }


        /** Discrete Sine Tranform
         *  @param isgn [ATTENTION] -1 for DST, 1 for IDST. Opposite from FFT.
         *  @param src data to transform. The length must be same as you passed to constructor.
         */
        public function ddst(isgn:int, src:Vector.<Number>) : void
        {
            var j:int, xr:Number;
            
            if (isgn < 0) {
                xr = src[_length - 1];
                for (j = _length - 2; j >= 2; j -= 2) {
                    src[j+1] = -src[j] - src[j - 1];
                    src[j] -= src[j - 1];
                }
                src[1] = src[0] + xr;
                src[0] -= xr;
                _rftbsub(src);
                _bitrv2(src, _length);
                _cftbsub(src);
                _dstsub(src);
            } else {
                _dstsub(src);
                _bitrv2(src, _length);
                _cftfsub(src);
                _rftfsub(src);
                xr = src[0] - src[1];
                src[0] += src[1];
                for (j = 2; j < _length; j += 2) {
                    src[j - 1] = -src[j] - src[j+1];
                    src[j] -= src[j+1];
                }
                src[_length - 1] = -xr;
            }
        }
        
        
        
        
    // internal function
    //------------------------------------------------------------
        // initializer
        private function _initialize(len:int) : void
        {
            for (_length=8; _length<len;) _length<<=1;
            _waveTable.length = _length >> 2;
            _cosTable.length = _length;
            var i:int, imax:int = _length >> 3, tlen:int = _waveTable.length, 
                dt:Number = 6.283185307179586 / _length;
            
            _waveTable[0] = 1;
            _waveTable[1] = 0;
            _waveTable[imax+1] = _waveTable[imax] = Math.cos(0.7853981633974483);
            for (i=2; i<imax; i+=2) {
                _waveTable[tlen-i+1] = _waveTable[i]   = Math.cos(i*dt);
                _waveTable[tlen-i]   = _waveTable[i+1] = Math.sin(i*dt);
            }
            _bitrv2(_waveTable, tlen);
            
            imax = _cosTable.length;
            dt = 1.5707963267948965 / imax;
            for (i=0; i<imax; i++) _cosTable[i] = Math.cos(i*dt) * 0.5;
        }
        
        
        // bit reverse
        private function _bitrv2(src:Vector.<Number>, srclen:int) : void
        {
            var j:int, j1:int, k:int, k1:int,
                xr:Number, xi:Number, yr:Number, yi:Number;
            
            _bitrvTemp[0] = 0;
            var l:int = srclen, m:int = 1;
            while ((m << 3) < l) {
                l >>= 1;
                for (j = 0; j < m; j++) _bitrvTemp[m + j] = _bitrvTemp[j] + l;
                m <<= 1;
            }
            var m2:int = m * 2;
            
            if ((m << 3) == l) {
                for (k = 0; k < m; k++) {
                    for (j = 0; j < k; j++) {
                        j1 = j + j + _bitrvTemp[k];
                        k1 = k + k + _bitrvTemp[j];
                        xr = src[j1];
                        xi = src[j1+1];
                        yr = src[k1];
                        yi = src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 += m2 + m2;
                        xr = src[j1];
                        xi = src[j1+1];
                        yr = src[k1];
                        yi = src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 -= m2;
                        xr = src[j1];
                        xi = src[j1+1];
                        yr = src[k1];
                        yi = src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 += m2 + m2;
                        xr = src[j1];
                        xi = src[j1+1];
                        yr = src[k1];
                        yi = src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                    }
                    j1 = k + k + m2 + _bitrvTemp[k];
                    k1 = j1 + m2;
                    xr = src[j1];
                    xi = src[j1+1];
                    yr = src[k1];
                    yi = src[k1+1];
                    src[j1]   = yr;
                    src[j1+1] = yi;
                    src[k1]   = xr;
                    src[k1+1] = xi;
                }
            } else {
                for (k = 1; k < m; k++) {
                    for (j = 0; j < k; j++) {
                        j1 = j + j + _bitrvTemp[k];
                        k1 = k + k + _bitrvTemp[j];
                        xr = src[j1];
                        xi = src[j1+1];
                        yr = src[k1];
                        yi = src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 += m2;
                        xr = src[j1];
                        xi = src[j1+1];
                        yr = src[k1];
                        yi = src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                    }
                }
            }
        }
        
        
        // bit reverse (conjugation)
        private function _bitrv2conj(src:Vector.<Number>, srclen:int) : void
        {
            var j:int, j1:int, k:int, k1:int,
                xr:Number, xi:Number, yr:Number, yi:Number;
            
            _bitrvTemp[0] = 0;
            var l:int = srclen, m:int = 1;
            while ((m << 3) < l) {
                l >>= 1;
                for (j = 0; j < m; j++) _bitrvTemp[m + j] = _bitrvTemp[j] + l;
                m <<= 1;
            }
            var m2:int = m << 1;

            if ((m << 3) == l) {
                for (k = 0; k < m; k++) {
                    for (j = 0; j < k; j++) {
                        j1 = j + j + _bitrvTemp[k];
                        k1 = k + k + _bitrvTemp[j];
                        xr =  src[j1];
                        xi = -src[j1+1];
                        yr =  src[k1];
                        yi = -src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 += m2 + m2;
                        xr =  src[j1];
                        xi = -src[j1+1];
                        yr =  src[k1];
                        yi = -src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 -= m2;
                        xr =  src[j1];
                        xi = -src[j1+1];
                        yr =  src[k1];
                        yi = -src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 += m2 + m2;
                        xr =  src[j1];
                        xi = -src[j1+1];
                        yr =  src[k1];
                        yi = -src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                    }
                    k1 = k + k + _bitrvTemp[k];
                    src[k1+1] = -src[k1+1];
                    j1 = k1 + m2;
                    k1 = j1 + m2;
                    xr =  src[j1];
                    xi = -src[j1+1];
                    yr =  src[k1];
                    yi = -src[k1+1];
                    src[j1]   = yr;
                    src[j1+1] = yi;
                    src[k1]   = xr;
                    src[k1+1] = xi;
                    k1 += m2;
                    src[k1+1] = -src[k1+1];
                }
            } else {
                src[1] = -src[1];
                src[m2+1] = -src[m2+1];
                for (k = 1; k < m; k++) {
                    for (j = 0; j < k; j++) {
                        j1 = j + j + _bitrvTemp[k];
                        k1 = k + k + _bitrvTemp[j];
                        xr =  src[j1];
                        xi = -src[j1+1];
                        yr =  src[k1];
                        yi = -src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                        j1 += m2;
                        k1 += m2;
                        xr =  src[j1];
                        xi = -src[j1+1];
                        yr =  src[k1];
                        yi = -src[k1+1];
                        src[j1]   = yr;
                        src[j1+1] = yi;
                        src[k1]   = xr;
                        src[k1+1] = xi;
                    }
                    k1 = k + k + _bitrvTemp[k];
                    src[k1+1] = -src[k1+1];
                    src[k1 + m2+1] = -src[k1 + m2+1];
                }
            }
        }
        
        
        
        
    // sub routines
    //------------------------------------------------------------
        private function _cftfsub(src:Vector.<Number>) : void
        {
            var j0:int, j1:int, j2:int, j3:int, l:int,
                x0r:Number, x1r:Number, x2r:Number, x3r:Number,
                x0i:Number, x1i:Number, x2i:Number, x3i:Number;
            
            _cft1st(src);
            l = 8;
            while ((l << 2) < _length) {
                _cftmdl(src, l);
                l <<= 2;
            }
            
            if ((l << 2) == _length) {
                for (j0 = 0; j0 < l; j0 += 2) {
                    j1 = j0 + l;
                    j2 = j1 + l;
                    j3 = j2 + l;
                    x0r = src[j0]   + src[j1];
                    x0i = src[j0+1] + src[j1+1];
                    x1r = src[j0]   - src[j1];
                    x1i = src[j0+1] - src[j1+1];
                    x2r = src[j2]   + src[j3];
                    x2i = src[j2+1] + src[j3+1];
                    x3r = src[j2]   - src[j3];
                    x3i = src[j2+1] - src[j3+1];
                    src[j0]   = x0r + x2r;
                    src[j0+1] = x0i + x2i;
                    src[j2]   = x0r - x2r;
                    src[j2+1] = x0i - x2i;
                    src[j1]   = x1r - x3i;
                    src[j1+1] = x1i + x3r;
                    src[j3]   = x1r + x3i;
                    src[j3+1] = x1i - x3r;
                }
            } else {
                for (j0 = 0; j0 < l; j0 += 2) {
                    j1 = j0 + l;
                    x0r = src[j0]   - src[j1];
                    x0i = src[j0+1] - src[j1+1];
                    src[j0]   += src[j1];
                    src[j0+1] += src[j1+1];
                    src[j1]   = x0r;
                    src[j1+1] = x0i;
                }
            }
        }


        private function _cftbsub(src:Vector.<Number>) : void
        {
            var j0:int, j1:int, j2:int, j3:int, l:int,
                x0r:Number, x1r:Number, x2r:Number, x3r:Number,
                x0i:Number, x1i:Number, x2i:Number, x3i:Number;
            
            _cft1st(src);
            l = 8;
            while ((l << 2) < _length) {
                _cftmdl(src, l);
                l <<= 2;
            }

            if ((l << 2) == _length) {
                for (j0 = 0; j0 < l; j0 += 2) {
                    j1 = j0 + l;
                    j2 = j1 + l;
                    j3 = j2 + l;
                    x0r =  src[j0]   + src[j1];
                    x0i = -src[j0+1] - src[j1+1];
                    x1r =  src[j0]   - src[j1];
                    x1i = -src[j0+1] + src[j1+1];
                    x2r =  src[j2]   + src[j3];
                    x2i =  src[j2+1] + src[j3+1];
                    x3r =  src[j2]   - src[j3];
                    x3i =  src[j2+1] - src[j3+1];
                    src[j0]   = x0r + x2r;
                    src[j0+1] = x0i - x2i;
                    src[j2]   = x0r - x2r;
                    src[j2+1] = x0i + x2i;
                    src[j1]   = x1r - x3i;
                    src[j1+1] = x1i - x3r;
                    src[j3]   = x1r + x3i;
                    src[j3+1] = x1i + x3r;
                }
            } else {
                for (j0 = 0; j0 < l; j0 += 2) {
                    j1 = j0 + l;
                    x0r =  src[j0]   - src[j1];
                    x0i = -src[j0+1] + src[j1+1];
                    src[j0]  +=  src[j1];
                    src[j0+1] = -src[j0+1] - src[j1+1];
                    src[j1]   = x0r;
                    src[j1+1] = x0i;
                }
            }
        }
        
        
        private function _cft1st(src:Vector.<Number>) : void
        {
            var j:int, k1:int, k2:int,
                wk1r:Number, wk2r:Number, wk3r:Number, x0r:Number, x1r:Number, x2r:Number, x3r:Number,
                wk1i:Number, wk2i:Number, wk3i:Number, x0i:Number, x1i:Number, x2i:Number, x3i:Number;
            
            x0r = src[0] + src[2];
            x0i = src[1] + src[3];
            x1r = src[0] - src[2];
            x1i = src[1] - src[3];
            x2r = src[4] + src[6];
            x2i = src[5] + src[7];
            x3r = src[4] - src[6];
            x3i = src[5] - src[7];
            src[0] = x0r + x2r;
            src[1] = x0i + x2i;
            src[4] = x0r - x2r;
            src[5] = x0i - x2i;
            src[2] = x1r - x3i;
            src[3] = x1i + x3r;
            src[6] = x1r + x3i;
            src[7] = x1i - x3r;
            wk1r = _waveTable[2];
            x0r = src[8] + src[10];
            x0i = src[9] + src[11];
            x1r = src[8] - src[10];
            x1i = src[9] - src[11];
            x2r = src[12] + src[14];
            x2i = src[13] + src[15];
            x3r = src[12] - src[14];
            x3i = src[13] - src[15];
            src[8] = x0r + x2r;
            src[9] = x0i + x2i;
            src[12] = x2i - x0i;
            src[13] = x0r - x2r;
            x0r = x1r - x3i;
            x0i = x1i + x3r;
            src[10] = wk1r * (x0r - x0i);
            src[11] = wk1r * (x0r + x0i);
            x0r = x3i + x1r;
            x0i = x3r - x1i;
            src[14] = wk1r * (x0i - x0r);
            src[15] = wk1r * (x0i + x0r);
            k1 = 0;
            for (j = 16; j < _length; j += 16) {
                k1 += 2;
                k2 = 2 * k1;
                wk2r = _waveTable[k1];
                wk2i = _waveTable[k1+1];
                wk1r = _waveTable[k2];
                wk1i = _waveTable[k2+1];
                wk3r = wk1r - 2 * wk2i * wk1i;
                wk3i = 2 * wk2i * wk1r - wk1i;
                x0r = src[j] + src[j + 2];
                x0i = src[j+1] + src[j + 3];
                x1r = src[j] - src[j + 2];
                x1i = src[j+1] - src[j + 3];
                x2r = src[j + 4] + src[j + 6];
                x2i = src[j + 5] + src[j + 7];
                x3r = src[j + 4] - src[j + 6];
                x3i = src[j + 5] - src[j + 7];
                src[j] = x0r + x2r;
                src[j+1] = x0i + x2i;
                x0r -= x2r;
                x0i -= x2i;
                src[j + 4] = wk2r * x0r - wk2i * x0i;
                src[j + 5] = wk2r * x0i + wk2i * x0r;
                x0r = x1r - x3i;
                x0i = x1i + x3r;
                src[j + 2] = wk1r * x0r - wk1i * x0i;
                src[j + 3] = wk1r * x0i + wk1i * x0r;
                x0r = x1r + x3i;
                x0i = x1i - x3r;
                src[j + 6] = wk3r * x0r - wk3i * x0i;
                src[j + 7] = wk3r * x0i + wk3i * x0r;
                wk1r = _waveTable[k2 + 2];
                wk1i = _waveTable[k2 + 3];
                wk3r = wk1r - 2 * wk2r * wk1i;
                wk3i = 2 * wk2r * wk1r - wk1i;
                x0r = src[j + 8] + src[j+10];
                x0i = src[j + 9] + src[j+11];
                x1r = src[j + 8] - src[j+10];
                x1i = src[j + 9] - src[j+11];
                x2r = src[j+12] + src[j+14];
                x2i = src[j+13] + src[j+15];
                x3r = src[j+12] - src[j+14];
                x3i = src[j+13] - src[j+15];
                src[j + 8] = x0r + x2r;
                src[j + 9] = x0i + x2i;
                x0r -= x2r;
                x0i -= x2i;
                src[j+12] = -wk2i * x0r - wk2r * x0i;
                src[j+13] = -wk2i * x0i + wk2r * x0r;
                x0r = x1r - x3i;
                x0i = x1i + x3r;
                src[j+10] = wk1r * x0r - wk1i * x0i;
                src[j+11] = wk1r * x0i + wk1i * x0r;
                x0r = x1r + x3i;
                x0i = x1i - x3r;
                src[j+14] = wk3r * x0r - wk3i * x0i;
                src[j+15] = wk3r * x0i + wk3i * x0r;
            }
        }
        
        
        private function _cftmdl(src:Vector.<Number>, l:int) : void
        {
            var j:int, j1:int, j2:int, j3:int, k:int, k1:int, k2:int, m:int, m2:int,
                wk1r:Number, wk2r:Number, wk3r:Number, x0r:Number, x1r:Number, x2r:Number, x3r:Number,
                wk1i:Number, wk2i:Number, wk3i:Number, x0i:Number, x1i:Number, x2i:Number, x3i:Number;
            
            m = l << 2;
            for (j = 0; j < l; j += 2) {
                j1 = j + l;
                j2 = j1 + l;
                j3 = j2 + l;
                x0r = src[j] + src[j1];
                x0i = src[j+1] + src[j1+1];
                x1r = src[j] - src[j1];
                x1i = src[j+1] - src[j1+1];
                x2r = src[j2] + src[j3];
                x2i = src[j2+1] + src[j3+1];
                x3r = src[j2] - src[j3];
                x3i = src[j2+1] - src[j3+1];
                src[j] = x0r + x2r;
                src[j+1] = x0i + x2i;
                src[j2] = x0r - x2r;
                src[j2+1] = x0i - x2i;
                src[j1] = x1r - x3i;
                src[j1+1] = x1i + x3r;
                src[j3] = x1r + x3i;
                src[j3+1] = x1i - x3r;
            }
            wk1r = _waveTable[2];
            for (j = m; j < l + m; j += 2) {
                j1 = j + l;
                j2 = j1 + l;
                j3 = j2 + l;
                x0r = src[j] + src[j1];
                x0i = src[j+1] + src[j1+1];
                x1r = src[j] - src[j1];
                x1i = src[j+1] - src[j1+1];
                x2r = src[j2] + src[j3];
                x2i = src[j2+1] + src[j3+1];
                x3r = src[j2] - src[j3];
                x3i = src[j2+1] - src[j3+1];
                src[j] = x0r + x2r;
                src[j+1] = x0i + x2i;
                src[j2] = x2i - x0i;
                src[j2+1] = x0r - x2r;
                x0r = x1r - x3i;
                x0i = x1i + x3r;
                src[j1] = wk1r * (x0r - x0i);
                src[j1+1] = wk1r * (x0r + x0i);
                x0r = x3i + x1r;
                x0i = x3r - x1i;
                src[j3] = wk1r * (x0i - x0r);
                src[j3+1] = wk1r * (x0i + x0r);
            }
            k1 = 0;
            m2 = 2 * m;
            for (k = m2; k < _length; k += m2) {
                k1 += 2;
                k2 = 2 * k1;
                wk2r = _waveTable[k1];
                wk2i = _waveTable[k1+1];
                wk1r = _waveTable[k2];
                wk1i = _waveTable[k2+1];
                wk3r = wk1r - 2 * wk2i * wk1i;
                wk3i = 2 * wk2i * wk1r - wk1i;
                for (j = k; j < l + k; j += 2) {
                    j1 = j + l;
                    j2 = j1 + l;
                    j3 = j2 + l;
                    x0r = src[j] + src[j1];
                    x0i = src[j+1] + src[j1+1];
                    x1r = src[j] - src[j1];
                    x1i = src[j+1] - src[j1+1];
                    x2r = src[j2] + src[j3];
                    x2i = src[j2+1] + src[j3+1];
                    x3r = src[j2] - src[j3];
                    x3i = src[j2+1] - src[j3+1];
                    src[j] = x0r + x2r;
                    src[j+1] = x0i + x2i;
                    x0r -= x2r;
                    x0i -= x2i;
                    src[j2] = wk2r * x0r - wk2i * x0i;
                    src[j2+1] = wk2r * x0i + wk2i * x0r;
                    x0r = x1r - x3i;
                    x0i = x1i + x3r;
                    src[j1] = wk1r * x0r - wk1i * x0i;
                    src[j1+1] = wk1r * x0i + wk1i * x0r;
                    x0r = x1r + x3i;
                    x0i = x1i - x3r;
                    src[j3] = wk3r * x0r - wk3i * x0i;
                    src[j3+1] = wk3r * x0i + wk3i * x0r;
                }
                wk1r = _waveTable[k2 + 2];
                wk1i = _waveTable[k2 + 3];
                wk3r = wk1r - 2 * wk2r * wk1i;
                wk3i = 2 * wk2r * wk1r - wk1i;
                for (j = k + m; j < l + (k + m); j += 2) {
                    j1 = j + l;
                    j2 = j1 + l;
                    j3 = j2 + l;
                    x0r = src[j] + src[j1];
                    x0i = src[j+1] + src[j1+1];
                    x1r = src[j] - src[j1];
                    x1i = src[j+1] - src[j1+1];
                    x2r = src[j2] + src[j3];
                    x2i = src[j2+1] + src[j3+1];
                    x3r = src[j2] - src[j3];
                    x3i = src[j2+1] - src[j3+1];
                    src[j] = x0r + x2r;
                    src[j+1] = x0i + x2i;
                    x0r -= x2r;
                    x0i -= x2i;
                    src[j2] = -wk2i * x0r - wk2r * x0i;
                    src[j2+1] = -wk2i * x0i + wk2r * x0r;
                    x0r = x1r - x3i;
                    x0i = x1i + x3r;
                    src[j1] = wk1r * x0r - wk1i * x0i;
                    src[j1+1] = wk1r * x0i + wk1i * x0r;
                    x0r = x1r + x3i;
                    x0i = x1i - x3r;
                    src[j3] = wk3r * x0r - wk3i * x0i;
                    src[j3+1] = wk3r * x0i + wk3i * x0r;
                }
            }
        }
        
        
        private function _rftfsub(src:Vector.<Number>) : void 
        {
            var j:int, k:int, kk:int, m:int,
                wkr:Number, wki:Number, xr:Number, xi:Number, yr:Number, yi:Number;
            
            m = _length >> 1;
            kk = 0;
            for (j = 2; j < m; j += 2) {
                k = _length - j;
                kk += 4;
                wkr = 0.5 - _cosTable[_length - kk];
                wki = _cosTable[kk];
                xr = src[j] - src[k];
                xi = src[j+1] + src[k+1];
                yr = wkr * xr - wki * xi;
                yi = wkr * xi + wki * xr;
                src[j] -= yr;
                src[j+1] -= yi;
                src[k] += yr;
                src[k+1] -= yi;
            }
        }


        private function _rftbsub(src:Vector.<Number>) : void 
        {
            var j:int, k:int, kk:int, m:int,
                wkr:Number, wki:Number, xr:Number, xi:Number, yr:Number, yi:Number;
            
            src[1] = -src[1];
            m = _length >> 1;
            kk = 0;
            for (j = 2; j < m; j += 2) {
                k = _length - j;
                kk += 4;
                wkr = 0.5 - _cosTable[_length - kk];
                wki = _cosTable[kk];
                xr = src[j] - src[k];
                xi = src[j+1] + src[k+1];
                yr = wkr * xr + wki * xi;
                yi = wkr * xi - wki * xr;
                src[j] -= yr;
                src[j+1] = yi - src[j+1];
                src[k] += yr;
                src[k+1] = yi - src[k+1];
            }
            src[m+1] = -src[m+1];
        }
        
        
        private function _dctsub(src:Vector.<Number>) : void 
        {
            var j:int, k:int, kk:int, m:int, wkr:Number, wki:Number, xr:Number;
            
            m = _length >> 1;
            kk = 0;
            for (j = 1; j < m; j++) {
                k = _length - j;
                kk += 1;
                wkr = _cosTable[kk] - _cosTable[_length - kk];
                wki = _cosTable[kk] + _cosTable[_length - kk];
                xr = wki * src[j] - wkr * src[k];
                src[j] = wkr * src[j] + wki * src[k];
                src[k] = xr;
            }
            src[m] *= 0.7071067811865476; // cos(pi/4)
        }


        private function _dstsub(src:Vector.<Number>) : void 
        {
           var j:int, k:int, kk:int, m:int, wkr:Number, wki:Number, xr:Number;
            
            m = _length >> 1;
            kk = 0;
            for (j = 1; j < m; j++) {
                k = _length - j;
                kk += 1;
                wkr = _cosTable[kk] - _cosTable[_length - kk];
                wki = _cosTable[kk] + _cosTable[_length - kk];
                xr = wki * src[k] - wkr * src[j];
                src[k] = wkr * src[k] + wki * src[j];
                src[j] = xr;
            }
            src[m] *= 0.7071067811865476; // cos(pi/4)
        }
    }
}










