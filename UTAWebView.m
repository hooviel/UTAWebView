//
//  UTAWebView.m
//  Doome
//
//  Created by David on 15/12/27.
//  Copyright © 2015年 VeryApps. All rights reserved.
//

#import "UTAWebView.h"

#import <CommonCrypto/CommonDigest.h>
#import "NJKWebViewProgress.h"
#import "Masonry.h"
#import "MJRefresh.h"
#import "NSString+URL.h"

#define kNewWindowScheme @"utanewwindow"
#define kBundleName @"UTAWebView.bundle"
#define kTableName @"UTAWebView"
#define UTAWebViewBundleCache @"com.utawebview.cache"

#pragma mark - UnpreventableUILongPressGestureRecognizer

@interface UnpreventableUILongPressGestureRecognizer : UILongPressGestureRecognizer

@end

@implementation UnpreventableUILongPressGestureRecognizer

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    return NO;
}

@end

static const void *UserDataKey = &UserDataKey;

@interface UIView (UTAWebView)

@property (nonatomic, strong) id userData;

@end

@implementation UIView (UTAWebView)

@dynamic userData;

#pragma mark - property
- (id)userData {
    id obj = objc_getAssociatedObject(self, UserDataKey);
    return obj;
}

- (void)setUserData:(id)userData {
    id obj = objc_getAssociatedObject(self, UserDataKey);
    if (obj)
        objc_removeAssociatedObjects(self);
    
    if(userData)
        objc_setAssociatedObject(self, UserDataKey, userData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


#pragma mark - UIViewReloadWeb
/*!
 *  当页面有错误的时候比如：超时，断网 的情况下显示一个重新加载的页面提示界面
 */
@interface UIViewReloadWeb : UIControl {
    UILabel *_labelFailureReason;
    UIButton *_btnReload;
}

@property (nonatomic, copy) NSString *failureReason;

@end

@implementation UIViewReloadWeb

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _instance];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _instance];
    }
    return self;
}

- (void)_instance {
    _labelFailureReason = [[UILabel alloc] init];
    _labelFailureReason.numberOfLines = 0;
    _labelFailureReason.textAlignment = NSTextAlignmentCenter;
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kBundleName]];
    
    _btnReload = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnReload setTitle:NSLocalizedStringFromTableInBundle(@"reload", kTableName, bundle, nil) forState:UIControlStateNormal];
    [_btnReload setImage:[UIImage imageNamed:@"btn_refresh"] forState:UIControlStateNormal];
    _btnReload.contentEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 14);
    _btnReload.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [_btnReload setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _btnReload.titleLabel.font = [UIFont systemFontOfSize:14];
    
    [self addSubview:_labelFailureReason];
    [self addSubview:_btnReload];
    [_btnReload sizeToFit];
    _btnReload.layer.cornerRadius = 8;
    _btnReload.layer.borderWidth = 0.5;
    _btnReload.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
    _btnReload.layer.masksToBounds = YES;
    _btnReload.tintColor = [UIColor darkGrayColor];
    
    [_btnReload mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self);
    }];
    
    [_labelFailureReason mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(_btnReload.mas_top).offset(-10);
        make.leading.greaterThanOrEqualTo(self).multipliedBy(0.8);
    }];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [_btnReload addTarget:target action:action forControlEvents:controlEvents];
}

- (void)setFailureReason:(NSString *)failureReason {
    _failureReason = [failureReason copy];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:failureReason?:@""];
    NSRange range = NSMakeRange(0, mas.length);
    [mas addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:range];
    [mas addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:range];
    _labelFailureReason.attributedText = mas;
}

@end

#pragma mark - UTAWebView
@interface UTAWebView () <UIWebViewDelegate, NJKWebViewProgressDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate>
{
    NJKWebViewProgress *_progress;
    NSDictionary *_dictActionTitle;
    NSBundle *_bundle;
    
    NSString *_titleForReload;
    NSString *_linkForReload;
    UIImageView *_imageViewSnap;
    UIImageView *_imageViewLogo;
    UIView *_viewCover;
    UIView *_viewLogo;
    UIViewReloadWeb *_viewReload;
}

