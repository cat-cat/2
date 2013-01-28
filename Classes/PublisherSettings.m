//
//  PublisherSettings.m
//  Audiobook
//
//  Created by System Administrator on 10/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PublisherSettings.h"

@implementation PublisherSettings
@synthesize abookId, publisherId, publisherName;

- (id)init
{
    self = [super init];
    if (self) 
    {
        abookId = -1;
        publisherId = -1;
        publisherName = @"";
    }
    return self;
}

- (id)initWithId:(int)thePublisherId andName:(NSString *)name
{
    self = [super init];
    if(self)
    {
        self.publisherId = thePublisherId;
        self.publisherName = name;
    }
    return self;
}
- (id)initWithId:(int)thePublisherId andName:(NSString *)name andBookId:(int)bookId
{
    self = [super init];
    if(self)
    {
        self.abookId = bookId;
        self.publisherId = thePublisherId;
        self.publisherName = name;
    }
    return self;
}

        
- (void)dealloc
{
//    [publisherName release];
//    [super dealloc];
}

@end
