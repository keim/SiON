// Sample for custom fader.
package {
    import flash.display.Sprite;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sion.utils.Fader;
    import org.si.sion.utils.SiONPresetVoice;
    import org.si.sion.effector.SiCtrlFilterLowPass;
    
    
    public class CustomFader extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // preset voice
        public var presetVoice:SiONPresetVoice = new SiONPresetVoice();
        
        // voice for sampler "%10"
        public var samplerVoice:SiONVoice = new SiONVoice(10);
        
        // MML data
        public var drumLoop:SiONData;

        // Custom fader
        public var lpfFader:Fader = new Fader();
        
        // low pass filter effector
        public var lpf:SiCtrlFilterLowPass = new SiCtrlFilterLowPass();
        
        
        // constructor
        function CustomFader() {
            // compile mml. 
            drumLoop = driver.compile("%6@0o3l8$c2cc.c.; %6@1o3$rcrc; %6@2v8l16$[crccrrcc]; %6@3v8o3$[rc8r8]")
            
            // set voices of "%6@0-3" from preset
            var percusVoices:Array = presetVoice["valsound.percus"];
            drumLoop.setVoice(0, percusVoices[0]);  // bass drum
            drumLoop.setVoice(1, percusVoices[27]); // snare drum
            drumLoop.setVoice(2, percusVoices[16]); // close hihat
            drumLoop.setVoice(3, percusVoices[21]); // open hihat
            
            // listen click
            driver.addEventListener(SiONEvent.STREAM_START, _onStreamStart);
            driver.addEventListener(SiONEvent.STREAM, _onStream);
            stage.addEventListener("click", _onClick);
            
            // set parameters of low pass filter
            lpf.initialize();
            lpf.control(1, 0.5);
            
            // connect low pass filter on slot0.
            driver.effector.initialize();
            driver.effector.connect(0, lpf);
            
            // play with an argument of resetEffector = false.
            driver.play(drumLoop, false);
        }
        
        
        private function _onClick(e:Event) : void
        {
            // start custom fade with 10[sec] if the fader is inactive. 
            // The "10 * 44100 / 2048" calculates callbacking count of _onStream in 10 seconds.
            if (!lpfFader.isActive) lpfFader.setFade(_fadeLPF, 1, 0, 10 * 44100 / 2048);
        }
        
        
        private function _onStreamStart(e:SiONEvent) : void
        {
            // start custom fade with 5[sec]. 
            // The "5 * 44100 / 2048" calculates callbacking count of _onStream in 5 seconds.
            lpfFader.setFade(_fadeLPF, 0, 1, 5 * 44100 / 2048);
        }
        
        
        private function _onStream(e:SiONEvent) : void
        {
            // execute fader in each streaming timing
            if (lpfFader.execute()) {
                // Fader.execute() returns true when the fading achieves to the end.
                // and stop if the fader is decrement.
                if (!lpfFader.isIncrement) driver.stop();
            }
        }
        
        
        // fading callback
        private function _fadeLPF(v:Number) : void
        {
            // change filters cutoff
            lpf.control(v, 0.5);
        }
    }
}

