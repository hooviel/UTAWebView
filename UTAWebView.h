//
//  UTAWebView.h
//  Doome
//
//  Created by David on 15/12/27.
//  Copyright © 2015年 VeryApps. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NJKWebViewProgress.h"

typedef NS_ENUM(NSInteger, UTAWebViewAction) {
    UTAWebViewActionOpenAtNewWindow     =1<<0,
    UTAWebViewActionOpenAtBackground    =1<<1,
    UTAWebViewActionOpenAtSelf          =1<<2,
    UTAWebViewActionOpenWithSafari      =1<<3,
    UTAWebViewActionSaveImage           =1<<4,
    UTAWebViewActionCopyLink            =1<<5,
    UTAWebViewActionCopyImageSrc        =1<<6
};

typedef NS_ENUM(NSInteger, UTAWebViewMsgType) {
    UTAWebViewMsgTypeSuccess,
    UTAWebViewMsgTypeInfo,
    UTAWebViewMsgTypeWarn,
    UTAWebViewMsgTypeError
};

@protocol UTAWebViewDelegate;

@interface UIWebView (UTAWebView)

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *link;

@property (nonatomic, assign, readonly) CGSize windowSize;
@property (nonatomic, assign, readonly) CGPoint scrollOffset;

@end

@interface UTAWebView : UIWebView

/*!
 *  代替delegate
 */
@property (nonatomic, weak) IBOutlet id<UTAWebViewDelegate> webViewDelegate;

/*!
 *  允许通过的Scheme，默认：@"http", @"https", @"file", @"ftp", @"utanewwindow", @"itms-apps"
 */
@property (nonatomic, strong) NSMutableArray *arrAllowedScheme;
/*!
 *  允许的UTAWebViewAction  NSNumber of UTAWebViewAction
 */
@property (nonatomic, strong) NSMutableArray *arrAllowedAction;

/*!
 *  是否有快照
 *  有快照不一定清理了内存
 */
@property (nonatomic, assign, readonly) BOOL hasSnap;

/*!
 *  快照图片
 */
@property (nonatomic, strong, readonly) UIImage *snap;

/*!
 *  是否清除过内存
 *  清除了内存，一定有快照
 */
@property (nonatomic, assign, readonly) BOOL cleanedMemory;

/*!
 *  显示覆盖面，在后台的时候显示
 */
@property (nonatomic, assign, readonly) BOOL showCover;

/*!
 *  超时秒数，默认30s
 */
@property (nonatomic, assign) NSTimeInterval timeoutSeconds;

/**
 *  字体比例(字体大小)
 */
@property (nonatomic, assign) CGFloat fontScale;

/** 是否支持拖拽刷新*/
@property (nonatomic, assign) BOOL canDragRrefresh;

// ------------------- 页内查找相关 begin-------------
/**
 *  页内查找模式，页内查找模式的时候，网页不允许操作：前进，后退，刷新，加载网页，点击打开链接
 */
@property (nonatomic, assign, readonly) BOOL isFindInPageMode;
@property (nonatomic, assign, readonly) NSInteger numberOfKeyword;
@property (nonatomic, assign, readonly) NSInteger indexOfKeyrowd;

/**
 *  开始页内查找模式
 */
- (void)beginFindInPage;

/**
 *  结束页内查找
 */
- (void)endFindInPage;

/**
 *  查找关键字
 *
 *  @param keyword 关键字
 *
 *  @return NSInteger 查找到的总数量
 */
- (NSInteger)findInPageWithKeyword:(NSString *)keyword;

/**
 *  滚动到 第几个关键字
 *
 *  @param integer 索引
 */
- (void)scrollToKeywordIndex:(NSInteger)index;
- (void)scrollToPrevKeyword;
- (void)scrollToNextKeyword;
// ------------------- 页内查找相关 end-------------

- (void)load:(NSString *)link;

/*!
 *  清理内存,
 *  需要保存快照，对应的函数为：reload，需要检查是否清除过缓存，是：load清除缓存前保存的链接地址，否则直接调用super reload
 */
- (void)cleanMemory;
/*!
 *  保存快照，对应的恢复函数为：restoreSnap，删除快照，然后检查是否清除过缓存，是：load清除缓存前保存的链接地址，否则无操作
 */
- (void)saveSnap;
/*!
 *  恢复快照，从快照返回到真实网页内容
 */
- (void)restoreSnap;

/*!
 *  显示logo，第一次加载或从非前端切换到前端时候显示
 *
 *  @param logo     logo视图
 *  @param logoSize 初始化大小
 *  @param animated 是否动画
 */
- (void)showCoverWithLogo:(UIView *)logo logoSize:(CGSize)logoSize animated:(BOOL)animated;
- (void)dismissCoverWithAnimated:(BOOL)animated;

@end

@protocol UTAWebViewDelegate <UIWebViewDelegate>

@optional
- (void)webView:(UTAWebView *)webView updateProgress:(float)progress;
- (void)webView:(UTAWebView *)webView action:(UTAWebViewAction)action obj:(id)obj;
- (void)webView:(UTAWebView *)webView msgType:(UTAWebViewMsgType)msgType msg:(NSString *)msg;

@end
