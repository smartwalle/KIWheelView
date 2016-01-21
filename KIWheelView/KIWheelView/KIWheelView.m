//
//  KIWheelView.m
//  KIWheelView
//
//  Created by apple on 16/1/20.
//  Copyright © 2016年 SmartWalle. All rights reserved.
//

#import "KIWheelView.h"
#import <QuartzCore/QuartzCore.h>
@interface KIWheelSection : NSObject
@property float minValue;
@property float maxValue;
@property float midValue;
@property int value;
@end

@interface KIWheelSectionView ()
@property (nonatomic, strong) UIImageView *backgroundImageView;
@end

@implementation KIWheelSectionView
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self.backgroundImageView setFrame:self.bounds];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self addSubview:self.backgroundImageView];
    [self sendSubviewToBack:self.backgroundImageView];
        self.backgroundColor = [UIColor yellowColor];
}

- (UIImageView *)backgroundImageView {
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] init];
        [_backgroundImageView setContentMode:UIViewContentModeScaleAspectFit];
    }
    return _backgroundImageView;
}

- (CGFloat)radianWithPoint:(CGPoint)point toOriginalPoint:(CGPoint)originalPoint {
    double radian = 0;
    double dx = ABS(point.x - originalPoint.x);
    double dy = ABS(point.y - originalPoint.y);
    radian = atan2(dy, dx);
    
//    if (point.x < originalPoint.x) {
//        radian = M_PI - radian;
//    }
//    if (point.y > originalPoint.y) {
//        radian = 2.0 * M_PI - radian;
//    }
//    if (radian > M_PI_2) {
//        radian -= M_PI_2;
//    } else {
//        radian += 3 * M_PI * 0.5;
//    }
    
    radian = ABS(2 * M_PI - radian);
    
    return radian;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGFloat radius = CGRectGetHeight(self.bounds);
    CGFloat width = CGRectGetWidth(self.bounds);
    CGPoint center = CGPointMake(width * 0.5, radius);
    
    // 一条直角边长为 width * 0.5, 斜边长为 radius, 根据勾股定理算出算出另一条直角边的长
    CGFloat distance = sqrt(pow(radius, 2) - pow(width * 0.5, 2));
    
    CGPoint p1 = CGPointMake(width * 0.5 * -1, distance);
    CGPoint p2 = CGPointMake(width * 0.5, distance);
    
    CGFloat r1 =  -M_PI_2-0.55;
    CGFloat r2 =  -M_PI_2+0.55;
    
    NSLog(@"%f--%f", r1, -M_PI_2-0.55);
    
    // 画圆弧
    // Center圆心
    // radius:半径
    // startAngle起始角度
    // endAngle:结束角度
    // clockwise:Yes 顺时针 No逆时针
//    CGPoint center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    //    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:100 startAngle:0 endAngle:M_PI_2 clockwise:NO];
    
    //    [path stroke];
    
    // 画扇形
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:r1 endAngle:r2 clockwise:YES];
    
    [path addLineToPoint:center];
    
    //    [path addLineToPoint:CGPointMake(self.bounds.size.height * 0.5 + 100, self.bounds.size.height * 0.5)];
    // 关闭路径:从路径的终点连接到起点
    //    [path closePath];
    // 设置填充颜色
    [[UIColor redColor] setFill];
    
    // 设置描边颜色
    [[UIColor greenColor] setStroke];
    
    //    [path stroke];
    // 如果路径不是封闭的,默认会关闭路径
    [path fill];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    [self.backgroundImageView setImage:backgroundImage];
}

@end

@implementation KIWheelSection
@end

@interface KIWheelView ()
@property (nonatomic, assign) CGFloat           deltaAngle;
@property (nonatomic, strong) UIView            *container;
@property (nonatomic, strong) UIImageView       *containerImageView;
@property (nonatomic, strong) NSMutableArray    *sections;
@property (nonatomic, strong) NSMutableArray    *sectionViews;
@property (nonatomic, assign) CGPoint           startPoint;
@property (nonatomic, assign) CGAffineTransform startTransform;
@property (nonatomic, assign) BOOL              touchBegin;
@property (nonatomic, assign) NSInteger         lastIndex;
@property (nonatomic, assign) NSInteger         selectedIndex;
@property (nonatomic, assign) CGPoint           originalPoint;

@property (nonatomic, copy) KIWheelViewDidLoadSectionViewBlock wheelViewDidLoadSectionViewBlock;
@property (nonatomic, copy) KIWheelViewShouldStartRotateBlock  wheelViewShouldStartRotateBlock;
@property (nonatomic, copy) KIWheelViewWillStartRotateBlock    wheelViewWillStartRotateBlock;
@property (nonatomic, copy) KIWheelViewDidUpdateIndexBlcok     wheelViewDidUpdateIndexBlcok;
@property (nonatomic, copy) KIWheelViewDidSelectedIndexBlock   wheelViewDidSelectedIndexBlock;
@end

