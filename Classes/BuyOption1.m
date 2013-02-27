//
//  BuyOption1.m
//  audiobook
//
//  Created by User on 22.02.13.
//
//

#import "BuyOption1.h"
#import "ASIHTTPRequest.h"
#import "gs.h"
#import "PlayerViewController.h"

@implementation BuyOption1

static ASIHTTPRequest* currentRequest = nil;


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


- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSError* error;
    NSString* response = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[gss() pathForBuy:[[request.userInfo objectForKey:@"bid" ] intValue]] ] encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"++Finished buy option1: %@", response);
    NSRange r = [response rangeOfString:@"yes"];
    if ((response && r.location != NSNotFound) && request.responseStatusCode == 200)
    {
       int isfree = [[request.userInfo valueForKey:@"isfree"] intValue];
        if (isfree) {
             NSString *devhash = [gs md5: [[[UIDevice currentDevice] identifierForVendor] UUIDString]];
             NSArray *arr = [gs srvArrForUrl:[NSString stringWithFormat:@"http://%@/free1closecode.php?dev=%@&bookid=%@", AppConnectionHost, devhash,[request.userInfo objectForKey:@"bid" ]] xpath:@"//canuse" message:[NSString stringWithFormat:@"**err:unable to request success to close code: %s", __func__ ]];
            NSString* canuse = [arr objectAtIndex:0];
            NSLog(@"++close code: %@", canuse);
//            if (![canuse isEqualToString:@"yes"]) {
//                ,
//            }
        }

        [StaticPlayer buyBook];
        
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
    NSLog(@"**err: request failed description %@, url: %@", [request.error description], [request url]);
}


-(BOOL)startWithBook:(int)bid isfree:(BOOL)free
{
    if (currentRequest && !currentRequest.complete) {
        return NO;
    }
    
    // create main request
    NSString *devhash = [gs md5: [[[UIDevice currentDevice] identifierForVendor] UUIDString]];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/buy.php?bid=%d&dev=%@&bt=1", AppConnectionHost, bid, devhash]];
    currentRequest = [ASIHTTPRequest requestWithURL:url];
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
    NSNumber* nBid = [NSNumber numberWithInt: bid];
    NSNumber* bookfree = [NSNumber numberWithInt: free];
    [currentRequest setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                nBid, @"bid", bookfree, @"isfree",  nil]];
    [currentRequest startAsynchronous];
    
    
    return YES;
}


+ (BuyOption1 *)sharedInstance
{
    static BuyOption1 *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BuyOption1 alloc] init];
        // Do any other initialisation stuff here
        
    });
    
    
    //...
    return sharedInstance;
}
@end
