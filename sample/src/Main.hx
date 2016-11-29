import haxepunk.Engine;
import haxepunk.HXP;
import haxepunk.RenderMode;
import flash.events.Event;
import flash.display.BitmapData;
import flash.geom.Point;

class Main extends Engine {
    public function new(width : Int=0, height : Int=0, frameRate : Float=60, fixed : Bool=false, ?renderMode : RenderMode) {
        super(width, height, frameRate, fixed, renderMode);
    }

    override public function init()
    {
#if debug
        HXP.console.enable();
#end
        HXP.screen.color = 0x808080;
        HXP.scene = new MainScene();
    }
    
    public static function main() { new Main(); }
}
