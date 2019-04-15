//
//  MoviePlayerView.m
//  AVPlayerDemo
//
//  Created by 杨强 on 8/4/2019.
//  Copyright © 2019 杨强. All rights reserved.
//

#import "MoviePlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "CustomSlider.h"

@interface MoviePlayerView ()<CAAnimationDelegate>
@property (weak, nonatomic) IBOutlet UIView *movieBGView;
@property (weak, nonatomic) IBOutlet UIView *playToolsBarView;

@property (weak, nonatomic) IBOutlet UIProgressView *playProgressView;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

@property (weak, nonatomic) IBOutlet UILabel *totalNeedPlayTimeLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet CustomSlider *sliderView;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBtn;
@property (weak, nonatomic) IBOutlet UIButton *voiceButton;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *currentPlayerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, strong) CALayer *subLayer;

@property (nonatomic, assign) BOOL isPlaying;//是否正在播放
@property (nonatomic, assign) BOOL isSlidering;//正在滑动

@property (nonatomic, assign) NSInteger optionCount; // 记录用户对页面的操作次数(点击, 滑动), 用于隐藏视频播放工具栏

@end

@implementation MoviePlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.originPoint = frame.origin;
        self.originSize = frame.size;
        
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.originPoint = self.frame.origin;
    self.originSize = self.frame.size;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTaped:)];
    [self.sliderView addGestureRecognizer:tap];
    
    [self.sliderView addTarget:self action:@selector(sliderValurChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
    [self.sliderView setThumbImage:[UIImage imageNamed:@"yuan"] forState:(UIControlStateNormal)];
    
    [self.playToolsBarView addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    
}

#pragma mark - Private Methods
- (void)loadResourceForPlay {
    //首先移除之前加载视图上的播放层
    for (CALayer *layer in self.movieBGView.layer.sublayers) {
        if ([layer isKindOfClass:[AVPlayerLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    
    NSArray *array = self.asset.tracks;
    CGSize videoSize = CGSizeZero; //获取视频的原生大小
    for (AVAssetTrack *track in array) {
        //AVMediaTypeVideo 视频 ; AVMediaTypeAudio 音频
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            videoSize = track.naturalSize;
        }
    }
    
    CGFloat aspect_w_h = videoSize.width/videoSize.height;
    
    if (aspect_w_h > 1) {
        CGFloat height = self.movieBGView.bounds.size.width/aspect_w_h;
        videoSize = CGSizeMake(self.movieBGView.bounds.size.width, height);
    } else {
        CGFloat width = self.movieBGView.bounds.size.height * aspect_w_h;
        videoSize = CGSizeMake(width, self.movieBGView.bounds.size.height);
    }
    
    self.videoSize = videoSize;
    
    CGRect frame = self.movieBGView.frame;
    CGRect bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
    CGPoint anchorPoint = CGPointMake(0.5f, 0.5f);
    CGPoint position = CGPointMake((frame.size.width - bounds.origin.x) * anchorPoint.x, (frame.size.height - bounds.origin.y) * anchorPoint.y);
    
    self.playerLayer.bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
    self.playerLayer.position = position;
    
    [self.movieBGView.layer addSublayer:self.playerLayer];
    
    [self.movieBGView bringSubviewToFront:self.playProgressView];
}

//转换时间格式的方法
- (NSString *)formatTimeWithTimeInterVal:(NSTimeInterval)timeInterVal{
    int minute = 0, hour = 0, second = timeInterVal;
    minute = (second % 3600)/60;
    hour = second / 3600;
    second = second % 60;
    NSString *string = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
    if (hour <= 0) {
        string = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    }
    return string;
}

//2.添加属性观察 视屏的加载进度变化
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        //获取playerItem的status属性最新的状态
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        switch (status) {
            case AVPlayerStatusReadyToPlay:{
                //获取视频长度
                CMTime duration = playerItem.duration;
                //更新显示:视频总时长(自定义方法显示时间的格式)
                self.totalNeedPlayTimeLabel.text = [self formatTimeWithTimeInterVal:CMTimeGetSeconds(duration)];
                //开启滑块的滑动功能
                self.sliderView.enabled = YES;
                //关闭加载Loading提示
//                [self showaAtivityInDicatorView:NO];
                //开始播放视频
                [self.player play];
                //开始播放后4秒将播放工具栏隐藏
                [self delaySecondsHiddenPlayToolsBarView];
                break;
            }
            case AVPlayerStatusFailed:{//视频加载失败，点击重新加载
//                [self showaAtivityInDicatorView:NO];//关闭Loading视图
//                self.playerInfoButton.hidden = NO; //显示错误提示按钮，点击后重新加载视频
//                [self.playerInfoButton setTitle:@"资源加载失败，点击继续尝试加载" forState: UIControlStateNormal];
                NSLog(@"%@", self.player.error.description);
                break;
            }
            case AVPlayerStatusUnknown:{
                NSLog(@"加载遇到未知问题:AVPlayerStatusUnknown");
                break;
            }
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        //获取视频缓冲进度数组，这些缓冲的数组可能不是连续的
        NSArray *loadedTimeRanges = playerItem.loadedTimeRanges;
        //获取最新的缓冲区间
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
        //缓冲区间的开始的时间
        NSTimeInterval loadStartSeconds = CMTimeGetSeconds(timeRange.start);
        //缓冲区间的时长
        NSTimeInterval loadDurationSeconds = CMTimeGetSeconds(timeRange.duration);
        //当前视频缓冲时间总长度
        NSTimeInterval currentLoadTotalTime = loadStartSeconds + loadDurationSeconds;
        NSLog(@"开始缓冲:%f,缓冲时长:%f,总时间:%f", loadStartSeconds, loadDurationSeconds, currentLoadTotalTime);
        //更新显示：当前缓冲总时长
//        _currentLoadTimeLabel.text = [self formatTimeWithTimeInterVal:currentLoadTotalTime];
        //更新显示：视频的总时长
        _totalNeedPlayTimeLabel.text = [self formatTimeWithTimeInterVal:CMTimeGetSeconds(self.player.currentItem.duration)];
        //更新显示：缓冲进度条的值
        _progressView.progress = currentLoadTotalTime/CMTimeGetSeconds(self.player.currentItem.duration);
    } else if ([keyPath isEqualToString:@"hidden"]) {
        if (!self.playToolsBarView.hidden) {
            [self delaySecondsHiddenPlayToolsBarView];
        } else {
            self.playProgressView.hidden = !self.playToolsBarView.hidden;
        }
    }
}

- (void)delaySecondsHiddenPlayToolsBarView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self.optionCount <= 1) {
            self.playToolsBarView.hidden = YES;
        }

        if (self.optionCount >= 1) {
            self.optionCount -= 1;
        }
        
        self.playProgressView.hidden = !self.playToolsBarView.hidden;
        
    });
}

