//
//  GYStickerView.m
//  GYStickerView
//
//  Created by 黄国裕 on 17/1/23.
//  Copyright © 2017年 黄国裕. All rights reserved.
//

#import "GYStickerView.h"

@interface GYStickerView()<UIGestureRecognizerDelegate>

/**
 CtrlTypeOne
 变换控制图
 */
@property (strong, nonatomic) UIImageView *transformCtrl;//同时控制旋转和缩放，右下角

/**
 CtrlTypeTwo
 变换控制图
 */
@property (strong, nonatomic) UIImageView *rotateCtrl;//控制旋转，右上角
@property (strong, nonatomic) UIImageView *resizeCtrl;//控制缩放，右下角

/**
 移除StickerView
 */
@property (strong, nonatomic) UIImageView *removeCtrl;

/**
 参考点视图
 */
@property (strong, nonatomic) UIView *oCtrlPointView;

/**
 旋转的初始水平角度
 */
@property (nonatomic) CGFloat initialAngle;


/**
 记录上一个控制点
 */
@property (nonatomic) CGPoint lastCtrlPoint;


/**
 self的手势
 */
@property (nonatomic) UIPinchGestureRecognizer *pinchGesture;     //捏合手势
@property (nonatomic) UIRotationGestureRecognizer *rotateGesture; //旋转手势
@property (nonatomic) UIPanGestureRecognizer *panGesture;         //拖动手势


@end

@implementation GYStickerView

#define CTRL_RADIUS 10 //控制图的半径


- (instancetype)initWithContentView:(UIView *)contentView {
    self = [super init];
    if (self) {
        self.contentView = contentView;

        [self showRemoveCtrl:YES];
        self.ctrlType = GYStickerViewCtrlTypeGesture;//默认为手势模式
        self.originalPoint = CGPointMake(0.5, 0.5);  //默认参考点为中心点
        self.scaleFit = YES;

        [self addGestureRecognizer:self.panGesture];//添加拖动手势，所有模式通用
    }
    return self;
}


#pragma mark - setter & getter 方法


/* setter */

- (void)setContentView:(UIView *)contentView {
    if (_contentView) {
        [_contentView removeFromSuperview];
        _contentView = nil;
        self.transform = CGAffineTransformIdentity;
    }
    _contentView = contentView;
    self.frame = _contentView.frame;
    _contentView.frame = self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:_contentView atIndex:0];
}

- (void)setCtrlType:(GYStickerViewCtrlType)ctrlType {
    _ctrlType = ctrlType;
    switch (_ctrlType) {
        case GYStickerViewCtrlTypeGesture:
            if (![self.gestureRecognizers containsObject:self.pinchGesture]) {
                [self addGestureRecognizer:self.pinchGesture];
            }
            if (![self.gestureRecognizers containsObject:self.rotateGesture]) {
                [self addGestureRecognizer:self.rotateGesture];
            }
            self.transformCtrl.hidden = YES;
            self.rotateCtrl.hidden = YES;
            self.resizeCtrl.hidden = YES;
            break;

        case GYStickerViewCtrlTypeOne:
            if ([self.gestureRecognizers containsObject:self.pinchGesture]) {
                [self removeGestureRecognizer:self.pinchGesture];
            }
            if ([self.gestureRecognizers containsObject:self.rotateGesture]) {
                [self removeGestureRecognizer:self.rotateGesture];
            }
            self.transformCtrl.hidden = NO;
            self.rotateCtrl.hidden = YES;
            self.resizeCtrl.hidden = YES;
            break;

        case GYStickerViewCtrlTypeTwo:
            if ([self.gestureRecognizers containsObject:self.pinchGesture]) {
                [self removeGestureRecognizer:self.pinchGesture];
            }
            if ([self.gestureRecognizers containsObject:self.rotateGesture]) {
                [self removeGestureRecognizer:self.rotateGesture];
            }
            self.transformCtrl.hidden = YES;
            self.rotateCtrl.hidden = NO;
            self.resizeCtrl.hidden = NO;
            break;

        default:
            break;
    }
}

