//
//  KIWheelView.h
//  KIWheelView
//
//  Created by apple on 16/1/20.
//  Copyright © 2016年 SmartWalle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KIWheelView;

typedef UIView*(^KIWheelViewGetSectionViewBlock)    (KIWheelView *wheelView, NSInteger index);

typedef void(^KIWheelViewWillStartRotateBlock)  (KIWheelView *wheelView);
typedef void(^KIWheelViewDidUpdateIndexBlcok)   (KIWheelView *wheelView, NSInteger index);
typedef void(^KIWheelViewDidSelectedIndexBlock) (KIWheelView *wheelView, NSInteger index);

@interface KIWheelView : UIView

@property (nonatomic, assign) NSInteger numberOfSections;

- (UIView *)container;

- (void)setViewForSectionBlock:(KIWheelViewGetSectionViewBlock)block;

- (void)setWillStartRotateBlcok:(KIWheelViewWillStartRotateBlock)block;

- (void)setDidUpdateIndexBlcok:(KIWheelViewDidUpdateIndexBlcok)block;

- (void)setDidSelectedIndexBlock:(KIWheelViewDidSelectedIndexBlock)block;

- (NSInteger)selectedIndex;

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;

@end
