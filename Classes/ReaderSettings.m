//
//  ReaderSettings.m
//  Audiobook
//
//  Created by System Administrator on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ReaderSettings.h"

@implementation ReaderSettings
@synthesize abookId, readerId, readerName;

- (id)init
{
    self = [super init];
    if (self) 
    {
        abookId  = -1;
        readerId = -1;
        readerName = @"";
    }
    return self;
}

- (id)initWithId:(int)theReaderId andName:(NSString *)name
{
    self = [super init];
    if(self)
    {
        self.readerId = theReaderId;
        self.readerName = name;
    }
    return self;
}

- (id)initWithId:(int)theReaderId andName:(NSString *)name  andBookId:(int)bookId
{
    self = [super init];
    if(self)
    {
        self.abookId    = bookId;
        self.readerId = theReaderId;
        self.readerName = name;
    }
    return self;
}


- (void)dealloc
{
//    [readerName release];
//    [super dealloc];
}

@end
