/*
     File: MainViewController.m 
 Abstract: Main table view controller for the application. 
  Version: 1.5 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "SearchViewController.h"
#import "CatalogItem.h"
#import "gs.h"
#import "PlayerViewController.h"

@implementation SearchViewController

@synthesize listContent, filteredListContent, savedSearchTerm, savedScopeButtonIndex, searchWasActive;

- (NSMutableArray *)db_GetBooksWithScope:(NSString*) scope searchPhrase:(NSString*)sf
{
    // TODO: make case insensitive search for russian phrases
    
    //char* sqlStatement = 0;
    
    NSString* query = @" SELECT t_abooks.abook_id AS id, title, GROUP_CONCAT(t_authors.name, ',') authors FROM t_abooks"
    " LEFT JOIN"
    " t_abooks_authors ON t_abooks_authors.abook_id=t_abooks.abook_id"
    " JOIN"
    " t_authors ON t_abooks_authors.author_id=t_authors.author_id";
    
    if (sf && sf.length) {
        query = [query stringByAppendingString:[NSString stringWithFormat:@" WHERE t_authors.name LIKE '%%%@%%' OR title LIKE '%%%@%%' ", sf, sf]];
    }
    
    if ([scope isEqualToString:@"Новые"]) // top level - genres without parents, add Search item at the top
        
        query = [query stringByAppendingString:[NSString stringWithFormat:@" GROUP BY t_abooks.abook_id ORDER BY  order_new DESC"]];    
        
    else // Все - sort by popular
        
        query = [query stringByAppendingString:[NSString stringWithFormat:@" GROUP BY t_abooks.abook_id ORDER BY  order_popular DESC"]];
    
//    else // Все
//        
//        query = [query stringByAppendingString:[NSString stringWithFormat:@" GROUP BY t_abooks.abook_id ORDER BY  title"]];
    
   
    
    
    //    printf(sqlStatement);
    sqlite3* db;
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr open: %s", sqlite3_errmsg(db) ]];
    
    sqlite3_stmt* statement;
    returnCode =
    sqlite3_prepare_v2(db,
                       [query UTF8String], strlen([query UTF8String]),
                       &statement, NULL);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr prepare: %s", sqlite3_errmsg(db) ]];
    //sqlite3_free(sqlStatement);
    
    
    NSMutableArray *genresList = [[NSMutableArray alloc] init];
    // get result
    returnCode = sqlite3_step(statement);
    while(returnCode == SQLITE_ROW){
        CatalogItem *genre = [[CatalogItem alloc] init];
        ;
        genre.ID = [NSString stringWithCString:sqlite3_column_text(statement, 0) == nil ? "" : (char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
        genre.name = [NSString stringWithCString:sqlite3_column_text(statement, 1) == nil ? "" : (char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding];
        genre.authors = [NSString stringWithCString:sqlite3_column_text(statement, 2) == nil ? "" : (char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding];
//        genre.subgenresCount = [NSString stringWithCString:sqlite3_column_text(statement, 2) == nil ? "" : (char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding];
//        genre.type = [NSString stringWithCString:sqlite3_column_text(statement, 3) == nil ? "" : (char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding];
        //        printf("name %s count %s ID %s\n",
        //               name, count, ID);
        returnCode = sqlite3_step(statement);
        
        [genresList insertObject:genre atIndex:genresList.count];
        
    }
    returnCode = sqlite3_finalize(statement);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr finalize: %s", sqlite3_errmsg(db) ]];
    
    returnCode = sqlite3_close(db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr close: %s", sqlite3_errmsg(db) ]];
    
    return genresList;
}


#pragma mark -
#pragma mark Lifecycle methods

- (void)viewDidLoad
{
	self.title = @"Поиск";
    // get data from database
    self.listContent = [[NSMutableArray alloc] initWithArray:[self db_GetBooksWithScope:@"Все" searchPhrase:@""]];

    
	
	// create a filtered list that will contain products for the search results table.
	self.filteredListContent = [NSMutableArray arrayWithCapacity:[self.listContent count]];
	
	// restore search settings if they were saved in didReceiveMemoryWarning.
    if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }
	
	[self.tableView reloadData];
	self.tableView.scrollEnabled = YES;
}

- (void)viewDidUnload
{
	self.filteredListContent = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    // save the state of the search UI so that it can be restored if the view is re-created
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
}

- (void)dealloc
{
}


#pragma mark -
#pragma mark UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	/*
	 If the requesting table view is the search display controller's table view, return the count of
     the filtered list, otherwise return the count of the main list.
	 */
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [self.filteredListContent count];
    }
	else
	{
        return [self.listContent count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellID = @"cellID";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	/*
	 If the requesting table view is the search display controller's table view, configure the cell using the filtered content, otherwise use the main list.
	 */
	CatalogItem *genre = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        genre = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else
	{
        genre = [self.listContent objectAtIndex:indexPath.row];
    }
	
	cell.textLabel.text = genre.name;
    cell.detailTextLabel.text = genre.authors;
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UIViewController *detailsViewController = [[UIViewController alloc] init];
    
	/*
	 If the requesting table view is the search display controller's table view, configure the next view controller using the filtered content, otherwise use the main list.
	 */
	CatalogItem *genre = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        genre = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else
	{
        genre = [self.listContent objectAtIndex:indexPath.row];
    }
	//detailsViewController.title = genre.name;
    PlayerViewController *pc = [[PlayerViewController alloc] initWithBook:[genre.ID intValue]];

//    [[self navigationController] pushViewController:detailsViewController animated:YES];
    [[self navigationController] pushViewController:pc animated:YES];
}


#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
//	for (CatalogItem *genre in listContent)
//	{
//		if ([scope isEqualToString:@"All"])
//		{
//			NSComparisonResult result = [genre.name compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
//            if (result == NSOrderedSame)
//			{
//                [self.filteredListContent addObject:genre];
    self.filteredListContent = [self db_GetBooksWithScope:scope searchPhrase:searchText];
//            }
//		}
//	}
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
			[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
			[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

BOOL shouldBeginEditing = YES;
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self.listContent removeAllObjects];
    
    if (selectedScope==0)
        self.listContent = [self db_GetBooksWithScope:@"Все" searchPhrase:[self.searchDisplayController.searchBar text]];
    else // 1
        self.listContent = [self db_GetBooksWithScope:@"Новые" searchPhrase:[self.searchDisplayController.searchBar text]];
 
    [(UITableView*) self.view reloadData];
    shouldBeginEditing = NO;
}


- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    BOOL answer = shouldBeginEditing;
    shouldBeginEditing = YES; // reset flag
    return answer;
}

- (void) liveScopeBar:(UISearchBar*)searchBar
{
    searchBar.showsScopeBar = YES;
    [searchBar sizeToFit];
    UITableView* tv = (UITableView*) self.view;
    tv.tableHeaderView = searchBar;   
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self liveScopeBar:searchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self liveScopeBar:searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self liveScopeBar:searchBar];
}
@end

