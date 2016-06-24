//
//  SlideshowViewController.h
//  Famicity
//
//  Created by Kristal on 02/03/2016.
//  Copyright © 2016 Famicity. All rights reserved.
//

#import <Cobalt/Cobalt.h>
#import "AbstractViewController.h"
#import "UIImageView+AFNetworking.h"
#import "ImageViewController.h"
#import "GalleryItemsStorage.h"

static NSMutableArray *rspphotos;

@interface SlideshowViewController : AbstractViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, ImageViewControllerDelegate>
- (void) slideshowStart: (id) photos;
- (void) setViewController: (CobaltViewController *)viewController;
@end
