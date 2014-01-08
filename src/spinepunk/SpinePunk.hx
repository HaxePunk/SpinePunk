package spinepunk;

import openfl.Assets;
import haxe.ds.ObjectMap;
import haxe.ds.Vector;

import com.haxepunk.HXP;
import com.haxepunk.RenderMode;
import com.haxepunk.Entity;
import com.haxepunk.Graphic;
import com.haxepunk.graphics.Image;
import com.haxepunk.graphics.atlas.AtlasData;
//import com.haxepunk.masks.Masklist;
//import com.haxepunk.masks.Hitbox;

import spinehaxe.Bone;
import spinehaxe.Slot;
import spinehaxe.Skeleton;
import spinehaxe.SkeletonData;
import spinehaxe.SkeletonJson;
import spinehaxe.animation.AnimationState;
import spinehaxe.animation.AnimationStateData;
import spinehaxe.atlas.Texture;
import spinehaxe.atlas.TextureAtlas;
import spinehaxe.attachments.Attachment;
import spinehaxe.attachments.RegionAttachment;
import spinehaxe.platform.nme.BitmapDataTexture;
import spinehaxe.platform.nme.BitmapDataTextureLoader;

import flash.geom.Rectangle;
import flash.geom.Point;
import flash.display.BitmapData;

using Lambda;


class SpinePunk extends Graphic {
    public static var nullPoint:Point;
    
    public var skeleton:Skeleton;
    public var skeletonData:SkeletonData;
    public var state:AnimationState;
    public var stateData:AnimationStateData;
    public var angle:Float=0;
    public var speed:Float=1;
    public var color:Int=0xffffff;
    public var mainHitbox:Rectangle;
    public var scaleX:Float=1;
    public var scaleY:Float=1;
    public var scale:Float=1;
    
    public static var atlasData:AtlasData;
    
    public var wrapperAngles:ObjectMap<RegionAttachment, Float>;
    public var cachedSprites:ObjectMap<RegionAttachment, Image>;
    public var hitboxSlots:Array<String>;
    public var hitboxes:Map<String, Rectangle>;
    
    public function new(skeletonData:SkeletonData) {
        super();
        
        this.skeletonData = skeletonData;
        
        stateData = new AnimationStateData(skeletonData);
        state = new AnimationState(stateData);
        
        skeleton = new Skeleton(skeletonData);
        skeleton.x = 0;
        skeleton.y = 0;
        skeleton.flipY = true;
        
        cachedSprites = new ObjectMap();
        wrapperAngles = new ObjectMap();
        hitboxSlots = new Array();
        hitboxes = new Map();
        mainHitbox = new Rectangle();
        
        _blit = HXP.renderMode != RenderMode.HARDWARE;
        
        //mask = new Masklist([]);
    }
    
    public var skin(default, set):String;
    function set_skin(skin:String) {
        if (skin != this.skin) {
            skeleton.skinName = skin;
            skeleton.setToSetupPose();
        }
        return this.skin = skin;
    }
    
    public var flipX(get, set):Bool;
    
    private function get_flipX():Bool {
        return skeleton.flipX;
    }
    
    private function set_flipX(value:Bool):Bool {
        if (value != skeleton.flipX) {
            skeleton.flipX = value;
            skeleton.updateWorldTransform();
        }
            
        return value;
    }
    
    public var flipY(get, set):Bool;
    
    private function get_flipY():Bool {
        return skeleton.flipY;
    }
    
    private function set_flipY(value:Bool):Bool {
        if (value != skeleton.flipY) {
            skeleton.flipY = value;
            skeleton.updateWorldTransform();
        }
            
        return value;
    }
    
    /**
     * Get Spine animation data.
     * @param    DataName    The name of the animation data files exported from Spine (.atlas .json .png).
     * @param    DataPath    The directory these files are located at
     * @param    Scale        Animation scale
     */
    public static function readSkeletonData(dataName:String, dataPath:String, scale:Float = 1):SkeletonData {
        if (dataPath.lastIndexOf("/") < 0) dataPath += "/"; // append / at the end of the folder path
        var spineAtlas:TextureAtlas = TextureAtlas.create(Assets.getText(dataPath + dataName + ".atlas"), dataPath, new BitmapDataTextureLoader());
        var json:SkeletonJson = SkeletonJson.create(spineAtlas);
        json.scale = scale;
        var skeletonData:SkeletonData = json.readSkeletonData(dataName, Assets.getText(dataPath + dataName + ".json"));
        return skeletonData;
    }
    
    public override function update():Void {
        state.update(HXP.elapsed*speed);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
        
        super.update();
    }
    
