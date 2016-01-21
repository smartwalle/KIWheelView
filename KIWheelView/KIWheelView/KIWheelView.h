//
//  KIWheelView.h
//  KIWheelView
//
//  Created by apple on 16/1/20.
//  Copyright © 2016年 SmartWalle. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface KIWheelSectionView : UIView
@property (nonatomic, strong) IBInspectable UIImage *backgroundImage;
@end

@class KIWheelView;
typedef void(^KIWheelViewDidLoadSectionViewBlock) (KIWheelView *wheelView, NSInteger index, KIWheelSectionView *sectionView);
typedef BOOL(^KIWheelViewShouldStartRotateBlock)  (KIWheelView *wheelView);
typedef void(^KIWheelViewWillStartRotateBlock)    (KIWheelView *wheelView);
typedef void(^KIWheelViewDidUpdateIndexBlcok)     (KIWheelView *wheelView, NSInteger index);
typedef void(^KIWheelViewDidSelectedIndexBlock)   (KIWheelView *wheelView, NSInteger index);

IB_DESIGNABLE
@interface KIWheelView : UIView
// 设置 Section 的数量，设置之后，将立刻执行 reload 操作
@property (nonatomic, assign) IBInspectable NSInteger numberOfSections;

// 统一设置所有 Section 的背景图片
@property (nonatomic, strong) IBInspectable UIImage   *sectionImage;

// 设置 Container 的背景图片
@property (nonatomic, strong) IBInspectable UIImage   *containerImage;

- (UIView *)container;

- (void)setDidLoadSectionViewBlock:(KIWheelViewDidLoadSectionViewBlock)block;

- (void)setShouldStartRotateBlock:(KIWheelViewShouldStartRotateBlock)block;
- (void)setWillStartRotateBlcok:(KIWheelViewWillStartRotateBlock)block;

- (void)setDidUpdateIndexBlcok:(KIWheelViewDidUpdateIndexBlcok)block;
- (void)setDidSelectedIndexBlock:(KIWheelViewDidSelectedIndexBlock)block;

- (NSInteger)selectedIndex;

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;

- (KIWheelSectionView *)sectionViewAtIndex:(NSInteger)index;

- (void)reload;

@end
