//
//  CatalogViewController.m
//  CDB
//
//  Created by Mac Pro on 9/4/12.
//
//

#import "MainViewController.h"
#import "CatalogViewController.h"
#import "CatalogItem.h"
#import "gs.h"

@implementation MainViewController
@synthesize message;
@synthesize selectedShow;
@synthesize selectedCharacter;

- (id)initWithMessage:(NSString *)theMessage andImage:(UIImage*) image {
	if (self = [super initWithNibName:nil bundle:nil]) {
        //		TVAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//		self.title =  [delegate characterNameForShowIndex:delegate.selectedShow.row atIndex:delegate.selectedCharacter.row];

//        selectedGenreIndex = -1;
        [self prepareDataModel];
        //	window = [[UIWindow alloc] initWithFrame:[[UIScreen  mainScreen] bounds]] ;
        CatalogViewController *genresViewController = [[CatalogViewController alloc] initWithStyle:UITableViewStylePlain andParentGenre:@"-1"];
        gss().navigationController = [[UINavigationController alloc] initWithRootViewController:genresViewController];

        [self.view addSubview:[gss().navigationController view]];
        //    [window addSubview:[navigationController view]];
        //	[window makeKeyAndVisible];
        [self.view addSubview:gss().playerButton];
        
		self.message = theMessage;
		self.tabBarItem.image  = image;

        
	}
	return self;
}



-(void)prepareDataModel{
//    @autoreleasepool {
//
    // init database
//        db = [[Database alloc] init];
//
//        if ([db open] == -1) {
//            fprintf(stderr, "\n** error: cannot open database\n");
//        }
    
//        [self nextGenres];
            

            
        NSDictionary    *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Seinfeld",
                                     @"Name",
                                     [NSArray arrayWithObjects:
                                      @"Jerry", @"George", @"Elaine", @"Kramer",
                                      @"Newman", @"Frank",  @"Susan",  @"Peterman",  @"Bania", nil],
                                     @"Characters",
                                     nil
                                     ];
        NSDictionary    *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Lost",
                                     @"Name",
                                     [NSArray arrayWithObjects:
                                      @"Kate", @"Sayid", @"Sun", @"Hurley",
                                      @"Boone", @"Claire",  @"Jin",  @"Locke",  @"Charlie", @"Eko", @"Ben", nil],
                                     @"Characters",
                                     nil
                                     ];
        theShows = [NSArray arrayWithObjects:dic1, dic2, nil];

//    }
    
//    [GlobalSingleton setDelegate:self];
    
    // start update timer
    [gs checkNetworkStatus:nil];
    
}

//-(int)dbOffset
//{
//    return dbOffset;
//}
//
//-(NSInteger)genresCount{
//	return [genres count];
//}
//
//@class Genre;
//-(Genre*)genreAtIndex:(NSInteger) index{
//	return [genres objectAtIndex:index];
//}

-(NSInteger)numberOfCharactersForShowAtIndex:(NSInteger) index{
    return [[[theShows objectAtIndex:index] valueForKey:@"Characters"] count];
}


-(NSString*)characterNameForShowIndex:(NSInteger) showIndex atIndex:(NSInteger) index{
	return [[[theShows objectAtIndex:showIndex] valueForKey:@"Characters"] objectAtIndex:index];
}


@end



