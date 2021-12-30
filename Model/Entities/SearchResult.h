//
//  SearchResult.h
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchResult : NSObject

@property (nonatomic, strong, nonnull) NSString *zimFileID;
@property (nonatomic, strong, nonnull) NSURL *url;
@property (nonatomic, strong, nonnull) NSString *title;
@property (nonatomic, strong, nullable) NSString *htmlSnippet;
@property (nonatomic, strong, nullable) NSAttributedString *snippet;
@property (nonatomic, strong, nullable) NSNumber *probability;

- (nullable instancetype)initWithZimFileID:(nonnull NSString *)zimFileId
                                      path:(nonnull NSString *)path
                                     title:(nonnull NSString *)title;
- (BOOL)isEqual:(nullable id)other;
- (NSUInteger)hash;

@end
