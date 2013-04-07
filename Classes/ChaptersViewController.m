//
//  ChaptersViewController.m
//  audiobook
//
//  Created by User on 2/4/13.
//
//

#import "ChaptersViewController.h"
#import "gs.h"
#import "ASIHTTPRequest.h"
#import "DDXMLDocument.h"
#import "PlayerViewController.h"
#import "PlayerViewController.h"
#import "Book.h"
#import "ChapterCellViewController.h"

//@interface UITableViewCell (FindUIViewController)
//- (UIViewController *) firstAvailableUIViewController;
//- (id) traverseResponderChainForUIViewController;
//@end
//
//@implementation UITableViewCell (FindUIViewController)
//- (UIViewController *) firstAvailableUIViewController {
//    // convenience function for casting and to "mask" the recursive function
//    return (UIViewController *)[self traverseResponderChainForUIViewController];
//}
//
//- (id) traverseResponderChainForUIViewController {
//    id nextResponder = [self nextResponder];
//    if ([nextResponder isKindOfClass:[ChapterCellViewController class]]) {
//        return nextResponder;
//    }
//    else if ([nextResponder isKindOfClass:[UITableViewCell class]]) {
//        return [nextResponder traverseResponderChainForUIViewController];
//    }
//    else {
//        return nil;
//    }
//}
//@end

@interface ChaptersViewController ()

@end

static NSString* BTN_READY = @"Готово";
static NSString* BTN_DOWNLOAD = @"Скачать";
static NSString* BTN_CANCEL = @"отменить";


@interface Chapter : NSObject
@property (nonatomic, strong) NSString* cId;
@property (nonatomic, strong) NSString* name;
@end
@implementation Chapter

@synthesize cId = _id, name = _name;
-(void) dealloc
{
    self.cId = self.name = nil;
}
@end

@implementation ChaptersViewController
//@synthesize bookId;
- (void)requestBookMeta:(NSString*)bid
{
     NSString *devid = [[UIDevice currentDevice] uniqueIdentifier];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/bookmeta.php?bid=%@&dev=%@", BookHost, bid, devid]];
    //NSURL *url = [NSURL URLWithString:@"http://dl.dropbox.com/u/4115029/bookMeta.xml"];
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
//    [request setDidFinishSelector:@selector(requestDone:)];
//    [request setDidFailSelector:@selector(requestWentWrong:)];
    //[[GlobalSingleton sharedInstance].queue addOperation:request]; //queue is an NSOperationQueue
    [request startAsynchronous];
    
    
    // Предупредить пользователя о загрузке оглавления
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Загрузка"
                                                        message:@"Загрузка оглавления\nпожалуйста, подождите..."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
    //[alertView show];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [alertView dismissWithClickedButtonIndex:-1 animated:YES];
    });
    alertView = nil;

}

- (void) updateMeta:(NSString*) fileContent
{
    // create xml from string
    NSError *error;
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:fileContent options:0 error:&error];
    [[gs sharedInstance] handleError:error];
    
    NSArray *items=[doc nodesForXPath:@"/abooks/abook/content/track" error:&error];
    
    [chapters removeAllObjects];
    for (DDXMLElement *item in items) {
        //NSLog(@"++item contents: %s", [[item XMLString] UTF8String]);
        doc = [doc initWithXMLString:[item XMLString] options:0 error:&error];
        NSString *cId = [[[doc nodesForXPath:@"//@number" error:&error] objectAtIndex:0] stringValue];
        NSString *cName = [[[doc nodesForXPath:@"//name" error:&error] objectAtIndex:0] stringValue];
        Chapter* c = [[Chapter alloc] init];
        c.name = cName;
        c.cId = cId;
        [chapters addObject:c];
        
    }
    
    //    for (Chapter *c in chapters){
    //        NSLog(@"chapter's data: %@, %@", c.cId, c.name);
    //    }
    
    
    //NSArray *sortedArray;
    NSArray* arr =  [chapters sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(Chapter*)a cId];
        NSString *second = [(Chapter*)b cId];
        return [first localizedCompare:second];
    }];
    [chapters removeAllObjects];
    [chapters addObjectsFromArray:arr];
    
    // reload table view
    [(UITableView*)[self view] reloadData];
}

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    for (id key in responseHeaders) {
        NSLog(@"key: %@, value: %@ \n", key, [responseHeaders objectForKey:key]);
    }
    
    NSString* isbought = [NSString stringWithFormat:@"<r><bt>%@</bt></r>", [responseHeaders valueForKey:@"Bought" ]];
