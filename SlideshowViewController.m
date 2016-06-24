//
//  SlideshowViewController.m
//  Famicity
//
//  Created by Kristal on 02/03/2016.
//  Copyright © 2016 Famicity. All rights reserved.
//

#import "SlideshowViewController.h"

@interface SlideshowViewController ()

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) ImageViewController *currentViewController;
@property (strong, nonatomic) NSMutableArray *dataSource;

@property (strong, nonatomic) NSMutableDictionary *loadedPhotos;
@property (strong, nonatomic) NSMutableArray *savingPhotos;
@property (strong, nonatomic) NSMutableArray *toSavePhotos;

@end

static Boolean barsVisible;
static Boolean topBarsExist;
static Boolean bottomBarsExist;

@implementation SlideshowViewController

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark LIFECYCLE

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;

    // Do any additional setup after loading the view.
    // bars are visible by default
    topBarsExist = ![self.navigationController isNavigationBarHidden];
    bottomBarsExist = ![self.navigationController isToolbarHidden];
    barsVisible = true;
    // alloc slideshow (uipage) view controller
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    _pageViewController.view.backgroundColor = [UIColor whiteColor];
    _pageViewController.view.frame = self.view.bounds;
    _pageViewController.delegate = self;
    _pageViewController.dataSource = self;

    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
}

#pragma mark Custom

// start the slideshow
- (void) slideshowStart: (NSArray *) data {
    if (data == nil || data.count == 0) {
        NSLog(@"It looks like that the image array retieved from plugin is empty... check event order and images source.");
        return;
    }
    if (DEBUG_COBALT) NSLog(@"slideshowStart() received %lu img", (unsigned long)data.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initSlideshowWithPhotos:data
                           andStartId:[[NSNumber alloc] initWithInt:1]];
    });
}

// set title of image from description from image's index
- (void) setTitleForImageIndex: (int) index {
    NSString *title = [[_dataSource valueForKey:@"description"] objectAtIndex:index];
    if (title == nil) return;
    [self sendMessage:@{kJSType: kJSTypePlugin,
                        kJSPluginName: @"slideshow",
                        kJSAction: @"slideshow:updateTitle",
                        kJSData: title
                        }];
}

// return the data of a photo from its index
- (ImageViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (_dataSource.count == 0
        || index >= _dataSource.count) {
        return nil;
    }

    id photo = _dataSource[index];
    if (! [photo isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    // update title
    [self setTitleForImageIndex:index];
    return [[ImageViewController alloc] initWithPhoto:photo
                                          andDelegate:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark METHODS

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)initSlideshowWithPhotos:(NSArray *)photos
                     andStartId:(NSNumber *)startId {
    _dataSource = [NSMutableArray arrayWithArray:photos];
    _loadedPhotos = [NSMutableDictionary dictionaryWithCapacity:photos.count];
    _savingPhotos = [NSMutableArray array];
    _toSavePhotos = [NSMutableArray array];
    if (startId != nil) {
        NSUInteger index = [self indexForPhotoIdentifier:startId];
        _currentViewController = [self viewControllerAtIndex:index != NSNotFound ? index : 0];
    }
    else {
        _currentViewController = [self viewControllerAtIndex:0];
    }

    if (_currentViewController != nil) { // push image to view controller
        [_pageViewController setViewControllers:@[_currentViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    }
}

- (NSUInteger)indexForPhotoIdentifier:(NSNumber *)identifier {
    __block NSUInteger index = NSNotFound;
    [_dataSource enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            id objId = obj[@"id"];
            if (objId != nil
                && [objId isKindOfClass:[NSNumber class]]
                && [objId isEqualToNumber:identifier]) {
                index = idx;
                *stop = YES;
            }
        }
    }];

    return index;
}

- (NSUInteger)indexOfViewController:(ImageViewController *)viewController {
    return [_dataSource indexOfObject:viewController.photo];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark SAVE IMAGE

////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)savePhotoWithIdentifier:(NSNumber *)identifier
                    andCallback:(NSString *)callback {
    NSURLRequest *photoRequest = _loadedPhotos[identifier];
    if (photoRequest != nil) {
        UIImage *photo = [[UIImageView sharedImageCache] cachedImageForRequest:photoRequest];
        [_savingPhotos addObject:@{@"photo": photo,
                                   kJSCallback: callback}];
        UIImageWriteToSavedPhotosAlbum(photo,
                                       self,
                                       @selector(image:didFinishSavingWithError:contextInfo:),
                                       nil);
    }
    else {
        [_toSavePhotos addObject:@{@"photo_id": identifier,
                                   kJSCallback: callback}];
    }
}

- (void)image:(UIImage *)image
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
    NSString *result = @"success";

    if (error != nil) {
        switch(error.code) {
            case -3310:
                result = @"disabled";
                break;
            default:
                result = @"failure";
                break;
        };
    }

    __block NSString *callback = nil;
    __block NSNumber *index = [NSNumber numberWithInteger:NSNotFound];
    [_savingPhotos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"photo"] isEqual:image]) {
            callback = obj[kJSCallback];
            index = [NSNumber numberWithUnsignedInteger:idx];
            *stop = YES;
        }
    }];

    [_savingPhotos removeObjectAtIndex:[index unsignedIntegerValue]];

    [self sendCallback:callback
              withData:@{@"result": result}];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark UIPAGEVIEWCONTROLLER

