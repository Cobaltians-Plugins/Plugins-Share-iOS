//
//  ImageViewController.h
//  Famicity
//
//  Created by Kristal on 02/03/2016.
//  Copyright © 2016 Famicity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+AFNetworking.h"

@protocol ImageViewControllerDelegate <NSObject>

@required

- (void)didLoadPhoto:(UIImage *)image
      withIdentifier:(NSNumber *)identifier
          andRequest:(NSURLRequest *)request;
- (void)didTapOnPhoto:(NSNumber *)identifier;
- (void)didLongPressOnPhoto:(NSNumber *)identifier;

@optional

- (void)didDoubleTapOnPhoto:(NSNumber *)identifier;
- (void)toggleBars;
@end

@interface ImageViewController : UIViewController <UIScrollViewDelegate>

@property (readonly, strong, nonatomic) NSDictionary *photo;

- (instancetype)initWithPhoto:(NSDictionary *)photo
                  andDelegate:(id<ImageViewControllerDelegate>)delegate;
- (NSNumber *)photoIdentifier;

@end
