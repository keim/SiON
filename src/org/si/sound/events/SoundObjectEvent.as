//----------------------------------------------------------------------------------------------------
// SoundObjectEvent
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.events {
    import flash.events.*;
    import org.si.sion.events.SiONTrackEvent;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.SoundObject;
    
    
    /** SoundObjectEvent is dispatched by all SoundObjects. @see org.si.sound.SoundObject */
    public class SoundObjectEvent extends Event
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** Dispatch when the note on appears.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>soundObject</td><td>Target SoundObject.</td></tr>
         * <tr><td>track</td><td>SiMMLTrack instance executing sequence.</td></tr>
         * <tr><td>eventTriggerID</td><td>Trigger ID specifyed by setEventTrigger().</td></tr>
         * <tr><td>note</td><td>Note number.</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * </table>
         * @eventType soundTrigger
         */
        public static const NOTE_ON_STREAM:String = 'noteOnStream';
        
        
        /** Dispatch when the note off appears in the sequence.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>soundObject</td><td>Target SoundObject.</td></tr>
         * <tr><td>track</td><td>SiMMLTrack instance executing sequence.</td></tr>
         * <tr><td>eventTriggerID</td><td>Trigger ID specifyed by setEventTrigger().</td></tr>
         * <tr><td>note</td><td>Note number.</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * </table>
         * @eventType soundTrigger
         */
        public static const NOTE_OFF_STREAM:String = 'noteOffStream';

        
        /** Dispatch when the sound starts.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>soundObject</td><td>Target SoundObject.</td></tr>
         * <tr><td>track</td><td>SiMMLTrack instance executing sequence.</td></tr>
         * <tr><td>eventTriggerID</td><td>Trigger ID specifyed by setEventTrigger().</td></tr>
         * <tr><td>note</td><td>Note number.</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * </table>
         * @eventType frameTrigger
         */
        public static const NOTE_ON_FRAME:String = 'noteOnFrame';

        
        /** Dispatch when the sound ends.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>soundObject</td><td>Target SoundObject.</td></tr>
         * <tr><td>track</td><td>SiMMLTrack instance executing sequence.</td></tr>
         * <tr><td>eventTriggerID</td><td>Trigger ID specifyed by setEventTrigger().</td></tr>
         * <tr><td>note</td><td>Note number.</td></tr>
         * <tr><td>bufferIndex</td><td>Buffering index</td></tr>
         * </table>
         * @eventType frameTrigger
         */
        public static const NOTE_OFF_FRAME:String = 'noteOffFrame';

        
        /** Dispatch in each frame in PatternSequencer.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>soundObject</td><td>Target SoundObject.</td></tr>
         * <tr><td>track</td><td>null. no meanings.</td></tr>
         * <tr><td>eventTriggerID</td><td>Trigger ID specifyed by setEventTrigger().</td></tr>
         * <tr><td>note</td><td>Note number.</td></tr>
         * <tr><td>bufferIndex</td><td>0. no meanings</td></tr>
         * </table>
         * @eventType sequencerTrigger
         */
        public static const ENTER_FRAME:String = 'soundObjectEnterFrame';

        
        /** Dispatch in each segment in PatternSequencer.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>soundObject</td><td>Target SoundObject.</td></tr>
         * <tr><td>track</td><td>null. no meanings.</td></tr>
         * <tr><td>eventTriggerID</td><td>Trigger ID specifyed by setEventTrigger().</td></tr>
         * <tr><td>note</td><td>0. no meanings</td></tr>
         * <tr><td>bufferIndex</td><td>0. no meanings</td></tr>
         * </table>
         * @eventType sequencerTrigger
         */
        public static const ENTER_SEGMENT:String = 'soundObjectEnterSegment';
        
        
        
        
    // valiables
    //----------------------------------------
        /** @private target sound object */ 
        _sound_object_internal var _soundObject:SoundObject;
        
        /** @private current track */ 
        _sound_object_internal var _track:SiMMLTrack;
        
        /** @private trigger event id */
        _sound_object_internal var _eventTriggerID:int
        
        /** @private note number */
        _sound_object_internal var _note:int;
        
        /** @private buffering index */
        _sound_object_internal var _bufferIndex:int;
        
        
    
        
    // properties
    //----------------------------------------
        /** Target sound object */
        public function get soundObject() : SoundObject { return _soundObject; }
        
        /** Sequencer track instance. */
        public function get track() : SiMMLTrack { return _track; }
        
        /** Trigger ID. */
        public function get eventTriggerID() : int { return _eventTriggerID; }
        
        /** Note number. */
        public function get note() : int { return _note; }
        
        /** Buffering index. */
        public function get bufferIndex() : int { return _bufferIndex; }
        
        
        
        
    // functions
    //----------------------------------------
        /** @private */
        function SoundObjectEvent(type:String, soundObject:SoundObject, trackEvent:SiONTrackEvent) {
            super(type, false, false);
            _soundObject    = soundObject;
            if (trackEvent) {
                _track          = trackEvent.track;
                _eventTriggerID = trackEvent.eventTriggerID;
                _note           = trackEvent.note;
                _bufferIndex    = trackEvent.bufferIndex;
            }
        }
    }
}



