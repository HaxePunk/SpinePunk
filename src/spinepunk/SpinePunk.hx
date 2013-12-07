package spinepunk;

import openfl.Assets;
import haxe.ds.ObjectMap;

import com.haxepunk.HXP;
import com.haxepunk.RenderMode;
import com.haxepunk.Entity;
import com.haxepunk.Graphic;
import com.haxepunk.graphics.Image;
import com.haxepunk.graphics.atlas.AtlasData;

import spinehx.Bone;
import spinehx.Slot;
import spinehx.Skeleton;
import spinehx.SkeletonData;
import spinehx.SkeletonJson;
import spinehx.AnimationState;
import spinehx.AnimationStateData;
import spinehx.atlas.Texture;
import spinehx.atlas.TextureAtlas;
import spinehx.attachments.Attachment;
import spinehx.attachments.RegionAttachment;
import spinehx.platform.nme.BitmapDataTexture;
import spinehx.platform.nme.BitmapDataTextureLoader;

import flash.geom.Rectangle;
import flash.geom.Point;
import flash.display.BitmapData;


class SpinePunk extends Entity {
    public var skeleton:Skeleton;
    public var skeletonData:SkeletonData;
    public var state:AnimationState;
    public var stateData:AnimationStateData;
    public var angle:Float=0;
    public var scaleX:Float = 1;
    public var scaleY:Float = 1;
    public var scale:Float = 1;
    public var scrollX:Float = 1;
    public var scrollY:Float = 1;
    public var speed:Float = 1;
    
    public var wrapperAngles:ObjectMap<RegionAttachment, Float>;
    public var cachedSprites:ObjectMap<RegionAttachment, Image>;
    
    /**
     * Instantiate a new Spine Sprite.
     * @param    skeletonData    Animation data from Spine (.json .skel .png), get it like this: FlxSpineSprite.readSkeletonData( "mySpriteData", "assets/" );
     * @param    X                The initial X position of the sprite.
     * @param    Y                The initial Y position of the sprite.
     * @param    Width            The maximum width of this sprite (avoid very large sprites since they are performance intensive).
     * @param    Height            The maximum height of this sprite (avoid very large sprites since they are performance intensive).
     */
    public function new(skeletonData:SkeletonData) {
        super();
        
        width = 0;
        height = 0;
        
        this.skeletonData = skeletonData;
        
        stateData = new AnimationStateData(skeletonData);
        state = new AnimationState(stateData);
        
        skeleton = Skeleton.create(skeletonData);
        skeleton.setX(0);
        skeleton.setY(0);
        skeleton.setFlipY(true);
        
        cachedSprites = new ObjectMap();
        wrapperAngles = new ObjectMap();
    }
    
    public var flipX(get, set):Bool;
    
    private function get_flipX():Bool {
        return skeleton.flipX;
    }
    
    private function set_flipX(value:Bool):Bool {
        if (value != skeleton.flipX)
            skeleton.setFlipX(value);
            
        return value;
    }
    
    public var flipY(get, set):Bool;
    
    private function get_flipY():Bool {
        return skeleton.flipY;
    }
    
    private function set_flipY(value:Bool):Bool {
        if (value != skeleton.flipY)
            skeleton.setFlipY(value);
            
        return value;
    }
    
    /**
     * Get Spine animation data.
     * @param    DataName    The name of the animation data files exported from Spine (.atlas .json .png).
     * @param    DataPath    The directory these files are located at
     * @param    Scale        Animation scale
     */
    public static function readSkeletonData(DataName:String, DataPath:String, Scale:Float = 1):SkeletonData {
        if (DataPath.lastIndexOf("/") < 0) DataPath += "/"; // append / at the end of the folder path
        var spineAtlas:TextureAtlas = TextureAtlas.create(Assets.getText(DataPath + DataName + ".atlas"), DataPath, new BitmapDataTextureLoader());
        var json:SkeletonJson = SkeletonJson.create(spineAtlas);
        json.setScale(Scale);
        var skeletonData:SkeletonData = json.readSkeletonData(DataName, Assets.getText(DataPath + DataName + ".json"));
        return skeletonData;
    }
    
    public override function update():Void {
        state.update(HXP.elapsed*speed);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
        
        super.update();
    }
    
