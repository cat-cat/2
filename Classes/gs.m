//
//  gs.m
//  audiobook
//
//  Created by Mac Pro on 1/18/13.
//
//
//#import <NSError>

#import "gs.h"
#import "KissXML/DDXMLDocument.h"
#import "MainViewController.h"
#import "Reachability.h"
#import "Book.h"
#import "ReaderSettings.h"
#import "PublisherSettings.h"
#import "GenreSettings.h"
#import "AuthorSettings.h"
#import "StandardPaths.h"
#import "ASINetworkQueue.h"
#import <CommonCrypto/CommonDigest.h>
#import "PlayerViewController.h"

// TODO: make all functions synchronized
@implementation gs

@synthesize navigationController = _navigationController;
//@synthesize queue = _queue;
static int connectionType;
static Reachability* hostReachable;
//static CatalogViewController* delegate;
//static NSString* AppConnectionHost = @"www.librofon.ru";
static NSString* databaseName;
#define ReachableViaWiFiNetwork          2
#define ReachableDirectWWAN               (1 << 18)

-(DDXMLDocument*) docForFile:(NSString *)path
{
    @synchronized(self)
    {
        NSError* error;
        NSString* str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        [gss() handleError:error];
        DDXMLDocument *xmldoc = [[DDXMLDocument alloc] initWithXMLString:str options:0 error:&error];
        [gss() handleError:error];
        return xmldoc;
    }
}

-(NSArray*) arrayForDoc:(DDXMLDocument *)doc xpath:(NSString*) xpath
{
    @synchronized(self)
    {
        NSError* error;
        NSArray *items=[doc nodesForXPath:xpath error:&error];
        [self handleError:error];
        NSMutableArray* arr = [[NSMutableArray alloc] init];
        for (DDXMLElement *item in items) {
            //NSLog(@"++ item string value: %@", [item stringValue]);
            [arr addObject:[item stringValue]];
        }
        return [arr copy];
    }
}

-(NSString*) pathForBuy:(int)bid
{
    NSString* path = [NSString stringWithFormat:@"%@/%@", [gss() dirsForBook:bid ], @"buy"];
    return path;
}

-(NSString*) pathForBookMeta:(int)bid
{
    @synchronized(self)
    {
        NSString* newDirPath = [self dirsForBook:bid];
        NSString* path =[ NSString stringWithFormat:@"%@/bookMeta.xml", newDirPath ];
        return path;
    }
}

-(NSString*) pathForBook:(int)bid andChapter:(NSString*) ch
{
    @synchronized(self)
    {
        NSString* newDirPath = [self dirsForBook:bid];
        NSString* path =[ NSString stringWithFormat:@"%@/ca/%@.mp3", newDirPath, ch ];
        return path;
    }
}

-(NSString*) pathForBookFinished:(int)bid chapter:(NSString*) ch
{
    @synchronized(self)
    {
        NSString* newDirPath = [self dirsForBook:bid];
        NSString* path =[ NSString stringWithFormat:@"%@/ca/%@finished!", newDirPath, ch ];
        return path;
    }
}

-(NSString*) dirsForBook:(int)bid
{
    @synchronized(self)
    {
        // try to create directory first
        NSString* newDirPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp/%d", bid]];
        NSURL *urlToDir = [NSURL fileURLWithPath:newDirPath ];
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:urlToDir withIntermediateDirectories:true attributes:nil error:&error];
        [self handleError:error];
        NSString* chaptersAudioPath = [newDirPath stringByAppendingString:@"/ca"];
        urlToDir = [NSURL fileURLWithPath:chaptersAudioPath ];
        bool success = [[NSFileManager defaultManager] createDirectoryAtURL:urlToDir withIntermediateDirectories:true attributes:nil error:&error];
        [self handleError:error];
        return  success ? newDirPath : nil;
    }
}

+(void)db_MybooksRemove:(NSString*)bid
{
    sqlite3* db;
    
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
    const char *query = [[NSString stringWithFormat:@"DELETE FROM mybooks WHERE abook_id = %@", bid] UTF8String];
    
    
    sqlite3_stmt *statement;
   
    returnCode =
    sqlite3_prepare_v2(db,
                       query, strlen(query),
                       &statement, NULL);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
    
    
    returnCode  = sqlite3_step(statement);
    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"error done: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
    
    returnCode = sqlite3_finalize(statement);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot finalize %s", sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot close %s", sqlite3_errmsg(db) ]];
}

