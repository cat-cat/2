//
//  MyTableViewController.m
//  audiobook
//
//  Created by User on 13.03.13.
//
//

#import "MyTableViewController.h"
//#import "PlayerViewController.h"
#import "PlayerViewController2.h"
#import "NewViewController.h"
#import "gs.h"

@interface MyTableViewController ()
-(NSArray*) db_getNewItems;
@end

@implementation MyTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void)goNew:(id)sender
{
    // TODO: add PlayerViewController as target
    NewViewController* newView = [[NewViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:newView animated:YES];
}

-(void)goPlayer:(id)sender
{
    //    NSLog(@"++ player button click");
    // TODO: add PlayerViewController
    PlayerViewController2* playerView = [[PlayerViewController2 alloc] initWithBook:@"current"];
    [self.navigationController pushViewController:playerView animated:YES];
}

-(NSArray*)db_getNewItems
{
    // assuming its not called from multiple threads, only from gui
    
    sqlite3* db;
    
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
    char *sqlStatement;
    
    sqlStatement = sqlite3_mprintf("SELECT abook_id"
                                   " FROM myupdates"
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

- (void)viewWillAppear:(BOOL)animated
{
    UIBarButtonItem *rightButton = nil;
    if ([StaticPlayer2 sharedInstance].shouldShowPlayerButton) {
        rightButton = [[UIBarButtonItem alloc]
                                        initWithTitle: @"Плеер"
                                        style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(goPlayer:)];
        
//      self.navigationItem.rightBarButtonItem = rightButton;
    }
  
    NSMutableArray *rightArray = [[NSMutableArray alloc] init];
    if (rightButton != nil) {
        [rightArray addObject:rightButton];
    }
    
    NSArray *newItems = [self db_getNewItems];
    
    if ([newItems count] > 0 && ![self isKindOfClass:[NewViewController class]]) {
        UIView* xibView = [[[NSBundle mainBundle] loadNibNamed:@"Common" owner:self options:nil] objectAtIndex:0];
        // now add the view to ourselves...
        UILabel *lv = (UILabel*) [xibView viewWithTag:22];
        [lv setText:[NSString stringWithFormat:@"%d",[newItems count]]];
        UIButton *nbtn = (UIButton*) [xibView viewWithTag:33];
        [nbtn addTarget:self action:@selector(goNew:) forControlEvents:UIControlEventTouchUpInside];
        [rightArray addObject:[[UIBarButtonItem alloc] initWithCustomView:xibView]];
    }
    
    if ([rightArray count] > 0) {
        self.navigationItem.rightBarButtonItems = rightArray;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    
//    // Configure the cell...
//    
//    return cell;
//}

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

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Navigation logic may go here. Create and push another view controller.
//    /*
//     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
//     // ...
//     // Pass the selected object to the new view controller.
//     [self.navigationController pushViewController:detailViewController animated:YES];
//     */
//}

@end