    public override function render() {
        _camera.x = _scene == null ? HXP.camera.x : _scene.camera.x;
        _camera.y = _scene == null ? HXP.camera.y : _scene.camera.y;
        renderGraphic((renderTarget != null) ? renderTarget : HXP.buffer, new Point(), _camera);
    }
    
    public function renderGraphic(target, point:Point, camera:Point):Void {
        var drawOrder:Array<Slot> = skeleton.drawOrder;
        var flipX:Int = (skeleton.flipX) ? -1 : 1;
        var flipY:Int = (skeleton.flipY) ? 1 : -1;
        var flip:Int = flipX * flipY;
        
        var _aabb = new Rectangle(0, 0, 0, 0);
        
        var radians:Float = angle * HXP.RAD;
        var cos:Float = Math.cos(radians);
        var sin:Float = Math.sin(radians);
        
        var oox:Float = originX + point.x - camera.x * scrollX;
        var ooy:Float = originY + point.y - camera.y * scrollY;
        
        for (slot in drawOrder)  {
            var attachment:Attachment = slot.attachment;
            if (Std.is(attachment, RegionAttachment)) {
                var regionAttachment:RegionAttachment = cast attachment;
                regionAttachment.updateVertices(slot);
                var vertices = regionAttachment.getVertices();
                var wrapper:Image = getImage(regionAttachment);
                var wrapperAngle:Float = wrapperAngles.get(regionAttachment);
                var region:AtlasRegion = cast regionAttachment.getRegion();
                var bone:Bone = slot.getBone();
                var x:Float = regionAttachment.x - region.offsetX;
                var y:Float = regionAttachment.y - region.offsetY;
                
                var dx:Float = bone.worldX + x * bone.m00 + y * bone.m01 - oox;
                var dy:Float = bone.worldY + x * bone.m10 + y * bone.m11 - ooy;
                
                var relX:Float = (dx * cos * scaleX - dy * sin * scaleY);
                var relY:Float = (dx * sin * scaleX + dy * cos * scaleY);
                
                wrapper.x = this.x + relX;
                wrapper.y = this.y + relY;
                
                wrapper.angle = ((bone.worldRotation + regionAttachment.rotation) + wrapperAngle) * flip + angle;
                wrapper.scaleX = (bone.worldScaleX + regionAttachment.scaleX - 1) * flipX * scaleX;
                wrapper.scaleY = (bone.worldScaleY + regionAttachment.scaleY - 1) * flipY * scaleY;
                wrapper.render(target, point, camera);
                
                if (_aabb.width == 0 && _aabb.height == 0)
                {
                    _aabb.copyFrom(wrapper.clipRect);
                }
                else
                {
                    _aabb.union(wrapper.clipRect);
                }
            }
        }
        
        setHitbox(cast _aabb.width, cast _aabb.height, cast _aabb.width/2, cast _aabb.height/2);
    }
    
    public function getImage(regionAttachment:RegionAttachment):Image {
        if (cachedSprites.exists(regionAttachment))
            return cachedSprites.get(regionAttachment);
        
        var region:AtlasRegion = cast regionAttachment.getRegion();
        var texture:BitmapDataTexture = cast region.getTexture();
        
        var cachedGraphic:BitmapData = texture.bd;
        var atlasData:AtlasData = AtlasData.create(cachedGraphic);
        
        var rect = new Rectangle(region.getRegionX(), region.getRegionY(), region.getRegionWidth(), region.getRegionHeight());
        
        var wrapper:Image;
        
        if (HXP.renderMode.has(RenderMode.HARDWARE)) {
            wrapper = new Image(atlasData.createRegion(rect));
        } else {
            var bd = new BitmapData(cast rect.width, cast rect.height, true, 0);
            bd.copyPixels(texture.bd, rect, new Point());
            wrapper = new Image(bd);
        }
        
        wrapper.originX = region.getRegionWidth() / 2; // Registration point.
        wrapper.originY = region.getRegionHeight() / 2;
        if (region.rotate) {
            wrapper.angle = -90;
        }
        
        cachedSprites.set(regionAttachment, wrapper);
        wrapperAngles.set(regionAttachment, wrapper.angle);
        
        return wrapper;
    }
}
