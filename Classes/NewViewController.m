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
#import "NewViewController.h"
#import "CatalogViewController.h"
#import "PlayerViewController.h"
#import "PlayerViewController2.h"
#import "MainViewController.h"
#import "CatalogItem.h"
#import "gs.h"
#import "Book.h"
#import "SearchViewController.h"
#import "MyBooksView.h"
#import "CatalogOptionCell.h"

@implementation NewViewController

- (id)initWithStyle:(UITableViewStyle)style {

	if (self = [super initWithStyle:style]) {
//        parent = p;
		self.title = @"Новинки";
        //self.navigationItem.backBarButtonItem.title = @"назад";
        self.wantsFullScreenLayout = YES;
        
        // TODO: should be anything but not category (-1)
        parentGenre = @"1";
        
        dbOffset = 0; // will be 0 with first call to db
        
        // output by "dbLimit" records at a time (for a query)
        // TODO: I hope this is enough
        dbLimit = 20000;
        
        
        genres = [[NSMutableArray alloc] init];
        
        // get updates into array
        [genres addObjectsFromArray:[self db_GetGenresAndBooksWithParent:parentGenre andOffset:dbOffset andLimit:dbLimit]];        
        //[self nextGenres];
        
	}
    
	return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//	CatalogViewController *delegate = self.delegate];
//	return [delegate genresCount] + 1; // + 1 cell for Add more rows button
	return [genres count];
}

-(void)goSearch:(UIButton*)sender
{
    // Create and configure the main view controller.
    static SearchViewController* sv = nil; // TODO: hack to avoid crash search bar released by system one more time then needed when view is unloaded
    if (sv)
        sv = nil;
    
    sv = [[SearchViewController alloc] initWithNibName:[gs nibFor:@"SearchView"]  bundle:nil];
    //searchViewController.listContent = genres;
    [gss().navigationController pushViewController:sv animated:YES];
}

-(void)goHistory:(UIButton*)sender
{
    MyBooksView* dv = [[MyBooksView alloc] initWithStyle:UITableViewStylePlain];
    //searchViewController.listContent = genres;
    [gss().navigationController pushViewController:dv animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    
    CatalogItem *g = [genres objectAtIndex:indexPath.row];
   // NSLog(@"++ g.type: %@", g.type);
    if ([g.type isEqualToString:@"-2"]) // search, recent
    {
        static NSString *MyIdentifier = @"CatalogOptionCell";
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            CatalogOptionCell* c = [[CatalogOptionCell alloc] initWithNibName:[gs nibFor:@"CatalogOptionCell"] bundle:nil];
            cell = (UITableViewCell *) [c view];
        }
        
        UIButton* btn = (UIButton*)[cell viewWithTag:2]; // history button        
        [btn addTarget:self action:@selector(goHistory:) forControlEvents:UIControlEventTouchUpInside];
        btn = (UIButton*)[cell viewWithTag:1]; // search button
        [btn addTarget:self action:@selector(goSearch:) forControlEvents:UIControlEventTouchUpInside];        
    }
    else if ([g.type isEqualToString:@"1"]) // category
    {        
        static NSString *MyIdentifier = @"CatalogItemCell";
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
        cell = [[UITableViewCell alloc]
             initWithStyle:UITableViewCellStyleDefault
             reuseIdentifier:MyIdentifier];
        }
        cell.textLabel.text = g.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else // only for book cells
    {
        cell = [gs catalogCellForBook:g tableView:tableView];
    }
    

	return cell;
}

