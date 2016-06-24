//
//  ImageViewController.m
//  Famicity
//
//  Created by Kristal on 02/03/2016.
//  Copyright © 2016 Famicity. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () {
    CGSize currentSize;
    CGPoint currentOffset;
    BOOL isResettingZoom;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImage *image;

@property (weak, nonatomic) id<ImageViewControllerDelegate> delegate;

@end

@implementation ImageViewController

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark LIFECYCLE

////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithPhoto:(NSDictionary *)photo
                  andDelegate:(id<ImageViewControllerDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        _photo = photo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _imageView = [[UIImageView alloc] init];
    [_scrollView addSubview:_imageView];

    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(onDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(onTap:)];
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [tapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(onLongPress:)];

    [_scrollView addGestureRecognizer:doubleTapGestureRecognizer];
    [_scrollView addGestureRecognizer:tapGestureRecognizer];
    [_scrollView addGestureRecognizer:longPressGestureRecognizer];

    // TODO: orientation handling
    if ([[UIDevice currentDevice].systemVersion compare:@"8.0"
                                                options:NSNumericSearch] == NSOrderedAscending) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];

        [self setScreenSizeForiOS7WithOrientation:[UIDevice currentDevice].orientation];
    }
    else {
        currentSize = [UIScreen mainScreen].bounds.size;
    }
    // TODO

    id urlOriginal = [_photo objectForKey:@"url"];
    if (urlOriginal != nil
        && [urlOriginal isKindOfClass:[NSString class]]) {
        NSURL *imageOriginalUrl = [NSURL URLWithString:urlOriginal];
        if (imageOriginalUrl != nil) {
            UIImage *cachedImageOriginal = [[UIImageView sharedImageCache] cachedImageForRequest:[NSURLRequest requestWithURL:imageOriginalUrl]];
            if (cachedImageOriginal != nil) {
                _image = cachedImageOriginal;
                [self setImage];
            }
            else {
                id urlNormal = [self.photo objectForKey:@"url_thumb"];
                if (urlNormal != nil
                    && [urlNormal isKindOfClass:[NSString class]]) {
                    NSURL *imageNormalUrl = [NSURL URLWithString:urlNormal];
                    if (imageNormalUrl != nil) {
                        __block ImageViewController *weakSelf = self;
                        [_imageView setImageWithURLRequest:[NSURLRequest requestWithURL:imageNormalUrl]
                                          placeholderImage:nil
                                                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                                       weakSelf.image = image;
                                                       [weakSelf setImage];

                                                       __block ImageViewController *weakWeakSelf = weakSelf;
                                                       [weakSelf.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:imageOriginalUrl]
                                                                                 placeholderImage:nil
                                                                                          success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                                                                              weakWeakSelf.image = image;
                                                                                              [weakWeakSelf setImage];

                                                                                              [weakWeakSelf.delegate didLoadPhoto:image
                                                                                                                   withIdentifier:weakWeakSelf.photoIdentifier
                                                                                                                       andRequest:request];
                                                                                          }
                                                                                          failure:nil];
                                                   }
                                                   failure:nil];
                    }
                }
                else {
                    __block ImageViewController *weakSelf = self;
                    [_imageView setImageWithURLRequest:[NSURLRequest requestWithURL:imageOriginalUrl]
                                      placeholderImage:nil
                                               success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                                   weakSelf.image = image;
                                                   [weakSelf setImage];

                                                   [weakSelf.delegate didLoadPhoto:image
                                                                    withIdentifier:weakSelf.photoIdentifier
                                                                        andRequest:request];
                                               }
                                               failure:nil];
                }
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setImage];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self resetZoomAnimated:NO
              whileRotating:NO];
}

- (void)dealloc {
    // TODO: orientation handling
    if ([[UIDevice currentDevice].systemVersion compare:@"8.0"
                                                options:NSNumericSearch] == NSOrderedAscending) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIDeviceOrientationDidChangeNotification
                                                      object:nil];
    }
    // /TODO
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark METHODS

////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSNumber *)photoIdentifier {
    id identifier = [_photo objectForKey:@"id"];
    if (identifier != nil
        && [identifier isKindOfClass:[NSNumber class]]) {
        return identifier;
    }

    return nil;
}

