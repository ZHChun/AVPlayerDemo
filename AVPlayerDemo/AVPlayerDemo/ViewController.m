//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by 杨强 on 29/3/2019.
//  Copyright © 2019 杨强. All rights reserved.
//

#import "ViewController.h"
#import "MoviePlayerView.h"

@interface ViewController ()<MoviePlayerViewDelegate>

@property (strong, nonatomic) IBOutlet MoviePlayerView *playerView;
@property (nonatomic, strong) CALayer *subLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES];
    
    NSString *movieString = @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4";
    
    NSURL *url = [NSURL URLWithString:movieString];
    
    NSString *localFilePath = [[NSBundle mainBundle] pathForResource:@"竖屏视频录制" ofType:@"mov"];
    NSURL *localUrl = [NSURL fileURLWithPath:localFilePath];
    
    self.playerView = [[[NSBundle mainBundle] loadNibNamed:@"MoviePlayerView" owner:self options:nil] firstObject];
    self.playerView.frame = CGRectMake(0, 200, SCREEN_WIDTH, SCREEN_WIDTH);
    self.playerView.originPoint = self.playerView.frame.origin;
    self.playerView.originSize = self.playerView.frame.size;

    [self.view addSubview:self.playerView];

    self.playerView.movieUrl = localUrl;
    self.playerView.delegate = self;
    
}

- (BOOL)prefersStatusBarHidden {
    return self.playerView.isFullScreen;
}

#pragma mark - MoviePlayerViewDelegate
- (void)fullScreenToPlayerMovie:(MoviePlayerView *)playerView IsFullScreen:(BOOL)isFullScreen {
    //更新状态栏状态
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Events
- (IBAction)jump:(id)sender {
    [self performSegueWithIdentifier:@"jump" sender:nil];
}


@end
