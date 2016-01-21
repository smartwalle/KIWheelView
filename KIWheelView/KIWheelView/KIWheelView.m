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

@implementation KIWheelSection
@end

@interface KIWheelView ()
@property (nonatomic, assign) CGFloat           deltaAngle;
@property (nonatomic, strong) UIView            *container;
@property (nonatomic, strong) NSMutableArray    *sections;
@property (nonatomic, assign) CGPoint           startPoint;
@property (nonatomic, assign) CGAffineTransform startTransform;
@property (nonatomic, assign) BOOL              touchBegin;
@property (nonatomic, assign) NSInteger         selectedIndex;
@property (nonatomic, assign) NSInteger         lastIndex;
@property (nonatomic, assign) CGPoint           originalPoint;

@property (nonatomic, copy) KIWheelViewGetSectionViewBlock   wheelViewGetSectionViewBlock;
@property (nonatomic, copy) KIWheelViewWillStartRotateBlock  wheelViewWillStartRotateBlock;
@property (nonatomic, copy) KIWheelViewDidUpdateIndexBlcok   wheelViewDidUpdateIndexBlcok;
@property (nonatomic, copy) KIWheelViewDidSelectedIndexBlock wheelViewDidSelectedIndexBlock;
@end

@implementation KIWheelView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self.container setFrame:self.bounds];
    [self setOriginalPoint:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    CGFloat distance = [self distanceWithPoint:point toOriginalPoint:self.originalPoint];
    
    if (distance > CGRectGetWidth(self.bounds)/2) {
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
	self.deltaAngle = atan2(dy,dx);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.touchBegin == NO) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
	float dx = point.x  - self.container.center.x;
	float dy = point.y  - self.container.center.y;
	float ang = atan2(dy,dx);
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
    
    if (tempIndex != self.selectedIndex) {
        self.selectedIndex = tempIndex;
        self.lastIndex = self.selectedIndex;
        if (self.wheelViewDidSelectedIndexBlock != nil) {
            self.wheelViewDidSelectedIndexBlock(self, self.selectedIndex);
        }
    }
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
    
    CGFloat angleSize = M_PI * 2 / self.numberOfSections;
    
    CGFloat perimeter = M_PI * CGRectGetWidth(self.bounds);
    CGFloat width = perimeter / self.numberOfSections;
    CGFloat height = CGRectGetHeight(self.container.bounds) / 2.0;
    
    for (int i=0; i<self.numberOfSections; i++) {
        UIView *view = [self viewAtSection:i];
        if (view != nil) {
            [view setFrame:CGRectMake(0, 0, width, height)];
            view.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
            view.layer.position    = point;
            view.transform         = CGAffineTransformMakeRotation(angleSize * i);
            [self.container addSubview:view];
            
            UIImageView *iv = [[UIImageView alloc] initWithFrame:view.bounds];
            [iv setImage:[UIImage imageNamed:@"section.png"]];
            [view addSubview:iv];
            
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
            }];
        }
    }
}

- (UIView *)viewAtSection:(NSInteger)index {
    if (self.wheelViewGetSectionViewBlock != nil) {
        return self.wheelViewGetSectionViewBlock(self, index);
    }
    return nil;
}

#pragma mark - Getters & Setters
- (void)setNumberOfSections:(NSInteger)numberOfSections {
    _numberOfSections = numberOfSections;
    [self buildWheel];
}

- (UIView *)container {
    if (_container == nil) {
        _container = [[UIView alloc] initWithFrame:self.bounds];
    }
    return _container;
}

- (void)setViewForSectionBlock:(KIWheelViewGetSectionViewBlock)block {
    [self setWheelViewGetSectionViewBlock:block];
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