    public override function render(target:BitmapData, point:Point, camera:Point):Void {
        var point = point.clone();
        var camera = camera.clone();
        
        if (nullPoint == null) nullPoint = new Point(0,0);
        
        var drawOrder:Array<Slot> = skeleton.drawOrder;
        var flipX:Int = (skeleton.flipX) ? -1 : 1;
        var flipY:Int = (skeleton.flipY) ? 1 : -1;
        var flip:Int = flipX * flipY;
        
        var _aabb:Rectangle = null;
        
        var radians:Float = angle * HXP.RAD;
        var cos:Float = Math.cos(radians);
        var sin:Float = Math.sin(radians);
        
        var oox:Float = 0;
        var ooy:Float = -mainHitbox.height/2;
        
        //cast(mask, Masklist).removeAll();
        
        for (slot in drawOrder)  {
            var attachment:Attachment = slot.attachment;
            if (Std.is(attachment, RegionAttachment)) {
                var regionAttachment:RegionAttachment = cast attachment;
                //regionAttachment.updateVertices(slot);
                //var vertices = regionAttachment.vertices;
                var wrapper:Image = getImage(regionAttachment);
                wrapper.color = color;
                var wrapperAngle:Float = wrapperAngles.get(regionAttachment);
                
                var region:AtlasRegion = cast regionAttachment.region;
                var bone:Bone = slot.bone;
                var x:Float = regionAttachment.x - region.offsetX;
                var y:Float = regionAttachment.y - region.offsetY;
                
                var dx:Float = bone.worldX + x * bone.m00 + y * bone.m01 - oox;
                var dy:Float = bone.worldY + x * bone.m10 + y * bone.m11 - ooy;
                
                var sx = scaleX * scale;
                var sy = scaleY * scale;
                
                var relX:Float = (dx * cos * sx - dy * sin * sy);
                var relY:Float = (dx * sin * sx + dy * cos * sy);
                
                wrapper.x = point.x + this.x + relX;
                wrapper.y = point.y + this.y + relY;
                
                wrapper.angle = ((bone.worldRotation + regionAttachment.rotation) + wrapperAngle) * flip + angle;
                wrapper.scaleX = (bone.worldScaleX + regionAttachment.scaleX - 1) * flipX * sx;
                wrapper.scaleY = (bone.worldScaleY + regionAttachment.scaleY - 1) * flipY * sy;
                wrapper.render(target, nullPoint, camera);
                
                var wRect:Rectangle = (hitboxes.exists(slot.data.name)) ?
                    hitboxes[slot.data.name] :
                    (hitboxes[slot.data.name] = new Rectangle());
                wRect.x = wrapper.x-wrapper.originX*scale;
                wRect.y = wrapper.y-wrapper.originY*scale;
                wRect.width = wrapper.width*scale;
                wRect.height = wrapper.height*scale;
                if (hitboxSlots.has(slot.data.name)) {
                    if (_aabb == null) {
                        _aabb = wRect;
                    } else {
                        _aabb = _aabb.union(wRect);
                    }
                }
            }
        }
        
        if (_aabb != null) {
            _aabb.x -= point.x + this.x;
            _aabb.y -= point.y + this.y;
            mainHitbox = _aabb;
        }
    }
    
    public function getImage(regionAttachment:RegionAttachment):Image {
        if (cachedSprites.exists(regionAttachment))
            return cachedSprites.get(regionAttachment);
        
        var region:AtlasRegion = cast regionAttachment.region;
        var texture:BitmapDataTexture = cast region.texture;
        
        if (atlasData == null) {
            var cachedGraphic:BitmapData = texture.bd;
            atlasData = AtlasData.create(cachedGraphic);
        }
        
        var rect = HXP.rect;
        rect.x = region.regionX;
        rect.y = region.regionY;
        rect.width = region.regionWidth;
        rect.height = region.regionHeight;
        
        var wrapper:Image;
        
        if (_blit) {
            var bd = new BitmapData(cast rect.width, cast rect.height, true, 0);
            HXP.point.x = HXP.point.y = 0;
            bd.copyPixels(texture.bd, rect, HXP.point);
            wrapper = new Image(bd);
        } else {
            wrapper = new Image(atlasData.createRegion(rect));
        }
        
        wrapper.originX = region.regionWidth / 2; // Registration point.
        wrapper.originY = region.regionHeight / 2;
        if (region.rotate) {
            wrapper.angle = -90;
        }
        
        cachedSprites.set(regionAttachment, wrapper);
        wrapperAngles.set(regionAttachment, wrapper.angle);
        
        return wrapper;
    }
}
