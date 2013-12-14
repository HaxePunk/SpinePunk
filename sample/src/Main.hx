import com.haxepunk.Engine;
import com.haxepunk.HXP;
import com.haxepunk.RenderMode;
import flash.events.Event;
import flash.display.BitmapData;
import flash.geom.Point;

class Main extends Engine {
    public function new(width : Int=0, height : Int=0, frameRate : Float=60, fixed : Bool=false, ?renderMode : RenderMode) {
        super(width, height, frameRate, fixed, renderMode);
        //super(width, height, frameRate, fixed, RenderMode.BUFFER);
    }

    override public function init()
    {
#if debug
        HXP.console.enable();
#end
        HXP.scene = new MainScene();
        
        onResize();
        HXP.stage.addEventListener(Event.RESIZE, onResize);
    }
    
    function onResize(e:Event=null) {
        HXP.screen.scaleX = 
        HXP.screen.scaleY = 
            (Math.min(HXP.screen.scaleX, HXP.screen.scaleY));
    }

    public static function main() { new Main(); }
}
