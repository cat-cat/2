//
//  Genre.h
//  CDB
//
//  Created by Mac Pro on 9/6/12.
//
//

#import <Foundation/Foundation.h>

@interface CatalogItem : NSObject {
//    NSString *priceios;
//    NSString *authors;
//    NSString *ID;
//    NSString *name;
//    NSString *subgenresCount;
//    NSString *type;
}
@property(copy) NSString *priceios;
@property(copy) NSString *authors;
@property(copy) NSString *ID;
@property(copy) NSString *name;
@property(copy) NSString *subgenresCount;
@property(copy) NSString *type;

-(id)initWithName:(NSString*) theName andID:(NSString*) vID andCount:(NSString*) count andType:(NSString*) vType;
-(id)init;
@end
