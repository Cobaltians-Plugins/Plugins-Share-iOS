//
//  GalleryItemsStorage.m
//  Slideshow plugin
//
//  Created by Roxane on 29/03/2016.
//  Copyright © 2016 kristal.io. All rights reserved.
//

#import "GalleryItemsStorage.h"

@implementation GalleryItemsStorage

#pragma mark Singleton Methods

+ (id)sharedManager {
    static GalleryItemsStorage *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        _photos = nil;
        _settings = [[NSMutableArray alloc] initWithObjects: @"#FFFFFF", @"#000000", nil];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end