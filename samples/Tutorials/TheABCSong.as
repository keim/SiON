// the simplest example
package {
    import flash.display.Sprite;
    import org.si.sion.*;
    
    public class TheABCSong extends Sprite {
        public var driver:SiONDriver = new SiONDriver();
        
        function TheABCSong() {
            driver.play("t100 l8 [ccggaag4 ffeeddc4 | [ggffeed4]2 ]2");
        }
    }
}

