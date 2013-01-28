//
//  ReaderSettings.h
//  Audiobook
//
//  Created by System Administrator on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReaderSettings : NSObject


@property (assign) int abookId;
@property (assign) int readerId;
@property (nonatomic, retain) NSString *readerName;

- (id)initWithId:(int)readerId andName:(NSString *)name;
- (id)initWithId:(int)theReaderId andName:(NSString *)name  andBookId:(int)bookId;
@end