#pragma mark - Events
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.playToolsBarView.hidden) {
        self.optionCount += 1;
    }
    
    self.playToolsBarView.hidden = !self.playToolsBarView.hidden;
    self.playProgressView.hidden = !self.playToolsBarView.hidden;
}

- (IBAction)playButtonClicked:(UIButton *)sender {
    self.optionCount += 1;
    self.playToolsBarView.hidden = NO;
    
    sender.selected = !sender.selected;
    if ([self isPlaying]) {
        [self.player pause];
    } else {
        if (CMTimeGetSeconds(self.currentPlayerItem.currentTime) == CMTimeGetSeconds(self.currentPlayerItem.duration)) {
            //重播
            CMTime seekTime = CMTimeMake(0, 1);
            __weak __typeof(self) weakSelf = self;
            [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
                [weakSelf.player play];
            }];
        } else {
            if (self.player.currentItem.status == AVPlayerStatusReadyToPlay) {
                [self.player play];
            }
        }
    }
}

- (void)sliderValurChanged:(UISlider*)slider forEvent:(UIEvent*)event {
    self.optionCount += 1;
    self.playToolsBarView.hidden = NO;
    
    UITouch *touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
            self.isSlidering = YES;
            break;
        case UITouchPhaseMoved:
            
            break;
        case UITouchPhaseEnded:
            if (self.player.status == AVPlayerStatusReadyToPlay) {
                NSTimeInterval timeInterval = slider.value * CMTimeGetSeconds(self.player.currentItem.duration);
                CMTime seekTime = CMTimeMake(timeInterval, 1);
                [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
                    [self.player play];
                    self.playButton.selected = NO;
                    self.isSlidering = NO;
                }];
            }
            
            break;
        case UITouchPhaseCancelled:
            self.isSlidering = NO;
            break;
            
        default:
            break;
    }
    
}

