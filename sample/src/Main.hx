import haxepunk.Engine;
import haxepunk.HXP;
import flash.events.Event;
import flash.display.BitmapData;
import flash.geom.Point;

class Main extends Engine {
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