//    if ([isbought isEqualToString:@"yes"]) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileName = [gss() pathForBuy:[StaticPlayer sharedInstance].bookID];
    NSData *data = [isbought dataUsingEncoding:NSUTF8StringEncoding];
    BOOL fileCreationSuccess =
    [fileManager createFileAtPath:fileName contents:data attributes:nil];
    NSAssert1(fileCreationSuccess, @"**err: Failed to create the buy file: %s", __func__);
    [StaticPlayer checkBuyBook];


//    }
    // [[NSFileManager defaultManager] removeItemAtPath:currentTrack.audioFilePath error:nil];
    //if(![[NSFileManager defaultManager] fileExistsAtPath:currentTrack.audioFilePath])
}

- (void)requestFinished:(ASIHTTPRequest *)request
{    
    NSString *response = [request responseString];
    
    int res = [[gs sharedInstance] handleSrvError:response];
    if (res) { // must be 0 - no error
        return;
    }
    
    // First write meta to disk
    NSFileManager *fm = [NSFileManager defaultManager];
    // save to home directory
    //    NSString *pathToBookDirectory =[ NSHomeDirectory() stringByAppendingPathComponent: [NSString stringWithFormat:@"tmp/books/%d/BookMeta.xml", bookId ]];
    NSString *pathToBookDirectory =[ [[gs sharedInstance] dirsForBook:[StaticPlayer sharedInstance].bookID] stringByAppendingPathComponent:@"bookMeta.xml"];
    [NSURL fileURLWithPath:pathToBookDirectory ];
    bool fileCreationSuccess = [ fm createFileAtPath:pathToBookDirectory contents:[request responseData ]  attributes:nil];
    if(fileCreationSuccess == NO){ NSLog(@"Failed to create the BookMeta file"); }
    
    //NSLog(@"++response %@", response);
    [self updateMeta:response];
    
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    
    [[gs sharedInstance] handleError:error];
    
    if(error)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сетевая ошибка"
                                                        message:@"ошибка получения оглавления"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

//
//- (id)initWithBook:(int)bid
//{
//    self = [super init];
//    if (self) {
//        // Custom initialization
//        bookId = bid;
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
//    bookId = [PlayerViewController myGetBookId];
    chapters = [[NSMutableArray alloc] init];
    
    NSString* fMetaPath = [NSString stringWithFormat:@"%@/%@",[[gs sharedInstance] dirsForBook:[StaticPlayer sharedInstance].bookID ],  @"bookMeta.xml"];
    // start request to get chapters, handle answer in handlers
    if(![[NSFileManager defaultManager]  fileExistsAtPath:fMetaPath ])
    {
        [self requestBookMeta:[StaticPlayer sharedInstance].bookID];
    }
    else
    {
        NSError *error;
        NSString* str = [NSString stringWithContentsOfFile:fMetaPath encoding:NSUTF8StringEncoding error:&error];
        [[gs sharedInstance] handleError:error];
        
        [self updateMeta:str];
    }

 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // reload table view
    //[(UITableView*)[self view] reloadData];
    
}