////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark Delegate

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    if (completed) {
        _currentViewController = (ImageViewController *) pageViewController.viewControllers.lastObject;

        NSNumber *photoId = _currentViewController.photoIdentifier;
        if (photoId != nil) {
            [self sendEvent:@"slideshow:onChange"
                   withData:@{@"photo_id": photoId}
                andCallback:nil];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark Data Source

////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:(ImageViewController *) viewController];

    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }

    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:(ImageViewController *) viewController];

    if (index == NSNotFound) {
        return nil;
    }

    index++;
    if (index == _dataSource.count) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}



- (void)removeViewControllerAtIndex:(NSUInteger)index {
    [_dataSource removeObjectAtIndex:index];

    _currentViewController = [self viewControllerAtIndex:index];
    if (_currentViewController != nil) {
        [_pageViewController setViewControllers:@[_currentViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];

    }
    else {
        _currentViewController = [self viewControllerAtIndex:index - 1];
        if (_currentViewController != nil) {
            [_pageViewController setViewControllers:@[_currentViewController]
                                          direction:UIPageViewControllerNavigationDirectionReverse
                                           animated:YES
                                         completion:nil];
        }
        else {
            // Handle case when dataSource is empty...
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark IMAGEVIEWCONTROLLERDELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////////
//sharedImageDownloader;setSharedImageDownloader
- (void)didLoadPhoto:(UIImage *)image
      withIdentifier:(NSNumber *)identifier
          andRequest:(NSURLRequest *)request {
    [[UIImageView sharedImageCache] cacheImage:image
                                    forRequest:request];

    [_loadedPhotos setObject:request
                      forKey:identifier];

    __block NSNumber *weakIdentifier = identifier;
    __block NSUInteger index = NSNotFound;
    __block NSMutableArray *indexes = [NSMutableArray array];
    [_toSavePhotos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"photo_id"] isEqualToNumber:weakIdentifier]) {
            index = idx;
            [indexes addObject:[NSNumber numberWithUnsignedInteger:idx]];
        }
    }];

    if (index != NSNotFound) {
        [self savePhotoWithIdentifier:identifier
                          andCallback:_toSavePhotos[index][kJSCallback]];
    }

    indexes = [[[indexes reverseObjectEnumerator] allObjects] mutableCopy];
    [indexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [_toSavePhotos removeObjectAtIndex:[obj unsignedIntegerValue]];
    }];
}

- (void)didTapOnPhoto:(NSNumber *)identifier {
    [self sendEvent:@"slideshow:onTouch"
           withData:@{@"photo_id": identifier}
        andCallback:nil];
}

- (void)didDoubleTapOnPhoto:(NSNumber *)identifier {
    [self sendEvent:@"slideshow:onDoubleTap"
           withData:@{@"photo_id": identifier}
        andCallback:nil];
}

