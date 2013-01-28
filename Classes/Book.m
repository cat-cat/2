//
//  Book.m
//  audiobook
//
//  Created by Mac Pro on 9/12/12.
//
//

#import "Book.h"

@implementation Book
@synthesize abookId, cover, title, authors, inRentGreen, inRentRed, isHit, rating, readedPercent, downloadedPercent;
@synthesize downloadBarIsBlue, isTransparent, readers, publishers, lengthTime, bitRate, size, cost, genres, description, isRecommended;
@synthesize releaseDate, updateDate, bookmarks, dlParams, listen, isExport, tracks, isBought, freeTrack, freePartDate, freePartNumber, lastOpened, isFirstRun, isLoadFromHistory;
@synthesize isFreePartBeginDownload, selectedChapter, freePartCount;

-(id)initWithID:(NSString *)ID:(NSString*) bid {
    self = [super init];
    if(self){
//        ID = bid;
//        self.name = theName;
    }
    return self;
}
-(id)init{
    self = [super init];
    if(self){
//        ID = bid;
        //        self.name = theName;
    }
    return self;
//    return [self initWithID:@""];
}

@end
