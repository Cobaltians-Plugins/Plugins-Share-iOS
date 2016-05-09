/*
* CobaltSharePlugin.h
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

#import <Cobalt/CobaltAbstractPlugin.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

// modify tokens here
// source of files
#define kAPITokenSource @"source"
#define kAPITokenPath @"path"
#define kAPITokenLocal @"local"
#define kAPITokenRemote @"url"
// types of files
#define kAPITokenType @"type"
#define kAPITokenImageType @"image"
#define kAPITokenTextType @"text"
#define kAPITokenContactType @"contact"
#define kAPITokenDataType @"data"
#define kAPITokenAudioType @"audio"
#define kAPITokenVideoType @"video"
#define kAPITokenDocumentType @"document"
// text fields
#define kAPITokenTextContent @"content"
// contact fields
#define kAPITokenContactName @"name"
#define kAPITokenContactMobile @"mobile"
#define kAPITokenContactEmail @"email"
#define kAPITokenContactCompany @"company"
#define kAPITokenContactPostal @"postal"
#define kAPITokenContactJob @"job"
// commons fields
#define kAPITokenTitle @"title"
#define kAPITokenDetail @"detail"

@interface CobaltSharePlugin: CobaltAbstractPlugin
@property (weak, nonatomic) CobaltViewController *viewController;
@property (strong, nonatomic) NSArray *tokens;
@property (weak, nonatomic) NSDictionary *filedata;
@end