- (void)setOriginalPoint:(CGPoint)originalPoint {
    if (self.ctrlType == GYStickerViewCtrlTypeGesture) {
        _originalPoint = CGPointMake(0.5, 0.5);
        return;
    }
    _originalPoint = originalPoint;
    [self updateCtrlPoint];
}


/* getter */

- (UIImageView *)transformCtrl {
    if (!_transformCtrl) {
        CGRect frame = CGRectMake(self.bounds.size.width - CTRL_RADIUS,
                                  self.bounds.size.height - CTRL_RADIUS,
                                  CTRL_RADIUS * 2,
                                  CTRL_RADIUS * 2);
        _transformCtrl = [[UIImageView alloc] initWithFrame:frame];
        _transformCtrl.backgroundColor = [UIColor redColor];
        _transformCtrl.userInteractionEnabled = YES;
        _transformCtrl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_transformCtrl];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(transformCtrlPan:)];
        [_transformCtrl addGestureRecognizer:panGesture];
    }
    return _transformCtrl;
}

- (UIImageView *)rotateCtrl {
    if (!_rotateCtrl) {
        CGRect frame = CGRectMake(self.bounds.size.width - CTRL_RADIUS,
                                  0 - CTRL_RADIUS,
                                  CTRL_RADIUS * 2,
                                  CTRL_RADIUS * 2);
        _rotateCtrl = [[UIImageView alloc] initWithFrame:frame];
        _rotateCtrl.backgroundColor = [UIColor purpleColor];
        _rotateCtrl.userInteractionEnabled = YES;
        _rotateCtrl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:_rotateCtrl];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateCtrlPan:)];
        [_rotateCtrl addGestureRecognizer:panGesture];
    }
    return _rotateCtrl;
}

- (UIImageView *)resizeCtrl {
    if (!_resizeCtrl) {
        CGRect frame = CGRectMake(self.bounds.size.width - CTRL_RADIUS,
                                  self.bounds.size.height - CTRL_RADIUS,
                                  CTRL_RADIUS * 2,
                                  CTRL_RADIUS * 2);
        _resizeCtrl = [[UIImageView alloc] initWithFrame:frame];
        _resizeCtrl.backgroundColor = [UIColor brownColor];
        _resizeCtrl.userInteractionEnabled = YES;
        _resizeCtrl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_resizeCtrl];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(resizeCtrlPan:)];
        [_resizeCtrl addGestureRecognizer:panGesture];
    }
    return _resizeCtrl;
}

- (UIImageView *)removeCtrl {
    if (!_removeCtrl) {
        CGRect frame = CGRectMake(0 - CTRL_RADIUS,
                                  0 - CTRL_RADIUS,
                                  CTRL_RADIUS * 2,
                                  CTRL_RADIUS * 2);
        _removeCtrl = [[UIImageView alloc] initWithFrame:frame];
        _removeCtrl.backgroundColor = [UIColor blackColor];
        _removeCtrl.userInteractionEnabled = YES;
        [self addSubview:_removeCtrl];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeCtrlTap:)];
        [_removeCtrl addGestureRecognizer:tapGesture];
    }
    return _removeCtrl;
}

- (CGPoint)getRealOriginalPoint {
    return CGPointMake(self.bounds.size.width * self.originalPoint.x,
                       self.bounds.size.height * self.originalPoint.y);
}

- (CGFloat)initialAngle {
    if (self.ctrlType == GYStickerViewCtrlTypeOne) {
        _initialAngle = atan2(-(self.transformCtrl.center.y - [self getRealOriginalPoint].y),
                                  self.transformCtrl.center.x - [self getRealOriginalPoint].x);
    }
    if (self.ctrlType == GYStickerViewCtrlTypeTwo) {
        _initialAngle = atan2(-(self.rotateCtrl.center.y - [self getRealOriginalPoint].y),
                                  self.rotateCtrl.center.x - [self getRealOriginalPoint].x);
    }
    return _initialAngle;
}

- (UIPinchGestureRecognizer *)pinchGesture {
    if (!_pinchGesture) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        _pinchGesture.delegate = self;
    }
    return _pinchGesture;
}

