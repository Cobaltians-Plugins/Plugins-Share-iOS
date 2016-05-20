/*
 * CobaltSharePlugin.m
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

#import "CobaltSharePlugin.h"

@implementation CobaltSharePlugin

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
    NSString * callback = [data objectForKey:kJSCallback];
    NSString * action = [data objectForKey:kJSAction];

    if (action != nil && [action isEqualToString:@"share"]) {
        if (DEBUG_COBALT) NSLog(@"SharePlugin received data %@", data.description);

        // prepare data
        _viewController = viewController;
        // add defined tokens
        _tokens = @[kAPITokenSource,
                    kAPITokenPath,
                    kAPITokenLocal,
                    kAPITokenRemote,
                    kAPITokenType,
                    kAPITokenImageType,
                    kAPITokenTextType,
                    kAPITokenContactType,
                    kAPITokenDataType,
                    kAPITokenAudioType,
                    kAPITokenVideoType,
                    kAPITokenDocumentType,
                    kAPITokenTextContent,
                    kAPITokenContactName,
                    kAPITokenContactMobile,
                    kAPITokenContactEmail,
                    kAPITokenContactCompany,
                    kAPITokenContactPostal,
                    kAPITokenContactJob,
                    kAPITokenTitle,
                    kAPITokenDetail];
    
        // parse dictionary
        _filedata = [self parseDictionary:data];
        if (_filedata.count == 0) {
            NSLog(@"Error while parsing file datas, check your javascript.");
            return;
        }
        if (DEBUG_COBALT) NSLog(@"SharePlugin input parsing done: %@", _filedata.description);

        // share text
        NSString *type = [_filedata objectForKey:kAPITokenType];
        if ([type isEqualToString:kAPITokenTextType]) {
            if ([self containsKey:kAPITokenTextContent]) {
                [self shareText :[_filedata objectForKey:kAPITokenTextContent] title:[_filedata objectForKey:kAPITokenTitle]];
            };
        }

        // share contact
        if ([type isEqualToString:kAPITokenContactType]) {
            if ([self containsKey:kAPITokenContactName] || [self containsKey:kAPITokenContactMobile] ||
                [self containsKey:kAPITokenContactEmail] || [self containsKey:kAPITokenContactCompany] ||
                [self containsKey:kAPITokenContactPostal] || [self containsKey:kAPITokenContactJob] ||
                [self containsKey:kAPITokenDetail]) {
                [self shareContact:[_filedata objectForKey:kAPITokenContactName]
                            mobile:[_filedata objectForKey:kAPITokenContactMobile]
                             email:[_filedata objectForKey:kAPITokenContactEmail]
                           company:[_filedata objectForKey:kAPITokenContactCompany]
                            postal:[_filedata objectForKey:kAPITokenContactPostal]
                               job:[_filedata objectForKey:kAPITokenContactJob]
                            detail:[_filedata objectForKey:kAPITokenDetail]];
            };
        }

        // share image
        if ([type isEqualToString:kAPITokenImageType]) {
            if ([self containsKey:kAPITokenSource] && [self containsKey:kAPITokenPath] ) {
                [self shareImage:[_filedata objectForKey:kAPITokenSource] path:[_filedata objectForKey:kAPITokenPath]];
            };
        }

        if ([type isEqualToString:kAPITokenDataType] || [type isEqualToString:kAPITokenAudioType] || [type isEqualToString:kAPITokenVideoType] || [type isEqualToString:kAPITokenDocumentType]) {
            if ([self containsKey:kAPITokenSource] && [self containsKey:kAPITokenPath]) {
                [self shareDataWithPath :[_filedata objectForKey:kAPITokenSource] path:[_filedata objectForKey:kAPITokenPath]];
            } else if ([self containsKey:kAPITokenSource] && [self containsKey:kAPITokenLocal]) {
                // todo assets management
            }
        }
        // send callback
        [viewController sendCallback: callback
                            withData: nil];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SHARE TEXT

////////////////////////////////////////////////////////////////////////////////////////////////

- (void) shareText: (NSString *)content
             title: (NSString *)title {
    NSArray *objectsToShare;
    if (title != NULL) {
        objectsToShare = @[title, content];
    } else {
        objectsToShare = @[content];
    }
    // share stored data
    [self shareObject:objectsToShare];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SHARE IMAGE

////////////////////////////////////////////////////////////////////////////////////////////////

- (void) shareImage: (NSString *)source
               path: (NSString *)path {
    NSArray *objectsToShare;
    // Share image from url
    if ([source isEqualToString:kAPITokenRemote]) {
        NSURL *url = [NSURL URLWithString:path];
        NSData *data = [NSData dataWithContentsOfURL:url];
        objectsToShare = @[[[UIImage alloc] initWithData:data]];
    } else if ([source isEqualToString:kAPITokenLocal]) {
        NSArray *parts = [path componentsSeparatedByString:@"/"];
        UIImage *img = [UIImage imageNamed:[parts lastObject]];
        if (img != NULL) {
            objectsToShare = @[img];
        } else {
            if (DEBUG_COBALT) NSLog(@"Cobalt Share Plugin > Fatal: image %@ not found in bundle.", path);
            return;
        }
    } else {
        return;
    }
    // share stored data
    [self shareObject:objectsToShare];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SHARE A CONTACT

////////////////////////////////////////////////////////////////////////////////////////////////

- (void) shareContact: (NSString *)name
               mobile: (NSString *)mobile
                email: (NSString *)email
              company: (NSString *)company
               postal: (NSString *)postal
                  job: (NSString *)job
               detail: (NSString *)detail {
    // init adressBook
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            // First time access has been granted, add the contact
            [self addPersonToAdressBook:name mobile:mobile email:email company:company postal:postal job:job detail:detail];
            return;
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [self addPersonToAdressBook:name mobile:mobile email:email company:company postal:postal job:job detail:detail];
        return;
    }
    else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Add Contact" message: @"You must give the app permission to add the contact first." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
            [cantAddContactAlert show];
        });
    }
}

- (void) addPersonToAdressBook: (NSString *)name
                        mobile: (NSString *)mobile
                         email: (NSString *)email
                       company: (NSString *)company
                        postal: (NSString *)postal
                           job: (NSString *)job
                        detail: (NSString *)detail {
    // init adressBook
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABPersonCreate();
    // add optionals values
    if (company != NULL) ABRecordSetValue(person, kABPersonOrganizationProperty, (__bridge CFTypeRef)(company), NULL);
    if (job != NULL) ABRecordSetValue(person, kABPersonJobTitleProperty, (__bridge CFTypeRef)(job), NULL);
    if (detail != NULL) ABRecordSetValue(person, kABPersonNoteProperty, (__bridge CFTypeRef)(detail), NULL);
    if (postal != NULL) {
        // add postal adress
        ABMutableMultiValueRef multiHome = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
        NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
        [addressDictionary setObject:postal forKey:(NSString *) kABPersonAddressStreetKey];
        bool didAddHome = ABMultiValueAddValueAndLabel(multiHome, (__bridge CFTypeRef)(addressDictionary), kABHomeLabel, NULL);
        if (didAddHome) ABRecordSetValue(person, kABPersonAddressProperty, multiHome, NULL);
    }
    if (email != NULL) {
        // add email
        ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(multiEmail, (__bridge CFTypeRef)(email), kABWorkLabel, NULL);
        ABRecordSetValue(person, kABPersonEmailProperty, multiEmail, NULL);
    }
    // add mandatory values
    ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(name), NULL);
    // add phone number
    ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)mobile, kABPersonPhoneMainLabel, NULL);
    ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumbers, nil);
    // add contact to book and feedback the user
    dispatch_async(dispatch_get_main_queue(), ^{
        ABAddressBookAddRecord(addressBook, person, NULL);
        ABAddressBookSave(addressBook, nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Contact Added" message:name delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    });
}


////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SHARE DATAS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void) shareDataWithPath: (NSString *)source
                      path: (NSString *)path {
    NSArray *objectsToShare;
    if ([source isEqualToString:kAPITokenRemote]) {
        // source is from the web
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
        objectsToShare = @[data];
    } else if ([source isEqualToString:kAPITokenLocal]) { // todo Assets management (bundle)
        // source is from internal storage
        NSArray *parts = [path componentsSeparatedByString:@"/"];
        NSData *data = [NSData dataWithContentsOfFile:[parts lastObject]];
        if (data != NULL) {
            objectsToShare = @[data];
        } else {
            if (DEBUG_COBALT) NSLog(@"Fatal: data %@ not found in bundle.", path);
            return;
        }
    } else {
        if (DEBUG_COBALT) NSLog(@"No action for this config");
        return;
    }
    [self shareObject:objectsToShare];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark TOOLS

////////////////////////////////////////////////////////////////////////////////////////////////

// todo Assets management (bundle)
- (NSData *)returnDataFromResourceBundle:(NSString*)name{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Resource" ofType:@"bundle"];
    NSString *receivedData = [[NSBundle bundleWithPath:bundlePath] pathForResource:name ofType:@"png"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:receivedData];
    if (DEBUG_COBALT) NSLog(@"returnUIImageFromResourceBundle from %@ => %@", name.description, data.description);
    return data;
}

// check if _filedata contains a key
- (BOOL)containsKey: (NSString *)key {
    BOOL retVal = false;
    NSArray *allKeys = [_filedata allKeys];
    retVal = [allKeys containsObject:key];
    return retVal;
}

// parse data from web and create _filedata
- (NSDictionary *) parseDictionary: (NSDictionary *)data {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSDictionary *fileDataDictionnary = [NSDictionary dictionaryWithDictionary:[data valueForKey:@"data"]];
    id field = nil;
    NSArray *fieldValues = [fileDataDictionnary allValues];
    if (fieldValues.count > 0) field = [fieldValues objectAtIndex:0];
    NSDictionary *object = [field objectAtIndex:0];

    for (NSString *aKey in [object allKeys]) {
        NSString *aSubValue = [object objectForKey:aKey];
        // get known tokens and put them into dictionary
        for (NSString *item in _tokens) {
            if ([aKey isEqualToString:item]) {
                [dictionary setValue:aSubValue forKey:item];
            }
        }
    }
    return dictionary;
}

// show popover or view controller to share
- (void) shareObject: (NSArray *)objectsToShare {
    //if (DEBUG_COBALT) NSLog(@"shareObject gonna share %@", objectsToShare.description);
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];

    //if iPhone
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_viewController presentViewController:controller animated:YES completion:nil];
        });
    }
    //if iPad
    else {
        // Change Rect to position Popover
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:controller];
        dispatch_async(dispatch_get_main_queue(), ^{
            [popup presentPopoverFromRect:CGRectMake(_viewController.view.frame.size.width/2, _viewController.view.frame.size.height/4, 0, 0)inView:_viewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        });
    }
}

@end