+(NSArray*)db_GetMybooks
{
    // assuming its not called from multiple threads, only from gui
    
    sqlite3* db;
    
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
    char *sqlStatement;
    
    sqlStatement = sqlite3_mprintf("SELECT abook_id"
                                   " FROM mybooks"
                                   " ORDER BY last_touched DESC");
    
    sqlite3_stmt *statement;
    
    returnCode =
    sqlite3_prepare_v2(db, sqlStatement, strlen(sqlStatement), &statement, NULL);
    [gs assertNoError:returnCode==SQLITE_OK withMsg: [NSString stringWithFormat: @"Unable to prepare statement: %s",sqlite3_errmsg(db) ]];
    
    sqlite3_free(sqlStatement);
    
    
    // get result
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    returnCode = sqlite3_step(statement);
    while(returnCode == SQLITE_ROW){
        NSString* bid = [NSString stringWithCString:sqlite3_column_text(statement, 0) == nil ? "" : (char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
        //        printf("name %s count %s ID %s\n",
        //               name, count, ID);
        [arr addObject:bid];
        returnCode = sqlite3_step(statement);
        
        
    }
    returnCode = sqlite3_finalize(statement);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot finalize %s", sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot close %s", sqlite3_errmsg(db) ]];
    return arr;
}

+ (Book*)db_GetBookWithID:(NSString*) bid
{
    // assuming its not called from multiple threads, only from gui
    
    sqlite3* db;
    
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
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
    [gs assertNoError:returnCode==SQLITE_OK withMsg: [NSString stringWithFormat: @"Unable to prepare statement: %s",sqlite3_errmsg(db) ]];
    
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
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot finalize %s", sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot close %s", sqlite3_errmsg(db) ]];
    return locBook;
}


+ (const char*) dbname
{
    return [databaseName UTF8String];
}

+ (sqlite3_stmt *)queryWithh:(const char*) sqlStatement
{
    sqlite3* db;
    sqlite3_stmt *statement;
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot open: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
    returnCode =
    sqlite3_prepare_v2(db,
                       sqlStatement, strlen(sqlStatement),
                       &statement, NULL);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
    
    //sqlite3_free(sqlStatement);
    
    // get result
    
    return statement;
}


+ (bool) checkNetworkStatus:(NSNotification *)notice
{
    // NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    NetworkStatus hostStatus     = [hostReachable currentReachabilityStatus];
    
    if (/*internetStatus == NotReachable ||*/ hostStatus == NotReachable)
    {
        NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!! No Server connection !!!!!!!!!!!!!!!!!!!!!!");
        connectionType = 0;
        //[[AudiobookAppDelegate delegate] showAlertAtTimer:@"Соединение с сервером отсутствует." delay:3];
        //        if(self.trackLoaders.count > 0)
        //        {
        //            NSLog(@"%d track in queue", self.trackLoaders.count);
        //            //[FileManager saveLoaders];
        //        }
        
    }
    else if (hostStatus == ReachableViaWiFi)
    {
        NSLog(@"************************ WiFi connection *************************");
        connectionType = 1;
        
        //        [self firstAction];
        //
        //        //[[AudiobookAppDelegate delegate] showAlertAtTimer:@"Соединение по WiFi." delay:1];
        //
        //        if(self.trackLoaders.count > 0)
        //            NSLog(@"%d track in queue", self.trackLoaders.count);
        //        //[self startReadLoaders];
        //        [self performSelectorInBackground: @selector(startReadLoaders) withObject:nil];
    }
    else if (hostStatus == ReachableViaWWAN)
    {
        NSLog(@"+++++++++++++++++ 3G connection! ++++++++++++++++++++");
        connectionType = 2;
    }
    
    /*
     if(hostStatus != NotReachable)
     {
     [self showRecoveryMsg];
     }
     */
    // TODO: without condition
    return YES;
}

+ (BOOL)gotConnectionToSrv:(BOOL)showMsg
{
    if(connectionType == 0 && showMsg)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Сервер не доступен. Проверьте интернет-соденинение." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] ;
        [alert show];
    }
    return connectionType != 0;
}

//+ (void) setDelegate:(CatalogViewController *)d
//{
//    delegate = d;
//}
- (int) handleSrvError:(NSString *)err
{
    @synchronized(self)
    {
        int result = 0;
        NSError *error;
        DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:err options:0 error:&error];
        [self handleError:error];
        NSArray *arr = [doc nodesForXPath:@"//error" error:&error];
        if ([arr count]) {
            result = [[[arr objectAtIndex:0] stringValue] intValue];
            NSLog(@"***srv Error: %d", result);
        }
        
        return result;
    }
}

- (bool)handleError:(NSError*) e
{
    @synchronized(self)
    {
        //NSAssert1(!e, @"**err: %@", [e localizedDescription]);

        bool res = NO;
        if (e) {
            NSLog(@"***Error: %@", [e localizedDescription]);
            res = YES;
        }
        
        return res;
    }
}

+ (DDXMLDocument*) GetDocOfPage:(NSString*) page withError:(NSError**) e
{
    DDXMLDocument *doc;
    NSString *tmp = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", AppConnectionHost, page]] encoding:NSUTF8StringEncoding error:e];
    
    //NSLog(@"url string content: %@", tmp);
    
    if([[gs sharedInstance] handleError:*e])
        return nil;
    
    doc = [[DDXMLDocument alloc] initWithXMLString:tmp options:0 error:e];
    
    if([[gs sharedInstance] handleError:*e])
        return nil;
    
    return doc;
}

