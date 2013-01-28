/******************************************************************************
 * Copyright (c) 2009, Maher Ali <maher.ali@gmail.com>
 * iPhone SDK 3 Programming - Advanced Mobile Development for Apple iPhone and iPod touch
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

#import "CharacterViewController.h"
#import "CatalogViewController.h"
#import "Book.h"
#import "CDBAppDelegate.h"
#import "GlobalSingleton.h"

@implementation CharacterViewController
//@synthesize delegate;

- (Book*)db_GetBookWithID:(NSString*) bid
{
    sqlite3* db;

    int returnCode = sqlite3_open([GlobalSingleton dbname], &db);
    [GlobalSingleton assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
    char *sqlStatement;
    
    sqlStatement = sqlite3_mprintf("SELECT abook_id"
                                   " , rate"
                                   " , title"
                                   " , summary"
                                   " , price"
                                   " , length"
                                   " , size"
                                   " , release_date"
                                   " , update_date"
                                   " , export"
                                   " , listen"
                                   " , bought"
                                   " , free"
                                   " , title_lower"
                                   " , free_part_number"
                                   " , free_part_downloaded_date"
                                   " , title_in_english"
                                   " , in_rent_red"
                                   " , last_opened"
                                   " , is_recommended"
                                   " , readed_percent"
                                   " , isFreePartDownloaded"
                                   " , selectedChapter"
                                   " , isLoadFromHistory"
                                   " , freePartCount"
                                   " FROM [t_abooks]"
                                   " WHERE abook_id=%s"
                                   " LIMIT 0,1", [bid UTF8String]);
    
    sqlite3_stmt *statement;
    
    returnCode =
    sqlite3_prepare_v2(db, sqlStatement, strlen(sqlStatement), &statement, NULL);
    [GlobalSingleton assertNoError:returnCode==SQLITE_OK withMsg: [NSString stringWithFormat: @"Unable to prepare statement: %s",sqlite3_errmsg(db) ]];
    
    sqlite3_free(sqlStatement);
    
    
    // get result
    Book *locBook;
    returnCode = sqlite3_step(statement);
    while(returnCode == SQLITE_ROW){
        locBook = [[Book alloc] init];
        locBook.abookId = sqlite3_column_int(statement, 0) == 0 ? -1 : sqlite3_column_int(statement, 0);
        locBook.title = [NSString stringWithCString:sqlite3_column_text(statement, 2) == nil ? "" : (char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding];
        //        printf("name %s count %s ID %s\n",
        //               name, count, ID);
        returnCode = sqlite3_step(statement);
        
        
    }
    returnCode = sqlite3_finalize(statement);
    [GlobalSingleton assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot finalize %s", sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [GlobalSingleton assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot close %s", sqlite3_errmsg(db) ]];
    return locBook;
}

- (id)initWithDelegate:(CatalogViewController*) d andBookID:(NSString*) bid
{
	if (self = [super init]) {
//		TVAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        delegate = d;

        //
        book = [self db_GetBookWithID:bid];
        
//		self.title =  [delegate characterNameForShowIndex:delegate.selectedShow.row atIndex:delegate.selectedCharacter.row];
		self.title =  book.title;
	}
	return self;
}

-(void)listenFree:(id)sender{
    //UIButton *button = sender;
    //printf("\ngo to free listening: %s", [button.titleLabel.text UTF8String]);
    
    CDBAppDelegate *d = [[UIApplication sharedApplication] delegate];
    [d changeViewControllerToIndex:3];
//    if(myButton == sender){
//        printf("The button was tapped\n");
//    }
}

- (void)loadView {
//	TVAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	theView   = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	theView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	theView.backgroundColor = [UIColor  whiteColor];
	
	CGRect labelFrame =  CGRectMake(80, 10, 190, 50);
	nameLabel = [[UILabel alloc] initWithFrame:labelFrame];
    nameLabel.font = [UIFont systemFontOfSize:25.0];
	nameLabel.textColor = [UIColor  blackColor];
	nameLabel.backgroundColor = [UIColor clearColor];
	nameLabel.textAlignment = UITextAlignmentLeft;   
	nameLabel.lineBreakMode = UILineBreakModeWordWrap;
	NSString  *theName = [delegate characterNameForShowIndex:delegate.selectedShow.row atIndex:delegate.selectedCharacter.row];
	nameLabel.text = [NSString stringWithFormat:@"%@:  %@", @"Name", theName];
    [theView addSubview: nameLabel];
	UIImageView   *imgView = [[UIImageView alloc] 
								initWithImage:[UIImage
												imageNamed:[NSString stringWithFormat:@"%@.jpg",  theName]]];
	imgView.frame = CGRectMake(30, 70, 250, 300);
	[theView addSubview:imgView];
    
    
    // addButton
    UIButton* myButton =
    [UIButton buttonWithType:UIButtonTypeRoundedRect];
    myButton.frame = CGRectMake(40.0, 100.0, 190, 50);
    [myButton setTitle:@"Слушать бесплатно" forState:UIControlStateNormal];
    [myButton addTarget:self
                 action:@selector(listenFree:)
       forControlEvents:UIControlEventTouchUpInside];
    [theView addSubview: myButton];
    
    
	
	self.view = theView;
}
 



@end
