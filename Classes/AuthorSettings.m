//
//  AuthorSettings.m
//  Audiobook
//
//  Created by System Administrator on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AuthorSettings.h"

@implementation AuthorSettings
@synthesize abookId, authorId, authorName, author_ids;

- (id)init
{
    self = [super init];
    if (self) 
    {
        abookId  = -1;
        authorId = -1;
        authorName = @"";
    }
    return self;
}

- (id)initWithId:(int)theAuthorId andName:(NSString *)name
{
    self = [super init];
    if(self)
    {
        self.authorId = theAuthorId;
        self.authorName = name;
    }
    return self;
}
- (id)initWithId:(int)theAuthorId andName:(NSString *)name andBookId:(int)bookId
{
    self = [super init];
    if(self)
    {
        self.abookId    = bookId;
        self.authorId   = theAuthorId;
        self.authorName = name;
    }
    return self;
}

- (void)dealloc
{
//    [authorName release];
//    [super dealloc];
}

@end