@implementation KIWheelView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self.container setFrame:self.bounds];
    [self.containerImageView setFrame:self.bounds];
    [self setOriginalPoint:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    CGFloat distance = [self distanceWithPoint:point toOriginalPoint:self.originalPoint];
    
    if (self.wheelViewShouldStartRotateBlock != nil) {
        if (self.wheelViewShouldStartRotateBlock(self) == NO) {
            return;
        }
    }
    
    if (distance > CGRectGetWidth(self.bounds) / 2) {
        return;
    }
    
    if (self.wheelViewWillStartRotateBlock != nil) {
        self.wheelViewWillStartRotateBlock(self);
    }
    
    [self setStartPoint:point];
    [self setTouchBegin:YES];
    
    self.startTransform = self.container.transform;
	float dx = point.x  - self.container.center.x;
	float dy = point.y  - self.container.center.y;
	self.deltaAngle = atan2(dy, dx);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.touchBegin == NO) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
	float dx = point.x  - self.container.center.x;
	float dy = point.y  - self.container.center.y;
	float ang = atan2(dy, dx);
    float angleDif = self.deltaAngle - ang;
    CGAffineTransform newTrans = CGAffineTransformRotate(self.startTransform, -angleDif);
    self.container.transform = newTrans;
    
    NSInteger tempIndex = [self calculateIndex:NO];
    if (tempIndex != self.lastIndex) {
        self.lastIndex = tempIndex;
        if (self.wheelViewDidUpdateIndexBlcok != nil) {
            self.wheelViewDidUpdateIndexBlcok(self, self.lastIndex);
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setTouchBegin:NO];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.touchBegin == NO) {
        return;
    }
    [self setTouchBegin:NO];
    
    NSInteger tempIndex = [self calculateIndex:YES];
    
//    if (tempIndex != self.selectedIndex) {
        self.selectedIndex = tempIndex;
        self.lastIndex = self.selectedIndex;
        if (self.wheelViewDidSelectedIndexBlock != nil) {
            self.wheelViewDidSelectedIndexBlock(self, self.selectedIndex);
        }
//    }
}

#pragma mark - Methods
- (CGFloat)distanceWithPoint:(CGPoint)point toOriginalPoint:(CGPoint)originalPoint {
    double distance = 0;
    double dx = ABS(point.x - originalPoint.x);
    double dy = ABS(point.y - originalPoint.y);
    distance = sqrt(pow(dx, 2) + pow(dy, 2));
    return distance;
}

- (CGPoint)convertPoint:(CGPoint)point toOriginalPoint:(CGPoint)originalPoint {
    double dx = point.x - originalPoint.x;
    double dy = point.y - originalPoint.y;
    return CGPointMake(dx, dy * -1);
}

- (NSInteger)calculateIndex:(BOOL)moveToNewPoint {
    NSInteger tempIndex = 0;
    CGFloat radians = atan2f(self.container.transform.b, self.container.transform.a);
    CGFloat newVal = 0.0;
    for (KIWheelSection *section in self.sections) {
        if (section.minValue > 0 && section.maxValue < 0) {
            if (section.maxValue > radians || section.minValue < radians) {
                if (radians > 0) {
                    newVal = radians - M_PI;
                } else {
                    newVal = M_PI + radians;
                }
                tempIndex = section.value;
            }
        }
        
        if (radians > section.minValue && radians < section.maxValue) {
            newVal = radians - section.midValue;
            tempIndex = section.value;
        }
    }
    
    if (moveToNewPoint) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        CGAffineTransform t = CGAffineTransformRotate(self.container.transform, -newVal);
        self.container.transform = t;
        [UIView commitAnimations];
    }
    return tempIndex;
}

- (void)buildWheel {
    self.sections = [[NSMutableArray alloc] initWithCapacity:self.numberOfSections];
    
    [self addSubview:self.container];
    [self.container setBackgroundColor:[UIColor clearColor]];

    
    CGPoint point = CGPointMake(CGRectGetWidth(self.container.bounds) / 2.0,
                                CGRectGetHeight(self.container.bounds) / 2.0);
    
    CGFloat angle = M_PI * 2 / self.numberOfSections;
    CGFloat perimeter = M_PI * CGRectGetWidth(self.bounds);
    CGFloat width = perimeter / self.numberOfSections;
    CGFloat height = CGRectGetHeight(self.container.bounds) / 2.0;

    for (KIWheelSectionView *view in self.sectionViews) {
        [view removeFromSuperview];
    }
    
    for (int i=0; i<self.numberOfSections; i++) {
        KIWheelSectionView *view = [[KIWheelSectionView alloc] init];
        [view setFrame:CGRectMake(0, 0, width, height)];
        view.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
        view.layer.position    = point;
//        view.transform         = CGAffineTransformMakeRotation(angle * i);
        view.backgroundColor   = [UIColor clearColor];
        [self.container addSubview:view];
        
        [self.sectionViews addObject:view];
        
        if (self.wheelViewDidLoadSectionViewBlock != nil) {
            self.wheelViewDidLoadSectionViewBlock(self, i, view);
        }
    }
    
    if (self.numberOfSections % 2 == 0) {
        [self buildSectionsWithEven];
    } else {
        [self buildSectionsWithOdd];
    }
}

