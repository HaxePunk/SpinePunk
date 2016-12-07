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
import spinehaxe.atlas.Atlas;
import spinehaxe.attachments.AtlasAttachmentLoader;
import spinehaxe.platform.openfl.BitmapDataTextureLoader;
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
	static var animations = ["stand", "walk", "run", "attack unarmed 1", "attack unarmed 2", "attack unarmed 1", "attack unarmed 3", "death", "revive"];
	static var loop = [true, true, true, false, false, false, false, false, false];
	var on:Int = 0;

	var atlas:Atlas;
	var skeleton:SpinePunk;
	var skeletonEntity:Entity;
	var state:AnimationState;

	var mode:Int = 0;

	public override function begin() {
		atlas = new Atlas(Assets.getText("assets/humanoid.atlas"), new BitmapDataTextureLoader("assets/"));
		var json = new SkeletonJson(new AtlasAttachmentLoader(atlas));
		var skeletonData:SkeletonData = json.readSkeletonData(Assets.getText("assets/humanoid.json"), "humanoid");

		var stateData = new AnimationStateData(skeletonData);
		stateData.defaultMix = 0.2;

		skeleton = new SpinePunk(skeletonData, stateData);
		skeleton.skin = 'elf';

		state = new AnimationState(stateData);
		state.setAnimationByName(0, animations[0], true);

		skeleton.state = state;
		skeleton.stateData = stateData;
		skeleton.speed = 1;
		skeleton.scale = 0.5;

		skeletonEntity = new Entity(HXP.width/2, HXP.height/2, skeleton);
		add(skeletonEntity);
	}

	public function onClick():Void {
		mode = (mode + 1) % animations.length;
		state.setAnimationByName(0, animations[mode], loop[mode]);
	}

	public override function update() {
		if (Input.mousePressed) onClick();
		super.update();
	}
}