- (void)db_myupdatesDelete:(NSString*)bookID {
    NSString *st = [NSString stringWithFormat:@"DELETE FROM myupdates WHERE abook_id='%@'", bookID];
    sqlite3* db;
    
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
    
    returnCode = sqlite3_exec(db, [st UTF8String], 0, 0, 0);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to exec statement db: %s", sqlite3_errmsg(db) ]];
        
    sqlite3_close(db);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    if(indexPath.row == [delegate genresCount])
//    {
//        int rowsToInsert = [delegate nextGenres];
//        
//        if(rowsToInsert == 0) // no results from db, all data is shown
//            return;
//        
//        NSMutableArray *a = [[NSMutableArray alloc] init];
//        int startIndex = [delegate genresCount] - rowsToInsert;
//        for (int i = 0; i<rowsToInsert; i++) {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(startIndex++) inSection:0];
//            [a addObject:indexPath];
//        }
//                
//        [[self tableView] insertRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationLeft];
//    }
//    else
//    {
        CatalogItem* g = [genres objectAtIndex:indexPath.row];
        if([g.type isEqualToString:@"1"]) // category
        {
            CatalogViewController *subGenresController = [[CatalogViewController alloc] initWithStyle:UITableViewStylePlain andParentGenre:g.ID];
            subGenresController.title = g.name;
            [[gs sharedInstance].navigationController pushViewController:subGenresController animated:YES];
        }
        else if([g.type isEqualToString:@"2"]) // @"2" - book
        {
            if([gs canGetMetaForBook:g.ID])
            {
                UIViewController *plConroller;
                if([g.ID hasPrefix:@"lrs"]) // book from litres catalog
                    plConroller = [[PlayerViewController2 alloc] initWithBook:g.ID];
                else
                    plConroller = [[PlayerViewController alloc] initWithBook:g.ID];
                
                // delete book from new items
                [self db_myupdatesDelete:g.ID];
                
                // Pass the selected object to the new view controller.
                [gss().navigationController pushViewController:plConroller animated:YES];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сообщение"
                                                                message:@"Для получения книги нужен интернет. Проверьте соединение."
                                                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];                
            }
        }
        else if([g.type isEqualToString:@"-2"])// search books
        {
            // Create and configure the main view controller.
            static SearchViewController* sv = nil; // TODO: hack to avoid crash search bar released by system one more time then needed when view is unloaded
            if (sv)
                sv = nil;
            
            sv = [[SearchViewController alloc] initWithNibName:[gs nibFor:@"SearchView"] bundle:nil];
            //searchViewController.listContent = genres;
            [gss().navigationController pushViewController:sv animated:YES];
        }
//        else // expected @"0" - downloaded books
//        {
//            MyBooksView* dv = [[MyBooksView alloc] initWithStyle:UITableViewStylePlain];
//            //searchViewController.listContent = genres;
//            [gss().navigationController pushViewController:dv animated:YES];
//        }
    
//    ShowCharactersTableViewController *showCharactersController = [[ShowCharactersTableViewController alloc] initWithStyle:UITableViewStylePlain];
//    showCharactersController.delegate = delegate;
//    [[delegate navigationController] pushViewController:showCharactersController animated:YES];
//    }
}
//
//-(void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    CGFloat height = scrollView.frame.size.height;
//    
//    CGFloat contentYoffset = scrollView.contentOffset.y;
//    
//    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
//    
//    if(distanceFromBottom < height)
//    {
//        int rowsToInsert = [delegate nextGenres];
//        
//        if(rowsToInsert == 0) // no results from db, all data is shown
//            return;
//        
//        NSMutableArray *a = [[NSMutableArray alloc] init];
//        int startIndex = [delegate genresCount] - rowsToInsert;
//        for (int i = 0; i<rowsToInsert; i++) {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(startIndex++) inSection:0];
//            [a addObject:indexPath];
//        }
//        
//        [[self tableView] insertRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationLeft];
//    }
//}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    CGFloat height = scrollView.frame.size.height;
//    
//    CGFloat contentYoffset = scrollView.contentOffset.y;
//    
//    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
//    
//    if(distanceFromBottom < height)
//    {
//        int rowsToInsert = [self nextGenres];
//        
//        if(rowsToInsert == 0) // no results from db, all data is shown
//            return;
//        
//        NSMutableArray *a = [[NSMutableArray alloc] init];
//        int startIndex = [genres count] - rowsToInsert;
//        for (int i = 0; i<rowsToInsert; i++) {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(startIndex++) inSection:0];
//            [a addObject:indexPath];
//        }
//        
//        [[self tableView] insertRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationLeft];
//    }
//    
//}


