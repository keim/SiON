//----------------------------------------------------------------------------------------------------
// NES configuration
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//--------------------------------------------------------------------------------


package org.si.sound.nsf {
    public class NESconfig {
        static public var NTSC:NESconfig = new NESconfig(1789772.5,   262, 1364, 1024, 340, 4, 29830, 60);
        static public var PAL :NESconfig = new NESconfig(1662607.125, 312, 1278,  960, 318, 2, 33252, 50);
        
        public var cpuClock:Number, frameRate:int, framePeriod:Number, totalScanlines:int;
        public var scanlineCycles:int, hDrawCycles:int, hBlankCycles:int, scanlineEndCycles:int;
        public var frameCycles:int, frameIrqCycles:int;
        
        function NESconfig(cl:Number, sl:int, slc:int, hdc:int, hbc:int, sec:int, fic:int, fr:int) {
            cpuClock = cl;
            totalScanlines = sl;
            scanlineCycles = slc;
            hDrawCycles = hdc;
            hBlankCycles = hbc;
            scanlineEndCycles = sec;
            frameCycles = sl * slc;
            frameIrqCycles = fic;
            frameRate = fr;
            framePeriod = 1000/fr;
        }
    }
}