@end

@implementation UIWebView (UTAWebView)

- (NSString *)title {
    return [self stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (NSString *)link {
    return [self stringByEvaluatingJavaScriptFromString:@"window.location.href"];
}

- (CGSize)windowSize {
    CGSize size;
    size.width = [[self stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
    size.height = [[self stringByEvaluatingJavaScriptFromString:@"window.innerHeight"] integerValue];
    return size;
}

- (CGPoint)scrollOffset {
    CGPoint pt;
    pt.x = [[self stringByEvaluatingJavaScriptFromString:@"window.pageXOffset"] integerValue];
    pt.y = [[self stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] integerValue];
    return pt;
}

@end

@implementation UTAWebView

@synthesize snap = _snap;

- (NSString *)link {
    if (_cleanedMemory) {
        return _linkForReload;
    }
    else {
        return [super link];
    }
}

- (NSString *)title {
    if (_cleanedMemory) {
        return _titleForReload;
    }
    else {
        return [super title];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _instance];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _instance];
    }
    return self;
}

- (void)_instance {
    _hasSnap = NO;
    _timeoutSeconds = 10;
    _arrAllowedAction = @[@(UTAWebViewActionOpenAtSelf),
                          @(UTAWebViewActionOpenAtNewWindow),
                          @(UTAWebViewActionOpenAtBackground),
                          @(UTAWebViewActionOpenWithSafari),
                          @(UTAWebViewActionCopyLink),
                          @(UTAWebViewActionCopyImageSrc),
                          @(UTAWebViewActionSaveImage)].mutableCopy;
    _arrAllowedScheme = @[@"http", @"https", @"file", @"ftp", @"utanewwindow", @"itms-apps", @"about", @"applewebdata"].mutableCopy;
    
    _bundle = [NSBundle bundleWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kBundleName]];
    _dictActionTitle = @{NSLocalizedStringFromTableInBundle(@"dangqianchuangkoudakai", kTableName, _bundle, nil):@(UTAWebViewActionOpenAtSelf),
                         NSLocalizedStringFromTableInBundle(@"xinchuangkoudakai", kTableName, _bundle, nil):@(UTAWebViewActionOpenAtNewWindow),
                         NSLocalizedStringFromTableInBundle(@"houtaidakai", kTableName, _bundle, nil):@(UTAWebViewActionOpenAtBackground),
                         NSLocalizedStringFromTableInBundle(@"safari_dakai", kTableName, _bundle, nil):@(UTAWebViewActionOpenWithSafari),
                         NSLocalizedStringFromTableInBundle(@"fuzhilianjie", kTableName, _bundle, nil):@(UTAWebViewActionCopyLink),
                         NSLocalizedStringFromTableInBundle(@"fuzhitupiandizhi", kTableName, _bundle, nil):@(UTAWebViewActionCopyImageSrc),
                         NSLocalizedStringFromTableInBundle(@"baocuntupian", kTableName, _bundle, nil):@(UTAWebViewActionSaveImage)};
    
    self.scalesPageToFit = YES;
    self.scrollView.maximumZoomScale = 1.5;
    _progress = [[NJKWebViewProgress alloc] init];
    _progress.progressDelegate = self;
    _progress.webViewProxyDelegate = self;
    self.delegate = _progress;
    
    UnpreventableUILongPressGestureRecognizer *longPressGesture = [[UnpreventableUILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    longPressGesture.allowableMovement = 20;
    longPressGesture.minimumPressDuration = 1.0f;
    [self addGestureRecognizer:longPressGesture];

    self.canDragRrefresh = YES;
}

- (void)dealloc {
    _progress.progressDelegate = nil;
    _progress.webViewProxyDelegate = nil;
    _progress = nil;
    self.webViewDelegate = nil;
    self.delegate = nil;
    
    [self stopLoading];
    
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - super methods
- (void)setDelegate:(id<UIWebViewDelegate>)delegate
{
    [super setDelegate:_progress];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL shouldReq = NO;
    do {
        // 过滤scheme
        NSString *scheme = [request.URL.scheme lowercaseString];
        if (![_arrAllowedScheme containsObject:scheme]) {
            break;
        }
        
        if ([scheme isEqualToString:kNewWindowScheme]) {
            NSString *link = [request.URL.resourceSpecifier stringByRemovingPercentEncoding]?:request.URL.resourceSpecifier;
            
            NSMutableCharacterSet *mcs = [NSCharacterSet URLFragmentAllowedCharacterSet].mutableCopy;
            [mcs addCharactersInString:@":/=?"];
            link = [link stringByAddingPercentEncodingWithAllowedCharacters:mcs];
            [self load:link];
            break;
        }
        if ([scheme isEqualToString:@"itms-apps"]) {
            break;
        }
        
        if (UIWebViewNavigationTypeLinkClicked==navigationType) {
            _titleForReload = [request.URL.absoluteString copy];
            _linkForReload = [request.URL.absoluteString copy];
        }
        
        if ([_webViewDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
            shouldReq = [_webViewDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
            break;
        }
        
        shouldReq = YES;
    } while (NO);
    return shouldReq;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if ([_webViewDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_webViewDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.link.length==0||[webView.request.URL.scheme isEqualToString:@"about"]||[webView.request.URL.scheme isEqualToString:@"applewebdata"]) {
        return;
    }

    [self insertJS];
    
    if ([_webViewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_webViewDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(nonnull NSError *)error {
    switch (error.code) {
        case NSURLErrorTimedOut: {
            /*
             如果网页获取不到主机地址，说明从来没有加载成功过，可以认为是当前网页超时
             如果超时的主机地址和当前网页的主机地址相同，则认为是网页超时
             */
            NSURL *urlError = error.userInfo[NSURLErrorFailingURLErrorKey];
            if (webView.request.URL.host && ![urlError.host isEqualToString:webView.request.URL.host])
                break;
        }
        case NSURLErrorNotConnectedToInternet: {
            [self createReloadView];
            NSString *link = [_linkForReload stringByRemovingPercentEncoding];
            link=link?:_linkForReload;
            _viewReload.failureReason = [link stringByAppendingFormat:@"\n\n%@", error.localizedDescription];
            
            [webView loadHTMLString:@"" baseURL:nil];
        } break;
            
        default:
            break;
    }
    
    if ([_webViewDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_webViewDelegate webView:webView didFailLoadWithError:error];
    }
}

#pragma mark - NJKWebViewProgressDelegate
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (1<=progress) {
        [self dismissCoverWithAnimated:YES];
    } else {
        [self performSelector:@selector(flushProgress) withObject:nil afterDelay:_timeoutSeconds];
    }
    
    if ([_webViewDelegate respondsToSelector:@selector(webView:updateProgress:)]) {
        [_webViewDelegate webView:self updateProgress:progress];
    }
}

- (void)flushProgress {
    NSLog(@"%s:%@", __FUNCTION__, @(_progress.progress));
//    [self stopLoading];
    [self dismissCoverWithAnimated:YES];
}

#pragma mark - private
/**
 *  网页 长按 手势
 *
 *  @param longPressGesture
 */
- (void)longPressGesture:(UnpreventableUILongPressGestureRecognizer *)longPressGesture {
    if (_isFindInPageMode) return;
    
    // 正在执行 页内查找 操作 不允许
    if (UIGestureRecognizerStateBegan==longPressGesture.state) {
        UIWebView *webView = (UIWebView *)longPressGesture.view;
        CGPoint point = [longPressGesture locationInView:webView];
        
        // convert point from view to HTML coordinate system
        CGSize viewSize = [self frame].size;
        CGSize windowSize = [self windowSize];
        
        CGFloat f = windowSize.width / viewSize.width;
        if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 5.) {
            point.x = point.x * f;
            point.y = point.y * f;
        } else {
            // On iOS 4 and previous, document.elementFromPoint is not taking
            // offset into account, we have to handle it
            CGPoint offset = [self scrollOffset];
            point.x = point.x * f + offset.x;
            point.y = point.y * f + offset.y;
        }
        
        // Load the JavaScript code from the Resources and inject it into the web page
        NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"UTAWebView.bundle/js/JSTools.js"];
        NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        [webView stringByEvaluatingJavaScriptFromString: jsCode];
        
        // get the Tags at the touch location
        NSString *tags = [webView stringByEvaluatingJavaScriptFromString:
                          [NSString stringWithFormat:@"MyAppGetHTMLElementsAtPoint(%li,%li);",(long)point.x,(long)point.y]];
        
        NSString *tagsHREF = [webView stringByEvaluatingJavaScriptFromString:
                              [NSString stringWithFormat:@"MyAppGetLinkHREFAtPoint(%li,%li);",(long)point.x,(long)point.y]];
        
        NSString *tagsSRC = [webView stringByEvaluatingJavaScriptFromString:
                             [NSString stringWithFormat:@"MyAppGetLinkSRCAtPoint(%li,%li);",(long)point.x,(long)point.y]];
        
        NSArray *arrA = [tagsHREF componentsSeparatedByString:@","];
        NSArray *arrIMG = [tagsSRC componentsSeparatedByString:@","];
        
        NSString *href = nil;
        NSString *src = nil;
        if ([tags rangeOfString:@",A,"].location != NSNotFound) {
            href = arrA[1];
            NSURL *url = [NSURL URLWithString:href];
            if ([url.scheme isEqualToString:kNewWindowScheme]) {
                href = [url.resourceSpecifier stringByRemovingPercentEncoding]?:url.resourceSpecifier;
                
                NSMutableCharacterSet *mcs = [NSCharacterSet URLFragmentAllowedCharacterSet].mutableCopy;
                [mcs addCharactersInString:@":/=?"];
                href = [href stringByAddingPercentEncodingWithAllowedCharacters:mcs];
            }
        }
        if ([tags rangeOfString:@",IMG,"].location != NSNotFound) {
            src = arrIMG[1];
        }
        
        if (![href isURLString]) {
            href = nil;
        }
        if (![src isURLString]) {
            src = nil;
        }
        
        if (href.length>0 || src.length>0) {
            UIActionSheet *actionSheet;
            if (src) {
                actionSheet =[self actionSheetWithLink:href imageSrc:src];
            }
            else {
                // 网址
                actionSheet =[self actionSheetWithLink:href];
            }
            actionSheet.delegate = self;
            NSMutableDictionary *dictInfo = @{}.mutableCopy;
            if (href.length>0) {
                dictInfo[@"link"] = href;
            }
            if (src.length>0) {
                dictInfo[@"imgsrc"] = src;
            }
            actionSheet.userData = dictInfo;
            
            if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
                [actionSheet showFromRect:CGRectMake(point.x, point.y, 0, 0) inView:[[UIApplication sharedApplication] keyWindow].rootViewController.view animated:YES];
            }
            else {
                [actionSheet showInView:[[UIApplication sharedApplication] keyWindow].rootViewController.view];
            }
        }
    }
}

- (UIActionSheet *)actionSheetWithLink:(NSString *)link imageSrc:(NSString *)imageSrc {
    NSString *safari;
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenWithSafari)]) {
        safari = NSLocalizedStringFromTableInBundle(@"safari_dakai", kTableName, _bundle, nil);
    }
    
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:link.length>0?link:imageSrc delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"quxiao", kTableName, _bundle, nil) destructiveButtonTitle:safari otherButtonTitles:nil];
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenAtSelf)]) {
        // 当前窗口打开
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"dangqianchuangkoudakai", kTableName, _bundle, nil)];
    }
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenAtNewWindow)]) {
        // 新窗口打开
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"xinchuangkoudakai", kTableName, _bundle, nil)];
    }
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenAtBackground)]) {
        // 后台打开
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"houtaidakai", kTableName, _bundle, nil)];
    }
    
    if (link.length>0 && [_arrAllowedAction containsObject:@(UTAWebViewActionCopyLink)]) {
        // 复制链接
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"fuzhilianjie", kTableName, _bundle, nil)];
    }
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionCopyImageSrc)]) {
        // 复制图片链接
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"fuzhitupiandizhi", kTableName, _bundle, nil)];
    }
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionSaveImage)]) {
        // 保存图片
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"baocuntupian", kTableName, _bundle, nil)];
    }
    return as;
}

