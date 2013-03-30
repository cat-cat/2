//
//  AppStore.m
//  audiobook
//
//  Created by User on 09.03.13.
//
//

#import "Myshop.h"
#import <StoreKit/StoreKit.h>
#import "ASIHTTPRequest.h"
#import "gs.h"
#import "PlayerViewController.h"
#import "MBProgressHUD.h"
#import "ASINetworkQueue.h"

@implementation Myshop

// ********************** Myshop part
MBProgressHUD *HUD2 = nil;
//static ASIHTTPRequest* currentRequest = nil;
static ASINetworkQueue *buyDownloadQueue;


-(void)hideHUD
{
    if (HUD2) {
        [MBProgressHUD hideHUDForView:gss().navigationController.view animated:YES];
        HUD2=nil;
    }
}

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    for (id key in responseHeaders) {
        NSLog(@"key: %@, value: %@ \n", key, [responseHeaders objectForKey:key]);
    }
    // [[NSFileManager defaultManager] removeItemAtPath:currentTrack.audioFilePath error:nil];
    //if(![[NSFileManager defaultManager] fileExistsAtPath:currentTrack.audioFilePath])
}

- (void) request:(ASIHTTPRequest *)request didReceiveBytes:(unsigned long long) bytes
{
    
}

//- (void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data
//{

//}

SKPaymentTransaction* currentTransaction = nil;
- (void)requestFinished:(ASIHTTPRequest *)request
{
    [self hideHUD];
    
    NSError* error;
    NSString* response = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[gss() pathForBuy:[request.userInfo objectForKey:@"bid" ]] ] encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"++Finished buy option1: %@", response);
    NSRange r = [response rangeOfString:@"yes"];
    if ((response && r.location != NSNotFound) && request.responseStatusCode == 200)
    {
        int isfree = [[request.userInfo valueForKey:@"isfree"] intValue];
        if (isfree) {
            NSString *devid = [[UIDevice currentDevice] uniqueIdentifier];
            NSArray *arr = [gs srvArrForUrl:[NSString stringWithFormat:@"http://%@/free1closecode.php?dev=%@&bookid=%@", BookHost, devid,[request.userInfo objectForKey:@"bid" ]] xpath:@"//canuse" message:[NSString stringWithFormat:@"**err:unable to request success to close code: %s", __func__ ]];
            NSString* canuse = [arr objectAtIndex:0];
            NSLog(@"++close code: %@", canuse);
            //            if (![canuse isEqualToString:@"yes"]) {
            //                ,
            //            }
        }
        
        if (currentTransaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction: currentTransaction];
            currentTransaction = nil;
            [StaticPlayer buyBook];
        }
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Покупка книги"
                                                        message:@"Ошибка: книга не куплена"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self hideHUD];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Покупка книги"
                                                    message:@"Ошибка: книга не куплена"
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    NSLog(@"**err: request failed description %@, url: %@", [request.error description], [request url]);
}


-(BOOL)startWithBook:(NSString*)bid isfree:(BOOL)free
{
//    if (currentRequest && !currentRequest.complete) {
//        return NO;
//    }
    
    // create main request
    NSString *devid =[[UIDevice currentDevice] uniqueIdentifier];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/buy.php?bid=%@&dev=%@&bt=1", BookHost, bid, devid]];
    ASIHTTPRequest* currentRequest = [ASIHTTPRequest requestWithURL:url];
    NSString *downloadPath = [gss() pathForBuy:bid];
    
    // create empty file for player could start streaming
    //        if(![[NSFileManager defaultManager]  fileExistsAtPath:downloadPath])
    //            [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
    
    // The full file will be moved here if and when the request completes successfully
    [currentRequest setDownloadDestinationPath:downloadPath];
    
    // This file has part of the download in it already
    //[currentRequest setTemporaryFileDownloadPath:downloadPath];
    //[currentRequest setAllowResumeForFileDownloads:YES];
    [currentRequest setDelegate:self];
    [currentRequest setDownloadProgressDelegate:self];
    //    int alreadyDownloaded = 2354100;
    //    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%i-", alreadyDownloaded]];
    //[currentRequest setMyDontRemoveFlag:true];
    NSString* nBid = bid;
    NSNumber* bookfree = [NSNumber numberWithInt: free];
    [currentRequest setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                 nBid, @"bid", bookfree, @"isfree",  nil]];
    //[currentRequest startAsynchronous];
    [buyDownloadQueue addOperation:currentRequest];
    [buyDownloadQueue go];
    
    if (!HUD2) {
        HUD2 = [MBProgressHUD showHUDAddedTo:gss().navigationController.view animated:YES];
        HUD2.labelText = @"проверка книги...";
    }

    
    return YES;
}

