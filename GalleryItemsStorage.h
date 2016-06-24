//
//  GalleryItemsStorage.h
//  Slideshow plugin
//
//  Created by Roxane on 29/03/2016.
//  Copyright © 2016 kristal.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GalleryItemsStorage : NSObject
@property (nonatomic) int currentImageIndex;
@property (strong, nonatomic) NSDictionary *photos;
@property (strong, nonatomic) NSMutableArray *settings;
+ (id)sharedManager;

@end
