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
    public var color:Int = 0xffffff;
    
    public static var atlasData:AtlasData;
    
    public var wrapperAngles:ObjectMap<RegionAttachment, Float>;
    public var cachedSprites:ObjectMap<RegionAttachment, Image>;
    public var hitboxSlots:Array<String>;
    public var hitboxes:Map<String, Rectangle>;
    
    public function new(skeletonData:SkeletonData) {
        super();
        
        width = 0;
        height = 0;
        
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
        if (value != skeleton.flipX)
            skeleton.flipX = value;
            
        return value;
    }
    
    public var flipY(get, set):Bool;
    
    private function get_flipY():Bool {
        return skeleton.flipY;
    }
    
    private function set_flipY(value:Bool):Bool {
        if (value != skeleton.flipY)
            skeleton.flipY = value;
            
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
        
        var _aabb:Rectangle = null;
        
        var radians:Float = angle * HXP.RAD;
        var cos:Float = Math.cos(radians);
        var sin:Float = Math.sin(radians);
        
        var oox:Float = 0;
        var ooy:Float = -height/2;
        
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
                
                wrapper.x = this.x + relX;
                wrapper.y = this.y + relY;
                
                wrapper.angle = ((bone.worldRotation + regionAttachment.rotation) + wrapperAngle) * flip + angle;
                wrapper.scaleX = (bone.worldScaleX + regionAttachment.scaleX - 1) * flipX * sx;
                wrapper.scaleY = (bone.worldScaleY + regionAttachment.scaleY - 1) * flipY * sy;
                wrapper.render(target, point, camera);
                
                var wRect = new Rectangle(wrapper.x-wrapper.originX*scale, 
                                          wrapper.y-wrapper.originY*scale, 
                                          wrapper.width*scale, 
                                          wrapper.height*scale);
                if (hitboxes.exists(slot.data.name)) {
                    hitboxes[slot.data.name].copyFrom(wRect);
                } else {
                    hitboxes[slot.data.name] = wRect;
                }
                if (hitboxSlots.indexOf(slot.data.name) > -1) {
                    if (_aabb == null) {
                        _aabb = wRect;
                    } else {
                        _aabb = _aabb.union(wRect);
                    }
                }
                
                //cast(mask, Masklist).add(
                //    new Hitbox(cast wRect.width, cast wRect.height, cast wRect.x, cast wRect.y));
            }
        }
        
        if (_aabb != null) {
            _aabb.x -= x;
            _aabb.y -= y;
            setHitboxTo(_aabb);
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
        
        var rect = new Rectangle(region.regionX, region.regionY, region.regionWidth, region.regionHeight);
        
        var wrapper:Image;
        
        if (HXP.renderMode.has(RenderMode.HARDWARE)) {
            wrapper = new Image(atlasData.createRegion(rect));
        } else {
            var bd = new BitmapData(cast rect.width, cast rect.height, true, 0);
            bd.copyPixels(texture.bd, rect, new Point());
            wrapper = new Image(bd);
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
