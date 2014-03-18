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
    public var skeleton:Skeleton;
    public var skeletonData:SkeletonData;
    public var state:AnimationState;
    public var stateData:AnimationStateData;
    public var angle:Float=0;
    public var speed:Float=1;
    public var color:Int=0xffffff;
    public var dynamicHitbox:Bool=true;
    public var mainHitbox:Rectangle;
    public var scaleX:Float=1;
    public var scaleY:Float=1;
    public var scale:Float=1;
    
    static var atlasData:AtlasData;
    
    var wrapperAngles:ObjectMap<RegionAttachment, Float>;
    var cachedImages:ObjectMap<RegionAttachment, Image>;
    public var hitboxSlots:Array<String>;
    public var hitboxes:Map<String, Rectangle>;
    
    var rect1:Rectangle;
    var rect2:Rectangle;
    var firstFrame=true;
    
    public function new(skeletonData:SkeletonData, dynamicHitbox:Bool=true) {
        super();
        
        this.skeletonData = skeletonData;
        
        stateData = new AnimationStateData(skeletonData);
        state = new AnimationState(stateData);
        
        skeleton = new Skeleton(skeletonData);
        skeleton.x = 0;
        skeleton.y = 0;
        skeleton.flipY = true;
        
        cachedImages = new ObjectMap();
        wrapperAngles = new ObjectMap();
        hitboxSlots = new Array();
        hitboxes = new Map();
        this.dynamicHitbox = dynamicHitbox;
        rect1 = new Rectangle();
        rect2 = new Rectangle();
        mainHitbox = rect1;
        
        blit = HXP.renderMode != RenderMode.HARDWARE;
    }
    
    public function resetHitbox() {
        mainHitbox.width = mainHitbox.height = 0;
        firstFrame = true;
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
    
    public override function renderAtlas(layer:Int, point:Point, camera:Point):Void {
        draw(point, camera, layer);
    }

    public override function render(target:BitmapData, point:Point, camera:Point):Void {
        draw(point, camera, 0, target);
    }
    
    function draw(point:Point, camera:Point, layer:Int=0, target:BitmapData=null):Void {
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
        var sx = scaleX * scale;
        var sy = scaleY * scale;
        
        var attachment:Attachment;
        var regionAttachment:RegionAttachment;
        var wrapper:Image;
        var wrapperAngle:Float;
        var region:AtlasRegion;
        var bone:Bone;
        var dx:Float, dy:Float;
        var relX:Float, relY:Float;
        var rx:Float, ry:Float;
        
        for (slot in drawOrder)  {
            attachment = slot.attachment;
            if (Std.is(attachment, RegionAttachment)) {
                regionAttachment = cast attachment;
                
                wrapper = getImage(regionAttachment);
                wrapper.color = color;
                wrapperAngle = wrapperAngles.get(regionAttachment);
                
                region = cast regionAttachment.region;
                bone = slot.bone;
                rx = regionAttachment.x;// + region.offsetX;
                ry = regionAttachment.y;// + region.offsetY;
                
                dx = bone.worldX + rx * bone.m00 + ry * bone.m01 - oox;
                dy = bone.worldY + rx * bone.m10 + ry * bone.m11 - ooy;
                
                relX = (dx * cos * sx - dy * sin * sy);
                relY = (dx * sin * sx + dy * cos * sy);
                
                wrapper.x = x + relX;
                wrapper.y = y + relY;
                
                wrapper.angle = ((bone.worldRotation + regionAttachment.rotation) + wrapperAngle) * flip + angle;
                wrapper.scaleX = (bone.worldScaleX + regionAttachment.scaleX - 1) * flipX * sx;
                wrapper.scaleY = (bone.worldScaleY + regionAttachment.scaleY - 1) * flipY * sy;
                if (blit) wrapper.render(target, point, camera);
                else wrapper.renderAtlas(layer, point, camera);
                
                var wRect:Rectangle = (hitboxes.exists(slot.data.name)) ?
                    hitboxes[slot.data.name] :
                    (hitboxes[slot.data.name] = new Rectangle());
                wRect.x = wrapper.x-(region.rotate ? wrapper.originY : wrapper.originX)*sx;
                wRect.y = wrapper.y-(region.rotate ? wrapper.originX : wrapper.originY)*sy;
                wRect.width = (region.rotate ? wrapper.height : wrapper.width)*sx;
                wRect.height = (region.rotate ? wrapper.width : wrapper.height)*sy;
                if (hitboxSlots.has(slot.data.name)) {
                    if (_aabb == null) {
                        _aabb = (mainHitbox == rect2 ? rect1 : rect2);
                        _aabb.x = wRect.x;
                        _aabb.y = wRect.y;
                        _aabb.width = wRect.width;
                        _aabb.height = wRect.height;
                    } else {
                        var x0 = _aabb.x > wRect.x ? wRect.x : _aabb.x;
                        var x1 = _aabb.right < wRect.right ? wRect.right : _aabb.right;
                        var y0 = _aabb.y > wRect.y ? wRect.y : _aabb.y;
                        var y1 = _aabb.bottom < wRect.bottom ? wRect.bottom : _aabb.bottom;
                        _aabb.left = x0;
                        _aabb.top = y0;
                        _aabb.width = x1 - x0;
                        _aabb.height = y1 - y0;
                    }
                }
            }
        }
        
        if (_aabb != null && (dynamicHitbox || (firstFrame))) {
            _aabb.x -= x;
            _aabb.y -= y;
            if (firstFrame) _aabb.y += (_aabb.height*sy/2);
            mainHitbox = _aabb;
            firstFrame = false;
        }
    }
    
    public function getImage(regionAttachment:RegionAttachment):Image {
        if (cachedImages.exists(regionAttachment))
            return cachedImages.get(regionAttachment);
        
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
        
        if (blit) {
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
        
        cachedImages.set(regionAttachment, wrapper);
        wrapperAngles.set(regionAttachment, wrapper.angle);
        
        return wrapper;
    }
}
