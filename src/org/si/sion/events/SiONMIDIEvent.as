//----------------------------------------------------------------------------------------------------
// Events for SiON Track
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.events {
    import flash.events.Event;
    import flash.media.Sound;
    import flash.utils.ByteArray;
    import org.si.sion.SiONDriver;
    import org.si.sion.SiONData;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.namespaces._sion_internal;
    import org.si.sion.midi.MIDIModule;
    import org.si.sion.midi.MIDIModuleChannel;
    
    
    /** SiON MIDI Event class. */
    public class SiONMIDIEvent extends SiONTrackEvent 
    {
    // constants
    //----------------------------------------
        /** Dispatch when the note on appears in MIDI data.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance.</td></tr>
         * <tr><td>data</td><td>SiONDataConverterSMF instance.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * <tr><td>eventTriggerID</td><td>MIDI channel Number</td></tr>
         * <tr><td>track</td><td>SiMMLTrack instance to play</td></tr>
         * <tr><td>midiModule</td><td>MIDIModule instance to play</td></tr>
         * <tr><td>midiChannel</td><td>MIDIModuleChannel instance to play</td></tr>
         * <tr><td>midiChannelNumber</td><td>MIDI channel Number</td></tr>
         * <tr><td>note</td><td>Note number.</td></tr>
         * <tr><td>value</td><td>velocity.</td></tr>
         * <tr><td>controllerNumber</td><td>same as note prop.</td></tr>
         * </table>
         * @eventType soundTrigger
         */
        public static const NOTE_ON:String = 'midiNoteOn';
        
        
        /** Dispatch when the note off appears in MIDI data.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance.</td></tr>
         * <tr><td>data</td><td>SiONDataConverterSMF instance.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * <tr><td>eventTriggerID</td><td>MIDI channel Number</td></tr>
         * <tr><td>track</td><td>SiMMLTrack instance to play</td></tr>
         * <tr><td>midiModule</td><td>MIDIModule instance to play</td></tr>
         * <tr><td>midiChannel</td><td>MIDIModuleChannel instance to play</td></tr>
         * <tr><td>midiChannelNumber</td><td>MIDI channel Number</td></tr>
         * <tr><td>note</td><td>Note number.</td></tr>
         * <tr><td>value</td><td>always 0.</td></tr>
         * <tr><td>controllerNumber</td><td>same as note prop.</td></tr>
         * </table>
         * @eventType soundTrigger
         */
        public static const NOTE_OFF:String = 'midiNoteOff';

        
        /** Dispatch when the control change command appears in MIDI data.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance.</td></tr>
         * <tr><td>data</td><td>SiONDataConverterSMF instance.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * <tr><td>eventTriggerID</td><td>MIDI channel Number</td></tr>
         * <tr><td>track</td><td>null</td></tr>
         * <tr><td>midiModule</td><td>MIDIModule instance to play</td></tr>
         * <tr><td>midiChannel</td><td>MIDIModuleChannel instance to play</td></tr>
         * <tr><td>midiChannelNumber</td><td>MIDI channel Number</td></tr>
         * <tr><td>note</td><td>same as controllerNumber prop.</td></tr>
         * <tr><td>value</td><td>data value for the controller</td></tr>
         * <tr><td>controllerNumber</td><td>Controller number</td></tr>
         * </table>
         * @eventType frameTrigger
         */
        public static const CONTROL_CHANGE:String = 'midiControlChange';

        
        /** Dispatch when the program change command appears in MIDI data.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance.</td></tr>
         * <tr><td>data</td><td>SiONDataConverterSMF instance.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * <tr><td>eventTriggerID</td><td>MIDI channel Number</td></tr>
         * <tr><td>track</td><td>null</td></tr>
         * <tr><td>midiModule</td><td>MIDIModule instance to play</td></tr>
         * <tr><td>midiChannel</td><td>MIDIModuleChannel instance to play</td></tr>
         * <tr><td>midiChannelNumber</td><td>MIDI channel Number</td></tr>
         * <tr><td>note</td><td>always 0</td></tr>
         * <tr><td>value</td><td>program number</td></tr>
         * <tr><td>controllerNumber</td><td>always 0</td></tr>
         * </table>
         * @eventType frameTrigger
         */
        public static const PROGRAM_CHANGE:String = 'midiProgramChange';
        
        
        /** Dispatch when the pitch bend command appears in MIDI data.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance.</td></tr>
         * <tr><td>data</td><td>SiONDataConverterSMF instance.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * <tr><td>eventTriggerID</td><td>MIDI channel Number</td></tr>
         * <tr><td>track</td><td>null</td></tr>
         * <tr><td>midiModule</td><td>MIDIModule instance to play</td></tr>
         * <tr><td>midiChannel</td><td>MIDIModuleChannel instance to play</td></tr>
         * <tr><td>midiChannelNumber</td><td>MIDI channel Number</td></tr>
         * <tr><td>note</td><td>always 0</td></tr>
         * <tr><td>value</td><td>bend value</td></tr>
         * <tr><td>controllerNumber</td><td>always 0</td></tr>
         * </table>
         * @eventType stream
         */
        public static const PITCH_BEND:String = 'midiPitchBend';
        
        
        
        
    // valiables
    //----------------------------------------
        // 2nd value
        private var _2ndValue:int;
        // midi channel
        private var _midiChannel:MIDIModuleChannel;
        
        
        
        
    // properties
    //----------------------------------------
        /** controller number of CONTROL_CHANGE, same as SiONTrackEvent's note */
        public function get controllerNumber() : int { return _note; }
        
        /** data(CONTROL_CHANGE), program number(PROGRAM_CHANGE), bendvalue(PITCH_BEND) or velocity(NOTE events). */
        public function get value() : int { return _2ndValue; }
        
        /** MIDI sound module to play */
        public function get midiModule() : MIDIModule { return _driver.midiModule; }
        
        /** MIDI channel instance */
        public function get midiChannel() : MIDIModuleChannel { return _midiChannel; }
        
        /** MIDI channel Number, same as SiON event trigger ID. */
        public function get midiChannelNumber() : int { return _eventTriggerID; }
        
        
        
        
    // functions
    //----------------------------------------
        /** This event can be created only in the callback function inside. @private */
        public function SiONMIDIEvent(type:String, driver:SiONDriver, track:SiMMLTrack, channelNumber:int, bufferIndex:int, note:int, value:int)
        {
            super(type, driver, track, bufferIndex);
            _midiChannel = _driver.midiModule.midiChannels[channelNumber];
            _eventTriggerID = channelNumber;
            _note = note;
            _2ndValue = value;
        }
        
        
        /** clone. */
        override public function clone() : Event
        { 
            var event:SiONMIDIEvent = new SiONMIDIEvent(type, _driver, _track, midiChannelNumber, _bufferIndex, _note, _2ndValue);
            event._bufferIndex = _bufferIndex;
            event._frameTriggerDelay = _frameTriggerDelay;
            event._frameTriggerTimer = _frameTriggerTimer;
            return event;
        }
    }
}

