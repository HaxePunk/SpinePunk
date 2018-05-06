package spinepunk;

import haxe.ds.ObjectMap;
import haxe.ds.Vector;
import haxepunk.HXP;
import haxepunk.Camera;
import haxepunk.Entity;
import haxepunk.Graphic;
import haxepunk.assets.AssetCache;
import haxepunk.assets.AssetLoader;
import haxepunk.graphics.Image;
import haxepunk.graphics.atlas.AtlasData;
import haxepunk.graphics.hardware.Texture;
import haxepunk.math.MathUtil;
import haxepunk.math.Vector2;
import haxepunk.utils.Color;
import spine.Bone;
import spine.Slot;
import spine.Skeleton;
import spine.SkeletonData;
import spine.SkeletonJson;
import spine.animation.AnimationState;
import spine.animation.AnimationStateData;
import spine.atlas.Atlas;
import spine.atlas.AtlasPage;
import spine.atlas.AtlasRegion;
import spine.attachments.AtlasAttachmentLoader;
import spine.attachments.Attachment;
import spine.attachments.MeshAttachment;
import spine.attachments.RegionAttachment;

using Lambda;

class HaxePunkTextureLoader implements spine.atlas.TextureLoader
{
	var prefix:String;
	var assetCache:AssetCache;

	public function new(prefix:String, ?assetCache:AssetCache) {
		this.prefix = prefix;
		this.assetCache = assetCache == null ? AssetCache.global : assetCache;
	}

	public function loadPage(page:AtlasPage, path:String):Void {
		var texture:Texture = assetCache.getTexture(prefix + path, false);
		page.rendererObject = texture;
		page.width = texture.width;
		page.height = texture.height;
	}

	public function loadRegion(region:AtlasRegion):Void {}

	public function unloadPage(page:AtlasPage):Void {}
}

@:access(haxepunk.graphics.Image)
class SpinePunk extends Graphic
{
	static var p:Vector2 = new Vector2();
	static var _triangles:Array<Int> = [0, 1, 2, 0, 2, 3];
	static var _vertices:Array<Float> = new Array();

	public var skeleton:Skeleton;
	public var skeletonData:SkeletonData;
	public var state:AnimationState;
	public var stateData:AnimationStateData;
	public var angle:Float = 0;
	public var speed:Float = 1;
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;
	public var scale:Float = 1;

	var atlasDataMap:Map<Attachment, AtlasData> = new Map();

	var name:String;

	public function new(skeletonData:SkeletonData, stateData:AnimationStateData, smooth:Bool=true)
	{
		super();

		Bone.yDown = true;

		this.skeletonData = skeletonData;
		name = skeletonData.toString();

		if (stateData == null) stateData = new AnimationStateData(skeletonData);
		this.stateData = stateData;
		state = new AnimationState(stateData);

		skeleton = new Skeleton(skeletonData);
		skeleton.x = 0;
		skeleton.y = 0;

		this.smooth = smooth;
		active = true;
	}

	public var skin(default, set):String;
	function set_skin(skin:String)
	{
		if (skin != this.skin)
		{
			skeleton.skinName = skin;
			skeleton.setToSetupPose();
		}
		return this.skin = skin;
	}

	public var flipX(get, set):Bool;

	private function get_flipX():Bool
	{
		return skeleton.flipX;
	}

	private function set_flipX(value:Bool):Bool
	{
		if (value != skeleton.flipX)
		{
			skeleton.flipX = value;
			skeleton.updateWorldTransform();
		}

		return value;
	}

	public var flipY(get, set):Bool;

	private function get_flipY():Bool
	{
		return skeleton.flipY;
	}

	private function set_flipY(value:Bool):Bool
	{
		if (value != skeleton.flipY)
		{
			skeleton.flipY = value;
			skeleton.updateWorldTransform();
		}

		return value;
	}

	/**
	 * Get Spine animation data.
	 * @param	DataName	The name of the animation data files exported from Spine (.atlas .json .png).
	 * @param	DataPath	The directory these files are located at
	 * @param	Scale		Animation scale
	 */
	public static function readSkeletonData(dataName:String, dataPath:String, scale:Float = 1, ?assetCache:AssetCache):SkeletonData
	{
		if (dataPath.lastIndexOf("/") < 0) dataPath += "/"; // append / at the end of the folder path
		var textureLoader = new HaxePunkTextureLoader(dataPath, assetCache);
		var spineAtlas:Atlas = new Atlas(AssetLoader.getText(dataPath + dataName + ".atlas"), textureLoader);
		var json:SkeletonJson = new SkeletonJson(new AtlasAttachmentLoader(spineAtlas));
		json.scale = scale;
		var skeletonData:SkeletonData = json.readSkeletonData(AssetLoader.getText(dataPath + dataName + ".json"), dataName);
		return skeletonData;
	}

