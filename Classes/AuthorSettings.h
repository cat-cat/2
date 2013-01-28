//
//  AuthorSettings.h
//  Audiobook
//
//  Created by System Administrator on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthorSettings : NSObject

@property (assign) int authorId;
@property (assign) int abookId;
@property (nonatomic, retain) NSString *authorName;
@property (nonatomic, retain) NSString *author_ids; // TODO: added only for compability for using in the CatalogDetailViewController::items array (which can also contain AuthorsCounter elements)

- (id)initWithId:(int)authorId andName:(NSString *)name;
- (id)initWithId:(int)theAuthorId andName:(NSString *)name andBookId:(int)bookId;
@end