-(void)scrollToLastSelection
{    
    // scroll down to previosly selected row
    if (rowIdx>=0 && [chapters count]>=rowIdx) {
        //end of loading
        //for example [activityIndicator stopAnimating];
        UITableView* thisView =  (UITableView*)[self view];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIdx inSection:0];
        @try {
            [thisView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
            [thisView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        @catch (NSException *exception) {
            NSLog(@"**err:cannot scroll table: %@", [exception description]);
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [chapters count];
}

-(void)downClick:(UIButton*)sender
{    
    NSLog(@"++btn state: %@", [sender titleForState:UIControlStateApplication]);
    
    Chapter* c = (Chapter*) [chapters objectAtIndex:[[sender titleForState:UIControlStateApplication]intValue]];
    NSString* chapterIdentity = [NSString stringWithFormat:@"%@:%@", [StaticPlayer sharedInstance].bookID, c.cId ];
    NSString* btnState = [sender titleForState:UIControlStateNormal];
    if ([btnState isEqualToString:BTN_CANCEL]) {
        [[StaticPlayer sharedInstance] removeDownqObject:chapterIdentity];
        [sender setTitle:BTN_DOWNLOAD forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"download.png"]  forState:UIControlStateNormal];
    }
    else if([btnState isEqualToString:BTN_DOWNLOAD])
    {
        if (![gs nfInternetAvailable:nil])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сообщение"
                                                            message:@"Для загрузки главы нужен интернет. Проверьте соединение."
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
            return;
        }

        [PlayerViewController appendChapterIdentityForDownloading:chapterIdentity];
        [sender setTitle:BTN_CANCEL forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"stop.png"]  forState:UIControlStateNormal];
    }
    // else BTN_READY - nothing to do
    
}

-(UITableViewCell*)findCellByChapter:(NSString*)chid
{
    int i = 0;
    for (Chapter* c in chapters) {
        if ([c.cId isEqualToString:chid])
            break;
        ++i;
    }
    UITableViewCell* cell =(UITableViewCell*) [self.view viewWithTag:1000+i ];
    return cell;
}

-(void)setProgressForChapter:(NSString*)chid value:(float)val
{
    UITableViewCell* cell = [self findCellByChapter:chid];
    UIProgressView* progress = (UIProgressView*) [cell viewWithTag:3];
    if (val < 1.0) {
        //[progress setProgress:val animated:YES];
        progress.progress = val;
    }
    else {
        progress.hidden = YES;
    }
}

-(void)setBtnTitleForChapter:(NSString*)chid title:(NSString*)title
{
    UITableViewCell* cell = [self findCellByChapter:chid];
    UIButton* btn = (UIButton*)[cell viewWithTag:4];
    
    // manage button
    if([title isEqualToString:BTN_READY])
        btn.hidden = YES;
    else
        [btn setTitle:title forState:UIControlStateNormal];
    
}

-(void)chapterFinishDownload:(NSString*)chapterIdentity
{
    NSString* bid = [gss() bidFromChapterIdentity:chapterIdentity];
    
    if (![bid isEqualToString: [StaticPlayer sharedInstance].bookID]) {
        NSLog(@"++ Финиш загрузки для другой книги!");
        return;
    }
    
    NSString* chid = [gss() chidFromChapterIdentity:chapterIdentity];
    
    float progress = [PlayerViewController calcDownProgressForBook:[StaticPlayer sharedInstance].bookID chapter:chid];
    [self setProgressForChapter:chid value: progress];
    
    if (progress < 1.0) {
        [self setBtnTitleForChapter:chid title:BTN_DOWNLOAD];
        
    }
    else {
        [self setBtnTitleForChapter:chid title:BTN_READY];
    }
}

-(void) updateProgressForChapterIdentity:(NSString*)chapterIdentity value:(float)val
{
    NSString* bid = [gss() bidFromChapterIdentity:chapterIdentity];
    
    if (![bid isEqualToString: [StaticPlayer sharedInstance].bookID]) {
        NSLog(@"++ Отображается оглавление другой книги!");
        return;
    }
    
    NSString* chid = [gss() chidFromChapterIdentity:chapterIdentity];
    
    [self setProgressForChapter:chid value: val];    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"myCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        ChapterCellViewController* c = [[ChapterCellViewController alloc] init];
        cell = (UITableViewCell *) [c view];
    }
    
    cell.tag = 1000+indexPath.row;
    // Configure the cell...
    Chapter *lc = [chapters objectAtIndex:indexPath.row];
    UILabel* lblSmall = (UILabel*)[cell viewWithTag:2];
    lblSmall.text = lc.name;
    UIProgressView* progress = (UIProgressView*) [cell viewWithTag:3];
    progress.progress = [PlayerViewController calcDownProgressForBook:[StaticPlayer sharedInstance].bookID chapter:lc.cId];
    UIButton* btn = (UIButton*)[cell viewWithTag:4];
    
    if (progress.progress < 1.0) {
        if ([[StaticPlayer sharedInstance] downqContainsObject:[NSString stringWithFormat:@"%@:%@", [StaticPlayer sharedInstance].bookID, lc.cId]]) {
            [btn setTitle:BTN_CANCEL forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"stop.png"]  forState:UIControlStateNormal];
  
        }
        else{
            [btn setTitle:BTN_DOWNLOAD forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"download.png"]  forState:UIControlStateNormal];
        }

        btn.hidden = NO;
        progress.hidden = NO;
    }
    else {
        [btn setTitle:BTN_READY forState:UIControlStateNormal];
        btn.hidden = YES;
        progress.hidden = YES;
    }
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer sharedInstance].bookID]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[@number='%@']/file/length", [StaticPlayer sharedInstance].bookID, lc.cId]];
    
    if ([arr count] != 1) {
        NSLog(@"**err: invalid length for book: %@, chpater: %@", [StaticPlayer sharedInstance].bookID, lc.cId);
    }
    else
    {
        int fsz = [[arr objectAtIndex:0] intValue];
        NSString* timeString = [NSString stringWithFormat:@"%d:%02d", (NSInteger)(fsz / 60.0),
         (NSInteger)fsz % 60];
        UILabel* lblBig = (UILabel*)[cell viewWithTag:1];
        lblBig.text = timeString;
    }
    
    
    [btn setTitle:[NSString stringWithFormat:@"%d",indexPath.row ] forState:UIControlStateApplication];
    [btn addTarget:self action:@selector(downClick:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
    
    
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
//    }
//    
//    // Configure the cell...
//    //NSLog(@"++ the index row number %d", indexPath.row);
//    Chapter *lc = [chapters objectAtIndex:indexPath.row];
//    cell.textLabel.text = lc.cId;
//    cell.detailTextLabel.text = lc.name;
//    
//    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate
static int rowIdx = 0;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    // get chapter id from index and find that chapter id in bookMeta.xml
    rowIdx = indexPath.row;
    int cc = [chapters count];
    // create xml from string
//    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer sharedInstance].bookID]];
//    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[%d]/@number", [StaticPlayer sharedInstance].bookID, rowIdx+1]];
//    if ([arr count] != 1) {
        if (rowIdx>=cc) {
            NSLog(@"**err: index more then chapters count");
            --rowIdx; // leave at last position
            return;
        }
        else if(rowIdx<0)
        {
            NSLog(@"**err: index less then chapters count");
            rowIdx = 0; // set to first chapter
            return;
        }
        //return;
    //}
    //NSString* chid = [arr objectAtIndex:0];
    NSString* chid = [[chapters objectAtIndex:rowIdx] cId];
    
    if (!tableView) { // call from player to select previous/next chapter
        [(UITableView*)[self view] selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    }
    
    if (tableView) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        Chapter *lc = [chapters objectAtIndex:indexPath.row];
        float progress = [PlayerViewController calcDownProgressForBook:[StaticPlayer sharedInstance].bookID chapter:lc.cId];
        UIButton* btn = (UIButton*)[cell viewWithTag:4];
        
        if (progress < 100.0) {
            // set progress button to right state
            [self downClick:(UIButton*)btn];
        }
        
    }
    
    [PlayerViewController startChapter:chid];
    
//
//     PlayerFreeViewController *plConroller = [[PlayerFreeViewController alloc] initWithBook:bookId andChapter:chid];
//     // ...
//     // Pass the selected object to the new view controller.
//     [gss().navigationController pushViewController:plConroller animated:YES];    
}

-(void)first
{
    rowIdx=-1;
    [self next:nil];
}

- (IBAction)next:(UIBarButtonItem *)sender {
    [self tableView:nil didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:++rowIdx inSection:0]];
}

- (IBAction)prev:(UIBarButtonItem *)sender {
    [self tableView:nil didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:--rowIdx inSection:0]];
}
@end