	public override function update():Void
	{
		state.update(HXP.elapsed * speed);
		state.apply(skeleton);
		skeleton.updateWorldTransform();

		super.update();
	}

	@:access(haxepunk.graphics.Image)
	public override function render(point:Vector2, camera:Camera):Void
	{
		skeleton.updateWorldTransform();

		var drawOrder:Array<Slot> = skeleton.drawOrder;
		var flipX:Int = (skeleton.flipX) ? -1 : 1;
		var flipY:Int = (skeleton.flipY) ? -1 : 1;
		var flip:Int = flipX * flipY;

		var radians:Float = angle * MathUtil.RAD;
		var cos:Float = Math.cos(radians);
		var sin:Float = Math.sin(radians);

		var sx = scaleX * scale;
		var sy = scaleY * scale;

		var attachment:Attachment;
		var regionAttachment:RegionAttachment;
		var dx:Float, dy:Float;
		var relX:Float, relY:Float;
		var rx:Float, ry:Float;

		for (slot in drawOrder)
		{
			var blend = switch (slot.data.blendMode) {
				case spine.BlendMode.additive: haxepunk.utils.BlendMode.Add;
				default: this.blend;
			};
			attachment = slot.attachment;

			if (attachment != null)
			{
				var atlasData:AtlasData;
				var uvs:Array<Float>;
				var triangles:Array<Int>;
				HXP.clear(_vertices);
				var r:Float, g:Float, b:Float, a:Float;
				if (Std.is(attachment, RegionAttachment))
				{
					var region:RegionAttachment = cast attachment;
					atlasData = getAtlasData(region);
					region.computeWorldVertices(0, 0, slot.bone, _vertices);
					uvs = region.uvs;
					triangles = _triangles;
					r = region.r;
					g = region.g;
					b = region.b;
					a = region.a;
				}
				else if (Std.is(attachment, MeshAttachment))
				{
					var mesh:MeshAttachment = cast attachment;
					atlasData = getAtlasData(mesh);
					mesh.computeWorldVertices(slot, _vertices);
					uvs = mesh.uvs;
					triangles = mesh.triangles;
					r = mesh.r;
					g = mesh.g;
					b = mesh.b;
					a = mesh.a;
				}
				else
				{
					// unsupported attachment type
					continue;
				}

				inline function transformX(x:Float, y:Float)
				{
					return (floorX(camera, this.x) + floorX(camera, skeleton.x + (x * sx * cos) - (y * sy * sin)) + floorX(camera, point.x) - floorX(camera, camera.x * scrollX)) * camera.screenScaleX;
				}
				inline function transformY(x:Float, y:Float)
				{
					return (floorY(camera, this.y) + floorY(camera, skeleton.y + (x * sx * sin) + (y * sy * cos)) + floorY(camera, point.y) - floorY(camera, camera.y * scrollY)) * camera.screenScaleY;
				}

				var i:Int = 0;
				var color = Color.getColorRGBFloat(r * color.red * slot.r, g * color.green * slot.g, b * color.blue * slot.b);
					alpha = a * alpha * slot.a;
				while (i < triangles.length)
				{
					var t1:Int = triangles[i] * 2,
						t2:Int = triangles[i+1] * 2,
						t3:Int = triangles[i+2] * 2;
					atlasData.prepareTriangle(
						transformX(_vertices[t1], _vertices[t1 + 1]), transformY(_vertices[t1], _vertices[t1 + 1]),
						uvs[t1], uvs[t1 + 1],
						transformX(_vertices[t2], _vertices[t2 + 1]), transformY(_vertices[t2], _vertices[t2 + 1]),
						uvs[t2], uvs[t2 + 1],
						transformX(_vertices[t3], _vertices[t3 + 1]), transformY(_vertices[t3], _vertices[t3 + 1]),
						uvs[t3], uvs[t3 + 1],
						color, alpha, shader, smooth, blend, flexibleLayer
					);
					i += 3;
				}
			}
		}
	}

	public function getAtlasData(attachment:Attachment):AtlasData
	{
		if (!atlasDataMap.exists(attachment))
		{
			var region:AtlasRegion;
			if (Std.is(attachment, RegionAttachment))
			{
				var r:RegionAttachment = cast attachment;
				region = cast r.rendererObject;
			}
			else if (Std.is(attachment, MeshAttachment))
			{
				var m:MeshAttachment = cast attachment;
				region = cast m.rendererObject;
			}
			else
			{
				throw "Unsupported attachment type: " + attachment;
			}
			var bmd:Texture = cast region.page.rendererObject;
			atlasDataMap[attachment] = new AtlasData(bmd);
		}
		return atlasDataMap[attachment];
	}
}
