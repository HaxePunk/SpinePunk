import haxepunk.HXP;
import haxepunk.Entity;
import haxepunk.Scene;
import haxepunk.assets.AssetCache;
import haxepunk.input.Mouse;
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

class MainScene extends Scene {
	static var animations = ["walk"];
	static var loop = [true];
	var on:Int = 0;

	var atlas:Atlas;
	var skeleton:SpinePunk;
	var skeletonEntity:Entity;
	var state:AnimationState;

	var mode:Int = 0;

	public override function begin() {
		atlas = new Atlas(assetCache.getText("assets/goblins.atlas"), new BitmapDataTextureLoader("assets/"));
		var json = new SkeletonJson(new AtlasAttachmentLoader(atlas));
		var skeletonData:SkeletonData = json.readSkeletonData(assetCache.getText("assets/goblins.json"), "goblins");

		var stateData = new AnimationStateData(skeletonData);
		stateData.defaultMix = 0.2;

		skeleton = new SpinePunk(skeletonData, stateData);
		skeleton.skin = 'goblin';

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
		if (Mouse.mousePressed) onClick();
		super.update();
	}
}
