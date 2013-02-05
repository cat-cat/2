//
//  ChaptersViewController.m
//  audiobook
//
//  Created by User on 2/4/13.
//
//

#import "ChaptersViewController.h"
#import "GlobalSingleton.h"
#import "ASIHTTPRequest.h"
#import "DDXMLDocument.h"

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

- (void)grabURLInTheBackground:(int)bid
{
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/getAbookById.php?bid=%d", AppConnectionHost, bid]];
    //NSURL *url = [NSURL URLWithString:@"http://dl.dropbox.com/u/4115029/bookMeta.xml"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    //[[GlobalSingleton sharedInstance].queue addOperation:request]; //queue is an NSOperationQueue
    [request startAsynchronous];
}

- (void)requestDone:(ASIHTTPRequest *)request
{
    NSString *response = [request responseString];
    NSLog(@"++response %@", response);
    // create xml from string
    NSError *error;
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:response options:0 error:&error];
    [GlobalSingleton handleError:error];
    
    NSArray *items=[doc nodesForXPath:@"/abooks/abook/content/track" error:&error];
    
    for (DDXMLElement *item in items) {
        NSLog(@"++item contents: %s", [[item XMLString] UTF8String]);
        doc = [doc initWithXMLString:[item XMLString] options:0 error:&error];
        NSString *cId = [[[doc nodesForXPath:@"//@number" error:&error] objectAtIndex:0] stringValue];
        NSString *cName = [[[doc nodesForXPath:@"//name" error:&error] objectAtIndex:0] stringValue];
        Chapter* c = [[Chapter alloc] init];
        c.name = cName;
        c.cId = cId;
        [chapters addObject:c];
        
    }
    
    for (Chapter *c in chapters){
        NSLog(@"chapter's data: %@, %@", c.cId, c.name);
    }
    
    
    NSFileManager *fm = [NSFileManager defaultManager];    
    // save to home directory
//    NSString *pathToBookDirectory =[ NSHomeDirectory() stringByAppendingPathComponent: [NSString stringWithFormat:@"tmp/books/%d/BookMeta.xml", bookId ]];
    NSString *pathToBookDirectory =[ NSHomeDirectory() stringByAppendingPathComponent:@"tmp/BookMeta.xml"];
    if(![fm fileExistsAtPath:pathToBookDirectory])
    {
       [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:pathToBookDirectory] ];
         bool fileCreationSuccess = [ fm createFileAtPath:pathToBookDirectory contents:[request responseData] attributes:nil];
        if(fileCreationSuccess == NO){ NSLog(@"Failed to create the html file");
        }
    }
    // parse
    
    // save to chapters variable
    
    // reload table view
    [(UITableView*)[self view] reloadData];
}

- (void)requestWentWrong:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    
    //TODO:  show error with Alert
    [GlobalSingleton handleError:error];
}

- (id)initWithBook:(int)bid
{
    self = [super init];
    if (self) {
        // Custom initialization
        bookId = bid;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    chapters = [[NSMutableArray alloc] init];
    
    // start request to get chapters, handle answer in handlers
    [self grabURLInTheBackground:bookId];

    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSLog(@"++ the index row number %d", indexPath.row);
    Chapter *lc = [chapters objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"++chNO %@ chTitle %@", lc.cId, lc.name ];
    
    return cell;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
