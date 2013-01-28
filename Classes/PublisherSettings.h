//
//  PublisherSettings.h
//  Audiobook
//
//  Created by System Administrator on 10/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PublisherSettings : NSObject


@property (assign) int abookId;
@property (assign) int publisherId;
@property (nonatomic, retain) NSString *publisherName;

- (id)initWithId:(int)publisherId andName:(NSString *)name;
- (id)initWithId:(int)thePublisherId andName:(NSString *)name andBookId:(int)bookId
;

@end