- (void)buildSectionsWithEven {
    CGFloat fanWidth = M_PI * 2 / self.numberOfSections;
    CGFloat mid = 0;
    for (int i=0; i<self.numberOfSections; i++) {
        KIWheelSection *section = [[KIWheelSection alloc] init];
        section.midValue = mid;
        section.minValue = mid - (fanWidth / 2);
        section.maxValue = mid + (fanWidth / 2);
        section.value = i;
        if (section.maxValue-fanWidth < - M_PI) {
            mid = 3.14;
            section.midValue = mid;
            section.minValue = fabsf(section.maxValue);
        }
        mid -= fanWidth;
        [self.sections addObject:section];
    }
}

- (void)buildSectionsWithOdd {
    CGFloat fanWidth = M_PI * 2 / self.numberOfSections;
    CGFloat mid = 0;
    for (int i=0; i<self.numberOfSections; i++) {
        KIWheelSection *section = [[KIWheelSection alloc] init];
        section.midValue = mid;
        section.minValue = mid - (fanWidth / 2);
        section.maxValue = mid + (fanWidth / 2);
        section.value = i;
        mid -= fanWidth;
        if (section.minValue < - M_PI) {
            mid = -mid;
            mid -= fanWidth;
        }
        [self.sections addObject:section];
    }
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated {
    for (KIWheelSection *section in self.sections) {
        if (section.value == index) {
            self.selectedIndex = index;
            self.lastIndex = index;
            [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
                self.container.transform = CGAffineTransformRotate([self.container transform], section.midValue);
            } completion:^(BOOL finished) {
                if (self.wheelViewDidSelectedIndexBlock != nil) {
                    self.wheelViewDidSelectedIndexBlock(self, self.selectedIndex);
                }
            }];
        }
    }
}

- (KIWheelSectionView *)sectionViewAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.sectionViews.count) {
        return self.sectionViews[index];
    }
    return nil;
}

- (void)reload {
    [self buildWheel];
}

#pragma mark - Getters & Setters
- (void)setNumberOfSections:(NSInteger)numberOfSections {
    if (_numberOfSections != numberOfSections) {
        _numberOfSections = numberOfSections;
        [self buildWheel];
    }
}

- (void)setSectionImage:(UIImage *)sectionImage {
    if (_sectionImage != sectionImage) {
        _sectionImage = sectionImage;
        for (KIWheelSectionView *view in self.sectionViews) {
            [view setBackgroundImage:sectionImage];
        }
    }
}

- (void)setContainerImage:(UIImage *)containerImage {
    if (_containerImage != containerImage) {
        _containerImage = containerImage;
        [self.containerImageView setImage:containerImage];
        [self.containerImageView setContentMode:UIViewContentModeScaleAspectFit];
        if (_containerImage == nil) {
            [_containerImageView removeFromSuperview];
            _containerImageView = nil;
        } else {
            [self.container addSubview:self.containerImageView];
            [self.container sendSubviewToBack:self.containerImageView];
        }
    }
}

- (NSMutableArray *)sectionViews {
    if (_sectionViews == nil) {
        _sectionViews = [[NSMutableArray alloc] init];
    }
    return _sectionViews;
}

- (UIView *)container {
    if (_container == nil) {
        _container = [[UIView alloc] initWithFrame:self.bounds];
    }
    return _container;
}

- (UIImageView *)containerImageView {
    if (_containerImageView == nil) {
        _containerImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    }
    return _containerImageView;
}

- (void)setDidLoadSectionViewBlock:(KIWheelViewDidLoadSectionViewBlock)block {
    [self setWheelViewDidLoadSectionViewBlock:block];
}

- (void)setShouldStartRotateBlock:(KIWheelViewShouldStartRotateBlock)block {
    [self setWheelViewShouldStartRotateBlock:block];
}

- (void)setWillStartRotateBlcok:(KIWheelViewWillStartRotateBlock)block {
    [self setWheelViewWillStartRotateBlock:block];
}

- (void)setDidUpdateIndexBlcok:(KIWheelViewDidUpdateIndexBlcok)block {
    [self setWheelViewDidUpdateIndexBlcok:block];
}

- (void)setDidSelectedIndexBlock:(KIWheelViewDidSelectedIndexBlock)block {
    [self setWheelViewDidSelectedIndexBlock:block];
}

@end
