import com.haxepunk.HXP;
import com.haxepunk.Scene;
import com.haxepunk.utils.Input;
import spinehx.SkeletonData;
import spinehx.Bone;
import spinehx.AnimationState;
import spinehx.Animation;
import spinehx.AnimationStateData;
import spinehx.SkeletonData;
import spinehx.SkeletonJson;
import spinehx.atlas.TextureAtlas;
import spinehx.platform.nme.BitmapDataTextureLoader;
import spinepunk.SpinePunk;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

#if openfl
import openfl.Assets;
import openfl.display.FPS;
#else
import nme.Assets;
import nme.display.FPS;
#end

class MainScene extends Scene {
    static inline var an1="walk";
    static inline var an2="jump";
    var on1=true;

    var atlas:TextureAtlas;
    var skeleton:SpinePunk;
    var root_:Bone;
    var state:AnimationState;
    var lastTime:Float = 0.0;
    
    var mode:Int = 1;
        
    public override function begin() {
        lastTime = haxe.Timer.stamp();
        
        atlas = TextureAtlas.create(Assets.getText("assets/humanoid.atlas"), "assets/", new BitmapDataTextureLoader());
        var json = SkeletonJson.create(atlas);
        var skeletonData:SkeletonData = json.readSkeletonData("humanoid", Assets.getText("assets/humanoid.json"));
        
        skeleton = new SpinePunk(skeletonData);
        
        // Define mixing between animations.
        var stateData = new AnimationStateData(skeletonData);
        stateData.setMixByName(an1, an2, 0);
        stateData.setMixByName(an2, an1, 0);
        stateData.setMixByName(an2, an2, 0);
        stateData.setMixByName(an1, an2, 0);
        
        state = new AnimationState(stateData);
        state.setAnimationByName(an1, true);
        
        skeleton.x = 400;
        skeleton.y = 300;
        skeleton.flipY = true;
        skeleton.state = state;
        skeleton.stateData = stateData;
        skeleton.speed = 1.5;
        
        //skeleton.updateWorldTransform();
        
        lastTime = haxe.Timer.stamp();
        
        add(skeleton);
    }
    
    public function onClick():Void {
//        mode++;
//        mode%=3;
        on1 = !on1;
        state.setAnimationByName(on1 ? an1 : an2, false);
        //state.addAnimationByNameSimple(an1, true);
    }
    
    public override function update() {
        if (state.getAnimation().getName() == an1) {
            // After one second, change the current animation. Mixing is done by AnimationState for you.
            if (state.getTime() >= skeleton.state.getAnimation().getDuration()) {
                skeleton.skeleton.setToSetupPose();
                state.setAnimationByName(an2, false);
            }
        } else {
            if (state.getTime() > skeleton.state.getAnimation().getDuration()) {
                skeleton.skeleton.setToSetupPose();
                state.setAnimationByName(an1, true);
            }
        }
        
        if (Input.mousePressed) onClick();
        
        super.update();
    }
}