- (UIActionSheet *)actionSheetWithLink:(NSString *)link {
    NSString *safari;
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenWithSafari)]) {
        safari = NSLocalizedStringFromTableInBundle(@"safari_dakai", kTableName, _bundle, nil);
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:link delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"quxiao", kTableName, _bundle, nil) destructiveButtonTitle:safari otherButtonTitles:nil];
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenAtSelf)]) {
        // 当前窗口打开
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"dangqianchuangkoudakai", kTableName, _bundle, nil)];
    }
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenAtNewWindow)]) {
        // 新窗口打开
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"xinchuangkoudakai", kTableName, _bundle, nil)];
    }
    
    if ([_arrAllowedAction containsObject:@(UTAWebViewActionOpenAtBackground)]) {
        // 后台打开
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"houtaidakai", kTableName, _bundle, nil)];
    }
    
    if (link.length>0 && [_arrAllowedAction containsObject:@(UTAWebViewActionCopyLink)]) {
        // 复制链接
        [as addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"fuzhilianjie", kTableName, _bundle, nil)];
    }
    return as;
}

- (void)insertJS
{
    NSString *file;
    NSString *js;
    
    // 自定义长按选择
    [self stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
    [self stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    
    // 注入 JS（修改打开链接方式）
    file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"UTAWebView.bundle/js//handle.js"];
    js = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    [self stringByEvaluatingJavaScriptFromString:js];
    [self stringByEvaluatingJavaScriptFromString:@"MyIPhoneApp_Init();"];
}

- (NSString *)md5WithString:(NSString *)str {
    const char *cStr = [str?str:@"" UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (uint32_t)strlen(cStr), result );
    NSString *md5 = [[NSString stringWithFormat:
                      @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                      result[0], result[1], result[2], result[3],
                      result[4], result[5], result[6], result[7],
                      result[8], result[9], result[10], result[11],
                      result[12], result[13], result[14], result[15]] lowercaseString];
    return md5;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (![_webViewDelegate respondsToSelector:@selector(webView:msgType:msg:)]) return;
    
    if (error) {
        [_webViewDelegate webView:self msgType:UTAWebViewMsgTypeError msg:[error.localizedFailureReason stringByAppendingFormat:@"\n%@", error.localizedRecoverySuggestion?:@""]];
    }
    else {
        [_webViewDelegate webView:self msgType:UTAWebViewMsgTypeSuccess msg:NSLocalizedStringFromTableInBundle(@"tupianbaocunchenggong", kTableName, _bundle, nil)];
    }
}

#pragma mark - public  页内查找
/**
 *  开始页内查找模式
 */
- (void)beginFindInPage
{
    _isFindInPageMode = YES;
    
    NSString *resPath = [[NSBundle mainBundle] resourcePath];
    static NSString *jsQuery = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jsQuery = [NSString stringWithContentsOfFile:[resPath stringByAppendingPathComponent:@"UTAWebView.bundle/js/js_plugins.js"] encoding:NSUTF8StringEncoding error:nil];
        
        jsQuery = [NSString stringWithFormat:@"var highlightPlugin = document.getElementById('js_plugins'); \
                   if (highlightPlugin == undefined) { \
                   document.body.innerHTML += '<div id=\"js_plugins\"> \
                   <style type=\"text/css\"> \
                   .utaHighlight { background-color:#0000FF; color:#FFFFFF;} \
                   .selectSpan { background-color:#FF0000; color:#FFFFFF; font-weight:bold; font-size:150%%} \
                   </style> \
                   </div>'; \
                   %@ \
                   }", jsQuery];
    });
    
    [self stringByEvaluatingJavaScriptFromString:jsQuery];
}