- (UIRotationGestureRecognizer *)rotateGesture {
    if (!_rotateGesture) {
        _rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
        _rotateGesture.delegate = self;
    }
    return _rotateGesture;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        _panGesture.delegate = self;
        _panGesture.minimumNumberOfTouches = 1;
        _panGesture.maximumNumberOfTouches = 2;
    }
    return _panGesture;
}


#pragma mark - 手势响应事件 --- 无控制图

- (void)rotate:(UIRotationGestureRecognizer *)gesture {
    self.transform = CGAffineTransformRotate(self.transform, gesture.rotation);
    gesture.rotation = 0;
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture {
    CGFloat scale = gesture.scale;
    if (self.scaleMode == GYStickerViewScaleModeBounds) {
        self.bounds = CGRectMake(self.bounds.origin.x,
                                 self.bounds.origin.y,
                                 self.bounds.size.width * scale,
                                 self.bounds.size.height * scale);
    } else {
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
    }
    gesture.scale = 1;
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    CGPoint pt = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + pt.x , self.center.y + pt.y);
    [gesture setTranslation:CGPointMake(0, 0) inView:self.superview];
}


#pragma mark - 手势响应事件 --- 一个控制图

- (void)transformCtrlPan:(UIPanGestureRecognizer *)gesture {

    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastCtrlPoint = [self convertPoint:self.transformCtrl.center toView:self.superview];
        return;
    }

    CGPoint ctrlPoint = [gesture locationInView:self.superview];

    // scale
    [self scaleFitWithCtrlPoint:ctrlPoint];

    // rotate
    [self rotateAroundOPointWithCtrlPoint:ctrlPoint];
}


#pragma mark - 手势响应事件 --- 两个控制图

- (void)rotateCtrlPan:(UIPanGestureRecognizer *)gesture {
    CGPoint ctrlPoint = [gesture locationInView:self.superview];
    [self rotateAroundOPointWithCtrlPoint:ctrlPoint];
}

- (void)resizeCtrlPan:(UIPanGestureRecognizer *)gesture {
    //等比缩放
    if (self.scaleFit) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            self.lastCtrlPoint = [self convertPoint:self.transformCtrl.center toView:self.superview];
            return;
        }

        CGPoint ctrlPoint = [gesture locationInView:self.superview];
        [self scaleFitWithCtrlPoint:ctrlPoint];
        return;
    }

    //自由缩放
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastCtrlPoint = self.transformCtrl.center;
        return;
    }

    CGPoint ctrlPoint = [gesture locationInView:self];
    [self scaleFreeWithCtrlPoint:ctrlPoint ctrlCenter:self.resizeCtrl.center];
}


#pragma mark - 旋转 --- 实现

- (void)rotateAroundOPointWithCtrlPoint:(CGPoint)ctrlPoint {

    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x - (self.center.x - oPoint.x),
                              self.center.y - (self.center.y - oPoint.y));


    float angle = atan2(self.center.y - ctrlPoint.y, ctrlPoint.x - self.center.x);
    angle = self.initialAngle - angle;
    self.transform = CGAffineTransformMakeRotation(angle);


    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));

}


#pragma mark - 缩放 --- 实现

/* 等比缩放 */
- (void)scaleFitWithCtrlPoint:(CGPoint)ctrlPoint {
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = oPoint;


    CGFloat preDistance = [self distanceWithStartPoint:self.center endPoint:self.lastCtrlPoint];
    CGFloat newDistance = [self distanceWithStartPoint:self.center endPoint:ctrlPoint];
    CGFloat scale = newDistance / preDistance;
    self.bounds = CGRectMake(self.bounds.origin.x,
                             self.bounds.origin.y,
                             self.bounds.size.width * scale,
                             self.bounds.size.height * scale);


    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));

    self.lastCtrlPoint = ctrlPoint;
    [self updateCtrlPoint];
}

