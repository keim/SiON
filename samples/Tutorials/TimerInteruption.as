// Control software synth by primitive operations
package {
    import flash.display.Sprite;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sion.sequencer.SiMMLTrack;
    
    
    public class TimerInteruption extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // voice
        public var voice:SiONVoice = new SiONVoice(5, 0, 40, 24);
        
        // tracks
        public var tracks:Vector.<SiMMLTrack> = new Vector.<SiMMLTrack>(2);
        
        // sequence
        public var sequences:Array = [Vector.<int>([60,60,67,67,69,69,67,0,65,65,64,64,62,62,60,0]),
                                      Vector.<int>([48,55,52,55,48,55,52,55,47,55,50,55,47,55,50,55])];
        // sequence pointer
        public var sequencePointer:int;
        
        
        // constructor
        function TimerInteruption() {
            // listen STREAM_START event to initialize tracks
            driver.addEventListener(SiONEvent.STREAM_START, _onStreamStart)
            // set timer interuption for each 16th beat on bpm=120.
            driver.bpm = 120;
            driver.setTimerInteruption(1, _onTimerInteruption);
            // start streaming
            driver.play();
        }
        
        
        // initialize tracks in STREAM_START event handler.
        private function _onStreamStart(event:SiONEvent) : void {
            // initialize pointer
            sequencePointer = 0;
            // SiMMLSequencer.newControlableTrack allocates new tracks in the sound module.
            tracks[0] = driver.sequencer.newControlableTrack(0);
            tracks[1] = driver.sequencer.newControlableTrack(0);
            // SiONVoice.setTrackVoice sets tracks voice
            voice.setTrackVoice(tracks[0]);
            voice.setTrackVoice(tracks[1]);
        }
        
        
        // timer interuption
        private function _onTimerInteruption() : void {
            if (sequencePointer & 1) {
                var index:int = (sequencePointer >> 1) & 15;
                for (var trackNumber:int=0; trackNumber<2; trackNumber++) {
                    var key:int = sequences[trackNumber][index];
                    // SiMMLTrack.keyOn sets track key on. the 2nd argument sets key on length by sampling count (4410=100ms).
                    if (key > 0) tracks[trackNumber].keyOn(key, 4410);
                }
            }
            ++sequencePointer;
        }
    }
}

