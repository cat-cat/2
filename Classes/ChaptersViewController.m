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
#import "PlayerFreeViewController.h"
#import "PlayerFreeViewController.h"
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
- (void)requestBookMeta:(int)bid
{
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/bookmeta.php?bid=%d", AppConnectionHost, bid]];
    //NSURL *url = [NSURL URLWithString:@"http://dl.dropbox.com/u/4115029/bookMeta.xml"];
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
//    [request setDidFinishSelector:@selector(requestDone:)];
//    [request setDidFailSelector:@selector(requestWentWrong:)];
    //[[GlobalSingleton sharedInstance].queue addOperation:request]; //queue is an NSOperationQueue
    [request startAsynchronous];
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
    
    
    // parse
    
    // save to chapters variable

    
    // reload table view
    [(UITableView*)[self view] reloadData];
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
    NSString *pathToBookDirectory =[ [[gs sharedInstance] dirsForBook:bookId] stringByAppendingPathComponent:@"bookMeta.xml"];
    [NSURL fileURLWithPath:pathToBookDirectory ];
    bool fileCreationSuccess = [ fm createFileAtPath:pathToBookDirectory contents:[request responseData ]  attributes:nil];
    if(fileCreationSuccess == NO){ NSLog(@"Failed to create the BookMeta file"); }
    
    //NSLog(@"++response %@", response);
    [self updateMeta:response];
    
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    
    //TODO:  show error with Alert
    [[gs sharedInstance] handleError:error];
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
    bookId = playerController.bookId;
    chapters = [[NSMutableArray alloc] init];
    
    NSString* fMetaPath = [NSString stringWithFormat:@"%@/%@",[[gs sharedInstance] dirsForBook:bookId ],  @"bookMeta.xml"];
    // start request to get chapters, handle answer in handlers
    if(![[NSFileManager defaultManager]  fileExistsAtPath:fMetaPath ])
    {
        [self requestBookMeta:bookId];
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
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [chapters count];
}

-(void)downClick:(UIButton*)sender
{
    Chapter* c = (Chapter*) [chapters objectAtIndex:[[sender titleForState:UIControlStateApplication]intValue]];
    NSString* chapterIdentity = [NSString stringWithFormat:@"%d:%@", bookId, c.cId ];
    [playerController appendChapterIdentityForDownloading:chapterIdentity];
    NSLog(@"++btn state: %@", [sender titleForState:UIControlStateApplication]);
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
    progress.progress = val;
}

-(void)setBtnTitleForChapter:(NSString*)chid title:(NSString*)title
{
    UITableViewCell* cell = [self findCellByChapter:chid];
    UIButton* btn = (UIButton*)[cell viewWithTag:4];
    [btn setTitle:@"Скачать" forState:UIControlStateNormal];
}

-(void)chapterFinishDownload:(NSString*)chapterIdentity
{
    int bid = [gss() bidFromChapterIdentity:chapterIdentity];
    
    if (bid != bookId) {
        NSLog(@"++ Отображается оглавление не той книги!");
        return;
    }
    
    NSString* chid = [gss() chidFromChapterIdentity:chapterIdentity];
    
    float progress = [playerController calcDownProgressForChapter:chid];
    [self setProgressForChapter:chid value: progress];
    [self setBtnTitleForChapter:chid title:@"Скачать"];
}

-(void) updateProgressForChapterIdentity:(NSString*)chapterIdentity value:(float)val
{
    int bid = [gss() bidFromChapterIdentity:chapterIdentity];
    
    if (bid != bookId) {
        NSLog(@"++ Отображается оглавление не той книги!");
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
        cell.tag = 1000+indexPath.row;
    }
    
    // Configure the cell...
    Chapter *lc = [chapters objectAtIndex:indexPath.row];
    UILabel* lblBig = (UILabel*)[cell viewWithTag:1];
    lblBig.text = lc.cId;
    UILabel* lblSmall = (UILabel*)[cell viewWithTag:2];
    lblSmall.text = lc.name;
    UIProgressView* progress = (UIProgressView*) [cell viewWithTag:3];
    progress.progress = [playerController calcDownProgressForChapter:lc.cId];
    UIButton* btn = (UIButton*)[cell viewWithTag:4];
    [btn setTitle:@"Скачать" forState:UIControlStateNormal];
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
static int rowIdx = -1;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    // get chapter id from index and find that chapter id in bookMeta.xml
    rowIdx = indexPath.row;
    // create xml from string
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:bookId]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%d']/content/track[%d]/@number", bookId, rowIdx+1]];
    if ([arr count] != 1) {
        NSLog(@"**err: invalid tracks array");
        if (rowIdx>0) {
            --rowIdx; // leave at last position
        }
        else
        {
            rowIdx = 0; // set to first chapter
        }
        return;
    }
    NSString* chid = [arr objectAtIndex:0];
    
    if (!tableView) { // call from player to select previous/next chapter
        [(UITableView*)[self view] selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    }
    
    [playerController startChapter:chid];
    
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