// ********************** Appstore part
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [self hideHUD];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Восстановление покупок"
                                                    message:@"Ошибка при восстановлении покупок."
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];

    [gss() handleError:error];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self hideHUD];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Восстановление покупок"
                                                    message:@"Покупки восстановлены!"
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

-(void)restorePurchases
{
    if (!HUD2) {
        HUD2 = [MBProgressHUD showHUDAddedTo:gss().navigationController.view animated:YES];
        HUD2.labelText = @"восстановление покупок...";
    }
    [[SKPaymentQueue defaultQueue]restoreCompletedTransactions];
}


-(void) requestProductData:(NSString*)kMyFeatureIdentifier
{
    NSLog(@"^^^ %s %@", __func__, kMyFeatureIdentifier);
   
    if (![SKPaymentQueue canMakePayments]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Покупка книги"
                                                        message:@"Книга не куплена. Возможность покупок отключена в настройках вашего айфона/айпода/айпада."
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        return;
    }
  
    SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:
                                 
                                 [NSSet setWithObject:  kMyFeatureIdentifier]];
    
    request.delegate = self;
    
    [request start];
    HUD2 = [MBProgressHUD showHUDAddedTo:gss().navigationController.view animated:YES];
    HUD2.labelText = @"проверка книги...";
}

//NSArray* myProducts;
- (void) completeTransaction: (SKPaymentTransaction *)transaction

{
    NSLog(@"^^^%s",__func__);
   
    // Your application should implement these two methods.
    
    //[self recordTransaction:transaction];
    
    [[Myshop sharedInstance] startWithBook:transaction.payment.productIdentifier isfree:NO];
    
    
    
    // Remove the transaction from the payment queue.
    
    //[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    currentTransaction = transaction;
    
    if (HUD2) {
        HUD2.labelText = @"регистрация книги...";
    }
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction

{
    NSLog(@"^^^%s", __func__);
  
    //[self recordTransaction: transaction];
    NSString* pid = transaction.originalTransaction.payment.productIdentifier;
    [[Myshop sharedInstance] startWithBook:pid isfree:NO];
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    //currentTransaction = transaction;
    
    if (HUD2) {
        HUD2.labelText = @"восстановление книги...";
    }
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction

{
    NSLog(@"^^^%s", __func__);

    
    [self hideHUD];

    
    if (transaction.error.code != SKErrorPaymentCancelled) {
        
        // Optionally, display an error here.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Покупка книги"
                                                        message:@"книга не куплена :("
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions

{
    NSLog(@"^^^%s", __func__);
    
    if ([transactions count] > 1) {
        if (HUD2) {
            HUD2.labelText = [NSString stringWithFormat:@"Всего покупок %d", [transactions count]];
        }
    }
   
    for (SKPaymentTransaction *transaction in transactions)
        
    {
        
        switch (transaction.transactionState)
        
        {
                
            case SKPaymentTransactionStatePurchased:
                
                [self completeTransaction:transaction];
                
                break;
                
            case SKPaymentTransactionStateFailed:
                
                [self failedTransaction:transaction];
                
                break;
                
            case SKPaymentTransactionStateRestored:
                
                [self restoreTransaction:transaction];
                
            default:
                
                break;
                
        }
        
    }
    
}

NSString* lastInvalidProductId = nil;
UIAlertView* alertViewToCheck = nil;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0 && alertViewToCheck == alertView) {
		[self requestProductData:lastInvalidProductId];
        lastInvalidProductId = nil;
	}
    //	else {
    //		NSLog(@"user pressed Cancel");
    //	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"^^^%s", __func__);
    
    NSArray *product = response.products;
    
    if(product.count > 0)
    {
        SKPayment *payment = [SKPayment paymentWithProduct:[product objectAtIndex:0]];
        if (payment)
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        
        if (HUD2) {
            HUD2.labelText = @"получение покупки...";
        }
    }
    else
    {
        NSLog(@"***err: %s no valid products:%@", __func__, response.invalidProductIdentifiers);
        [self hideHUD];
        if ([response.invalidProductIdentifiers count]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка сервера"
                                                            message:@"Книга не куплена.\nПовторить попытку?"
                                                           delegate:self cancelButtonTitle:@"Нет" otherButtonTitles:@"Да", nil];
            [alert show];
            
            lastInvalidProductId = [response.invalidProductIdentifiers objectAtIndex:0];
            alertViewToCheck = alert;
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка сервера"
                                                            message:@"Книга не куплена."
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    
}

+ (Myshop *)sharedInstance
{    static Myshop *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Myshop alloc] init];
        
        // Do any other initialisation stuff here
        buyDownloadQueue = [[ASINetworkQueue alloc] init];
        [buyDownloadQueue setShouldCancelAllRequestsOnFailure:NO];
        buyDownloadQueue.maxConcurrentOperationCount = 1;
    });
    
    
    //...
    return sharedInstance;
}

@end
