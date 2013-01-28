//
//  GenreSettings.h
//  Audiobook
//
//  Created by System Administrator on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenreSettings : NSObject


@property (assign) int abookId;
@property (assign) int genreId;
@property (assign) int genreParentId;
@property (nonatomic, retain) NSString *genreName;

- (id)initWithId:(int)genreId andParentId:(int)parentId andName:(NSString *)name;

- (id)initWithId:(int)genreId andParentId:(int)parentId andName:(NSString *)name andBookId:(int)bookId;
@end
