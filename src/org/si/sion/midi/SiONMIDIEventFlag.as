//----------------------------------------------------------------------------------------------------
// SiON MIDI internal namespace
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.midi {
    public class SiONMIDIEventFlag {
        /** dispatch flag for SiONMIDIEvent.NOTE_ON */
        static public const NOTE_ON:int = 1;
        /** dispatch flag for SiONMIDIEvent.NOTE_OFF */
        static public const NOTE_OFF:int = 2;
        /** dispatch flag for SiONMIDIEvent.CONTROL_CHANGE*/
        static public const CONTROL_CHANGE:int = 4;
        /** dispatch flag for SiONMIDIEvent.PROGRAM_CHANGE */
        static public const PROGRAM_CHANGE:int = 8;
        /** dispatch flag for SiONMIDIEvent.PITCH_BEND */
        static public const PITCH_BEND:int = 16;
        /** Flag for all */
        static public const ALL:int = 31;
    }
}


