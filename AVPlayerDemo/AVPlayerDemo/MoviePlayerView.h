//
//  MoviePlayerView.h
//  AVPlayerDemo
//
//  Created by 杨强 on 8/4/2019.
//  Copyright © 2019 杨强. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MoviePlayerView;
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

NS_ASSUME_NONNULL_BEGIN

@protocol MoviePlayerViewDelegate <NSObject>
@optional
- (void)fullScreenToPlayerMovie:(MoviePlayerView *)playerView IsFullScreen:(BOOL)isFullScreen;
@end

@interface MoviePlayerView : UIView
@property (nonatomic, assign) CGPoint originPoint;
@property (nonatomic, assign) CGSize originSize;

@property (nonatomic, strong) NSURL *movieUrl;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, weak)id<MoviePlayerViewDelegate> delegate;



@end

NS_ASSUME_NONNULL_END