- (void)sliderTaped:(UITapGestureRecognizer *)gesture {
    self.optionCount += 1;
    self.playToolsBarView.hidden = NO;
    
    //手指抬起的那一刻位置最准确
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [gesture locationInView:self.sliderView];
        
        CGFloat value = point.x/self.sliderView.frame.size.width;
        
        self.sliderView.value = value;
        
        NSTimeInterval timeInterval = value * CMTimeGetSeconds(self.player.currentItem.duration);
        CMTime seekTime = CMTimeMake(timeInterval, 1);
        [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
            if (![self isPlaying]) {
                [self.player play];
            }
        }];
    }
}

- (IBAction)voiceBtnClicked:(UIButton *)sender {
    self.optionCount += 1;
    self.playToolsBarView.hidden = NO;
    
    sender.selected = !sender.selected;
    if (sender.selected) {
        self.player.volume = 0;
    } else {
        self.player.volume = 1;
    }
}

- (IBAction)fullScreenBtnClicked:(UIButton *)sender {
    self.optionCount += 1;
    self.playToolsBarView.hidden = NO;
    
    sender.selected = !sender.selected;
    self.isFullScreen = !self.isFullScreen;
    if (self.delegate && [self.delegate respondsToSelector:@selector(fullScreenToPlayerMovie:IsFullScreen:)]) {
        [self.delegate fullScreenToPlayerMovie:self IsFullScreen:self.isFullScreen];
    }
    if (self.isFullScreen) {
        [self beginEnterFullScreen];
        self.backButton.hidden = NO;
    } else {
        [self beginOutFullScreen];
        self.backButton.hidden = YES;
    }
}

- (IBAction)backBtnClicked:(UIButton *)sender {
    self.optionCount += 1;
    self.playToolsBarView.hidden = NO;
    
    self.isFullScreen = NO;
    [self beginOutFullScreen];
    self.backButton.hidden = YES;
}

#pragma mark - 转屏处理逻辑
- (void)beginEnterFullScreen{
    //目前layer层没有动画, 竖屏会有问题
    if (self.videoSize.width > self.videoSize.height) {
        [UIView animateWithDuration:0.2 animations:^{
            self.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
            self.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
            CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI/2);
            self.transform = rotate;
            
            self.playerLayer.bounds = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
            self.playerLayer.position = CGPointMake(self.playerLayer.bounds.size.width * self.playerLayer.anchorPoint.x, self.playerLayer.bounds.size.height * self.playerLayer.anchorPoint.y);
            
        } completion:^(BOOL finished) {
            
        }];
    } else {
#warning 竖屏动画bug view层动画有, layer层动画无
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        //关闭layer层属性改变的隐士动画
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.playerLayer.bounds = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        self.playerLayer.position = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
        [CATransaction commit];
        
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"bounds"];
//        CGRect rect = self.playerLayer.bounds;
//        rect.size.width = SCREEN_WIDTH;
//        rect.size.height =  SCREEN_HEIGHT;
//        animation.duration = 0.2f;
//        animation.toValue = [NSValue valueWithCGRect:rect];
//        animation.delegate = self;
//        animation.removedOnCompletion = NO;
//        animation.fillMode = kCAFillModeForwards;
//        [self.playerLayer addAnimation:animation forKey:@"EnterFullScreen"];
        