/**
 *  结束页内查找
 */
- (void)endFindInPage
{
    _numberOfKeyword = 0;
    _indexOfKeyrowd = 0;
    _isFindInPageMode = NO;
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"jQuery('body').removeHighlight();"]];
}

/**
 *  查找关键字
 *
 *  @param keyword 关键字
 *
 *  @return NSInteger 查找到的总数量
 */
- (NSInteger)findInPageWithKeyword:(NSString *)keyword
{
    if (!_isFindInPageMode) return 0;
    
    _numberOfKeyword = 0;
    _indexOfKeyrowd = 0;
    
    // 清除上次的高亮并设置当前关键字高亮
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"jQuery('body').removeHighlight().utaHighlight('%@');", keyword]];
    
    // 获取关键字数量
    NSString *total = [self stringByEvaluatingJavaScriptFromString:@"jQuery('.utaHighlight').length"];
    _numberOfKeyword = [total integerValue];
    
    // 默认滚动到第一个关键字
    if (_numberOfKeyword>0) {
        [self scrollToKeywordIndex:0];
    }
    
    return _numberOfKeyword;
}

/**
 *  滚动到 第几个关键字
 *
 *  @param integer 索引
 */
- (void)scrollToKeywordIndex:(NSInteger)index
{
    _indexOfKeyrowd = index;
    
    NSString *js = [NSString stringWithFormat:@"scrollToFindIdx(%ld);", (long)_indexOfKeyrowd];
    CGFloat offset = [[self stringByEvaluatingJavaScriptFromString:js] floatValue];
    offset = MAX(0, offset+40-self.bounds.size.height);
    
    CGFloat contentHeight = self.scrollView.contentSize.height;
    offset = MIN(offset, contentHeight-self.scrollView.bounds.size.height);
    [self.scrollView setContentOffset:CGPointMake(0, offset) animated:YES];
}

