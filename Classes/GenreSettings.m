//
//  GenreSettings.m
//  Audiobook
//
//  Created by System Administrator on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GenreSettings.h"

@implementation GenreSettings
@synthesize abookId, genreId, genreParentId, genreName;

- (id)init
{
    self = [super init];
    if (self) 
    {
        abookId = -1;
        genreId = -1;
        genreParentId = -1;
        genreName = @"";
    }
    return self;
}

- (id)initWithId:(int)theGenreId andParentId:(int)theParentId andName:(NSString *)name
{
    self = [super init];
    if(self)
    {  
        self.genreId = theGenreId;
        self.genreParentId = theParentId;
        self.genreName = name;
    }
    return self;
}

- (id)initWithId:(int)theGenreId andParentId:(int)theParentId andName:(NSString *)name andBookId:(int)bookId
{
    self = [super init];
    if(self)
    {
        self.abookId = bookId;
        self.genreId = theGenreId;
        self.genreParentId = theParentId;
        self.genreName = name;
    }
    return self;
}

- (void)dealloc
{
//    [genreName release];
//    [super dealloc];
}

@end
