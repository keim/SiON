// Sample for fade-in and out.
package {
    import flash.display.Sprite;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sion.utils.SiONPresetVoice;
    
    
    public class FadeInOut extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // preset voice
        public var presetVoice:SiONPresetVoice = new SiONPresetVoice();
        
        // voice for sampler "%10"
        public var samplerVoice:SiONVoice = new SiONVoice(10);
        
        // MML data
        public var drumLoop:SiONData;
        
        // constructor
        function FadeInOut() {
            // compile mml. 
            drumLoop = driver.compile("#EFFECT0{ws95lf4000}; %6@0o3l8$c2cc.c.; %6@1o3$rcrc; %6@2v8l16$[crccrrcc]; %6@3v8o3$[rc8r8]")
            
            // set voices of "%6@0-3" from preset
            var percusVoices:Array = presetVoice["valsound.percus"];
            drumLoop.setVoice(0, percusVoices[0]);  // bass drum
            drumLoop.setVoice(1, percusVoices[27]); // snare drum
            drumLoop.setVoice(2, percusVoices[16]); // close hihat
            drumLoop.setVoice(3, percusVoices[21]); // open hihat
            
            // listen click
            stage.addEventListener("click", _onClick);

            // listen FADE_PROGRESS and FADE_*_COMPLETE
            driver.addEventListener(SiONEvent.FADE_PROGRESS,     _onFading);
            driver.addEventListener(SiONEvent.FADE_IN_COMPLETE,  _onFadeInComplete);
            driver.addEventListener(SiONEvent.FADE_OUT_COMPLETE, _onFadeOutComplete);
            
            // stop when fadeout is completed.
            driver.autoStop = true;
            
            // ...and play it
            driver.play(drumLoop);
            
            // fade-in in 5[sec]
            driver.fadeIn(5);
        }
        
        
        private function _onClick(e:Event) : void
        {
            // fade-out in 5[sec] when fader is not active. The fader is active while fading.
            if (!driver.fader.isActive) driver.fadeOut(5);
        }
        
        
        // dispatch while fading
        private function _onFading(e:SiONEvent) : void
        {
            // driver.fader.value refers the fading volume ranged between 0-1.
            trace(driver.fader.value);
        }
        
        
        // dispatch when finished to fade in.
        private function _onFadeInComplete(e:SiONEvent) : void
        {
            trace(">fade in");
        }
        
        
        // dispatch when finished to fade out.
        private function _onFadeOutComplete(e:SiONEvent) : void
        {
            trace(">fade out");
        }
    }
}