- (void)scrollToPrevKeyword
{
    if (!_isFindInPageMode || 0==_indexOfKeyrowd) return;
    
    [self scrollToKeywordIndex:--_indexOfKeyrowd];
}

- (void)scrollToNextKeyword
{
    if (!_isFindInPageMode || (_numberOfKeyword-1)<=_indexOfKeyrowd) return;
    
    [self scrollToKeywordIndex:++_indexOfKeyrowd];
}

#pragma mark - public
- (void)setFontScale:(CGFloat)fontScale {
    if (fontScale!=_fontScale) {
        _fontScale = fontScale;
        
        NSString *js = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%@%%'", @(_fontScale*100)];
        [self stringByEvaluatingJavaScriptFromString:js];
    }
}

- (void)setCanDragRrefresh:(BOOL)canDragRrefresh {
    _canDragRrefresh = canDragRrefresh;
    if (_canDragRrefresh) {
        __weak typeof(self) wself = self;
        MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            [wself reload];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself.scrollView.mj_header endRefreshing];
            });
        }];
        header.stateLabel.hidden = YES;
        header.lastUpdatedTimeLabel.hidden = YES;
        self.scrollView.mj_header = header;
    }
    else {
        self.scrollView.mj_header = nil;
    }
}

- (void)load:(NSString *)link {
    _titleForReload = [link copy];
    _linkForReload = [link copy];
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_timeoutSeconds]];
}