- (NSMutableArray *)db_GetGenresAndBooksWithParent:(NSString*) parentItem /*parentItem not used*/ andOffset:(int) offset andLimit:(int) limit
{
    NSString* sqlStatement = [NSString stringWithFormat:@"SELECT t_abooks.abook_id AS id, title AS name, -1 AS subgenres, 2 AS type, CASE t_abooks.bought WHEN 1 THEN '+' ELSE priceios END priceios, GROUP_CONCAT(t_authors.name, ',') authors  FROM t_abooks"
                        " JOIN myupdates ON t_abooks.abook_id=myupdates.abook_id "
                        " LEFT JOIN"
                        " t_abooks_authors ON t_abooks_authors.abook_id=t_abooks.abook_id"
                        " JOIN"
                        " t_authors ON t_abooks_authors.author_id=t_authors.author_id"
                   " JOIN t_abooks_genres ON t_abooks.abook_id = t_abooks_genres.abook_id"
                   " WHERE t_abooks.deleted=0 GROUP BY name"
                   " ORDER BY  type, name DESC  LIMIT %d, %d", offset, limit];
    
   
    
    //    printf(sqlStatement);
    sqlite3* db;
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr open: %s", sqlite3_errmsg(db) ]];
    
    sqlite3_stmt* statement;
    returnCode =
    sqlite3_prepare_v2(db,
                       [sqlStatement UTF8String], strlen([sqlStatement UTF8String]),
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
        genre.subgenresCount = [NSString stringWithCString:sqlite3_column_text(statement, 2) == nil ? "" : (char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding];
        genre.type = [NSString stringWithCString:sqlite3_column_text(statement, 3) == nil ? "" : (char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding];
        genre.priceios = [NSString stringWithCString:sqlite3_column_text(statement, 4) == nil ? "" : (char *)sqlite3_column_text(statement, 4) encoding:NSUTF8StringEncoding];
        genre.authors = [NSString stringWithCString:sqlite3_column_text(statement, 5) == nil ? "" : (char *)sqlite3_column_text(statement, 5) encoding:NSUTF8StringEncoding];
        //        printf("name %s count %s ID %s\n",
        //               name, count, ID);
        returnCode = sqlite3_step(statement);
        
        [genresList insertObject:genre atIndex:genresList.count];
        
    }
    returnCode = sqlite3_finalize(statement);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr finalize: %s", sqlite3_errmsg(db) ]];
    
    returnCode = sqlite3_close(db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr close: %s", sqlite3_errmsg(db) ]];
    
    return [genresList copy];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![genres count] || ![((CatalogItem*)[genres objectAtIndex:0]).type isEqualToString:@"-2"]) { // only for top level with search
        return;
    }
    
//    NSArray* arr = [gs db_GetMybooks];
//    
//    if([arr count] && [genres count]>=2 && ![((CatalogItem*)[genres objectAtIndex:1]).type isEqualToString:@"0"]) // show
//    {
//        UITableView* tv = (UITableView*)self.view;
//        CatalogItem* ci = [[CatalogItem alloc] init];
//        ci.name = @"Скаченные";
//        ci.type = @"0";
//        [genres insertObject:ci atIndex:1];
//        [tv insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
//    }else if (![arr count] && [genres count]>=2 && [((CatalogItem*)[genres objectAtIndex:1]).type isEqualToString:@"0"]) // hide
//    {
//        UITableView* tv = (UITableView*)self.view;
//        [genres removeObjectAtIndex:1];
//        [tv deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
//    }
    // else probably should do nothing - didn't check
}

//-(int) nextGenres
//{
//    int oldGenres = [genres count];
//    dbOffset += dbLimit;
//    [genres addObjectsFromArray:[self db_GetGenresAndBooksWithParent:parentGenre andOffset:dbOffset andLimit:dbLimit]];
//    
//    
//    
//    //    fprintf(stderr, "\n** genres.count: %i", [genres count]);
//    
//    return [genres count] - oldGenres;
//}

@end