/* 自由缩放 */
- (void)scaleFreeWithCtrlPoint:(CGPoint)ctrlPoint ctrlCenter:(CGPoint)ctrlCenter{
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = oPoint;


    CGFloat cX = ctrlPoint.x - self.lastCtrlPoint.x;
    CGFloat cY = ctrlPoint.y - self.lastCtrlPoint.y;

    if ([self getRealOriginalPoint].y == ctrlCenter.y) {
        cY = 0;
    }
    if ([self getRealOriginalPoint].x == ctrlCenter.x) {
        cX = 0;
    }

    CGFloat width = self.bounds.size.width + cX;
    CGFloat height = self.bounds.size.height + cY;
    if (width > 0 && height > 0) {
        self.bounds = CGRectMake(self.bounds.origin.x,
                                 self.bounds.origin.y,
                                 self.bounds.size.width + cX,
                                 self.bounds.size.height + cY);
    }

    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));

    self.lastCtrlPoint = ctrlPoint;
    [self updateCtrlPoint];
}


#pragma mark - 移除StickerView

- (void)removeCtrlTap:(UITapGestureRecognizer *)gesture {
    [self removeFromSuperview];
}


#pragma mark - UIGestureRecognizerDelegate

/* 同时触发多个手势 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

/* 控制手势是否触发 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer.view == self) {
        CGPoint p = [touch locationInView:self];
        if (CGRectContainsPoint(self.transformCtrl.frame, p) ||
            CGRectContainsPoint(self.rotateCtrl.frame, p) ||
            CGRectContainsPoint(self.resizeCtrl.frame, p)) {
            return NO;
        }
    }
    return YES;
}


#pragma mark - 重写hitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        int count = (int)self.subviews.count;
        for (int i = count - 1; i >= 0; i--) {
            UIView *subView = self.subviews[i];
            CGPoint p = [subView convertPoint:point fromView:self];
            if (CGRectContainsPoint(subView.bounds, p)) {
                if (subView.isHidden) {
                    continue;
                }
                return subView;
            }
        }
    }
    return view;
}


#pragma mark - Actions

- (void)showCtrlPoint:(BOOL)b {
    if (self.ctrlType == GYStickerViewCtrlTypeGesture) {
        return;
    }
    if (!self.oCtrlPointView && b) {
        self.oCtrlPointView = [[UIView alloc] initWithFrame:CGRectMake([self getRealOriginalPoint].x - 4, [self getRealOriginalPoint].y - 4, 8, 8)];
        self.oCtrlPointView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.oCtrlPointView];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:self.oCtrlPointView.bounds];
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.fillColor = [UIColor redColor].CGColor;
        layer.path = path.CGPath;
        [self.oCtrlPointView.layer addSublayer:layer];
    }
    self.oCtrlPointView.hidden = !b;
}

- (void)updateCtrlPoint {
    if (self.oCtrlPointView) {
        self.oCtrlPointView.frame = CGRectMake([self getRealOriginalPoint].x - 4, [self getRealOriginalPoint].y - 4, 8, 8);
    }
}

- (void)showRemoveCtrl:(BOOL)b {
    self.removeCtrl.hidden = !b;
}

/* 计算两点间距 */
- (CGFloat)distanceWithStartPoint:(CGPoint)start endPoint:(CGPoint)end {
    CGFloat x = start.x - end.x;
    CGFloat y = start.y - end.y;
    return sqrt(x * x + y * y);
}


#pragma mark - 设置控制图图片

- (void)setTransformCtrlImage:(UIImage *)image {
    self.transformCtrl.backgroundColor = [UIColor clearColor];
    self.transformCtrl.image = image;
}

- (void)setResizeCtrlImage:(UIImage *)resizeImage rotateCtrlImage:(UIImage *)rotateImage {
    self.resizeCtrl.backgroundColor = [UIColor clearColor];
    self.rotateCtrl.backgroundColor = [UIColor clearColor];
    self.resizeCtrl.image = resizeImage;
    self.rotateCtrl.image = rotateImage;
}

- (void)setRemoveCtrlImage:(UIImage *)image {
    self.removeCtrl.backgroundColor = [UIColor clearColor];
    self.removeCtrl.image = image;
}


@end