/*!
 *  清理内存,
 *  需要保存快照，对应的函数为：reload
 */
- (void)cleanMemory {
    if (YES==_cleanedMemory) {
        return;
    }
    
    [self saveSnap];
    
    _titleForReload = [self.title copy];
    _linkForReload = [self.link copy];
    _cleanedMemory = YES;
    [self loadHTMLString:@"" baseURL:nil];
}

/*!
 *  需要检查是否清除过缓存，是：load清除缓存前保存的链接地址，否则直接调用super reload
 */
- (void)reload {
    if (_hasSnap) {
        [UIView animateWithDuration:0.5 animations:^{
            _imageViewSnap.alpha = 0;
        } completion:^(BOOL finished) {
            [_imageViewSnap removeFromSuperview];
            _imageViewSnap = nil;
            _snap = nil;
            _hasSnap = NO;
        }];
    }
    
    if (_cleanedMemory || _viewReload) {
        [self load:_linkForReload];
        _cleanedMemory = NO;
        [_viewReload removeFromSuperview];
        _viewReload = nil;
    } else {
        [super reload];
    }
    
    if (!self.userInteractionEnabled) {
        self.userInteractionEnabled = YES;
    }
}

- (BOOL)isLoading {
    if (_progress.progress<1) {
        return [super isLoading];
    } else {
        return NO;
    }
}

