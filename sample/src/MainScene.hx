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
    static var animations=["stand", "walk", "run", "jump", "draw weapon", "swing 1", "swing 2", "swing 3", "swing 1", "swing 1", "swing 2", "death", "revive"];
    var on=0;
    
    var atlas:TextureAtlas;
    var skeleton:SpinePunk;
    var root_:Bone;
    var state:AnimationState;
    var lastTime:Float = 0.0;
    static var moveSpeed:Float=0;
    
    var mode:Int = 1;
        
    public override function begin() {
        moveSpeed = 75 / HXP.screen.scale;
        
        lastTime = haxe.Timer.stamp();
        
        atlas = TextureAtlas.create(Assets.getText("assets/humanoid.atlas"), "assets/", new BitmapDataTextureLoader());
        var json = SkeletonJson.create(atlas);
        var skeletonData:SkeletonData = json.readSkeletonData("humanoid", Assets.getText("assets/humanoid.json"));
        
        skeleton = new SpinePunk(skeletonData);
        skeleton.skin = 'elf';

        // Define mixing between animations.
        var stateData = new AnimationStateData(skeletonData);
        /*stateData.setMixByName(an1, an2, 0);
        stateData.setMixByName(an2, an1, 0);
        stateData.setMixByName(an2, an2, 0);
        stateData.setMixByName(an1, an2, 0);*/
        
        state = new AnimationState(stateData);
        state.setAnimationByName(animations[0], false);
        
        skeleton.x = 50;
        skeleton.y = HXP.screen.height/2/HXP.screen.scale;
        skeleton.flipY = true;
        skeleton.state = state;
        skeleton.stateData = stateData;
        skeleton.speed = 1;
        skeleton.scale = 1/HXP.screen.scale;
        
        //skeleton.updateWorldTransform();
        
        lastTime = haxe.Timer.stamp();
        
        add(skeleton);
    }
    
    public function onClick():Void {
//        mode++;
//        mode%=3;
        on += 1;
        if (on >= animations.length) {
            on = 0;
            skeleton.flipX = !skeleton.flipX;
        }
        //state.setAnimationByName(on1 ? an1 : an2, false);
        //state.addAnimationByNameSimple(an1, true);
    }
    
    public override function update() {
        var cur = animations[on];
        var duration = skeleton.state.getAnimation().getDuration();
        switch(cur) {
        case 'death', 'revive': {
            duration += 2;
            if (cur == 'death') skeleton.color = 0x808080;
            else skeleton.color = 0xffffff;
        }
        case 'swing 3': {
            skeleton.color = 0xffffff;
            skeleton.x += (HXP.elapsed*moveSpeed/4) * (skeleton.flipX ? -1 : 1);
        }
        case 'walk': {
            skeleton.color = 0xffffff;
            skeleton.x += (HXP.elapsed*moveSpeed) * (skeleton.flipX ? -1 : 1);
        }
        case 'run', 'jump': {
            skeleton.color = 0xffffff;
            skeleton.x += (HXP.elapsed*moveSpeed*2) * (skeleton.flipX ? -1 : 1);
        }
        default: 
            skeleton.color = 0xffffff;
        }
        
        if (state.getTime() >= duration) {
            if (on + 1 >= animations.length) {
                on = 0;
                skeleton.skeleton.setToSetupPose();
                skeleton.flipX = !skeleton.flipX;
                state.setAnimationByName(animations[0], false);
            } else {
                on += 1;
                if (animations[on] != animations[on-1]) skeleton.skeleton.setToSetupPose();
                state.setAnimationByName(animations[on], false);
            }
        }
        
        if (Input.mousePressed) onClick();
        
        super.update();
    }
}
