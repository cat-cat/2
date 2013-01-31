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
#import "GenresViewController.h"
#import "BookViewController.h"
#import "CatalogViewController.h"
#import "Genre.h"
#import "GlobalSingleton.h"
#import "Book.h"

@implementation GenresViewController


- (void) onRefreshCatalog
{
    NSLog(@"++Обновление каталога завершено");
    [[self tableView] reloadData];
}


- (id)initWithStyle:(UITableViewStyle)style andParentGenre:(NSString*) parentParam andParent:(CatalogViewController*)p{
	if (self = [super initWithStyle:style]) {
        parent = p;
		self.title = @"Каталог";
        self.navigationItem.backBarButtonItem.title = @"Каталог";
        
        parentGenre = [[NSString alloc] initWithString:parentParam];
        
        genres = [[NSMutableArray alloc] init];
        
        dbOffset = -7; // will be 0 with first call to db
        
        // output by "dbLimit" records at a time (for a query)
        dbLimit = 7;
        
        [self nextGenres];
        
        
        // add message handlers
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onRefreshCatalog)
                                                     name:@"ntf_onRefreshCatalog"
                                                   object:nil];
        
	}
	return self;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//	CatalogViewController *delegate = self.delegate];
//	return [delegate genresCount] + 1; // + 1 cell for Add more rows button
	return [genres count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
//    if(indexPath.row == [delegate genresCount])
//    {
//        static NSString *MyIdentifier = @"ButtonMore";
//        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
//        if (cell == nil) {
//            cell = [[UITableViewCell alloc]
//                    initWithStyle:UITableViewCellStyleDefault
//                    reuseIdentifier:MyIdentifier];
//        }
//        cell.textLabel.text =  @"Еще...";
//        cell.accessoryType = UITableViewCellAccessoryNone;
//    }
//    else
//    {
        static NSString *MyIdentifier = @"Show";
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] 
                 initWithStyle:UITableViewCellStyleDefault
                 reuseIdentifier:MyIdentifier];
        }
    //	TVAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        Genre *g = [genres objectAtIndex:indexPath.row];
        cell.textLabel.text =  g.name;
    
    if ([g.type isEqualToString:@"1"])
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
//    }
	return cell;
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
        Genre* g = [genres objectAtIndex:indexPath.row];
        if([g.type isEqualToString:@"1"]) // category
        {
            GenresViewController *subGenresController = [[GenresViewController alloc] initWithStyle:UITableViewStylePlain andParentGenre:g.ID andParent:parent];
            [[parent navigationController] pushViewController:subGenresController animated:YES];
        }
        else // expected @"2" - book
        {
            
            //*****
            BookViewController* bookViewController = [[BookViewController alloc] initWithNibName:@"BookView" bundle:nil andBook:g.ID];
//            if (bookViewController.view) {// !!! accessing view will initialize view with all controls before it's shown
//                [bookViewController.nameLabel setText:g.name]; // !!! will work only after "if" above
//            }
            
           
            //*****

            //CharacterViewController *characterController = [[CharacterViewController alloc] initWithDelegate:delegate andBookID:g.ID];
            [[parent navigationController] pushViewController:bookViewController animated:YES];
        }
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

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    CGFloat height = scrollView.frame.size.height;
    
    CGFloat contentYoffset = scrollView.contentOffset.y;
    
    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
    
    if(distanceFromBottom < height)
    {
        int rowsToInsert = [self nextGenres];
        
        if(rowsToInsert == 0) // no results from db, all data is shown
            return;
        
        NSMutableArray *a = [[NSMutableArray alloc] init];
        int startIndex = [genres count] - rowsToInsert;
        for (int i = 0; i<rowsToInsert; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(startIndex++) inSection:0];
            [a addObject:indexPath];
        }
        
        [[self tableView] insertRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationLeft];
    }
    
}


- (NSMutableArray *)db_GetGenresAndBooksWithParent:(NSString*) parentItem andOffset:(int) offset andLimit:(int) limit
{
    
    
    char* sqlStatement = sqlite3_mprintf("SELECT t_abooks.abook_id AS id, title AS name, -1 AS subgenres, 2 AS type FROM t_abooks"
                                   
                                   " JOIN t_abooks_genres ON t_abooks.abook_id = t_abooks_genres.abook_id"
                                   
                                   " WHERE t_abooks_genres.genre_id = %s"
                                   
                                   
                                   
                                   " UNION"
                                   
                                   
                                   
                                   " SELECT t_genres.genre_id AS id, name, COUNT(t_abooks_genres.genre_id) AS subgenres, 1 AS type FROM t_genres"
                                   
                                   " LEFT JOIN"
                                   
                                   " t_abooks_genres"
                                   
                                   " WHERE t_genres.genre_parent_id = %s AND t_genres.genre_id = t_abooks_genres.genre_id"
                                   
                                   " GROUP BY name"
                                   
                                   
                                   
                                   " ORDER BY  type, name  LIMIT %d, %d", [parentItem UTF8String], [parentItem UTF8String], offset, limit);
    
   
    
    //    printf(sqlStatement);
    sqlite3* db;
    int returnCode = sqlite3_open([GlobalSingleton dbname], &db);
    [GlobalSingleton assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr open: %s", sqlite3_errmsg(db) ]];
    
    sqlite3_stmt* statement;
    returnCode =
    sqlite3_prepare_v2(db,
                       sqlStatement, strlen(sqlStatement),
                       &statement, NULL);
    [GlobalSingleton assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr prepare: %s", sqlite3_errmsg(db) ]];
    sqlite3_free(sqlStatement);
    
    
    NSMutableArray *genresList = [[NSMutableArray alloc] init];
    // get result
    returnCode = sqlite3_step(statement);
    while(returnCode == SQLITE_ROW){
        Genre *genre = [[Genre alloc] init];
        ;
        genre.ID = [NSString stringWithCString:sqlite3_column_text(statement, 0) == nil ? "" : (char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
        genre.name = [NSString stringWithCString:sqlite3_column_text(statement, 1) == nil ? "" : (char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding];
        genre.subgenresCount = [NSString stringWithCString:sqlite3_column_text(statement, 2) == nil ? "" : (char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding];
        genre.type = [NSString stringWithCString:sqlite3_column_text(statement, 3) == nil ? "" : (char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding];
        //        printf("name %s count %s ID %s\n",
        //               name, count, ID);
        returnCode = sqlite3_step(statement);
        
        [genresList insertObject:genre atIndex:genresList.count];
        
    }
    returnCode = sqlite3_finalize(statement);
    [GlobalSingleton assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr finalize: %s", sqlite3_errmsg(db) ]];
    
    returnCode = sqlite3_close(db);
    [GlobalSingleton assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"dberr close: %s", sqlite3_errmsg(db) ]];
    
    return [genresList copy];
}



-(int) nextGenres
{
    int oldGenres = [genres count];
    dbOffset += dbLimit;
    [genres addObjectsFromArray:[self db_GetGenresAndBooksWithParent:parentGenre andOffset:dbOffset andLimit:dbLimit]];
    
    
    
    //    fprintf(stderr, "\n** genres.count: %i", [genres count]);
    
    return [genres count] - oldGenres;
}

@end