- (void)didLongPressOnPhoto:(NSNumber *)identifier {
    [self sendEvent:@"slideshow:onLongTouch"
           withData:@{@"photo_id": identifier}
        andCallback:nil];
}

- (void)toggleBars {
    GalleryItemsStorage *sharedManager = [GalleryItemsStorage sharedManager];
    NSLog(@"shared manaer color bar = %@", sharedManager.settings);
    if (barsVisible) { // change view to fullscreen mode
        [self sendMessage:@{kJSType: kJSTypePlugin,
                            kJSPluginName: @"slideshow",
                            kJSAction: @"slideshow:hideBars",
                            @"top": (topBarsExist ? @true : false),
                            @"bottom": (bottomBarsExist ? @true : @false)
                            }];
        barsVisible = false;
        // change background
        [self changeBackgroundColor:[sharedManager.settings valueForKey:@"fullscreenBackgroundColor"]];
    } else { // normal view
        [self sendMessage:@{kJSType: kJSTypePlugin,
                            kJSPluginName: @"slideshow",
                            kJSAction: @"slideshow:showBars",
                            @"top": (topBarsExist ? @true : false),
                            @"bottom": (bottomBarsExist ? @true : @false)
                            }];
        barsVisible = true;
        // change background
        [self changeBackgroundColor:[sharedManager.settings valueForKey:@"backgroundColor"]];
    }
}

- (void) changeBackgroundColor:(NSString *) color {
    if (color != nil
        && [color isKindOfClass:[NSString class]]) {
        UIColor *backgroundColor = [Cobalt colorFromHexString:color];
        if (backgroundColor != nil) {
            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                             animations:^{
                                 _pageViewController.view.backgroundColor = backgroundColor;
                             }];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark COBALT

////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)onUnhandledMessage:(NSDictionary *)message {
    NSLog(@"%@ received Cobalt message %@", NSStringFromClass([self class]), message);
    return false;
}

- (BOOL)onUnhandledCallback:(NSString *)callback
                   withData:(NSDictionary *)data {
    NSLog(@"Received callback %@", callback);
    return false;
}

- (BOOL)onUnhandledEvent:(NSString *)event
                withData:(NSDictionary *)data
             andCallback:(NSString *)callback {
    if ([@"slideshow:start" isEqualToString:event]) {
        GalleryItemsStorage *sharedManager = [GalleryItemsStorage sharedManager];
        NSLog(@"Start slideshow received event %@ with %@ images data", event, sharedManager.photos.description);
        id startId = sharedManager.photos[@"startId"];
        id photos = sharedManager.photos[@"photos"];
        if ((startId == nil || [startId isKindOfClass:[NSNumber class]])
            && photos != nil && [photos isKindOfClass:[NSArray class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initSlideshowWithPhotos:photos
                                   andStartId:startId];
            });
        }
        return YES;
    }
    if ([@"slideshow:setBackground" isEqualToString:event]) {
        id color = data[@"color"];
        if (color != nil
            && [color isKindOfClass:[NSString class]]) {
            UIColor *backgroundColor = [Cobalt colorFromHexString:color];
            if (backgroundColor != nil) {
                [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                                 animations:^{
                                     _pageViewController.view.backgroundColor = backgroundColor;
                                 }];
            }
        }
        return YES;
    }
    if ([@"slideshow:setBackground" isEqualToString:event]) {
        id color = data[@"color"];

        if (color != nil
            && [color isKindOfClass:[NSString class]]) {
            UIColor *backgroundColor = [Cobalt colorFromHexString:color];
            if (backgroundColor != nil) {
                [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                                 animations:^{
                                     _pageViewController.view.backgroundColor = backgroundColor;
                                 }];
            }
        }
        return YES;
    }
    return NO;
}

- (void)onBarButtonItemPressed:(NSString *)name {
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{kJSAction: JSActionPressed,
                                                                                kJSName: name}];
    NSNumber *photoId = _currentViewController.photoIdentifier;
    if (photoId != nil) {
        [data setObject:@{@"photo_id": photoId}
                 forKey:kJSData];
    }

    [self sendMessage:@{kJSType: JSTypeUI,
                        kJSControl: JSControlBars,
                        kJSData: data}];
}


@end
