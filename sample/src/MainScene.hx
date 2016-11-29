import haxepunk.HXP;
import haxepunk.Entity;
import haxepunk.Scene;
import haxepunk.utils.Input;
import spinehaxe.SkeletonData;
import spinehaxe.Bone;
import spinehaxe.animation.AnimationState;
import spinehaxe.animation.Animation;
import spinehaxe.animation.AnimationStateData;
import spinehaxe.SkeletonData;
import spinehaxe.SkeletonJson;
import spinehaxe.atlas.TextureAtlas;
import spinehaxe.platform.nme.BitmapDataTextureLoader;
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
    static var animations=["stand", "walk", "run", "attack unarmed 1", "attack unarmed 2", "attack unarmed 1", "attack unarmed 3", "death", "revive"];
    static var loop      =[true,    true,   true,  false,              false,              false,              false,              false,    false];
    var on=0;
    
    var atlas:TextureAtlas;
    var skeleton:SpinePunk;
    var skeletonEntity:Entity;
    var state:AnimationState;
    
    var mode:Int = 0;
        
    public override function begin() {
        atlas = TextureAtlas.create(Assets.getText("assets/humanoid.atlas"), "assets/", new BitmapDataTextureLoader());
        var json = SkeletonJson.create(atlas);
        var skeletonData:SkeletonData = json.readSkeletonData(Assets.getText("assets/humanoid.json"), "humanoid");
        
        skeleton = new SpinePunk(skeletonData);
        skeleton.skin = 'elf';

        var stateData = new AnimationStateData(skeletonData);
        stateData.defaultMix = 0.2;
        
        state = new AnimationState(stateData);
        state.setAnimationByName(0, animations[0], true);
        
        skeleton.flipY = true;
        skeleton.state = state;
        skeleton.stateData = stateData;
        skeleton.speed = 1;
        skeleton.scale = 0.5;
        skeleton.hitboxSlots = ['body', 'front shoulder', 'mouth'];
        
        skeletonEntity = new Entity(HXP.width/2, HXP.height/2, skeleton);
        add(skeletonEntity);
    }
    
    public function onClick():Void {
        mode = (mode + 1) % animations.length;
        state.setAnimationByName(0, animations[mode], loop[mode]);
    }
    
    public override function update() {
        if (Input.mousePressed) onClick();
        skeleton.update();
        skeletonEntity.setHitboxTo(skeleton.mainHitbox);
        super.update();
    }
}
