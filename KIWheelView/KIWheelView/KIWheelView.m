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
@property int   value;
@end

@interface KIWheelSectionView ()
@property (nonatomic, assign) CGFloat      fanWidth;
@property (nonatomic, strong) UIBezierPath *path;
@end

@implementation KIWheelSectionView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat radius = CGRectGetHeight(self.bounds);
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), radius);
    
    CGFloat r1 = -M_PI_2 - self.fanWidth * 0.5;
    CGFloat r2 = -M_PI_2 + self.fanWidth * 0.5;
    
    self.path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:r1 endAngle:r2 clockwise:YES];
    [self.path addLineToPoint:center];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = self.path.CGPath;
    [self.layer setMask:layer];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [self.path containsPoint:point];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    if (_backgroundImage == nil) {
        [self setBackgroundColor:[UIColor whiteColor]];
    } else {
        [self setBackgroundColor:[UIColor colorWithPatternImage:_backgroundImage]];
    }
}

@end

@implementation KIWheelSection
@end

@interface KIWheelView ()
@property (nonatomic, assign) CGFloat           deltaAngle;
@property (nonatomic, strong) UIView            *container;
@property (nonatomic, strong) NSMutableArray    *sections;
@property (nonatomic, strong) NSMutableArray    *sectionViews;
@property (nonatomic, assign) CGPoint           startPoint;
@property (nonatomic, assign) CGAffineTransform startTransform;
@property (nonatomic, assign) BOOL              touchBegin;
@property (nonatomic, assign) NSInteger         lastIndex;
@property (nonatomic, assign) NSInteger         selectedIndex;
@property (nonatomic, assign) CGPoint           originalPoint;
@property (nonatomic, strong) UIBezierPath      *path;

@property (nonatomic, copy) KIWheelViewDidLoadSectionViewBlock wheelViewDidLoadSectionViewBlock;
@property (nonatomic, copy) KIWheelViewShouldStartRotateBlock  wheelViewShouldStartRotateBlock;
@property (nonatomic, copy) KIWheelViewWillStartRotateBlock    wheelViewWillStartRotateBlock;
@property (nonatomic, copy) KIWheelViewDidUpdateIndexBlcok     wheelViewDidUpdateIndexBlcok;
@property (nonatomic, copy) KIWheelViewDidSelectedIndexBlock   wheelViewDidSelectedIndexBlock;
@end

@implementation KIWheelView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [self.path containsPoint:point];
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    if (self.wheelViewShouldStartRotateBlock != nil) {
        if (self.wheelViewShouldStartRotateBlock(self) == NO) {
            return;
        }
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
    [self setOriginalPoint:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
    
    for (KIWheelSectionView *view in self.sectionViews) {
        [view removeFromSuperview];
    }
    [self.sectionViews removeAllObjects];
    [self.sections removeAllObjects];
    [self.container setFrame:self.bounds];
    [self addSubview:self.container];
    
    CGPoint point = CGPointMake(CGRectGetWidth(self.container.bounds) * 0.5,
                                CGRectGetHeight(self.container.bounds) * 0.5);
    
    CGFloat angle = M_PI * 2 / self.numberOfSections;
    CGFloat perimeter = M_PI * CGRectGetWidth(self.bounds);
    CGFloat width = perimeter / self.numberOfSections;
    CGFloat height = CGRectGetHeight(self.container.bounds) * 0.5;
    CGFloat fanWidth = M_PI * 2 / self.numberOfSections;
    
    for (int i=0; i<self.numberOfSections; i++) {
        KIWheelSectionView *view = [[KIWheelSectionView alloc] init];
        [view setFrame:CGRectMake(0, 0, width, height)];
        view.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
        view.layer.position    = point;
        view.transform         = CGAffineTransformMakeRotation(angle * i);
//        view.backgroundColor   = [UIColor whiteColor];
        view.fanWidth          = fanWidth;
        view.backgroundImage   = self.sectionImage;
        
        [self.container addSubview:view];
        [self.sectionViews addObject:view];
        
        if (self.wheelViewDidLoadSectionViewBlock != nil) {
            self.wheelViewDidLoadSectionViewBlock(self, i, view);
        }
    }
    
    self.path = [UIBezierPath bezierPathWithOvalInRect:self.container.bounds];
    [self.path addLineToPoint:point];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = self.path.CGPath;
    [self.layer setMask:layer];
    
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
            [view setBackgroundImage:_sectionImage];
        }
    }
}

- (NSMutableArray *)sections {
    if (_sections == nil) {
        _sections = [[NSMutableArray alloc] init];
    }
    return _sections;
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
