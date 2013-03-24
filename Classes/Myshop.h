//
//  AppStore.h
//  audiobook
//
//  Created by User on 09.03.13.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface Myshop : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    
}
+ (Myshop *)sharedInstance;

//********** Myshop part
-(BOOL)startWithBook:(NSString*)bid isfree:(BOOL)free;

//********** Appstore part
-(void) restorePurchases;
//@property (nonatomic, strong) Myshop* delegate;
-(void) requestProductData:(NSString*)kMyFeatureIdentifier;
@end
