/*******************************************************************************
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ******************************************************************************/

package spinehx.attachments;
import spinehx.atlas.TextureAtlas;
import spinehx.attachments.RegionSequenceAttachment;
import spinehx.attachments.RegionAttachment;
import spinehx.Exception;
class AtlasAttachmentLoader implements AttachmentLoader {
    private var atlas:TextureAtlas;

    public function new(atlas:TextureAtlas) {
        if (atlas == null) throw new IllegalArgumentException("atlas cannot be null.");
        this.atlas = atlas;
    }

    public function newAttachment(skin:Skin, type:AttachmentType, name:String):Attachment {
        var attachment:Attachment = null;
        switch (type) {
            case region:
                attachment = new RegionAttachment(name);
            case regionSequence:
                attachment = new RegionSequenceAttachment(name);
//            default:
//                throw new IllegalArgumentException("Unknown attachment type: " + type);
        }

        if (Std.is(attachment, RegionAttachment)) {
            var region:AtlasRegion = atlas.findRegion(attachment.getName());
            if (region == null)
                throw new RuntimeException("Region not found in atlas: " + attachment + " (" + type + " attachment: " + name + ")");
            cast(attachment, RegionAttachment).setRegion(region);
        }

        return attachment;
    }
}
