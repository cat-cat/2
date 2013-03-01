//
//  Free1ViewController.m
//  audiobook
//
//  Created by User on 22.02.13.
//
//

#import "Free1ViewController.h"
#import "ASIHTTPRequest.h"
#import "gs.h"
#import "DDXMLDocument.h"

enum FreeOps {FO_GETCODE, FO_CHECKCODE, FO_GETBOOK};

@interface Free1ViewController ()

@end

@implementation Free1ViewController
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

- (void) handleGetcode:(ASIHTTPRequest*)request
{
    NSString* str = [request responseString];
    if (str && [str rangeOfString:@"yes"].location != NSNotFound) {
        NSError* error;
        DDXMLDocument* doc = [[DDXMLDocument alloc] initWithXMLString:str options:0 error:&error];
        [gss() handleError:error];
        NSArray* arr = [gss() arrayForDoc:doc xpath:@"//code"];
        NSAssert1([arr count], @"**err: no code!: %s", __func__);
        txtCode.text = [arr objectAtIndex:0];
    }
}

-(void)handleCheckcode:(ASIHTTPRequest*)request
{
    NSString* str = [request responseString];
    
    if (str && [str rangeOfString:@"yes"].location != NSNotFound) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Поздравляем!"
                                                        message:@"Проверка кода успешна! Теперь вы можете выбрать для бесплатного прослушивания 1 любую книгу."
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Проверка кода"
                                                        message:@"Ошибка проверки кода! проверьте email и код и повторите попытку"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];        
    }
}

-(void)handleGetbook:(ASIHTTPRequest*)request
{
    
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    switch (request.tag) {
        case FO_GETCODE:
            [self handleGetcode:request];
            break;
        case FO_CHECKCODE:
            [self handleCheckcode:request];
            break;
        case FO_GETBOOK:
            [self handleGetbook:request];
            
        default:
            break;
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"**err: request failed description %@, url: %@", [request.error description], [request url]);
    
    // TODO: message to user request failed
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)getCode:(UIButton *)sender {
    // TODO: check email format
    NSLog(@"++txtEmail: %@", txtEmail.text);
    
    if (currentRequest && !currentRequest.complete) {
        // TODO: message to the user
        return;
    }
    
    // create main request
    NSString *devid =  [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/free1getcode.php?dev=%@&email=%@", AppConnectionHost, devid, txtEmail.text]];
    currentRequest = [ASIHTTPRequest requestWithURL:url];
    [currentRequest setDelegate:self];
    [currentRequest setDownloadProgressDelegate:self];
    [currentRequest setTag:FO_GETCODE];
    [currentRequest startAsynchronous];
}

- (IBAction)checkCode:(UIButton *)sender {
    NSLog(@"++txtCode: %@", txtCode.text);
    
    if (currentRequest && !currentRequest.complete) {
        // TODO: message to the user
        return;
    }
    
    // create main request
    NSString *devid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/free1setcode.php?dev=%@&email=%@&code5=%@", AppConnectionHost, devid, txtEmail.text, txtCode.text]];
    currentRequest = [ASIHTTPRequest requestWithURL:url];
    [currentRequest setDelegate:self];
    [currentRequest setDownloadProgressDelegate:self];
    [currentRequest setTag:FO_CHECKCODE];
    [currentRequest startAsynchronous];
}

//************ constant staff
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [txtCode setDelegate:self];
    [txtEmail setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    txtEmail = nil;
    txtCode = nil;
    [super viewDidUnload];
}

@end
