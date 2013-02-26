//
//  Genre.m
//  CDB
//
//  Created by Mac Pro on 9/6/12.
//
//

#import "CatalogItem.h"

@implementation CatalogItem
@synthesize authors;
@synthesize ID;
@synthesize name;
@synthesize subgenresCount;
@synthesize type;

-(id)initWithName:(NSString*) theName andID:(NSString*) vID andCount:(NSString*) count andType:(NSString*) vType{
    self = [super init];
    if(self){
        self.ID = vID;
        self.name = theName;
        self.subgenresCount = count;
        self.type = vType;
    }
    return self;
}
-(id)init{
    return [self initWithName:@"" andID:@"" andCount:@"" andType:@""];
}
@end