/*!
 *  保存快照，对应的恢复函数为：restoreSnap，删除快照，然后检查是否清除过缓存，是：load清除缓存前保存的链接地址，否则无操作
 */
- (void)saveSnap {
    // 清除过内存，一定有快照 有快照就不需要再保存快照了
    if (_hasSnap||_cleanedMemory) return;
    
    self.userInteractionEnabled = NO;
    _imageViewSnap = [[UIImageView alloc] initWithImage:self.snap];
    _imageViewSnap.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    _imageViewSnap.contentMode = UIViewContentModeScaleAspectFill;
    _imageViewSnap.clipsToBounds = YES;
    _imageViewSnap.frame = self.bounds;
    _imageViewSnap.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self addSubview:_imageViewSnap];
    
    _hasSnap = YES;
}

/*!
 *  恢复快照，从快照返回到真实网页内容
 *  1、检查是否清除过缓存，是：load清除缓存前保存的链接地址，否则无操作
 *  2、删除快照
 */
- (void)restoreSnap {
    if (_cleanedMemory) {
        [self reload];
    }
    
    if (_hasSnap) {
        self.userInteractionEnabled = YES;
        [UIView animateWithDuration:0.5 animations:^{
            _imageViewSnap.alpha = 0;
        } completion:^(BOOL finished) {
            [_imageViewSnap removeFromSuperview];
            _imageViewSnap = nil;
            _snap = nil;
        }];
        _hasSnap = NO;
    }
}

/*!
 *  得到快照
 *
 *  @return UIImage 快照图
 */
- (UIImage *)snap {
    if (!_hasSnap) {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [self.layer renderInContext:ctx];
        _snap = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return _snap;
}

- (void)createReloadView {
    self.userInteractionEnabled = YES;
    if (!_viewReload) {
        _viewReload = [[UIViewReloadWeb alloc] init];
        [_viewReload addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_viewReload];
        [_viewReload mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        _viewReload.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    }
}

/*!
 *  显示logo，第一次加载或从非前端切换到前端时候显示
 *
 *  @param logo     logo视图
 *  @param logoSize 初始化大小
 *  @param animated 是否动画
 */
- (void)showCoverWithLogo:(UIView *)logo logoSize:(CGSize)logoSize animated:(BOOL)animated {
    _showCover = YES;
    
    [_viewLogo.layer removeAllAnimations];
    [_viewLogo removeFromSuperview];
    _viewLogo = nil;
    
    [_viewCover removeFromSuperview];
    _viewCover = nil;
    
    self.userInteractionEnabled = NO;
    _viewCover = [[UIView alloc] init];
    _viewCover.backgroundColor = [UIColor whiteColor];
    [self addSubview:_viewCover];
    [_viewCover mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    if (logo) {
        _viewLogo = logo;
        [_viewCover addSubview:_viewLogo];
        [_viewLogo mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_viewCover);
            make.size.equalTo([NSValue valueWithCGSize:logoSize]);
        }];
    }
    [self layoutIfNeeded];
    
    if (_viewLogo && animated) {
        [self startLogoAnimation];
    }
}

- (void)dismissCoverWithAnimated:(BOOL)animated {
    if (!_viewCover) {
        return;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _viewCover.alpha = 0;
        } completion:^(BOOL finished) {
            [_viewLogo.layer removeAllAnimations];
            [_viewCover removeFromSuperview];
            _viewCover = nil;
            self.userInteractionEnabled = YES;
            _showCover = NO;
        }];
    } else {
        [_viewLogo.layer removeAllAnimations];
        [_viewCover removeFromSuperview];
        _viewCover = nil;
        self.userInteractionEnabled = YES;
        _showCover = NO;
    }
}

