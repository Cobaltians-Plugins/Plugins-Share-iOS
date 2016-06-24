/*
 * CobaltSideshowPlugin.m
 * Cobalt
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Cobaltians
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "CobaltSlideshowPlugin.h"
#import "GalleryItemsStorage.h"

@implementation CobaltslideshowPlugin

- (void) onMessageFromCobaltController: (CobaltViewController *)viewController
                               andData: (NSDictionary *)data {
    [self onMessageWithCobaltController:viewController andData:data];
}

- (void) onMessageFromWebLayerWithCobaltController: (CobaltViewController *)viewController
                                           andData: (NSDictionary *)data {
    [self onMessageWithCobaltController:viewController andData:data];
}

- (void) onMessageWithCobaltController: (CobaltViewController *)viewController
                               andData: (NSDictionary *)data {
    NSString * action = [data objectForKey:kJSAction];

    if (action != nil) {
        if (DEBUG_COBALT) NSLog(@"slideshowPlugin received data %@", data.description);
        // prepare data
        GalleryItemsStorage *sharedManager = [GalleryItemsStorage sharedManager];
        _viewController = viewController;
        // add defined tokens (useless for now but can be used to check javascript or json errors/missing mandatory fields in the futur)
        _parseTokens = @[kJSTokenData,
                        kJSTokenStartId,
                        kJSTokenPhotos,
                        kJSTokenPhotosId,
                        kJSTokenUrl,
                        kJSTokenUrlThumbnail,
                        kJSTokenDescription,
                        kJSTokenColor];
        _eventTokens = @[kJSTokenPhotoPosition];
        _nativeTokens = @[kJSSlideshowSetBackgroundColor,
                         kJSSlideshowUpdateTitle,
                         kJSSlideshowOnChange];
        _settingsTokens = @[kJSTokenSettingsBgColor,
                         kJSTokenSettingsFullscreenBgColor];

        if ([action isEqualToString:kJSSlideshowConfiguration]) {
            // set image in singleton for futur usage
            sharedManager.settings = [data objectForKey:@"data"];
        } else if ([action isEqualToString:kJSSlideshowInit]) {
            // store images in singleton
            sharedManager.photos = [data objectForKey:@"data"];
        } else {
            if (DEBUG_COBALT) NSLog(@"Plugin Slideshow received unhandled slideshow action: %@", action);
        }
    }
}

@end
