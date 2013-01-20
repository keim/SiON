//----------------------------------------------------------------------------------------------------
// Events for SiON
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.events {
    import flash.events.Event;
    import flash.media.Sound;
    import flash.utils.ByteArray;
    import org.si.sion.SiONDriver;
    import org.si.sion.SiONData;
    
    
    /** SiON Event class. */
    public class SiONEvent extends Event 
    {
    // constants
    //----------------------------------------
        /** Dispatch when executing queued jobs.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>true; Cancel compiling/rendering immediately.</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance compiling/rendering compiling now.</td></tr>
         * <tr><td>driver.mmlString</td><td>MML string compiling now. null when the job is "render".</td></tr>
         * <tr><td>data</td><td>SiONData instance compiling/rendering now. This data is not available when compiling.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * </table>
         * @eventType queueProgress
         */
        public static const QUEUE_PROGRESS:String = 'queueProgress';
        
        
        /** Dispatch when finish all queued jobs.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance compiled/rendered.</td></tr>
         * <tr><td>driver.mmlString</td><td>MML string compiled. null when the job is "render".</td></tr>
         * <tr><td>data</td><td>SiONData instance compiled/rendered.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * </table>
         * @eventType queueComplete
         */
        public static const QUEUE_COMPLETE:String = 'queueComplete';
        
        
        /** Dispatch when cancel all queued jobs.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance compiled/rendered.</td></tr>
         * <tr><td>driver.mmlString</td><td>null</td></tr>
         * <tr><td>data</td><td>null</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * </table>
         * @eventType queueCancel
         */
        public static const QUEUE_CANCEL:String = 'queueCancel';
        
        
        /** Dispatch while streaming. This event is called inside SiONDriver.play() after SiONEvent.STREAM_START, and each streaming timing.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>true; Stop streaming. SiONDriver.stop() s called inside</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance playing now.</td></tr>
         * <tr><td>data</td><td>SiONData instance playing now. This property is null if you call SiONDriver.play() with null of the 1st argument.</td></tr>
         * <tr><td>streamBuffer</td><td>ByteArray instance of this stream. The length is twice of SiONDriver.bufferLength in the unit of float. You can get the renderd wave data by this propertiy.</td></tr>
         * </table>
         * @eventType stream
         */
        public static const STREAM:String = 'stream';
        
        
        /** Dispatch when start streaming. This event is called inside SiONDriver.play() before SiONEvent.STREAM.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>true; Cancel to start streaming.</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance to start streaming.</td></tr>
         * <tr><td>data</td><td>SiONData instance to start streaming. This property is null if you call SiONDriver.play() with null of the 1st argument.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * </table>
         * @eventType streamStart
         */
        public static const STREAM_START:String = 'streamStart';
        
        
        /** Dispatch when stop streaming. This event is dispatched inside SiONDriver.stop().
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance to stop streaming.</td></tr>
         * <tr><td>data</td><td>SiONData instance to stop streaming. This property is null if you call SiONDriver.play() with null of the 1st argument.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * </table>
         * @eventType streamStop
         */
        public static const STREAM_STOP:String = 'streamStop';
        
        
        /** Dispatch when finish executing all sequences.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance playing now.</td></tr>
         * <tr><td>data</td><td>SiONData instance playing now.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * </table>
         * @eventType finishSequence
         */
        public static const FINISH_SEQUENCE:String = 'finishSequence';
        
        
        /** Dispatch while fading. This event is dispatched after SiONEvent.STREAM.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>true to cancel fading.</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance to stop streaming.</td></tr>
         * <tr><td>data</td><td>SiONData instance playing now. This property is null if you call SiONDriver.play() with null of the 1st argument.</td></tr>
         * <tr><td>streamBuffer</td><td>null</td></tr>
         * </table>
         * @eventType fadeProgress
         */
        public static const FADE_PROGRESS:String = 'fadeProgress';
        
        
        /** Dispatch when fade in is finished. This event is dispatched after SiONEvent.STREAM.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance to stop streaming.</td></tr>
         * <tr><td>data</td><td>SiONData instance playing now. This property is null if you call SiONDriver.play() with null of the 1st argument.</td></tr>
         * <tr><td>streamBuffer</td><td>ByteArray instance of this stream. The length is twice of SiONDriver.bufferLength in the unit of float. You can get the renderd wave data by this propertiy.</td></tr>
         * </table>
         * @eventType fadeInComplete
         */
        public static const FADE_IN_COMPLETE:String = 'fadeInComplete';
        
        
        /** Dispatch when fade out is finished. This event is dispatched after SiONEvent.STREAM.
         * <p>The properties of the event object have the following values:</p>
         * <table class='innertable'>
         * <tr><th>Property</th><th>Value</th></tr>
         * <tr><td>cancelable</td><td>false</td></tr>
         * <tr><td>driver</td><td>SiONDriver instance to stop streaming.</td></tr>
         * <tr><td>data</td><td>SiONData instance playing now. This property is null if you call SiONDriver.play() with null of the 1st argument.</td></tr>
         * <tr><td>streamBuffer</td><td>ByteArray instance of this stream. The length is twice of SiONDriver.bufferLength in the unit of float. You can get the renderd wave data by this propertiy.</td></tr>
         * </table>
         * @eventType fadeInComplete
         */
        public static const FADE_OUT_COMPLETE:String = 'fadeOutComplete';
        
        
        
        
    // valiables
    //----------------------------------------
        /** driver @private */
        protected var _driver:SiONDriver;
        
        /** streaming buffer @private */
        protected var _streamBuffer:ByteArray;
        
        
        
        
    // properties
    //----------------------------------------
        /** Sound driver. */
        public function get driver():SiONDriver { return _driver; }
        
        /** Sound data. */
        public function get data():SiONData { return _driver.data; }
        
        /** ByteArray of sound stream. This is available only in STREAM event. */
        public function get streamBuffer():ByteArray { return _streamBuffer; }
        
        
        
        
    // functions
    //----------------------------------------
        /** Creates an SiONEvent object to pass as a parameter to event listeners. */
        public function SiONEvent(type:String, driver:SiONDriver, streamBuffer:ByteArray = null, cancelable:Boolean = false)
        {
            super(type, false, cancelable);
            _driver = driver;
            _streamBuffer = streamBuffer;
        }
        
        
        /** clone. */
        override public function clone() : Event
        { 
            return new SiONEvent(type, driver, streamBuffer, cancelable);
        }
    }
}

