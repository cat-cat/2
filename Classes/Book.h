//
//  Book.h
//  audiobook
//
//  Created by Mac Pro on 9/12/12.
//
//

#import <Foundation/Foundation.h>
@class TrackSettings;
@interface Book : NSObject 
// from abook service:
@property (assign) int abookId;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *authors;
@property (nonatomic, retain) NSMutableArray *readers;
@property (nonatomic, retain) NSMutableArray *genres;
@property (nonatomic, retain) NSMutableArray *publishers;
@property (nonatomic, retain) NSMutableArray *tracks;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSDate *releaseDate;
@property (nonatomic, retain) NSDate *updateDate;
@property (assign) int rating;
@property (assign) int size;
@property (assign) int lengthTime;
@property (assign) int listen;
@property (assign) int isExport;
@property (assign) float cost;
@property (nonatomic, retain) UIImage *cover;

@property (nonatomic, retain) TrackSettings *freeTrack;
@property (nonatomic, assign) NSInteger freePartNumber;
//Store in Europe/Moscow timeZone
@property (nonatomic, retain) NSString *freePartDate;

@property (assign) BOOL isBought;
@property (assign) BOOL isLoadFromHistory;

@property (assign) bool inRentGreen;
@property (assign) bool inRentRed;

@property (assign) bool isHit;
@property (assign) float readedPercent;
@property (assign) float downloadedPercent;
@property (assign) bool downloadBarIsBlue; // or downloadBarIsGrey
@property (assign) bool isTransparent; // f.e. book deleted
@property (assign) int bitRate;

@property (assign) BOOL isRecommended;
@property (assign) int isFirstRun;
@property (assign) BOOL isFreePartBeginDownload;

@property (assign) int freePartCount;

@property (nonatomic, retain) NSArray *dlParams;
@property (nonatomic, retain) NSMutableArray *bookmarks; // [{chapter + [bookmarks]}] <-> [{@"chapter" + @"bookmarks"}], bookmark <-> {@"text" + @"offset"}

@property (nonatomic, retain) NSDate *lastOpened;
@property (assign) int selectedChapter;

- (NSComparisonResult)compareByRating:(Book *)otherObject;
- (NSComparisonResult)compareByUpdateDate:(Book *)otherObject;

-(id)initWithID:(NSString*) ID;
-(id)init;

@end
