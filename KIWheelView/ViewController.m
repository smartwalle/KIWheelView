//
//  ViewController.m
//  KIWheelView
//
//  Created by apple on 16/1/20.
//  Copyright © 2016年 SmartWalle. All rights reserved.
//

#import "ViewController.h"

#import "KIWheelView.h"

@interface ViewController ()
@property (nonatomic, strong) KIWheelView *wheelView;
@property (nonatomic, strong) KIWheelView *wheelView2;
@property (nonatomic, strong) KIWheelView *wheelView3;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.wheelView = (KIWheelView *)[self.view viewWithTag:1001];
    self.wheelView2 = (KIWheelView *)[self.view viewWithTag:1002];
    
    [self.wheelView setDidLoadSectionViewBlock:^(KIWheelView *wheelView, NSInteger index, KIWheelSectionView *sectionView) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sectionView.bounds.size.width, 50)];
        [label setText:[NSString stringWithFormat:@"%d", index]];
        [label setFont:[UIFont boldSystemFontOfSize:30]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [sectionView addSubview:label];
        
        if (index % 2 == 0) {
            [sectionView setBackgroundColor:[UIColor redColor]];
        } else {
            [sectionView setBackgroundColor:[UIColor greenColor]];
        }
    }];
    
    [self.wheelView2 setDidLoadSectionViewBlock:^(KIWheelView *wheelView, NSInteger index, KIWheelSectionView *sectionView) {
        if (index % 2 == 0) {
            [sectionView setBackgroundColor:[UIColor redColor]];
        } else {
            [sectionView setBackgroundColor:[UIColor greenColor]];
        }
    }];
    
//    KIWheelView *view = [[KIWheelView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
//    [view setBackgroundColor:[UIColor redColor]];
//    
//    
//    UIImageView *iv = [[UIImageView alloc] init];
//    [iv setFrame:view.bounds];
//    [iv setImage:[UIImage imageNamed:@"turn_table.png"]];
//    
////    [view.container addSubview:iv];
//    
//    [view setDidSelectedIndexBlock:^(KIWheelView *wheelView, NSInteger selectedIndex) {
//        NSLog(@"%d", selectedIndex);
//    }];
//    
//    [view setDidLoadSectionViewBlock:^(KIWheelView *wheelView, NSInteger index, KIWheelSectionView *sectionView) {
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(sectionView.bounds), 20)];
//        [label setText:[NSString stringWithFormat:@"%d", index]];
//        [label setTextAlignment:NSTextAlignmentCenter];
//        [sectionView addSubview:label];
//    }];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [view selectIndex:3 animated:YES];
//    });
//    
//    [view setNumberOfSections:8];
//    [view reload];
//    
//    [self.view addSubview:view];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.wheelView reload];
    [self.wheelView2 reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
