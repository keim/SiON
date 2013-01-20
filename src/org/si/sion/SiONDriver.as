//----------------------------------------------------------------------------------------------------
// SiON driver
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion {
    import flash.errors.*;
    import flash.events.*;
    import flash.media.*;
    import flash.net.*;
    import flash.display.Sprite;
    import flash.utils.getTimer;
    import flash.utils.ByteArray;
    import org.si.utils.SLLint;
    import org.si.utils.SLLNumber;
    import org.si.sion.events.*;
    import org.si.sion.sequencer.base._sion_sequencer_internal;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.sequencer.base.MMLEvent;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLEnvelopTable;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.sequencer.SiMMLVoice;
    import org.si.sion.module.ISiOPMWaveInterface;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.module.SiOPMWaveSamplerData;
    import org.si.sion.effector.SiEffectModule;
    import org.si.sion.effector.SiEffectBase;
    import org.si.sion.midi.SiONMIDIEventFlag;
    import org.si.sion.midi.SMFData;
    import org.si.sion.midi.MIDIModule;
    import org.si.sion.midi.SiONDataConverterSMF;
    import org.si.sion.utils.soundloader.SoundLoader;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.utils.Fader;
    import org.si.sion.namespaces._sion_internal;
    
    
    // Dispatching events
    /** @eventType org.si.sion.events.SiONEvent.QUEUE_PROGRESS */
    [Event(name="queueProgress",   type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.QUEUE_COMPLETE */
    [Event(name="queueComplete",   type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.QUEUE_CANCEL */
    [Event(name="queueCancel",     type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.STREAM */
    [Event(name="stream",          type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.STREAM_START */
    [Event(name="streamStart",     type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.STREAM_STOP */
    [Event(name="streamStop",      type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.FINISH_SEQUENCE */
    [Event(name="finishSequence",  type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.FADE_PROGRESS */
    [Event(name="fadeProgress",    type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.FADE_IN_COMPLETE */
    [Event(name="fadeInComplete",  type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONEvent.FADE_OUT_COMPLETE */
    [Event(name="fadeOutComplete", type="org.si.sion.events.SiONEvent")]
    /** @eventType org.si.sion.events.SiONTrackEvent.NOTE_ON_STREAM */
    [Event(name="noteOnStream",    type="org.si.sion.events.SiONTrackEvent")]
    /** @eventType org.si.sion.events.SiONTrackEvent.NOTE_OFF_STREAM */
    [Event(name="noteOffStream",   type="org.si.sion.events.SiONTrackEvent")]
    /** @eventType org.si.sion.events.SiONTrackEvent.NOTE_ON_FRAME */
    [Event(name="noteOnFrame",     type="org.si.sion.events.SiONTrackEvent")]
    /** @eventType org.si.sion.events.SiONTrackEvent.NOTE_OFF_FRAME */
    [Event(name="noteOffFrame",    type="org.si.sion.events.SiONTrackEvent")]
    /** @eventType org.si.sion.events.SiONTrackEvent.BEAT */
    [Event(name="beat",            type="org.si.sion.events.SiONTrackEvent")]
    /** @eventType org.si.sion.events.SiONTrackEvent.CHANGE_BPM */
    [Event(name="changeBPM",       type="org.si.sion.events.SiONTrackEvent")]
    
    
    /** SiONDriver class provides the driver of SiON's digital signal processor emulator. SiON's all basic operations are provided as SiONDriver's properties, methods and events. You can create only one SiONDriver instance in one SWF file, and the error appears when you try to create plural SiONDrivers.<br/>
     * @see SiONData
     * @see SiONVoice
     * @see org.si.sion.events.SiONEvent
     * @see org.si.sion.events.SiONTrackEvent
     * @see org.si.sion.module.SiOPMModule
     * @see org.si.sion.sequencer.SiMMLSequencer
     * @see org.si.sion.effector.SiEffectModule
@example 1) The simplest sample. Create new instance and call play with MML string.<br/>
<listing version="3.0">
// create driver instance.
var driver:SiONDriver = new SiONDriver();
// call play() with mml string whenever you want to play sound.
driver.play("t100 l8 [ ccggaag4 ffeeddc4 | [ggffeed4]2 ]2");
</listing>
     */
    public class SiONDriver extends Sprite implements ISiOPMWaveInterface
    {
    // namespace
    //----------------------------------------
        use namespace _sion_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** version number */
        static public const VERSION:String = "0.6.5.3";
        
        
        /** note-on exception mode "ignore", SiON does not consider about track ID's conflict in noteOn() method (default). */
        static public const NEM_IGNORE:int = 0;
        /** note-on exception mode "reject", Reject new note when the track IDs are conflicted. */
        static public const NEM_REJECT:int = 1;
        /** note-on exception mode "overwrite", Overwrite current note when the track IDs are conflicted. */
        static public const NEM_OVERWRITE:int = 2;
        /** note-on exception mode "shift", Shift the sound timing to next quantize when the track IDs are conflicted. */
        static public const NEM_SHIFT:int = 3;
        
        static private const NEM_MAX:int = 4;
        
        
        // event listener type
        private const NO_LISTEN:int = 0;
        private const LISTEN_QUEUE:int = 1;
        private const LISTEN_PROCESS:int = 2;
        
        // time avaraging sample count
        private const TIME_AVARAGING_COUNT:int = 8;
        
        
        
        
    // valiables
    //----------------------------------------
        /** SiOPM digital signal processor module instance.  */
        public var module:SiOPMModule;
        
        /** Effector module instance. */
        public var effector:SiEffectModule;
        
        /** Sequencer module instance. */
        public var sequencer:SiMMLSequencer;
        
        
        // private:
        //----- general
        private var _data:SiONData;         // data to compile or process
        private var _tempData:SiONData;     // temporary data
        private var _mmlString:String;      // mml string of previous compiling
        //----- sound related
        private var _sound:Sound;                   // sound stream instance
        private var _soundChannel:SoundChannel;     // sound channel instance
        private var _soundTransform:SoundTransform; // sound transform
        private var _fader:Fader;                   // sound fader
        //----- SiOPM DSP module related
        private var _channelCount:int;          // module output channels (1 or 2)
        private var _sampleRate:Number;         // module output frequency ratio (44100 or 22050)
        private var _bitRate:int;               // module output bitrate
        private var _bufferLength:int;          // module and streaming buffer size (8192, 4096 or 2048)
        private var _debugMode:Boolean;         // true; throw Error, false; throw ErrorEvent
        private var _dispatchStreamEvent:Boolean; // dispatch steam event
        private var _dispatchFadingEvent:Boolean; // dispatch fading event
        private var _inStreaming:Boolean;         // in streaming
        private var _preserveStop:Boolean;        // preserve stop after streaming
        private var _suspendStreaming:Boolean;      // suspend streaming
        private var _suspendWhileLoading:Boolean;   // suspend starting steam while loading
        private var _loadingSoundList:Array;        // loading sound list
        private var _isFinishSeqDispatched:Boolean; // FINISH_SEQUENCE event already dispacthed
        //----- operation related
        private var _autoStop:Boolean;          // auto stop when the sequence finished
        private var _noteOnExceptionMode:int;   // track id exception mode
        private var _isPaused:Boolean;          // flag to pause
        private var _position:Number;           // start position [ms]
        private var _masterVolume:Number;       // master volume
        private var _faderVolume:Number;        // fader volume
        private var _dispatchChangeBPMEventWhenPositionChanged:Boolean; 
        //----- background sound
        private var _backgroundSound:Sound;                 // background Sound
        private var _backgroundLoopPoint:Number;            // loop point (in seconds)
        private var _backgroundFadeOutFrames:int;           // fading out frames
        private var _backgroundFadeInFrames:int;            // fading in frames
        private var _backgroundFadeGapFrames:int;           // fading gap frames
        private var _backgroundTotalFadeFrames:int;         // total fading in frames
        private var _backgroundVoice:SiONVoice;             // voice
        private var _backgroundSample:SiOPMWaveSamplerData; // sampling data
        private var _backgroundTrack:SiMMLTrack;            // track for background Sound
        private var _backgroundTrackFadeOut:SiMMLTrack;     // track for background Sound's cross fading
        //----- queue
        private var _queueInterval:int;         // interupting interval to execute queued jobs
        private var _queueLength:int;           // queue length to execute
        private var _jobProgress:Number;        // progression of current job
        private var _currentJob:int;            // current job 0=no job, 1=compile, 2=render
        private var _jobQueue:Vector.<SiONDriverJob> = null;   // compiling/rendering jobs queue
        private var _trackEventQueue:Vector.<SiONTrackEvent>;  // SiONTrackEvents queue
        //----- timer interruption
        private var _timerSequence:MMLSequence;     // global sequence
        private var _timerIntervalEvent:MMLEvent;   // MMLEvent.GLOBAL_WAIT event
        private var _timerCallback:Function;        // callback function
        //----- rendering
        private var _renderBuffer:Vector.<Number>;  // rendering buffer
        private var _renderBufferChannelCount:int;  // rendering buffer channel count
        private var _renderBufferIndex:int;         // rendering buffer writing index
        private var _renderBufferSizeMax:int;       // maximum value of rendering buffer size
        //----- timers
        private var _timeCompile:int;           // previous compiling time.
        private var _timeRender:int;            // previous rendering time.
        private var _timeProcess:int;           // averge processing time in 1sec.
        private var _timeProcessTotal:int;      // total processing time in last 8 bufferings.
        private var _timeProcessData:SLLint;    // processing time data of last 8 bufferings.
        private var _timeProcessAveRatio:Number;// number to averaging _timeProcessTotal
        private var _timePrevStream:int;        // previous streaming time.
        private var _latency:Number;            // streaming latency [ms]
        private var _prevFrameTime:int;         // previous frame time
        private var _frameRate:int;             // frame rate
        //----- listeners management
        private var _eventListenerPrior:int;    // event listeners priority
        private var _listenEvent:int;           // current lintening event
        //----- MIDI related
        private var _midiModule:MIDIModule;                 // midi sound module
        private var _midiConverter:SiONDataConverterSMF;    // SMF data converter
        
        
        // mutex instance
        static private var _mutex:SiONDriver = null;            // unique instance
        static private var _allowPluralDrivers:Boolean = false; // allow plural drivers
        
        
        
    // properties
    //----------------------------------------
        /** Instance of unique SiONDriver. null when new SiONDriver is not created yet. */
        static public function get mutex() : SiONDriver { return _mutex; }
        
        
        //----- data
        /** MML string (this property is only available during compiling). */
        public function get mmlString() : String { return _mmlString; }
        
        /** Data to compile, render and process. */
        public function get data() : SiONData { return _data; }
        
        /** flash.media.Sound instance to stream SiON's sound. */
        public function get sound() : Sound { return _sound; }
        
        /** flash.media.SoundChannel instance of SiON's sound stream (this property is only available during streaming). */
        public function get soundChannel() : SoundChannel { return _soundChannel; }

        /** Fader to control fade-in/out. You can check activity by "fader.isActive". */
        public function get fader() : Fader { return _fader; }
        
        
        //----- sound paramteters
        /** The number of sound tracks (this property is only available during streaming). */
        public function get trackCount() : int { return sequencer.tracks.length; }
        
        /** Streaming buffer length. */
        public function get bufferLength() : int { return _bufferLength; }
        /** Sample rate (44100 is only available in current version). */
        public function get sampleRate() : Number { return _sampleRate; }
        /** bit rate, the value of 0 means the wave is represented as float value[-1 - +1]. */
        public function get bitRate() : Number { return _bitRate; }
        
        /** Sound volume. */
        public function get volume() : Number { return _masterVolume; }
        public function set volume(v:Number) : void {
            _masterVolume = v;
            _soundTransform.volume = _masterVolume * _faderVolume;
            if (_soundChannel) _soundChannel.soundTransform = _soundTransform;
        }
        
        /** Sound panning. */
        public function get pan() : Number { return _soundTransform.pan; }
        public function set pan(p:Number) : void {
            _soundTransform.pan = p;
            if (_soundChannel) _soundChannel.soundTransform = _soundTransform;
        }
        
        
        //----- measured times
        /** previous compiling time [ms]. */
        public function get compileTime() : int { return _timeCompile; }
        
        /** previous rendering time [ms]. */
        public function get renderTime() : int { return _timeRender; }
        
        /** average processing time in 1sec [ms]. */
        public function get processTime() : int { return _timeProcess; }
        
        /** progression of current compiling/rendering (0=start -> 1=finish). */
        public function get jobProgress() : Number { return _jobProgress; }
        
        /** progression of all queued jobs (0=start -> 1=finish). */
        public function get jobQueueProgress() : Number {
            if (_queueLength == 0) return 1;
            return (_queueLength - _jobQueue.length - 1 + _jobProgress) / _queueLength;
        }
        
        /** streaming latency [ms]. */
        public function get latency() : Number { return _latency; }
        
        /** compiling/rendering jobs queue length. */
        public function get jobQueueLength() : int { return _jobQueue.length; }
        
        
        //----- status flags
        /** Is job executing ? */
        public function get isJobExecuting() : Boolean { return (_jobProgress>0 && _jobProgress<1); }
        
        /** Is streaming ? */
        public function get isPlaying() : Boolean { return (_soundChannel != null); }
        
        /** Is paused ? */
        public function get isPaused() : Boolean { return _isPaused; }
        
        
        //----- background sound
        /** background sound */
        public function get backgroundSound() : Sound { return _backgroundSound; }
        
        /** track for background sound */
        public function get backgroundSoundTrack() : SiMMLTrack { return _backgroundTrack; }
        
        /** background sound fading out time in seconds */
        public function get backgroundSoundFadeOutTime() : Number { return _backgroundFadeOutFrames * _bufferLength / _sampleRate; }
        
        /** background sound fading in time in seconds */
        public function get backgroundSoundFadeInTime() : Number { return _backgroundFadeInFrames * _bufferLength / _sampleRate; }
        
        /** background sound fading time in seconds */
        public function get backgroundSoundFadeGapTime() : Number { return _backgroundFadeGapFrames * _bufferLength / _sampleRate; }
        
        /** background sound volume @default 0.5 */
        public function get backgroundSoundVolume() : Number { return _backgroundVoice.channelParam.volumes[0]; }
        public function set backgroundSoundVolume(vol:Number) : void {
            _backgroundVoice.channelParam.volumes[0] = vol;
            if (_backgroundTrack) _backgroundTrack.masterVolume = vol * 128;
            if (_backgroundTrackFadeOut) _backgroundTrackFadeOut.masterVolume = vol * 128;
        }
        
        /** MIDI sound module */
        public function get midiModule() : MIDIModule { return _midiModule; }
        
        
        //----- operation
        /** Get playing position[ms] of current data, or Set initial position of playing data. @default 0 */
        public function get position() : Number {
            return sequencer.processedSampleCount * 1000 / _sampleRate;
        }
        public function set position(pos:Number) : void {
            _position = pos;
            if (sequencer.isReadyToProcess) {
                sequencer._resetAllTracks();
                sequencer.dummyProcess(_position * _sampleRate * 0.001);
            }
        }
        
        
        //----- other parameters
        /** The maximum limit of sound tracks. @default 128 */
        public function get maxTrackCount() : int { return sequencer._maxTrackCount; }
        public function set maxTrackCount(max:int) : void { sequencer._maxTrackCount = max; }
        
        /** Beat par minute value of SiON's play. @default 120 */
        public function get bpm() : Number {
            return (sequencer.isReadyToProcess) ? sequencer.bpm : sequencer.setting.defaultBPM;
        }
        public function set bpm(t:Number) : void {
            sequencer.setting.defaultBPM = t;
            if (sequencer.isReadyToProcess) {
                if (!sequencer.isEnableChangeBPM) throw errorCannotChangeBPM();
                sequencer.bpm = t;
            }
        }
        
        /** Auto stop when the sequence finished or fade-outed. @default false */
        public function get autoStop() : Boolean { return _autoStop; }
        public function set autoStop(mode:Boolean) : void { _autoStop = mode; }
        
        /** pause while loading sound @default true */
        public function get pauseWhileLoading() : Boolean { return _suspendWhileLoading; }
        public function set pauseWhileLoading(b:Boolean) : void { _suspendWhileLoading = b; }
        
        /** Debug mode, true; throw Error / false; throw ErrorEvent when error appears inside. @default false */
        public function get debugMode() : Boolean { return _debugMode; }
        public function set debugMode(mode:Boolean) : void { _debugMode = mode; }
        
        /** Note on exception mode, this mode is refered when the noteOn() sound's track IDs are conflicted at the same moment. This value have to be SiONDriver.NEM_*. @default NEM_IGNORE. 
         *  @see #NEM_IGNORE
         *  @see #NEM_REJECT
         *  @see #NEM_OVERWRITE
         *  @see #NEM_SHIFT
         */
        public function get noteOnExceptionMode() : int { return _noteOnExceptionMode; }
        public function set noteOnExceptionMode(mode:int) : void { _noteOnExceptionMode = (0<mode && mode<NEM_MAX) ? mode : 0; }
        
        /** dispatch CHANGE_BPM Event When position changed @default true */
        public function get dispatchChangeBPMEventWhenPositionChanged() : Boolean { return _dispatchChangeBPMEventWhenPositionChanged; }
        public function set dispatchChangeBPMEventWhenPositionChanged(b:Boolean) : void { _dispatchChangeBPMEventWhenPositionChanged = b; }
        
        /** Allow plural drivers <b>[CAUTION] This function is quite experimental</b> and plural drivers require large memory area. */
        static public function set allowPluralDrivers(b:Boolean) : void { _allowPluralDrivers = b; }
        static public function get allowPluralDrivers() : Boolean { return _allowPluralDrivers; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Create driver to manage the synthesizer, sequencer and effector. Only one SiONDriver instance can be created.
         *  @param bufferLength Buffer size of sound stream. The value of 8192, 4096 or 2048 is available.
         *  @param channel Channel count. 1(monoral) or 2(stereo) is available.
         *  @param sampleRate Sampling ratio of wave. 44100 is only available in current version.
         *  @param bitRate Bit ratio of wave. 0 means float value [-1 to 1].
         */
        function SiONDriver(bufferLength:int=2048, channelCount:int=2, sampleRate:int=44100, bitRate:int=0)
        {
            // check mutex
            if (_mutex != null && !_allowPluralDrivers) throw errorPluralDrivers();
            
            // check parameters
            if (bufferLength != 2048 && bufferLength != 4096 && bufferLength != 8192) throw errorParamNotAvailable("stream buffer", bufferLength);
            if (channelCount != 1 && channelCount != 2) throw errorParamNotAvailable("channel count", channelCount);
            if (sampleRate != 44100) throw errorParamNotAvailable("sampling rate", sampleRate);
            
            // initialize tables
            var dummy:*;
            dummy = SiOPMTable.instance; //initialize(3580000, 1789772.5, 44100) sampleRate;
            dummy = SiMMLTable.instance; //initialize();
            
            // allocation
            _jobQueue = new Vector.<SiONDriverJob>();
            module = new SiOPMModule();
            effector = new SiEffectModule(module);
            sequencer = new SiMMLSequencer(module, _callbackEventTriggerOn, _callbackEventTriggerOff, _callbackTempoChanged);
            _sound = new Sound();
            _soundTransform = new SoundTransform();
            _fader = new Fader();
            _timerSequence = new MMLSequence();
            _loadingSoundList = [];
            _midiModule = new MIDIModule();
            _midiConverter = new SiONDataConverterSMF(null, _midiModule);
            
            // initialize
            _tempData = null;
            _channelCount = channelCount;
            _sampleRate = sampleRate; // sampleRate; 44100 is only in current version.
            _bitRate = bitRate;
            _bufferLength = bufferLength;
            _listenEvent = NO_LISTEN;
            _dispatchStreamEvent = false;
            _dispatchFadingEvent = false;
            _preserveStop = false;
            _inStreaming = false;
            _suspendStreaming = false;
            _suspendWhileLoading = true;
            _autoStop = false;
            _noteOnExceptionMode = NEM_IGNORE;
            _debugMode = false;
            _isFinishSeqDispatched = false;
            _dispatchChangeBPMEventWhenPositionChanged = true;
            _timerCallback = null;
            _timerSequence.initialize();
            _timerSequence.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
            _timerSequence.appendNewEvent(MMLEvent.TIMER, 0);
            _timerIntervalEvent = _timerSequence.appendNewEvent(MMLEvent.GLOBAL_WAIT, 0, 0);
            
            _backgroundSound = null;
            _backgroundLoopPoint = -1;
            _backgroundFadeInFrames = 0;
            _backgroundFadeOutFrames = 0;
            _backgroundFadeGapFrames = 0;
            _backgroundTotalFadeFrames = 0;
            _backgroundVoice = new SiONVoice(SiMMLTable.MT_SAMPLE);
            _backgroundVoice.updateVolumes = true;
            _backgroundSample = null;
            _backgroundTrack = null;
            _backgroundTrackFadeOut = null;
            
            _position = 0;
            _masterVolume = 1;
            _faderVolume = 1;
            _soundTransform.pan = 0;
            _soundTransform.volume = _masterVolume * _faderVolume;
            
            _eventListenerPrior = 1;
            _trackEventQueue = new Vector.<SiONTrackEvent>();
            
            _queueInterval = 500;
            _jobProgress = 0;
            _currentJob = 0;
            _queueLength = 0;
            
            _timeCompile = 0;
            _timeProcessTotal = 0;
            _timeProcessData = SLLint.allocRing(TIME_AVARAGING_COUNT);
            _timeProcessAveRatio = _sampleRate / (_bufferLength * TIME_AVARAGING_COUNT);
            _timePrevStream = 0;
            _latency = 0;
            _prevFrameTime = 0;
            _frameRate = 1;
            
            _mmlString    = null;
            _data         = null;
            _soundChannel = null;
            
            // register sound streaming function 
            _sound.addEventListener("sampleData", _streaming);
            
            // set mutex
            _mutex = this;
        }
        
        
        
        
    // interfaces for data preparation
    //----------------------------------------
        /** Compile MML string to SiONData. 
         *  @param mml MML string to compile.
         *  @param data SiONData to compile. The SiONDriver creates new SiONData instance when this argument is null.
         *  @return Compiled data.
         */
        public function compile(mml:String, data:SiONData=null) : SiONData
        {
            try {
                // stop sound
                stop();
                
                // compile immediately
                var t:int = getTimer();
                _prepareCompile(mml, data);
                _jobProgress = sequencer.compile(0);
                _timeCompile = getTimer() - t;
                _mmlString = null;
            } catch(e:Error) {
                // error
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
            
            return _data;
        }
        
        
        /** Push queue job to compile MML string. Start compiling after calling startQueue.<br/>
         *  @param mml MML string to compile.
         *  @param data SiONData to compile.
         *  @return Queue length.
         *  @see #startQueue()
         */
        public function compileQueue(mml:String, data:SiONData) : int
        {
            if (mml == null || data == null) return _jobQueue.length;
            return _jobQueue.push(new SiONDriverJob(mml, null, data, 2, false));
        }
        
        
        
        
    // interfaces for sound rendering
    //----------------------------------------
        /** Render wave data from MML string or SiONData. This method may take long time, please consider the using renderQueue() instead.
         *  @param data SiONData or mml String to play.
         *  @param renderBuffer Rendering target. null to create new buffer. The length of this argument limits the rendering length (except for 0).
         *  @param renderBufferChannelCount Channel count of renderBuffer. 2 for stereo and 1 for monoral.
         *  @param resetEffector reset all effectors before play data.
         *  @return rendered wave data as Vector.&lt;Number&gt;.
         */
        public function render(data:*, renderBuffer:Vector.<Number>=null, renderBufferChannelCount:int=2, resetEffector:Boolean=true) : Vector.<Number>
        {
            try {
                // stop sound
                stop();
                
                // rendering immediately
                var t:int = getTimer();
                _prepareRender(data, renderBuffer, renderBufferChannelCount, resetEffector);
                while(true) { if (_rendering()) break; }
                _timeRender = getTimer() - t;
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
            
            return _renderBuffer;
        }
        
        
        /** Push queue job to render sound. Start rendering after calling startQueue.<br/>
         *  @param data SiONData or mml String to render.
         *  @param renderBuffer Rendering target. The length of renderBuffer limits rendering length except for 0.
         *  @param renderBufferChannelCount Channel count of renderBuffer. 2 for stereo and 1 for monoral.
         *  @return Queue length.
         *  @see #startQueue()
         */
        public function renderQueue(data:*, renderBuffer:Vector.<Number>, renderBufferChannelCount:int=2, resetEffector:Boolean=false) : int
        {
            if (data == null || renderBuffer == null) return _jobQueue.length;
            
            if (data is String) {
                var compiled:SiONData = new SiONData();
                _jobQueue.push(new SiONDriverJob(data as String, null, compiled, 2, false));
                return _jobQueue.push(new SiONDriverJob(null, renderBuffer, compiled, renderBufferChannelCount, resetEffector));
            } else 
            if (data is SiONData) {
                return _jobQueue.push(new SiONDriverJob(null, renderBuffer, data as SiONData, renderBufferChannelCount, resetEffector));
            }
            
            var e:Error = errorDataIncorrect();
            if (_debugMode) throw e;
            else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            return _jobQueue.length;
        }
        
        
        
        
    // interfaces for jobs queue
    //----------------------------------------
        /** Execute all elements queued by compileQueue() and renderQueue().
         *  After calling this function, the SiONEvent.QUEUE_PROGRESS, SiONEvent.QUEUE_COMPLETE and ErrorEvent.ERROR events will be dispatched.<br/>
         *  The SiONEvent.QUEUE_PROGRESS is dispatched when it's executing queued job.<br/>
         *  The SiONEvent.QUEUE_COMPLETE is dispatched when finish all queued jobs.<br/>
         *  The ErrorEvent.ERROR is dispatched when some error appears during the compile.<br/>
         *  @param interval Interupting interval
         *  @return Queue length.
         *  @see #compileQueue()
         *  @see #renderQueue()
         */
        public function startQueue(interval:int=500) : int
        {
            try {
                stop();
                _queueLength = _jobQueue.length;
                if (_jobQueue.length > 0) {
                    _queueInterval = interval;
                    _executeNextJob();
                    _queue_addAllEventListners();
                }
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                _cancelAllJobs();
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
            return _queueLength;
        }
                
        
        /** Listen loading status of flash.media.Sound instance. 
         *  When SiONDriver.pauseWhileLoading is true, SiONDriver starts streaming after all Sound instances passed by this function are loaded.
         *  @param sound Sound or SoundLoader instance to listern 
         *  @param prior listening priority 
         *  @return return false when the sound is loaded already.
         *  @see #pauseWhileLoading()
         *  @see #clearLoadingSoundList()
         */
        public function listenSoundLoadingStatus(sound:*, prior:int=-99999) : Boolean 
        {
            if (_loadingSoundList.indexOf(sound) != -1) return true;
            if (sound is Sound) {
                if (sound.bytesTotal == 0 || sound.bytesLoaded != sound.bytesTotal) {
                    _loadingSoundList.push(sound);
                    sound.addEventListener(Event.COMPLETE,        _onSoundEvent, false, prior);
                    sound.addEventListener(IOErrorEvent.IO_ERROR, _onSoundEvent, false, prior);
                    return true;
                }
            } else 
            if (sound is SoundLoader) {
                if (sound.loadingFileCount > 0) {
                    _loadingSoundList.push(sound);
                    sound.addEventListener(Event.COMPLETE,   _onSoundEvent, false, prior);
                    sound.addEventListener(ErrorEvent.ERROR, _onSoundEvent, false, prior);
                    return true;
                }
            } else {
                throw errorCannotListenLoading();
            }
            return false;
        }
        
        
        /** Clear all listening sound list registerd by SiONDriver.listenLoadingStatus().
         */
        public function clearSoundLoadingList() : void
        {
            _loadingSoundList.length = 0;
        }
        
        
        /** Set hash table of Sound instance refered from #SAMPLER and #PCMWAVE commands. You have to set this table BEFORE compile mml.
         */
        public function setSoudReferenceTable(soundReferenceTable:* = null) : void
        {
            SiOPMTable.instance.soundReference = soundReferenceTable || {};
        }
        
        
        
    // interfaces for sound streaming
    //----------------------------------------
        /** Play SiONData or MML string.
         *  @param data SiONData, mml String, Sound object, mp3 file URLRequest or SMFData object to play. You can pass null when resume after pause or streaming without any data.
         *  @param resetEffector reset all effectors before play data.
         *  @return SoundChannel instance to play data. This instance is same as soundChannel property.
         *  @see #soundChannel
         */
        public function play(data:*=null, resetEffector:Boolean=true) : SoundChannel
        {
            try {
                if (_isPaused) {
                    _isPaused = false;
                } else {
                    // stop sound
                    stop();
                    
                    // preparation
                    _prepareProcess(data, resetEffector);

                    // initialize
                    _timeProcessTotal = 0;
                    for (var i:int=0; i<TIME_AVARAGING_COUNT; i++) {
                        _timeProcessData.i = 0;
                        _timeProcessData = _timeProcessData.next;
                    }
                    _isPaused = false;
                    _isFinishSeqDispatched = (data == null);
                    
                    // start streaming
                    _suspendStreaming = true;
                    _soundChannel = _sound.play();
                    _soundChannel.soundTransform = _soundTransform;
                    _process_addAllEventListners();
                }
            } catch(e:Error) {
                // error
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
            
            return _soundChannel;
        }
        
        
        /** Stop sound. */
        public function stop() : void
        {
            if (_soundChannel) {
                if (_inStreaming) {
                    _preserveStop = true;
                } else {
                    stopBackgroundSound();
                    _removeAllEventListners();
                    _preserveStop = false;
                    _soundChannel.stop();
                    _soundChannel = null;
                    _latency = 0;
                    _fader.stop();
                    _faderVolume = 1;
                    _isPaused = false;
                    _soundTransform.volume = _masterVolume;
                    sequencer._sion_internal::_stopSequence();
                    
                    // dispatch streaming stop event
                    dispatchEvent(new SiONEvent(SiONEvent.STREAM_STOP, this));
                }
            }
        }
        
        
        /** Reset signal processor. The effector and sequencer will not be reset. If you want to reset all, call SiONDriver.stop() instead. */
        public function reset() : void
        {
            sequencer._resetAllTracks();
        }
        
        
        /** Pause sound. You can resume it by resume() or play(). @see resume() @see play() */
        public function pause() : void
        {
            _isPaused = true;
        }
        
        
        /** Resume sound. same as play() after pause(). @see pause() */
        public function resume() : void
        {
            _isPaused = false;
        }
        
        
        /** Play Sound as a background.
         *  @param sound Sound instance to play background.
         *  @param mixLevel Mixing level (0-1), this value same as backgroundSoundVolume.
         *  @param loopPoint loop point in second. -1 sets no loop
         *  @see backgroundSound 
         */
        public function setBackgroundSound(sound:Sound, mixLevel:Number=0.5, loopPoint:Number=-1) : void
        {
            backgroundSoundVolume = mixLevel;
            _backgroundLoopPoint = loopPoint;
            _setBackgroundSound(sound);
        }
        
        
        /** Stop background sound. */
        public function stopBackgroundSound() : void
        {
            _setBackgroundSound(null);
        }
        
        
        /** set fading time of background sound
         *  @param fadeInTime  fade in time [sec]. positive value only
         *  @param fadeOutTime fade out time [sec]. positive value only
         *  @param gapTime     gap between 2 sound [sec]. You can specify negative values to play with cross fading.
         */
        public function setBackgroundSoundFadeTime(fadeInTime:Number, fadeOutTime:Number, gapTime:Number) : void
        {
            var t2f:Number = _sampleRate / _bufferLength;
            _backgroundFadeInFrames  = fadeInTime  * t2f;
            _backgroundFadeOutFrames = fadeOutTime * t2f;
            _backgroundFadeGapFrames = gapTime     * t2f;
            _backgroundTotalFadeFrames = _backgroundFadeOutFrames + _backgroundFadeInFrames + _backgroundFadeGapFrames;
        }
        
        
        /** Fade in all sound played by SiONDriver. You can set this method before calling play().
         *  @param time Fading time [second].
         */
        public function fadeIn(time:Number) : void
        {
            _fader.setFade(_fadeVolume, 0, 1, time * _sampleRate / _bufferLength);
            _dispatchFadingEvent = (hasEventListener(SiONEvent.FADE_PROGRESS));
        }
        
        
        /** Fade out all sound played by SiONDriver.
         *  @param time Fading time [second].
         */
        public function fadeOut(time:Number) : void
        {
            _fader.setFade(_fadeVolume, 1, 0, time * _sampleRate / _bufferLength);
            _dispatchFadingEvent = (hasEventListener(SiONEvent.FADE_PROGRESS));
        }
        
        
        /** Set timer interruption.
         *  @param length16th Interupting interval in 16th beat.
         *  @param callback Callback function. the Type is function():void.
         */
        public function setTimerInterruption(length16th:Number=1, callback:Function=null) : void
        {
            _timerIntervalEvent.length = length16th * sequencer.setting.resolution * 0.0625;
            _timerCallback = (length16th > 0) ? callback : null;
        }
        
        
        /** Set callback interval of SiONTrackEvent.BEAT.
         *  @param length16th Interval in 16th beat. 2^n is only available(1,2,4,8,16....).
         */
        public function setBeatCallbackInterval(length16th:Number=1) : void
        {
            var filter:int = 1;
            while (length16th > 1.5) {
                filter <<= 1;
                length16th *= 0.5
            }
            sequencer._setBeatCallbackFilter(filter - 1);
        }
        
        
        /** Force dispatch stream event. The SiONEvent.STREAM is dispatched only when the event listener is set BEFORE calling play(). You can let SiONDriver to dispatch SiONEvent.STREAM event by this function. 
         *  @param dispatch Set true to force dispatching. Or set false to not dispatching if there are no listeners.
         */
        _sion_internal function forceDispatchStreamEvent(dispatch:Boolean=true) : void
        {
            _dispatchStreamEvent = dispatch || (hasEventListener(SiONEvent.STREAM));
        }
        
        
        
    // Interface for public data registration
    //----------------------------------------
        /** Set wave table data refered by %4.
         *  @param index wave table number.
         *  @param table wave shape vector ranges in -1 to 1.
         */
        public function setWaveTable(index:int, table:Vector.<Number>) : SiOPMWaveTable
        {
            var len:int, bits:int=-1;
            for (len=table.length; len>0; len>>=1) bits++;
            if (bits<2) return null;
            var waveTable:Vector.<int> = SiONUtil.logTransVector(table, 1, null);
            waveTable.length = 1<<bits;
            return SiOPMTable._instance.registerWaveTable(index, waveTable);
        }
        
        
        /** Set PCM wave data rederd by %7.
         *  @param index PCM data number.
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound instance is extracted internally, the maximum length to extract is SiOPMWavePCMData.maxSampleLengthFromSound[samples].
         *  @param samplingNote Sampling wave's original note number, this allows decimal number
         *  @param keyRangeFrom Assigning key range starts from (not implemented in current version)
         *  @param keyRangeTo Assigning key range ends at (not implemented in current version)
         *  @param srcChannelCount channel count of source data, 1 for monoral, 2 for stereo.
         *  @param channelCount channel count of this data, 1 for monoral, 2 for stereo, 0 sets same with srcChannelCount.
         *  @see #org.si.sion.module.SiOPMWavePCMData.maxSampleLengthFromSound
         *  @see #render()
         */
        public function setPCMWave(index:int, data:*, samplingNote:Number=69, keyRangeFrom:int=0, keyRangeTo:int=127, srcChannelCount:int=2, channelCount:int=0) : SiOPMWavePCMData
        {
            var pcmVoice:SiMMLVoice = SiOPMTable._instance._getGlobalPCMVoice(index & (SiOPMTable.PCM_DATA_MAX-1));
            var pcmTable:SiOPMWavePCMTable = pcmVoice.waveData as SiOPMWavePCMTable;
            return pcmTable.setSample(new SiOPMWavePCMData(data, int(samplingNote*64), srcChannelCount, channelCount), keyRangeFrom, keyRangeTo);
        }
        
        
        /** Set sampler wave data refered by %10.
         *  @param index note number. 0-127 for bank0, 128-255 for bank1.
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound is extracted when the length is shorter than SiOPMWaveSamplerData.extractThreshold[msec].
         *  @param ignoreNoteOff True to set ignoring note off.
         *  @param pan pan of this sample [-64 - 64].
         *  @param srcChannelCount channel count of source data, 1 for monoral, 2 for stereo.
         *  @param channelCount channel count of this data, 1 for monoral, 2 for stereo, 0 sets same with srcChannelCount.
         *  @return created data instance
         *  @see #org.si.sion.module.SiOPMWaveSamplerData.extractThreshold
         *  @see #render()
         */
        public function setSamplerWave(index:int, data:*, ignoreNoteOff:Boolean=false, pan:int=0, srcChannelCount:int=2, channelCount:int=0) : SiOPMWaveSamplerData
        {
            return SiOPMTable._instance.registerSamplerData(index, data, ignoreNoteOff, pan, srcChannelCount, channelCount);
        }
        
        
        /** Set pcm voice 
         *  @param index PCM data number.
         *  @param voice pcm voice to set, ussualy from SiONSoundFont
         *  @see SiONSoundFont
         */
        public function setPCMVoice(index:int, voice:SiONVoice) : void
        {
            SiOPMTable._instance._setGlobalPCMVoice(index & (SiOPMTable.PCM_DATA_MAX-1), voice);
        }
        
        
        /** Set sampler table 
         *  @param bank bank number
         *  @param table sampler table class, ussualy from SiONSoundFont
         *  @see SiONSoundFont
         */
        public function setSamplerTable(bank:int, table:SiOPMWaveSamplerTable) : void
        {
            SiOPMTable._instance.samplerTables[bank & (SiOPMTable.SAMPLER_TABLE_MAX-1)] = table;
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setPCMWave instead of this function. @see #setPCMWave(). */
        public function setPCMData(index:int, data:Vector.<Number>, samplingOctave:int=5, keyRangeFrom:int=0, keyRangeTo:int=127, isSourceDataStereo:Boolean=false) : SiOPMWavePCMData
        {
            return setPCMWave(index, data, samplingOctave*12+9, keyRangeFrom, keyRangeTo, (isSourceDataStereo)?2:1);
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setPCMWave instead of this function. @see #setPCMWave(). */
        public function setPCMSound(index:int, sound:Sound, samplingOctave:int=5, keyRangeFrom:int=0, keyRangeTo:int=127) : SiOPMWavePCMData
        {
            return setPCMWave(index, sound, samplingOctave*12+9, keyRangeFrom, keyRangeTo, 1, 0);
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setSamplerWave instead of this function. @see #setSamplerWave(). */
        public function setSamplerData(index:int, data:Vector.<Number>, ignoreNoteOff:Boolean=false, channelCount:int=1) : SiOPMWaveSamplerData
        {
            return setSamplerWave(index, data, ignoreNoteOff, 0, channelCount);
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setSamplerWave instead of this function. @see #setSamplerWave(). */
        public function setSamplerSound(index:int, sound:Sound, ignoreNoteOff:Boolean=false, channelCount:int=2) : SiOPMWaveSamplerData
        {
            return setSamplerWave(index, sound, ignoreNoteOff, 0, channelCount);
        }
        
        
        /** Set envelop table data refered by &#64;&#64;,na,np,nt,nf,_&#64;&#64;,_na,_np,_nt and _nf.
         *  @param index envelop table number.
         *  @param table envelop table vector.
         *  @param loopPoint returning point index of looping. -1 sets no loop.
         */
        public function setEnvelopTable(index:int, table:Vector.<int>, loopPoint:int=-1) : void
        {
            SiMMLTable.registerMasterEnvelopTable(index, new SiMMLEnvelopTable(table, loopPoint));
        }
        
        
        /** Set wave table data refered by %6.
         *  @param index wave table number.
         *  @param voice voice to register.
         */
        public function setVoice(index:int, voice:SiONVoice) : void
        {
            if (!voice._isSuitableForFMVoice) throw errorNotGoodFMVoice();
            SiMMLTable.registerMasterVoice(index, voice);
        }
        
        
        /** Clear all of WaveTables, FM Voices, EnvelopTables, Sampler waves and PCM waves. 
         *  @see #setWaveTable()
         *  @see #setVoice()
         *  @see #setEnvelopTable()
         *  @see #setSamplerWave()
         *  @see #setPCMWave()
         */
        public function clearAllUserTables() : void
        {
            SiOPMTable.instance.resetAllUserTables();
            SiMMLTable.instance.resetAllUserTables();
        }
        
        
        
        
    // Interface for intaractivity
    //----------------------------------------
        /** Play sound registered in sampler table (registered by setSamplerData()), same as noteOn(note, new SiONVoice(10), ...).
         *  @param sampleNumber sample number [0-127].
         *  @param length note length in 16th beat. 0 sets no note off, this means you should call noteOff().
         *  @param delay note on delay units in 16th beat.
         *  @param quant quantize in 16th beat. 0 sets no quantization. 4 sets quantization by 4th beat.
         *  @param trackID new tracks id (0-65535).
         *  @param isDisposable use disposable track. The disposable track will free automatically when finished rendering. 
         *         This means you should not keep a dieposable track in your code perpetually. 
         *         If you want to keep track, set this argument false. And after using, SiMMLTrack::setDisposal() to disposed by system.<br/>
         *         [REMARKS] Not disposable track is kept perpetually in the system while streaming, this may causes critical performance loss.
         *  @return SiMMLTrack to play the note. 
         */
        public function playSound(sampleNumber:int, 
                                  length:Number      = 0, 
                                  delay:Number       = 0, 
                                  quant:Number       = 0, 
                                  trackID:int        = 0, 
                                  isDisposable:Boolean = true) : SiMMLTrack
        {
            var internalTrackID:int = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.DRIVER_NOTE,
                mmlTrack:SiMMLTrack = null, 
                delaySamples:Number = sequencer.calcSampleDelay(0, delay, quant);
            
            // check track id exception
            if (_noteOnExceptionMode != NEM_IGNORE) {
                // find a track sounds at same timing
                mmlTrack = sequencer._findActiveTrack(internalTrackID, delaySamples);
                if (_noteOnExceptionMode == NEM_REJECT && mmlTrack != null) return null; // reject
                else if (_noteOnExceptionMode == NEM_SHIFT) { // shift timing
                    var step:int = sequencer.calcSampleLength(quant);
                    while (mmlTrack) {
                        delaySamples += step;
                        mmlTrack = sequencer._findActiveTrack(internalTrackID, delaySamples);
                    }
                }
            }
            
            mmlTrack = mmlTrack || sequencer._newControlableTrack(internalTrackID, isDisposable);
            if (mmlTrack) {
                mmlTrack.setChannelModuleType(10, 0);
                mmlTrack.keyOn(sampleNumber, length * sequencer.setting.resolution * 0.0625, delaySamples);
            }
            return mmlTrack;
        }
        
        
        /** Note on. This function only is available after play(). The NOTE_ON_STREAM event is dispatched inside.
         *  @param note note number [0-127].
         *  @param voice SiONVoice to play note. You can specify null, but it sets only a default square wave.
         *  @param length note length in 16th beat. 0 sets no note off, this means you should call noteOff().
         *  @param delay note on delay units in 16th beat.
         *  @param quant quantize in 16th beat. 0 sets no quantization. 4 sets quantization by 4th beat.
         *  @param trackID new tracks id (0-65535).
         *  @param isDisposable use disposable track. The disposable track will free automatically when finished rendering. 
         *         This means you should not keep a dieposable track in your code perpetually. 
         *         If you want to keep track, set this argument false. And after using, call SiMMLTrack::setDisposal() to disposed by system.<br/>
         *         [REMARKS] Not disposable track is kept in the system perpetually while streaming, this may causes critical performance loss.
         *  @return SiMMLTrack to play the note.
         */
        public function noteOn(note:int, 
                               voice:SiONVoice    = null, 
                               length:Number      = 0, 
                               delay:Number       = 0, 
                               quant:Number       = 0, 
                               trackID:int        = 0,
                               isDisposable:Boolean = true) : SiMMLTrack
        {
            var internalTrackID:int = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.DRIVER_NOTE,
                mmlTrack:SiMMLTrack = null, 
                delaySamples:Number = sequencer.calcSampleDelay(0, delay, quant);
            
            // check track id exception
            if (_noteOnExceptionMode != NEM_IGNORE) {
                // find a track sounds at same timing
                mmlTrack = sequencer._findActiveTrack(internalTrackID, delaySamples);
                if (_noteOnExceptionMode == NEM_REJECT && mmlTrack != null) return null; // reject
                else if (_noteOnExceptionMode == NEM_SHIFT) { // shift timing
                    var step:int = sequencer.calcSampleLength(quant);
                    while (mmlTrack) {
                        delaySamples += step;
                        mmlTrack = sequencer._findActiveTrack(internalTrackID, delaySamples);
                    }
                }
            }

            mmlTrack = mmlTrack || sequencer._newControlableTrack(internalTrackID, isDisposable);
            if (mmlTrack) {
                if (voice) voice.updateTrackVoice(mmlTrack);
                mmlTrack.keyOn(note, length * sequencer.setting.resolution * 0.0625, delaySamples);
            }
            return mmlTrack;
        }
        
        
        /** Note off. This function only is available after play(). The NOTE_OFF_STREAM event is dispatched inside.
         *  @param note note number [-1-127]. The value of -1 ignores note number.
         *  @param trackID track id to note off.
         *  @param delay note off delay units in 16th beat.
         *  @param quant quantize in 16th beat. 0 sets no quantization. 4 sets quantization by 4th beat.
         *  @param stopImmediately stop sound with reseting channel's process
         *  @return All SiMMLTracks switched key off.
         */
        public function noteOff(note:int, trackID:int=0, delay:Number=0, quant:Number=0, stopImmediately:Boolean=false) : Vector.<SiMMLTrack>
        {
            var internalTrackID:int = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.DRIVER_NOTE,
                delaySamples:int = sequencer.calcSampleDelay(0, delay, quant), n:int, 
                tracks:Vector.<SiMMLTrack> = new Vector.<SiMMLTrack>();
            for each (var mmlTrack:SiMMLTrack in sequencer.tracks) {
                if (mmlTrack._sion_sequencer_internal::_internalTrackID == internalTrackID) {
                    if (note == -1 || (note == mmlTrack.note && mmlTrack.channel.isNoteOn)) {
                        mmlTrack.keyOff(delaySamples, stopImmediately);
                        tracks.push(mmlTrack);
                    } else if (mmlTrack.executor.noteWaitingFor == note) {
                        // if this track is waiting for starting sound ...
                        mmlTrack.keyOn(note, 1, delaySamples);
                        tracks.push(mmlTrack);
                    }
                }
            }
            return tracks;
        }
        
        
        /** Play sequences with synchronizing. This function only is available after play(). 
         *  @param data The SiONData including sequences. This data is used only for sequences. The system ignores wave, envelop and voice data.
         *  @param voice SiONVoice to play sequence. The voice setting in the sequence has priority.
         *  @param length note length in 16th beat. 0 sets no note off, this means you should call noteOff().
         *  @param delay note on delay units in 16th beat.
         *  @param quant quantize in 16th beat. 0 sets no quantization. 4 sets quantization by 4th beat.
         *  @param trackID new tracks id (0-65535).
         *  @param isDisposable use disposable track. The disposable track will free automatically when finished rendering. 
         *         This means you should not keep a dieposable track in your code perpetually. 
         *         If you want to keep track, set this argument false. And after using, call SiMMLTrack::setDisposal() to disposed by system.<br/>
         *         [REMARKS] Not disposable track is kept in the system perpetually while streaming, this may causes critical performance loss.
         *  @return list of SiMMLTracks to play sequence.
         */
        public function sequenceOn(data:SiONData, 
                                   voice:SiONVoice  = null, 
                                   length:Number    = 0, 
                                   delay:Number     = 0, 
                                   quant:Number     = 1, 
                                   trackID:int      = 0,
                                   isDisposable:Boolean = true) : Vector.<SiMMLTrack>
        {
            var internalTrackID:int = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.DRIVER_SEQUENCE,
                mmlTrack:SiMMLTrack, 
                tracks:Vector.<SiMMLTrack> = new Vector.<SiMMLTrack>(), 
                seq:MMLSequence = data.sequenceGroup.headSequence, 
                delaySamples:int = sequencer.calcSampleDelay(0, delay, quant),
                lengthSamples:int = sequencer.calcSampleLength(length);
            
            // create new sequence tracks
            while (seq) {
                if (seq.isActive) {
                    mmlTrack = sequencer._newControlableTrack(internalTrackID, isDisposable);
                    mmlTrack.sequenceOn(seq, lengthSamples, delaySamples);
                    if (voice) voice.updateTrackVoice(mmlTrack);
                    tracks.push(mmlTrack);
                }
                seq = seq.nextSequence;
            }
            return tracks;
        }
        
        
        /** Stop the sequences with synchronizing. This function only is available after play(). 
         *  @param trackID tracks id to stop.
         *  @param delay sequence off delay units in 16th beat.
         *  @param quant quantize in 16th beat. 0 sets no quantization. 4 sets quantization by 4th beat.
         *  @param stopWithReset stop sound with reseting channel's process
         *  @return list of SiMMLTracks stopped to play sequence.
         */
        public function sequenceOff(trackID:int, delay:Number=0, quant:Number=1, stopWithReset:Boolean=false) : Vector.<SiMMLTrack>
        {
            var internalTrackID:int = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.DRIVER_SEQUENCE,
                delaySamples:int = sequencer.calcSampleDelay(0, delay, quant), stoppedTrack:SiMMLTrack = null,
                tracks:Vector.<SiMMLTrack> = new Vector.<SiMMLTrack>();
            for each (var mmlTrack:SiMMLTrack in sequencer.tracks) {
                if (mmlTrack._sion_sequencer_internal::_internalTrackID == internalTrackID) {
                    mmlTrack.sequenceOff(delaySamples, stopWithReset);
                    tracks.push(mmlTrack);
                }
            }
            return tracks;
        }
        
        
        /** Create new user controlable track. This function only is available after play(). 
         *  @trackID new user controlable track's ID.
         *  @return new user controlable track. This track is NOT disposable.
         */
        public function newUserControlableTrack(trackID:int=0) : SiMMLTrack
        {
            var internalTrackID:int = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.USER_CONTROLLED;
            return sequencer._newControlableTrack(internalTrackID, false);
        }
        
        
        /** dispatch SiONTrackEvent.USER_DEFINED event with latency delay 
         *  @param eventTriggerID SiONTrackEvent.eventTriggerID
         *  @param note SiONTrackEvent.note
         */
        public function dispatchUserDefinedTrackEvent(eventTriggerID:int, note:int) : void
        {
            var event:SiONTrackEvent = new SiONTrackEvent(SiONTrackEvent.USER_DEFINED, this, null, sequencer.streamWritingPositionResidue, note, eventTriggerID);
            _trackEventQueue.push(event);
        }
        
        
        
        
    //====================================================================================================
    // Internal uses
    //====================================================================================================
    // callback for event trigger
    //----------------------------------------
        // call back when sound streaming
        private function _callbackEventTriggerOn(track:SiMMLTrack) : Boolean
        {
            return _publishEventTrigger(track, track.eventTriggerTypeOn, SiONTrackEvent.NOTE_ON_FRAME, SiONTrackEvent.NOTE_ON_STREAM);
        }
        
        // call back when sound streaming
        private function _callbackEventTriggerOff(track:SiMMLTrack) : Boolean
        {
            return _publishEventTrigger(track, track.eventTriggerTypeOff, SiONTrackEvent.NOTE_OFF_FRAME, SiONTrackEvent.NOTE_OFF_STREAM);
        }
        
        // publish event trigger
        private function _publishEventTrigger(track:SiMMLTrack, type:int, frameEvent:String, streamEvent:String) : Boolean
        {
            var event:SiONTrackEvent;
            if (type & 1) { // frame event. dispatch later
                event = new SiONTrackEvent(frameEvent, this, track);
                _trackEventQueue.push(event);
            }
            if (type & 2) { // sound event. dispatch immediately
                event = new SiONTrackEvent(streamEvent, this, track);
                dispatchEvent(event);
                return !(event.isDefaultPrevented());
            }
            return true;
        }
        
        // call back when tempo changed
        private function _callbackTempoChanged(bufferIndex:int, isDummy:Boolean) : void
        {
            if (isDummy && _dispatchChangeBPMEventWhenPositionChanged) {
                dispatchEvent(new SiONTrackEvent(SiONTrackEvent.CHANGE_BPM, this, null, bufferIndex));
            } else {
                var event:SiONTrackEvent = new SiONTrackEvent(SiONTrackEvent.CHANGE_BPM, this, null, bufferIndex);
                _trackEventQueue.push(event);
            }
        }
        
        // call back on beat
        private function _callbackBeat(bufferIndex:int, beatCounter:int) : void
        {
            var event:SiONTrackEvent = new SiONTrackEvent(SiONTrackEvent.BEAT, this, null, bufferIndex, 0, beatCounter);
            _trackEventQueue.push(event);
        }
        
        
        
        
    // operate event listener
    //----------------------------------------
        // add all event listners
        private function _queue_addAllEventListners() : void
        {
            if (_listenEvent != NO_LISTEN) throw errorDriverBusy(LISTEN_QUEUE);
            addEventListener(Event.ENTER_FRAME, _queue_onEnterFrame, false, _eventListenerPrior);
            _listenEvent = LISTEN_QUEUE;
        }
        
        
        // add all event listners
        private function _process_addAllEventListners() : void
        {
            if (_listenEvent != NO_LISTEN) throw errorDriverBusy(LISTEN_PROCESS);
            addEventListener(Event.ENTER_FRAME, _process_onEnterFrame, false, _eventListenerPrior);
            if (hasEventListener(SiONTrackEvent.BEAT)) sequencer._setBeatCallback(_callbackBeat);
            else sequencer._setBeatCallback(null);
            _dispatchStreamEvent = (hasEventListener(SiONEvent.STREAM));
            _prevFrameTime = getTimer();
            _listenEvent = LISTEN_PROCESS;
        }
        
        
        // remove all event listners
        private function _removeAllEventListners() : void
        {
            switch (_listenEvent) {
            case LISTEN_QUEUE:
                removeEventListener(Event.ENTER_FRAME, _queue_onEnterFrame);
                break;
            case LISTEN_PROCESS:
                removeEventListener(Event.ENTER_FRAME, _process_onEnterFrame);
                sequencer._setBeatCallback(null);
                _dispatchStreamEvent = false;
                break;
            }
            _listenEvent = NO_LISTEN;
        }
        
        
        // handler for Sound COMPLETE/IO_ERROR Event 
        private function _onSoundEvent(e:Event) : void
        {
            if (e.target is Sound) {
                e.target.removeEventListener(Event.COMPLETE,        _onSoundEvent);
                e.target.removeEventListener(IOErrorEvent.IO_ERROR, _onSoundEvent);
            } else { // e.target is SoundLoader
                e.target.removeEventListener(Event.COMPLETE,   _onSoundEvent);
                e.target.removeEventListener(ErrorEvent.ERROR, _onSoundEvent);
            }
            var i:int = _loadingSoundList.indexOf(e.target);
            if (i != -1) _loadingSoundList.splice(i, 1);
        }
        
        
        
        
    // parse
    //----------------------------------------
        // parse system command on SiONDriver
        private function _parseSystemCommand(systemCommands:Array) : Boolean
        {
            var id:int, wcol:uint, effectSet:Boolean = false;
            for each (var cmd:* in systemCommands) {
                switch(cmd.command){
                case "#EFFECT":
                    effectSet = true;
                    effector.parseMML(cmd.number, cmd.content, cmd.postfix);
                    break;
                case "#WAVCOLOR":
                case "#WAVC":
                    wcol = parseInt(cmd.content, 16);
                    setWaveTable(cmd.number, SiONUtil.waveColor(wcol));
                    break;
                }
            }
            return effectSet;
        }
        
        
        
        
    // jobs queue
    //----------------------------------------
        // cancel
        private function _cancelAllJobs() : void
        {
            _data = null;
            _mmlString = null;
            _currentJob = 0;
            _jobProgress = 0;
            _jobQueue.length = 0;
            _queueLength = 0;
            _removeAllEventListners();
            dispatchEvent(new SiONEvent(SiONEvent.QUEUE_CANCEL, this, null));
        }
        
        
        // next job
        private function _executeNextJob() : Boolean
        {
            _data = null;
            _mmlString = null;
            _currentJob = 0;
            if (_jobQueue.length == 0) {
                _queueLength = 0;
                _removeAllEventListners();
                dispatchEvent(new SiONEvent(SiONEvent.QUEUE_COMPLETE, this, null));
                return true;
            }
            
            var queue:SiONDriverJob = _jobQueue.shift();
            if (queue.mml) _prepareCompile(queue.mml, queue.data);
            else _prepareRender(queue.data, queue.buffer, queue.channelCount, queue.resetEffector);
            return false;
        }
        
        
        // on enterFrame
        private function _queue_onEnterFrame(e:Event) : void
        {
            try {
                var event:SiONEvent, t:int = getTimer();
                
                switch (_currentJob) {
                case 1: // compile
                    _jobProgress = sequencer.compile(_queueInterval);
                    _timeCompile += getTimer() - t;
                    break;
                case 2: // render
                    _jobProgress += (1 - _jobProgress) * 0.5;
                    while (getTimer() - t <= _queueInterval) { 
                        if (_rendering()) {
                            _jobProgress = 1;
                            break;
                        }
                    }
                    _timeRender += getTimer() - t;
                    break;
                }
                
                // finish job
                if (_jobProgress == 1) {
                    // finish all jobs
                    if (_executeNextJob()) return;
                }
                
                // progress
                event = new SiONEvent(SiONEvent.QUEUE_PROGRESS, this, null, true);
                dispatchEvent(event);
                if (event.isDefaultPrevented()) _cancelAllJobs();   // canceled
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                _cancelAllJobs();
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
        }
        
        
        
        
    // compile
    //----------------------------------------
        // prepare to compile
        private function _prepareCompile(mml:String, data:SiONData) : void
        {
            if (data) data.clear();
            _data = data || new SiONData();
            _mmlString = mml;
            sequencer.prepareCompile(_data, _mmlString);
            _jobProgress = 0.01;
            _timeCompile = 0; 
            _currentJob = 1;
        }
        
        
        
        
    // render
    //----------------------------------------
        // prepare for rendering
        private function _prepareRender(data:*, renderBuffer:Vector.<Number>, renderBufferChannelCount:int, resetEffector:Boolean) : void
        {
            // same preparation as streaming
            _prepareProcess(data, resetEffector);
            
            // prepare rendering buffer
            _renderBuffer = renderBuffer || new Vector.<Number>();
            _renderBufferChannelCount = (renderBufferChannelCount==2) ? 2 : 1;
            _renderBufferSizeMax = _renderBuffer.length;
            _renderBufferIndex = 0;

            // initialize parameters
            _jobProgress = 0.01;
            _timeRender = 0;
            _currentJob = 2;
        }
        
        
        // rendering @return true when finished rendering.
        private function _rendering() : Boolean
        {
            var i:int, j:int, imax:int, extention:int, 
                output:Vector.<Number> = module.output, 
                finished:Boolean = false;
            
            // processing
            module._beginProcess();
            effector._beginProcess();
            sequencer._process();
            effector._endProcess();
            module._endProcess();
            
            // limit rendering length
            imax      = _bufferLength<<1;
            extention = _bufferLength<<(_renderBufferChannelCount-1);
            if (_renderBufferSizeMax != 0 && _renderBufferSizeMax < _renderBufferIndex+extention) {
                extention = _renderBufferSizeMax - _renderBufferIndex;
                finished = true;
            }
            
            // extend buffer
            if (_renderBuffer.length < _renderBufferIndex+extention) {
                _renderBuffer.length = _renderBufferIndex+extention;
            }
            
            // copy output
            if (_renderBufferChannelCount==2) {
                for (i=0, j=_renderBufferIndex; i<imax; i++, j++) {
                    _renderBuffer[j] = output[i];
                }
            } else {
                for (i=0, j=_renderBufferIndex; i<imax; i+=2, j++) {
                    _renderBuffer[j] = output[i];
                }
            }
            
            // incerement index
            _renderBufferIndex += extention;
            
            return (finished || (_renderBufferSizeMax==0 && sequencer.isFinished));
        }
        
        
        
        
    // process
    //----------------------------------------
        // prepare for processing
        private function _prepareProcess(data:*, resetEffector:Boolean) : void
        {
            if (data) {
                if (data is String) { // mml
                    // compile mml and play
                    _tempData = _tempData || new SiONData();
                    _data = compile(data as String, _tempData);
                } else if (data is SiONData) {
                    // type check and play
                    _data = data;
                } else if (data is Sound) {
                    // play data as background sound
                    setBackgroundSound(data);
                } else if (data is URLRequest) {
                    // load sound from url
                    var sound:Sound = new Sound(data);
                    setBackgroundSound(sound);
                } else if (data is SMFData) {
                    // MIDI file
                    _midiConverter.smfData = data;
                    _midiConverter.useMIDIModuleEffector = resetEffector;
                    _data = _midiConverter;
                } else {
                    // not good data type
                    throw errorDataIncorrect();
                }
            }
            
            // THESE FUNCTIONS ORDER IS VERY IMPORTANT !!
            module.initialize(_channelCount, _bitRate, _bufferLength);      // initialize DSP
            module.reset();                                                 // reset all channels
            if (resetEffector) effector.initialize();                       // initialize (or reset) effectors
            else effector._reset();
            sequencer._prepareProcess(_data, _sampleRate, _bufferLength);   // set sequencer tracks (should be called after module.reset())
            if (_data) _parseSystemCommand(_data.systemCommands);           // parse #EFFECT command (should be called after effector._reset())
            effector._prepareProcess();                                     // set effector connections
            _trackEventQueue.length = 0;                                    // clear event que
            
            // set position
            if (_data && _position > 0) {
                sequencer.dummyProcess(_position * _sampleRate * 0.001);
            }
            
            // start background sound
            if (_backgroundSound) {
                _startBackgroundSound();
            }
            
            // set timer interruption
            if (_timerCallback != null) {
                sequencer.setGlobalSequence(_timerSequence); // set timer interruption
                sequencer._setTimerCallback(_timerCallback);
            }
        }
        
        
        // on enterFrame
        private function _process_onEnterFrame(e:Event) : void
        {
            // frame rate
            var t:int = getTimer();
            _frameRate = t - _prevFrameTime;
            _prevFrameTime = t;
            
            // _suspendStreaming = true when first streaming
            if (_suspendStreaming) {
                _onSuspendStream();
            } else {
                // preserve stop
                if (_preserveStop) stop();

                // frame trigger
                if (_trackEventQueue.length > 0) {
                    _trackEventQueue = _trackEventQueue.filter(_trackEventQueueFilter);
                }
            }
        }
        
        
        // _trackEventQueue filter
        private function _trackEventQueueFilter(e:SiONTrackEvent, i:int, v:Vector.<SiONTrackEvent>) : Boolean {
            if (e._decrementTimer(_frameRate)) {
                dispatchEvent(e);
                return false;
            }
            return true;
        }
        
        
        // suspend starting stream
        private function _onSuspendStream() : void {
            // reset suspending
            _suspendStreaming = _suspendWhileLoading && (_loadingSoundList.length > 0);

            if (!_suspendStreaming) {
                // dispatch streaming start event
                var event:SiONEvent = new SiONEvent(SiONEvent.STREAM_START, this, null, true);
                dispatchEvent(event);
                if (event.isDefaultPrevented()) stop();   // canceled
            }
        }
        

        // on sampleData
        private function _streaming(e:SampleDataEvent) : void
        {
            var buffer:ByteArray = e.data, extracted:int, 
                output:Vector.<Number> = module.output, 
                imax:int, i:int, event:SiONEvent;

            // calculate latency (0.022675736961451247 = 1/44.1)
            if (_soundChannel) {
                _latency = e.position * 0.022675736961451247 - _soundChannel.position;
            }

            try {
                // set streaming flag
                _inStreaming = true;
                
                if (_isPaused || _suspendStreaming) {
                    // fill silence
                    _fillzero(e.data);
                } else {
                    // process starting time
                    var t:int = getTimer();
                    
                    // processing
                    module._beginProcess();
                    effector._beginProcess();
                    sequencer._process();
                    effector._endProcess();
                    module._endProcess();
                    
                    // calculate average of processing time
                    _timePrevStream = t;
                    _timeProcessTotal -= _timeProcessData.i;
                    _timeProcessData.i = getTimer() - t;
                    _timeProcessTotal += _timeProcessData.i;
                    _timeProcessData   = _timeProcessData.next;
                    _timeProcess = _timeProcessTotal * _timeProcessAveRatio;
                    
                    // write samples
                    imax = output.length;
                    for (i=0; i<imax; i++) buffer.writeFloat(output[i]);
                    
                    // dispatch streaming event
                    if (_dispatchStreamEvent) {
                        event = new SiONEvent(SiONEvent.STREAM, this, buffer, true);
                        dispatchEvent(event);
                        if (event.isDefaultPrevented()) stop();   // canceled
                    }
                    
                    // dispatch finishSequence event
                    if (!_isFinishSeqDispatched && sequencer.isSequenceFinished) {
                        dispatchEvent(new SiONEvent(SiONEvent.FINISH_SEQUENCE, this));
                        _isFinishSeqDispatched = true;
                    }
                    
                    // fading
                    if (_fader.execute()) {
                        var eventType:String = (_fader.isIncrement) ? SiONEvent.FADE_IN_COMPLETE : SiONEvent.FADE_OUT_COMPLETE;
                        dispatchEvent(new SiONEvent(eventType, this, buffer));
                        if (_autoStop && !_fader.isIncrement) stop();
                    } else {
                        // auto stop
                        if (_autoStop && sequencer.isFinished) stop();
                    }
                }
                
                // reset streaming flag
                _inStreaming = false;
                
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
        }
        
        
        // fill zero
        private function _fillzero(buffer:ByteArray) : void {
            var i:int, imax:int = _bufferLength;
            for (i=0; i<imax; i++) {
                buffer.writeFloat(0);
                buffer.writeFloat(0);
            }
        }
        
        
        
        
    // MIDI related
    //----------------------------------------
        /** @private dispatch SiONMIDIEvent call from MIDIModule */
        _sion_internal function _checkMIDIEventListeners() : int
        {
            return ((hasEventListener(SiONMIDIEvent.NOTE_ON))?        SiONMIDIEventFlag.NOTE_ON : 0) | 
                   ((hasEventListener(SiONMIDIEvent.NOTE_OFF))?       SiONMIDIEventFlag.NOTE_OFF : 0) | 
                   ((hasEventListener(SiONMIDIEvent.CONTROL_CHANGE))? SiONMIDIEventFlag.CONTROL_CHANGE : 0) | 
                   ((hasEventListener(SiONMIDIEvent.PROGRAM_CHANGE))? SiONMIDIEventFlag.PROGRAM_CHANGE : 0) | 
                   ((hasEventListener(SiONMIDIEvent.PITCH_BEND))?     SiONMIDIEventFlag.PITCH_BEND : 0);
        }
        
        
        /** @private dispatch SiONMIDIEvent call from MIDIModule */
        _sion_internal function _dispatchMIDIEvent(type:String, track:SiMMLTrack, channelNumber:int, note:int, data:int) : void
        {
            var event:SiONMIDIEvent = new SiONMIDIEvent(type, this, track, channelNumber, sequencer.streamWritingPositionResidue, note, data);
            _trackEventQueue.push(event);
        }
        
        
        
        
    // operations
    //----------------------------------------
        // volume fading
        private function _fadeVolume(v:Number) : void {
            _faderVolume = v;
            _soundTransform.volume = _masterVolume * _faderVolume;
            if (_soundChannel) _soundChannel.soundTransform = _soundTransform;
            if (_dispatchFadingEvent) {
                var event:SiONEvent = new SiONEvent(SiONEvent.FADE_PROGRESS, this, null, true);
                dispatchEvent(event);
                if (event.isDefaultPrevented()) _fader.stop();   // canceled
            }
        }
        
        
        
        
    // baclkground sound
    //----------------------------------------
        // 1st internal entry point (pass null to stop sound)
        private function _setBackgroundSound(sound:Sound) : void {
            if (sound) {
                if (sound.bytesTotal == 0 || sound.bytesLoaded != sound.bytesTotal) {
                    sound.addEventListener(Event.COMPLETE,        _onBackgroundSoundLoaded);
                    sound.addEventListener(IOErrorEvent.IO_ERROR, _errorBackgroundSound);
                } else {
                    _backgroundSound = sound;
                    if (isPlaying) _startBackgroundSound();
                }
            } else {
                // stop
                _backgroundSound = null;
                if (isPlaying) _startBackgroundSound();
            }
        }
        
        
        // on loaded
        private function _onBackgroundSoundLoaded(e:Event) : void {
            _backgroundSound = e.target as Sound;
            if (isPlaying) _startBackgroundSound();
        }
        
        
        // start
        private function _startBackgroundSound() : void {
            // frame index of start and end fading
            var startFrame:int, endFrame:int;
            
            // currently fading out -> stop fade out track
            if (_backgroundTrackFadeOut) {
                _backgroundTrackFadeOut.setDisposable();
                _backgroundTrackFadeOut.keyOff(0, true);
                _backgroundTrackFadeOut = null;
            }
            // background sound is playing now -> fade out
            if (_backgroundTrack) {
                _backgroundTrackFadeOut = _backgroundTrack;
                _backgroundTrack = null;
                startFrame = 0;
            } else {
                // no fadeout
                startFrame = _backgroundFadeOutFrames + _backgroundFadeGapFrames;
            }
            
            if (_backgroundSound) {
                // play sound with fade in
                _backgroundSample = new SiOPMWaveSamplerData(_backgroundSound, true, 0, 2, 2);
                _backgroundVoice.waveData = _backgroundSample;
                if (_backgroundLoopPoint != -1) {
                    _backgroundSample.slice(-1, -1, _backgroundLoopPoint * 44100);
                }
                _backgroundTrack = sequencer._newControlableTrack(SiMMLTrack.DRIVER_BACKGROUND, false);
                _backgroundTrack.expression = 128;
                _backgroundVoice.updateTrackVoice(_backgroundTrack);
                _backgroundTrack.keyOn(60, 0, (_backgroundFadeOutFrames+_backgroundFadeGapFrames)*_bufferLength);
                endFrame = _backgroundTotalFadeFrames;
            } else {
                // no new sound
                _backgroundSample = null;
                _backgroundVoice.waveData = null;
                _backgroundLoopPoint = -1;
                endFrame = _backgroundFadeOutFrames + _backgroundFadeGapFrames;
            }
            
            // set fader
            if (endFrame - startFrame > 0) {
                _fader.setFade(_fadeBackgroundSound, startFrame, endFrame, endFrame - startFrame);
            } else {
                // stop fade out immediately
                if (_backgroundTrackFadeOut) {
                    _backgroundTrackFadeOut.setDisposable();
                    _backgroundTrackFadeOut.keyOff(0, true);
                    _backgroundTrackFadeOut = null;
                }
            }
        }
        
        
        // error
        private function _errorBackgroundSound(e:IOErrorEvent) : void {
            _backgroundSound = null;
            throw errorSoundLoadingFailure();
        }
        
        
        // background sound cross fading
        private function _fadeBackgroundSound(v:Number) : void {
            var fo:Number, fi:Number=0;
            if (_backgroundTrackFadeOut) {
                if (_backgroundFadeOutFrames > 0) {
                    fo = 1 - v / _backgroundFadeOutFrames;
                         if (fo<0) fo=0;
                    else if (fo>1) fo=1;
                } else {
                    fo = 0;
                }
                _backgroundTrackFadeOut.expression = fo * 128;
            }
            if (_backgroundTrack) {
                if (_backgroundFadeInFrames > 0) {
                    fi = 1 - (_backgroundTotalFadeFrames - v) / _backgroundFadeInFrames;
                         if (fi<0) fi=0;
                    else if (fi>1) fi=1;
                } else {
                    fi = 1;
                }
                _backgroundTrack.expression = fi * 128;
            }
            if (_backgroundTrackFadeOut && (fo==0 || fi==1)) {
                _backgroundTrackFadeOut.setDisposable();
                _backgroundTrackFadeOut.keyOff(0, true);
                _backgroundTrackFadeOut = null;
            }
        }

        
        
        
        
    // errors
    //----------------------------------------
        private function errorPluralDrivers() : Error {
            return new Error("SiONDriver error; Cannot create pulral SiONDrivers.");
        }
        
        
        private function errorParamNotAvailable(param:String, num:Number) : Error {
            return new Error("SiONDriver error; Parameter not available. " + param + String(num));
        }
        
        
        private function errorDataIncorrect() : Error {
            return new Error("SiONDriver error; data incorrect in play() or render().");
        }
        
        
        private function errorDriverBusy(execID:int) : Error {
            var states:Array = ["???", "compiling", "streaming", "rendering"];
            return new Error("SiONDriver error: Driver busy. Call " + states[execID] + " while " + states[_listenEvent] + ".");
        }
        
        
        private function errorCannotChangeBPM() : Error {
            return new Error("SiONDriver error: Cannot change bpm while rendering (SiONTrackEvent.NOTE_*_STREAM).");
        }
        
        
        private function errorNotGoodFMVoice() : Error {
            return new Error("SiONDriver error; Cannot register the voice.");
        }
        
        
        private function errorCannotListenLoading() : Error {
            return new Error("SiONDriver error; the class not available for listenSoundLoadingStatus");
        }
        
        
        private function errorSoundLoadingFailure() : Error {
            return new Error("SiONDriver error; fail to load the sound file");
        }
    }
}




import org.si.sion.SiONData;

class SiONDriverJob
{
    public var mml:String;
    public var buffer:Vector.<Number>;
    public var data:SiONData;
    public var channelCount:int;
    public var resetEffector:Boolean;
    
    function SiONDriverJob(mml_:String, buffer_:Vector.<Number>, data_:SiONData, channelCount_:int, resetEffector_:Boolean) 
    {
        mml = mml_;
        buffer = buffer_;
        data = data_ || new SiONData();
        channelCount = channelCount_;
        resetEffector = resetEffector_;
    }
}


