//
//  UTAWebViewManager.h
//  Doome
//
//  Created by David on 16/1/6.
//  Copyright © 2016年 VeryApps. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UTAWebView.h"

@interface UTAWebViewManager : NSObject

@property (nonatomic, strong) NSMutableArray *arrItems;
@property (nonatomic, strong) UTAWebView *currWebView;
@property (nonatomic, assign) NSInteger currIndex;

@property (nonatomic, assign, readonly) NSInteger maxNumbers;

- (UTAWebView *)newWebView;
- (UTAWebView *)newWebViewWithFrame:(CGRect)frame;
- (UTAWebView *)webViewWithLink:(NSString *)link;

- (void)moveWebViewToHeader:(UTAWebView *)webView;
- (void)moveWebViewToFooter:(UTAWebView *)webView;

@end