+ (NSString*) getNodeTextWithXPath:(NSString*) xpath andXMLDoc:(DDXMLDocument*)doc
{
    NSError *error;
    NSArray *bookNodes = [doc nodesForXPath:xpath error:&error];
    
    
    NSString* resultStr = [[bookNodes objectAtIndex:0] stringValue];
    if (error) {
        NSLog(@"*** Error getting xpath");
        resultStr = @"";
    }
    
    // get data
    return resultStr;
}

+ (void) assertNoError:(int) noErrorFlag withMsg:(NSString*)  message
{
    NSAssert(noErrorFlag, message);
    
    if (!noErrorFlag) {
    }
}

+ (bool)updateCatalog:(NSTimer*)t
{
    NSLog(@"++ updateCatalog is called");
    
    @synchronized(self) {
        
        // first handle errors
        //
        
        NSError* err;
        
        DDXMLDocument *doc = [self GetDocOfPage:@"/hasUpdate2.php" withError:&err];
        if ([gss() handleError:err] || doc == nil) {
            NSLog(@"*Update - updates error");
            return false; // no update error
        }
        
        NSArray* na = [doc nodesForXPath:@"/abooks/update"  error:&err];
        if([gss() handleError:err])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Error"
                                                            message:[err localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return false;
        }
        
        if ([na count] == 0) {
            NSLog(@"*update path not found");
            return false;
        }
        
        // success
        //
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy'-'MM'-'dd HH:mm"];
        
        NSString* dstr = [[na objectAtIndex:0] stringValue];
        NSDate *serverDate = [formatter dateFromString:dstr];
        
        char *query = "SELECT max(abook.update_date) FROM t_abooks abook";
        
        sqlite3* db;
        sqlite3_stmt *statement;
        
        
        // OPEN DB
        int returnCode = sqlite3_open([gs dbname], &db);
        
        [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot open: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
        returnCode =
        sqlite3_prepare_v2(db,
                           query, strlen(query),
                           &statement, NULL);
        [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
        
        
        
        NSString *date;
        while(sqlite3_step(statement) == SQLITE_ROW)
        {
            date = [NSString stringWithCString:sqlite3_column_text(statement, 0) == nil ? "" : (char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
            NSLog(@"date : %@",date);
        }
        sqlite3_finalize(statement);
        [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"error finalize: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
        
        [formatter setDateFormat:@"yyyy'-'MM'-'dd HH:mm:ss"];
        NSDate *catalogDate = [formatter dateFromString:date];
        
        if (catalogDate == nil) { // uninitialized in database
            catalogDate = [NSDate distantPast];
        }
        
        
        double interval = [serverDate timeIntervalSinceDate:catalogDate];
        
        if (interval > 0 && [self gotConnectionToSrv:YES])
        {
            doc = [self GetDocOfPage:@"/getAbookCatalogUpdate.php" withError:&err];
            if ([gss() handleError:err] || doc == nil) {
                NSLog(@"*Update - catalog updates error");
                return false; // no update error
            }
            
            NSArray *errArr=[doc nodesForXPath:@"/abooks/error/code" error:&err];;
            
            if ([errArr count]  || err) {
                NSLog(@"***err: error parsing data for updating");
                return NO;
            }
            
            //*************************
            
            // init relulting variables
            NSString* updateDate;
            NSMutableArray *books = [[NSMutableArray alloc] initWithCapacity:5000];
            NSMutableArray *a_authors = [[NSMutableArray alloc] initWithCapacity:5000];
            NSMutableArray *a_readers = [[NSMutableArray alloc] initWithCapacity:5000];
            NSMutableArray *a_genres = [[NSMutableArray alloc] initWithCapacity:5000];
            NSMutableArray *a_publishers = [[NSMutableArray alloc] initWithCapacity:5000];
            
            // catalog date
            NSArray *cdateArr=[doc nodesForXPath:@"//catalog/@date" error:(&err)];
            if (![cdateArr count]  || err) {
                NSLog(@"***err: error parsing catalog attribute"); // probably "<abooks />" - is the answer from server
                return NO;
            }
            updateDate = [[cdateArr objectAtIndex:0] stringValue];
            
            // books ids
            NSArray *booksIds = [doc nodesForXPath:@"//abook/@id[not (ancestor::remove)]" /*only for updated and added books*/ error:&err];
            
            for(DDXMLNode *bidNode in booksIds) {
                
                // init variables
                NSString *bid = [bidNode stringValue];
                Book *bookSettings = [[Book alloc] init];
                bookSettings.abookId = [bid intValue];
                //NSString *bookStr = [NSString stringWithFormat:@"//abook[@id=%@]/*", bid ];
                NSString *bookStr = [NSString stringWithFormat:@"//abook[@id=%@]", bid ];
                //NSArray *bookNodes = [doc nodesForXPath:bookStr error:&error];
                
                // get data
                bookSettings.title   = [self getNodeTextWithXPath:[bookStr stringByAppendingString:@"/title"] andXMLDoc:doc];
                bookSettings.rating  = [[self getNodeTextWithXPath:[bookStr stringByAppendingString:@"/rate"] andXMLDoc:doc] intValue];
                bookSettings.size    = [[self getNodeTextWithXPath:[bookStr stringByAppendingString:@"/size"] andXMLDoc:doc] intValue];
                bookSettings.cost    = [[self getNodeTextWithXPath:[bookStr stringByAppendingString:@"/price"] andXMLDoc:doc] floatValue];
                bookSettings.lengthTime  = [[self getNodeTextWithXPath:[bookStr stringByAppendingString:@"/length"] andXMLDoc:doc] intValue];
                bookSettings.description = [self getNodeTextWithXPath:[bookStr stringByAppendingString:@"/description"] andXMLDoc:doc];
                // prepare date formatter
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                [df setDateFormat:@"yyyy'-'MM'-'dd HH:mm"];
                bookSettings.updateDate  = [df dateFromString:[self getNodeTextWithXPath:[bookStr stringByAppendingString:@"/release"] andXMLDoc:doc]];
                [df setDateFormat:@"yyyy'-'MM'-'dd HH:mm:ss"];
                bookSettings.releaseDate = [df dateFromString:updateDate];
                
                // get authors
                NSString *authorsStr = [NSString stringWithFormat:@"//abook[@id=%@]/authors/name", bid ];
                NSArray *authorsNodes = [doc nodesForXPath:authorsStr error:&err];
                for(DDXMLNode *authorNode in authorsNodes)
                {
                    NSArray *curAuthorIds = [authorNode nodesForXPath:@"./@id" error:&err];
                    NSInteger aid = [[[curAuthorIds objectAtIndex:0] stringValue] intValue];
                    [a_authors insertObject:[[AuthorSettings alloc] initWithId:aid
                                                                       andName:[authorNode stringValue]
                                                                     andBookId:[bid intValue]] atIndex:a_authors.count];
                }
                
                // get readers
                NSString *readersStr = [NSString stringWithFormat:@"//abook[@id=%@]/readers/name", bid ];
                NSArray *readersNodes = [doc nodesForXPath:readersStr error:&err];
                for(DDXMLNode *readerNode in readersNodes)
                {
                    NSArray *curreaderIds = [readerNode nodesForXPath:@"./@id" error:&err];
                    NSInteger aid = [[[curreaderIds objectAtIndex:0] stringValue] intValue];
                    [a_readers insertObject:[[ReaderSettings alloc] initWithId:aid
                                                                       andName:[readerNode stringValue]
                                                                     andBookId:[bid intValue]] atIndex:a_readers.count];
                }
                
                // get publishers
                NSString *publishersStr = [NSString stringWithFormat:@"//abook[@id=%@]/publishers/name", bid ];
                NSArray *publishersNodes = [doc nodesForXPath:publishersStr error:&err];
                for(DDXMLNode *publisherNode in publishersNodes)
                {
                    NSArray *curpublisherIds = [publisherNode nodesForXPath:@"./@id" error:&err];
                    NSInteger aid = [[[curpublisherIds objectAtIndex:0] stringValue] intValue];
                    [a_publishers insertObject:[[PublisherSettings alloc] initWithId:aid
                                                                             andName:[publisherNode stringValue]
                                                                           andBookId:[bid intValue]] atIndex:a_publishers.count];
                }
                
                // get genres
                NSString *genresStr = [NSString stringWithFormat:@"//abook[@id=%@]/genres/name", bid ];
                NSArray *genresNodes = [doc nodesForXPath:genresStr error:&err];
                for(DDXMLNode *genreNode in genresNodes)
                {
                    NSArray *curgenreIds = [genreNode nodesForXPath:@"./@id" error:&err];
                    NSInteger aid = [[[curgenreIds objectAtIndex:0] stringValue] intValue];
                    [a_genres insertObject:[[GenreSettings alloc] initWithId:aid
                                                                 andParentId:-1
                                                                     andName:[genreNode stringValue]
                                                                   andBookId:[bid intValue]] atIndex:a_genres.count];
                }
                
                // get subgenres
                NSString *subgenresStr = [NSString stringWithFormat:@"//abook[@id=%@]/subgenres/name", bid ];
                NSArray *subgenresNodes = [doc nodesForXPath:subgenresStr error:&err];
                for(DDXMLNode *subgenreNode in subgenresNodes)
                {
                    NSArray *cursubgenreIds = [subgenreNode nodesForXPath:@"./@id" error:&err];
                    NSInteger aid = [[[cursubgenreIds objectAtIndex:0] stringValue] intValue];
                    NSArray *genreIds = [subgenreNode nodesForXPath:@"./@genreid" error:&err];
                    NSInteger gaid = [[[genreIds objectAtIndex:0] stringValue] intValue];
                    [a_genres insertObject:[[GenreSettings alloc] initWithId:aid
                                                                 andParentId:gaid
                                                                     andName:[subgenreNode stringValue]
                                                                   andBookId:[bid intValue]] atIndex:a_genres.count];
                }
                
                // insert book
                [books insertObject:bookSettings atIndex:books.count];
            }
            
            // now process books to remove
            NSArray *booksToRemoveIds = [doc nodesForXPath:@"//abook/@id[ancestor::remove]" error:&err];
            
            returnCode = sqlite3_exec(db, "BEGIN", 0, 0, 0);
            [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"db cannot begin: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
            
            for(DDXMLNode *bidNode in booksToRemoveIds) {
                // init variables
                NSString *bid = [bidNode stringValue];
                Book *bookSettings = [[Book alloc] init];
                bookSettings.abookId = [bid intValue];
                // delete from t_abooks
                const char *query = [[NSString stringWithFormat:@"DELETE FROM t_abooks WHERE abook_id = %@", bid] UTF8String];
                
                
                returnCode =
                sqlite3_prepare_v2(db,
                                   query, strlen(query),
                                   &statement, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                
                returnCode  = sqlite3_step(statement);
                [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"error done: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                returnCode = sqlite3_finalize(statement);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"db error cannot finalize: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
            }
            
            
            //            // rest of function...
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ntf_onStartLoadCatalog" object:nil];
            
            NSLog(@"Book to Load - %d", books.count);
            if (books.count > 0)
            {
                if (books.count == 0)
                {
                    NSLog(@"No books!");
                    //return ;
                }
                char *query = "INSERT OR REPLACE INTO t_abooks (rate, title, summary, price, length, size, release_date, update_date, export, listen, bought, free, title_lower, free_part_number, free_part_downloaded_date, title_in_english, in_rent_red, last_opened, is_recommended, readed_percent, isFreePartDownloaded, selectedChapter, isLoadFromHistory, freePartCount, abook_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                sqlite3_stmt *Stmt;
                
                
                
                
                NSString *freeDate = @"", *lastOpened;
                
                returnCode = sqlite3_prepare_v2(db, query, -1, &Stmt, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"db error prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                [formatter setDateFormat:@"yyyy'-'MM'-'dd HH:mm:ss"];
                [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Moscow"]];
                
                for (Book *book in books)
                {
                    //NSLog(@"Load book : %d", book.abookId);
                    NSString *releaseDate = [formatter stringFromDate:book.releaseDate];
                    updateDate  = [formatter stringFromDate:book.updateDate];
                    lastOpened  = [formatter stringFromDate:book.lastOpened];
                    book.isExport = book.isTransparent;
                    
                    sqlite3_bind_int(Stmt,    1, book.rating);
                    sqlite3_bind_text(Stmt,   2, [book.title UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(Stmt,   3, [book.description UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_double(Stmt, 4, book.cost);
                    sqlite3_bind_int(Stmt,    5, book.lengthTime);
                    sqlite3_bind_int(Stmt,    6, book.size);
                    sqlite3_bind_text(Stmt,   7, [releaseDate UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(Stmt,   8, [updateDate UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(Stmt,    9, book.isExport);
                    sqlite3_bind_int(Stmt,    10, book.listen);
                    sqlite3_bind_int(Stmt,    11, book.isBought ? 1 : 0);
                    sqlite3_bind_int(Stmt,    12, book.inRentRed || book.inRentGreen ? 1 : 0);
                    sqlite3_bind_text(Stmt,   13, [[book.title lowercaseString] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(Stmt,    14, book.freePartNumber);
                    sqlite3_bind_text(Stmt,   15, [freeDate UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(Stmt,    16, [self firstLetterInEnglish:book.title] ? 1 : 0);
                    sqlite3_bind_int(Stmt,    17, book.inRentRed ? 1 : 0);
                    sqlite3_bind_text(Stmt,   18, [lastOpened UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(Stmt,    19, book.isRecommended ? 1 : 0);
                    sqlite3_bind_double(Stmt, 20, book.readedPercent);
                    sqlite3_bind_int(Stmt,    21, book.isFreePartBeginDownload);
                    sqlite3_bind_int(Stmt,    22, book.selectedChapter);
                    sqlite3_bind_int(Stmt,    23, book.isLoadFromHistory);
                    sqlite3_bind_int(Stmt,    24, book.freePartCount);
                    
                    sqlite3_bind_int(Stmt,    25, book.abookId);
                    
                    int returnCode = sqlite3_step(Stmt);
                    
                    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"db error step: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                    //sqlite3_clear_bindings(Stmt);
                    returnCode = sqlite3_reset(Stmt);
                    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"db error reset: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                }
                sqlite3_finalize(Stmt);
                
            }
            
            NSLog(@"Authors to Load - %d", a_authors.count);
            if (a_authors.count > 0)
            {
                
                sqlite3_stmt *Stmt;
                
                // authors one
                NSString *query = @"INSERT OR REPLACE INTO t_authors (author_id, name, name_lower) VALUES (?, ?, ?)";
                
                
                returnCode  = sqlite3_prepare_v2(db, [query UTF8String], -1, &Stmt, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr cannot prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                for (AuthorSettings *author in a_authors)
                {
                    
                    //NSLog(@"Load book : %d", author.abookId);
                    sqlite3_bind_int(Stmt, 1, author.authorId);
                    sqlite3_bind_text(Stmt, 2, [author.authorName UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(Stmt, 3, [[author.authorName lowercaseString] UTF8String], -1, SQLITE_TRANSIENT);
                    
                    returnCode = sqlite3_step(Stmt);
                    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"dberror cannot step: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                    returnCode = sqlite3_reset(Stmt);
                    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberror cannot reset: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                }
                
                returnCode = sqlite3_finalize(Stmt);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr cannot finalize: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                // authors two
                query = @"INSERT INTO t_abooks_authors (abook_id, author_id) VALUES (?, ?)";
                
                
                returnCode = sqlite3_prepare_v2(db, [query UTF8String], -1, &Stmt, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"unable to prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                for (AuthorSettings *author in a_authors)
                {
                    
                    //NSLog(@"Load book : %d", author.abookId);
                    
                    sqlite3_bind_int(Stmt, 1, author.abookId);
                    sqlite3_bind_int(Stmt, 2, author.authorId);
                    
                    returnCode = sqlite3_step(Stmt);
                    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"dberr unable to step: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                    
                    returnCode = sqlite3_reset(Stmt);
                    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr unable to reset: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                }
                
                returnCode = sqlite3_finalize(Stmt);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr unable to finalize: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
            }
            NSLog(@"Readers to Load - %d", a_readers.count);
            if (a_readers.count > 0)
            {
                // readers one
                NSString *query = @"INSERT OR REPLACE INTO t_readers (reader_id, name) VALUES (?, ?)";
                sqlite3_stmt *Stmt;
                
                
                returnCode = sqlite3_prepare_v2(db, [query UTF8String], -1, &Stmt, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr cannot prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                for (ReaderSettings *reader in a_readers)
                {
                    
                    //NSLog(@"Load reader : %d", reader.readerId);
                    
                    sqlite3_bind_int(Stmt, 1, reader.readerId);
                    sqlite3_bind_text(Stmt, 2, [reader.readerName UTF8String], -1, SQLITE_TRANSIENT);
                    
                    returnCode = sqlite3_step(Stmt);
                    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"dberr cannot step: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                    returnCode = sqlite3_reset(Stmt);
                    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr cannot reset: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                }
                returnCode = sqlite3_finalize(Stmt);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr finalize: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                // reders two
                query = @"INSERT OR REPLACE INTO t_abooks_readers (abook_id, reader_id) VALUES (?, ?)";
                
                
                returnCode = sqlite3_prepare_v2(db, [query UTF8String], -1, &Stmt, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberror cannot prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                for (ReaderSettings *reader in a_readers)
                {
                    
                    //NSLog(@"Load reader : %d", reader.readerId);
                    
                    sqlite3_bind_int(Stmt, 1, reader.abookId);
                    sqlite3_bind_int(Stmt, 2, reader.readerId);
                    
                    returnCode = sqlite3_step(Stmt);
                    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"dberror unable to step: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                    
                    returnCode = sqlite3_reset(Stmt);
                    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberror unable to reset: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                }
                
                returnCode = sqlite3_finalize(Stmt);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr unable to finalize:: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
            }
            
            //******************* GENRES **************************
            NSLog(@"Genres to Load - %d", a_genres.count);
            if (a_genres.count > 0)
            {
                int returnCode;
                query = "INSERT OR REPLACE INTO t_genres (genre_id, genre_parent_id, name) VALUES (?, ?, ?)";
                sqlite3_stmt *Stmt;
                
                returnCode = sqlite3_prepare_v2(db, query, -1, &Stmt, NULL);
                [self assertNoError:returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Error while prepare GENRES statement. '%s'", sqlite3_errmsg(db)]];
                
                
                for (GenreSettings *genre in a_genres)
                {
                    
                    //NSLog(@"Load genre : %d", genre.genreId);
                    
                    sqlite3_bind_int(Stmt, 1, genre.genreId);
                    sqlite3_bind_int(Stmt, 2, genre.genreParentId);
                    sqlite3_bind_text(Stmt, 3, [genre.genreName UTF8String], -1, SQLITE_TRANSIENT);
                    
                    returnCode = sqlite3_step(Stmt);
                    [self assertNoError:returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"Error while step GENRES statement. '%s'", sqlite3_errmsg(db)]];
                    
                    
                    returnCode = sqlite3_reset(Stmt);
                    [self assertNoError:returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Error while reset GENRES statement. '%s'", sqlite3_errmsg(db)]];
                }
                returnCode = sqlite3_finalize(Stmt);
                [self assertNoError:returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Error while finalize GENRES statement. '%s'", sqlite3_errmsg(db)]];
                
                NSString *query = @"INSERT INTO t_abooks_genres (abook_id, genre_id) VALUES (?, ?)";
                
                returnCode = sqlite3_prepare_v2(db, [query UTF8String], -1, &Stmt, NULL);
                [self assertNoError:returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Error while prepare abook GENRES statement. '%s'", sqlite3_errmsg(db)]];
                
                for (GenreSettings *genre in a_genres)
                {
                    
                    //NSLog(@"Load genre : %d", genre.genreId);
                    
                    sqlite3_bind_int(Stmt, 1, genre.abookId);
                    sqlite3_bind_int(Stmt, 2, genre.genreId);
                    
                    returnCode = sqlite3_step(Stmt);
                    [self assertNoError:returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"Error while step abook GENRES statement. '%s'", sqlite3_errmsg(db)]];
                    
                    returnCode = sqlite3_reset(Stmt);
                    [self assertNoError:returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Error while reset abook GENRES statement. '%s'", sqlite3_errmsg(db)]];
                }
                
                returnCode = sqlite3_finalize(Stmt);
                [self assertNoError:returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Error while finalize abook GENRES statement. '%s'", sqlite3_errmsg(db)]];
                
            }
            
            //***************** PUBLISHERS *************************
            NSLog(@"Publishers to Load - %d", a_publishers.count);
            if (a_publishers.count > 0)
            {
                // publishers one
                NSString *query = @"INSERT OR REPLACE INTO t_publishers (publisher_id, name) VALUES (?, ?)";
                sqlite3_stmt *Stmt;
                
                
                returnCode = sqlite3_prepare_v2(db, [query UTF8String], -1, &Stmt, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr prepare: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                for (PublisherSettings *publisher in a_publishers)
                {
                    
                    //NSLog(@"Load publisher : %d", publisher.abookId);
                    
                    sqlite3_bind_int(Stmt, 1, publisher.publisherId);
                    sqlite3_bind_text(Stmt, 2, [publisher.publisherName UTF8String], -1, SQLITE_TRANSIENT);
                    
                    returnCode = sqlite3_step(Stmt);
                    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"dberr unable to step: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                    
                    returnCode = sqlite3_reset(Stmt);
                    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr unable to reset: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                }
                returnCode = sqlite3_finalize(Stmt);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr unable to finalize: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                // publishers two
                query = @"INSERT INTO t_abooks_publishers (abook_id, publisher_id) VALUES (?, ?)";
                
                
                returnCode = sqlite3_prepare_v2(db, [query UTF8String], -1, &Stmt, NULL);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr unable to prepare abook_publishers: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
                for (PublisherSettings *publisher in a_publishers)
                {
                    
                    //NSLog(@"Load publisher : %d", publisher.abookId);
                    
                    sqlite3_bind_int(Stmt, 1, publisher.abookId);
                    sqlite3_bind_int(Stmt, 2, publisher.publisherId);
                    
                    returnCode = sqlite3_step(Stmt);
                    [gs assertNoError: returnCode == SQLITE_DONE withMsg:[NSString stringWithFormat:@"db errr cannot step abook_publishers: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                    
                    returnCode = sqlite3_reset(Stmt);
                    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr cannot reset abook_publishers: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                }
                
                returnCode = sqlite3_finalize(Stmt);
                [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr cannot finalize abook_publishers: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
                
            }
            
            NSLog(@"END LOAD...............................");
            returnCode = sqlite3_exec(db, "COMMIT", 0, 0, 0);
            [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"db error commit: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
            
            // DB CLOSE
            returnCode = sqlite3_close(db);
            [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr close: %s, func: %s", sqlite3_errmsg(db), __func__ ]];
            
            //            [AudiobookAppDelegate delegate].isDBLocked = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ntf_onRefreshCatalog" object:nil];
            //                [NSThread detachNewThreadSelector:@selector(launchThread:)
            //                                         toTarget:self
            //                                       withObject:nil];
            //[self performSelectorInBackground: @selector(update) withObject:nil];
        }
        //        else
        {
            //            [[NSNotificationCenter defaultCenter] postNotificationName:@"ntf_onNoNovelty" object:nil];
            //            [[AudiobookAppDelegate delegate] performSelector:@selector(showRecoveryMsg) withObject:nil afterDelay:30];
            //
        }
        //    }
        //    self.dxml = nil;
        //    [conData setLength:0];
        //    self.conData = nil;
    }// @synchronized
    
    return true;
}

+ (BOOL)firstLetterInEnglish:(NSString *)word
{
    [[word uppercaseString] characterAtIndex:0] ;
    if(!word)
        return YES;
    if(word.length == 0)
        return YES;
    
    char c = [word characterAtIndex:0];
    return ((int)c >= (int)'a' && (int)c <= 'z') || ((int)c >= 'A' && (int)c <= (int)'Z');
}

-(void)downqInsert:(NSString*)item atIndex:(int)idx
{
    @synchronized(self){
        
    }
}

-(void)downqRemove:(NSString*)item atIndex:(int)idx
{
    @synchronized(self)
    {
        
    }
}

-(int)bidFromChapterIdentity:(NSString*)ci
{
    @synchronized(self)
    {
    NSArray *array = [ci componentsSeparatedByString:@":"]; // format bookid:chapternum
    return [[array objectAtIndex:0] intValue];
    }
}

-(NSString*)chidFromChapterIdentity:(NSString*)ci
{
    @synchronized(self)
    {
    NSArray *array = [ci componentsSeparatedByString:@":"]; // format bookid:chapternum
    return [array objectAtIndex:1];
    }
}

-(void)playerButtonClick:(id)sender
{
//    NSLog(@"++ player button click");
    PlayerViewController* playerView = [[PlayerViewController alloc] initWithBook:0];
    [self.navigationController pushViewController:playerView animated:YES];
}

//#include <netinet/in.h>
#include <arpa/inet.h>
+ (gs *)sharedInstance
{
    static gs *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[gs alloc] init];
        // Do any other initialisation stuff here
        
        //****************** init requests queue
        CGRect	rectFrame = CGRectMake(220.0, 440.0, 100, 20);
		// create a UIButton (UIButtonTypeRoundedRect)
		sharedInstance.playerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		sharedInstance.playerButton.frame = rectFrame;
		[sharedInstance.playerButton setTitle:@"Плеер" forState:UIControlStateNormal];
		sharedInstance.playerButton.backgroundColor = [UIColor clearColor];		
		sharedInstance.playerButton.tag = 2;
        [sharedInstance.playerButton addTarget:sharedInstance action:@selector(playerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [sharedInstance.playerButton setHidden:YES];
        //[sharedInstance.navigationController.view addSubview:sharedInstance.playerButton];

        //theView.myController = self;
        
        
        
        //******************** save database path for future use
        // find database file path
        NSString *documentsDir = [[NSFileManager defaultManager] publicDataPath];
        NSString *dbWorkingCopyPath = [documentsDir stringByAppendingPathComponent:@"database.db"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:dbWorkingCopyPath])
        {
            NSString *dbSourcePath = [[NSBundle mainBundle] pathForResource:@"database" ofType:@"db"];
            [[NSFileManager defaultManager] copyItemAtPath:dbSourcePath toPath:dbWorkingCopyPath error:nil];
        }
        databaseName = dbWorkingCopyPath;
        
        
        //*************** monitor network status
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkNetworkStatus:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
        NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
        NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
        NSLog(@"Server Host : %@, version : %@, build : %@", AppConnectionHost, version, build);
        
        //hostReachable = [Reachability reachabilityWithHostName:AppConnectionHost];
        struct sockaddr_in sin;
        bzero(&sin, sizeof(sin));
        sin.sin_len = sizeof(sin);
        sin.sin_family = AF_INET;
        inet_aton([[@"http://" stringByAppendingString: AppConnectionHost] UTF8String], &sin.sin_addr);
        hostReachable = [Reachability reachabilityWithAddress:&sin];
        [hostReachable startNotifier];
        [self checkNetworkStatus:nil];
        
        
        // TODO: switch on update timer
        //[NSTimer scheduledTimerWithTimeInterval:5.0 // do not need to save timer, passed to callback function as the only argument
//                                         target:self
//                                       selector:@selector(updateCatalog:)
//                                       userInfo:nil
//                                        repeats:YES];
    });
    
    
    //...
    return sharedInstance;
}

+ (NSString*)md5:(NSString*)object
{
    const char *object_str = [object UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
	
    CC_MD5(object_str, strlen(object_str), result);
	
    NSMutableString *hash = [NSMutableString string];
	
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
	{
        [hash appendFormat:@"%02X", result[i]];
	}
	
    return [hash lowercaseString];
}

//+(NSArray*)srvArrForUrl:(NSString*)strWithFormat args:(NSArray*)arguments xpath:(NSString*)xp message:(NSString*)msg
+(NSArray*)srvArrForUrl:(NSString*)strUrl xpath:(NSString*)xp message:(NSString*)msg
{
    @synchronized(gss())
    {
        // first format string url
//        NSArray *fixedArguments = arguments;        
//        NSRange range = NSMakeRange(0, [fixedArguments count]);        
//        NSMutableData* data = [NSMutableData dataWithLength: sizeof(id) * [fixedArguments count]];        
//        [fixedArguments getObjects: (__unsafe_unretained id *)data.mutableBytes range:range];        
//        NSString* content = [[NSString alloc] initWithFormat: strWithFormat  arguments: data.mutableBytes];
//        
//        NSLog(@"%@", content);
        
        // create url and make request
        NSError* error;
        NSURL* url = [NSURL URLWithString:strUrl];
        NSString* response = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        [gss() handleError:error];
        DDXMLDocument* doc = [[DDXMLDocument alloc] initWithXMLString:response options:0 error:&error];
        [gss() handleError:error];
        NSAssert1(doc, @"**err: cannot create ddxmldoc: %@", msg);
        NSArray* arr = [gss() arrayForDoc:doc xpath:xp];
        NSAssert1([arr count], @"**err: %@", msg);
        return [arr copy];
    }
}

@end

gs* gss()
{
    return [gs sharedInstance];
}