- (void)startLogoAnimation {
    [_viewLogo.layer removeAllAnimations];
    
    CABasicAnimation *animScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animScale.fromValue = [NSValue valueWithCGPoint:CGPointMake(0.9, 0.9)];
    animScale.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
    
    CABasicAnimation *animOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animOpacity.fromValue = @(0.5);
    animOpacity.toValue = @(1);
    
    CAAnimationGroup *animGroup = [CAAnimationGroup animation];
    animGroup.animations = @[animScale, animOpacity];
    
    animGroup.autoreverses = YES;
    animGroup.duration = 0.5;
    animGroup.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.8 :0.1 :0.95 :0.95];
    animGroup.repeatCount = MAXFLOAT;
    [_viewLogo.layer addAnimation:animGroup forKey:@"group"];
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex==buttonIndex) {
        return;
    }
    
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    __block UTAWebViewAction webViewAction;
    [_dictActionTitle enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([title isEqualToString:key]) {
            webViewAction = [obj integerValue];
            *stop = YES;
        }
    }];
    
    NSString *link = actionSheet.userData[@"link"];
    NSString *imgSrc = actionSheet.userData[@"imgsrc"];
    switch (webViewAction) {
        case UTAWebViewActionOpenAtSelf: {
            [self load:link?:imgSrc];
        }break;
        case UTAWebViewActionOpenAtNewWindow:
        case UTAWebViewActionOpenAtBackground: {
            if ([_webViewDelegate respondsToSelector:@selector(webView:action:obj:)]) {
                [_webViewDelegate webView:self action:webViewAction obj:link?:imgSrc];
            }
        }break;
        case UTAWebViewActionOpenWithSafari: {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link?:imgSrc]];
        }break;
        case UTAWebViewActionCopyLink: {
            // 复制链接
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = link;
            if ([_webViewDelegate respondsToSelector:@selector(webView:msgType:msg:)]) {
                [_webViewDelegate webView:self msgType:UTAWebViewMsgTypeSuccess msg:NSLocalizedStringFromTableInBundle(@"lianjieyifuzhi", kTableName, _bundle, nil)];
            }
        }break;
        case UTAWebViewActionCopyImageSrc: {
            // 复制图片链接
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = imgSrc;
            if ([_webViewDelegate respondsToSelector:@selector(webView:msgType:msg:)]) {
                [_webViewDelegate webView:self msgType:UTAWebViewMsgTypeSuccess msg:NSLocalizedStringFromTableInBundle(@"tupiandizhiyifuzhi", kTableName, _bundle, nil)];
            }
        }break;
        case UTAWebViewActionSaveImage: {
            
            do {
                NSCachedURLResponse *resp = [[NSURLCache sharedURLCache] cachedResponseForRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imgSrc]]];
                UIImage *image = [UIImage imageWithData:resp.data];
                if (image) {
                    // TODO: 保存图片
                    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                    break;
                }
                
                NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
                cacheFolder = [cacheFolder stringByAppendingPathComponent:UTAWebViewBundleCache];
                if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFolder]) {
                    [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:nil];
                }
                NSString *cacheFilepath = [cacheFolder stringByAppendingPathComponent:[self md5WithString:imgSrc]];
                image = [UIImage imageWithContentsOfFile:cacheFilepath];
                if (image) {
                    // TODO: 保存图片
                    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                    break;
                }
                
                // 下载
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgSrc]];
                    UIImage *image = [UIImage imageWithData:data];
                    if(image) {
                        [data writeToFile:cacheFilepath atomically:YES];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            // TODO: 保存图片
                            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                        });
                    }
                });
                
            } while (NO);
        }break;
            
        default:
            break;
    }
}

@end