- (void)setImage {
    if (_image != nil) {
        [self resetZoomAnimated:NO
                  whileRotating:NO];

        _imageView.image = _image;

        CATransition *transition = [CATransition animation];
        transition.duration = 0.3f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [_imageView.layer addAnimation:transition
                                forKey:nil];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark UISCROLLVIEW DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)resetZoomAnimated:(BOOL)animated
            whileRotating:(BOOL)rotating {
    CGSize imageSize = _image.size;
    if (! CGSizeEqualToSize(imageSize, CGSizeZero)) {
        isResettingZoom = YES;

        CGFloat minScale = MIN(currentSize.width / imageSize.width, currentSize.height / imageSize.height);
        _scrollView.minimumZoomScale = minScale;
        _scrollView.maximumZoomScale = minScale > 1 ? minScale : 1;

        CGFloat scaledImageWidth = imageSize.width * minScale;
        CGFloat scaledImageHeight = imageSize.height * minScale;

        if (rotating
            && minScale < 1) {
            CGSize currentImageViewSize = _imageView.frame.size;
            CGSize newImageViewSize = CGSizeZero;
            if (currentImageViewSize.width < scaledImageWidth
                || currentImageViewSize.height < scaledImageHeight) {
                _scrollView.zoomScale = minScale;

                newImageViewSize = CGSizeMake(scaledImageWidth,
                                              scaledImageHeight);
            }
            else {
                newImageViewSize = CGSizeMake(currentImageViewSize.width,
                                              currentImageViewSize.height);
            }

            [UIView animateWithDuration:animated ? 0.3 : 0
                             animations:^{
                                 _imageView.frame = CGRectMake(newImageViewSize.width <= currentSize.width ? (currentSize.width - newImageViewSize.width) / 2 : 0,
                                                               newImageViewSize.height <= currentSize.height ? (currentSize.height - newImageViewSize.height) / 2 : 0,
                                                               newImageViewSize.width,
                                                               newImageViewSize.height);

                                 NSComparisonResult osVersionComparison = [[UIDevice currentDevice].systemVersion compare:@"8.0"
                                                                                                                  options:NSNumericSearch];
                                 if (osVersionComparison == NSOrderedSame || osVersionComparison == NSOrderedDescending) {
                                     _scrollView.contentOffset = CGPointMake(currentSize.width / 2 + currentOffset.x, currentSize.height / 2 + currentOffset.y);
                                 }
                             }];
        }
        else {
            _scrollView.zoomScale = minScale;

            [UIView animateWithDuration:animated ? 0.3 : 0
                             animations:^{
                                 _imageView.frame = CGRectMake((currentSize.width - scaledImageWidth) / 2,
                                                               (currentSize.height - scaledImageHeight) / 2,
                                                               scaledImageWidth,
                                                               scaledImageHeight);
                             }];
        }

        isResettingZoom = NO;
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (! isResettingZoom) {
        CGSize scrollViewSize = scrollView.bounds.size;
        CGSize imageViewSize = _imageView.frame.size;

        _imageView.frame = CGRectMake(imageViewSize.width <= scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0,
                                      imageViewSize.height <= scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0,
                                      imageViewSize.width,
                                      imageViewSize.height);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark ORIENTATION DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////////

// iOS7
- (void)orientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = ((UIDevice *)notification.object).orientation;
    [self setScreenSizeForiOS7WithOrientation:orientation];

    [self resetZoomAnimated:YES
              whileRotating:YES];
}

- (void)setScreenSizeForiOS7WithOrientation:(UIDeviceOrientation)orientation {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    switch(orientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
            currentSize = CGSizeMake(MIN(screenSize.width, screenSize.height), MAX(screenSize.width, screenSize.height));
            break;
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            currentSize = CGSizeMake(MAX(screenSize.width, screenSize.height), MIN(screenSize.width, screenSize.height));
            break;
    }
}

// iOS8+
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size
          withTransitionCoordinator:coordinator];

    currentSize = size;
    currentOffset = _scrollView.contentOffset;

    [self resetZoomAnimated:YES
              whileRotating:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark GESTURES

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)onDoubleTap:(UITapGestureRecognizer *)sender {
    if (_delegate != nil
        && [_delegate respondsToSelector:@selector(didDoubleTapOnPhoto:)]) {
        id identifier = [_photo objectForKey:@"id"];

        if (identifier != nil
            && [identifier isKindOfClass:[NSNumber class]]) {
            [_delegate didDoubleTapOnPhoto:identifier];
        }
        // toggle bars
        [_delegate toggleBars];
    }
    else {
        if (_scrollView.zoomScale >= _scrollView.maximumZoomScale) {
            [_scrollView setZoomScale:_scrollView.minimumZoomScale
                             animated:YES];
        }
        else {
            [_scrollView setZoomScale:_scrollView.maximumZoomScale
                             animated:YES];
        }
    }
}

- (void)onTap:(UITapGestureRecognizer *)sender {
    if (_delegate != nil) {
        id identifier = [_photo objectForKey:@"id"];

        if (identifier != nil
            && [identifier isKindOfClass:[NSNumber class]]) {
            [_delegate didTapOnPhoto:identifier];
        }
    }
}

- (void)onLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan
        && _delegate != nil) {
        id identifier = [_photo objectForKey:@"id"];

        if (identifier != nil
            && [identifier isKindOfClass:[NSNumber class]]) {
            [_delegate didLongPressOnPhoto:identifier];
        }
    }
}

@end