//        CABasicAnimation *positionAni = [CABasicAnimation animationWithKeyPath:@"position"];
//        positionAni.duration = 3;
//        positionAni.toValue = [NSValue valueWithCGPoint:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)];
//        positionAni.delegate = self;
//        positionAni.removedOnCompletion = NO;
//        positionAni.fillMode = kCAFillModeForwards;
//        [self.playerLayer addAnimation:positionAni forKey:@"EnterFullScreen"];

    }
}

- (void)beginOutFullScreen{
    //目前layer层没有动画, 竖屏会有问题
    if (self.videoSize.width > self.videoSize.height) {
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.frame = CGRectMake(self.originPoint.x, self.originPoint.y, self.originSize.width, self.originSize.height);
            
            CGRect frame = self.frame;
            CGRect bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
            CGPoint anchorPoint = CGPointMake(0.5f, 0.5f);
            CGPoint position = CGPointMake((frame.size.width - bounds.origin.x) * anchorPoint.x, (frame.size.height - bounds.origin.y) * anchorPoint.y);
            
            self.playerLayer.bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
            self.playerLayer.position = position;
            
        } completion:^(BOOL finished) {
            
        }];
    } else {
#warning 竖屏动画bug view层动画有, layer层动画无
        self.frame = CGRectMake(self.originPoint.x, self.originPoint.y, self.originSize.width, self.originSize.height);
        CGRect frame = self.frame;
        CGRect bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
        CGPoint anchorPoint = CGPointMake(0.5f, 0.5f);
        CGPoint position = CGPointMake((frame.size.width - bounds.origin.x) * anchorPoint.x, (frame.size.height - bounds.origin.y) * anchorPoint.y);
        
        //关闭layer层属性改变的隐士动画
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.playerLayer.bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
        self.playerLayer.position = position;
        [CATransaction commit];
        

    }
    
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStart:(CAAnimation *)anim {
    
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    //动画结束会出现一闪的不协调
    if ([self.playerLayer animationForKey:@"EnterFullScreen"] == anim) {
        [self.playerLayer removeAllAnimations];
        self.playerLayer.bounds = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        self.playerLayer.position = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
    }
}

#pragma mark - Setter & Getter
- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
        
        //1.注册观察者，监测播放器属性
        //观察Status属性，可以在加载成功之后得到视频的长度
        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //观察loadedTimeRanges，可以获取缓存进度，实现缓冲进度条
        [_player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        
        //播放进度监听
        __weak __typeof(self) weakSelf = self;
        [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            //当前播放的时间
            NSTimeInterval currentTime = CMTimeGetSeconds(time);
            //视频的总时间
            NSTimeInterval totalTime = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
            //当滑块将要滑动的时候, 滑块进度不随着视频的播放进度一起改变, 而是跟着手势而变化
            //当滑块滑动结束, 恢复滑块跟着视频播放播放进度一起改变
            if (!weakSelf.isSlidering) {
                //设置滑块的当前进度
                weakSelf.sliderView.value = currentTime/totalTime;
            }
            
            weakSelf.playProgressView.progress = currentTime/totalTime;
            //设置显示的时间：以00:00:00的格式
            weakSelf.currentTimeLabel.text = [weakSelf formatTimeWithTimeInterVal:currentTime];
            
        }];
    }
    return _player;
}

- (AVPlayerItem *)currentPlayerItem {
    if (!_currentPlayerItem) {
        _currentPlayerItem = [AVPlayerItem playerItemWithAsset:self.asset];
    }
    return _currentPlayerItem;
}

- (void)setMovieUrl:(NSURL *)movieUrl {
    _movieUrl = movieUrl;
    if (movieUrl) {
        AVAsset *asset = [AVAsset assetWithURL:movieUrl];
        self.asset = asset;
        //官方提供异步加载track的方法，防止线程阻塞（加载track是耗时操作）
        [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (asset.playable) {
                    [self loadResourceForPlay];
                }
            });
        }];
        
    }
}

- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return _playerLayer;
}

- (BOOL)isPlaying {
    if (@available(iOS 10.0, *)) {
        return self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying;
    } else {
        // Fallback on earlier versions
        return self.player.rate == 1;
    }
}

@end
