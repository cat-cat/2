//
//  CatalogViewController.h
//  CDB
//
//  Created by Mac Pro on 9/4/12.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MyViewController.h"
//@class Database;
@interface MainViewController : MyViewController {
	NSString *message;
	NSIndexPath  *selectedShow;
	NSIndexPath  *selectedCharacter;
	NSArray		 *theShows;
}
@property (nonatomic) int selectedGenreIndex;
@property (nonatomic, strong) NSString *message;

@property(nonatomic, strong) NSIndexPath *selectedShow;
@property(nonatomic, strong) NSIndexPath *selectedCharacter;

//-(void)resetDBCursor;
- (id)initWithMessage:(NSString *)theMessage andImage:(UIImage*) image;
//-(int)dbOffset;
//-(NSInteger)genresCount;
//-(NSString*)genreAtIndex:(NSInteger) index;
//-(NSInteger)numberOfCharactersForShowAtIndex:(NSInteger) index;
//-(NSString*)characterNameForShowIndex:(NSInteger) showIndex atIndex:(NSInteger) index;
@end




