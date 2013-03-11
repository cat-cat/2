//
//  DownloadsViewController.m
//  audiobook
//
//  Created by User on 2/19/13.
//
//

#import "DownloadsViewController.h"
#import "PlayerViewController.h"
#import "gs.h"

@interface DownloadsViewController ()

@end

@implementation DownloadsViewController

- (id)initWithStyle:(UITableViewStyle)style andDelegate:(StaticPlayer*)d
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.downq = [[NSMutableArray alloc] initWithArray:d.downq copyItems:YES];
        self.delegate = d;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return [self.downq count];
}

-(NSArray*)titlesForChapterIdentity:(NSString*)chid
{
    NSArray* arr = [chid componentsSeparatedByString:@":"];
    NSString* bid = [arr objectAtIndex:0];
    NSString* chapterId = [arr objectAtIndex:1];
    DDXMLDocument* doc = [gss() docForFile:[gss() pathForBookMeta:bid]];
    NSArray *titleArr = [gss() arrayForDoc:doc xpath:[NSString stringWithFormat:@"/abooks/abook[@id='%@']/title",bid ]];
    NSAssert1([titleArr count], @"**err: titleArr is empty: %s", __func__);
    NSArray* chapterNameArr = [gss() arrayForDoc:doc xpath:[NSString stringWithFormat:@"/abooks/abook[@id='%@']//track[@number='%@']/name",bid,chapterId ]];
    NSAssert1([chapterNameArr count], @"**err: chapterNameArr is empty: %s", __func__);
    
    return @[[titleArr objectAtIndex:0], [chapterNameArr objectAtIndex:0]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    // get titles for book and chapter
    NSArray* titles = [NSArray arrayWithArray: [self titlesForChapterIdentity:[self.downq objectAtIndex:indexPath.row]]];
    cell.textLabel.text = [titles objectAtIndex:1];
    cell.detailTextLabel.text = [titles objectAtIndex:0];
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.delegate removeDownqObject:[self.downq objectAtIndex:indexPath.row ]];
        [self.downq removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


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


