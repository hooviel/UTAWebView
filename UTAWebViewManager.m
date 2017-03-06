//
//  UTAWebViewManager.m
//  Doome
//
//  Created by David on 16/1/6.
//  Copyright © 2016年 VeryApps. All rights reserved.
//

#import "UTAWebViewManager.h"

@implementation UTAWebViewManager

@synthesize currIndex = _currIndex;
@synthesize currWebView = _currWebView;

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxNumbers = 10;
        _arrItems = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private methods
- (void)didReceiveMemoryWarning {
    for (UTAWebView *webView in _arrItems) {
        if (webView!=self.currWebView) {
            [webView cleanMemory];
        }
    }
}

#pragma mark - public methods

- (UTAWebView *)newWebView {
    return [self newWebViewWithFrame:CGRectZero];
}

- (UTAWebView *)newWebViewWithFrame:(CGRect)frame {
    UTAWebView *webView = [[UTAWebView alloc] initWithFrame:frame];
    webView.scalesPageToFit = YES;
    [_arrItems addObject:webView];
    return webView;
}

- (UTAWebView *)webViewWithLink:(NSString *)link {
    for (UTAWebView *webView in _arrItems) {
        if ([webView.link isEqualToString:link]) {
            return webView;
        }
    }
    return nil;
}

- (void)moveWebViewToHeader:(UTAWebView *)webView {
    [_arrItems removeObjectIdenticalTo:webView];
    [_arrItems insertObject:webView atIndex:0];
    
    _currIndex = [_arrItems indexOfObjectIdenticalTo:_currWebView];
}

- (void)moveWebViewToFooter:(UTAWebView *)webView {
    [_arrItems removeObjectIdenticalTo:webView];
    [_arrItems addObject:webView];
    
    _currIndex = [_arrItems indexOfObjectIdenticalTo:_currWebView];
}

- (void)setCurrIndex:(NSInteger)currIndex {
    if (NSLocationInRange(currIndex, NSMakeRange(0, _arrItems.count))) {
        _currIndex = currIndex;
        _currWebView = _arrItems[currIndex];
    }
    else {
        _currIndex = NSNotFound;
        _currWebView = nil;
    }
}

- (void)setCurrWebView:(UTAWebView *)currWebView {
    if ([_arrItems containsObject:currWebView]) {
        _currWebView = currWebView;
        _currIndex = [_arrItems indexOfObjectIdenticalTo:currWebView];
    }
    else {
        _currIndex = NSNotFound;
        _currWebView = nil;
    }
}

- (NSInteger)currIndex {
    if (_currWebView && [_arrItems containsObject:_currWebView]) {
        _currIndex = [_arrItems indexOfObjectIdenticalTo:_currWebView];
    }
    else {
        _currIndex = NSNotFound;
        _currWebView = nil;
    }
    
    return _currIndex;
}

@end
