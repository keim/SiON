//----------------------------------------------------------------------------------------------------
// NES Emulator
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//--------------------------------------------------------------------------------


package org.si.sound.nsf {
    public class NES {
        static public var cpu:CPU = new CPU();
        static public var apu:APU = new APU();
        static public var ppu:PPU = new PPU();
        static public var pad:PAD = new PAD();
        static public var rom:ROM;
        static public var map:Mapper;
        static public var cfg:NESconfig;
    }
}


