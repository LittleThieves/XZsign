//
//  HJSignatureView.m
//  HJSignatureDemo
//
//  Created by Ju on 2018/11/22.
//  Copyright © 2018 HJ. All rights reserved.
//

#import "HJSignatureView.h"
#import <Photos/Photos.h>
#import "UIImage+HJImage.h"

@interface HJSignatureView()
@property (nonatomic, strong) UIBezierPath *signaturePath;
@property (nonatomic, assign) CGPoint oldPoint;

@property (nonatomic, assign) BOOL touchIn;

@property (nonatomic, strong) NSTimer *timer;

/**
 是否有签名
 */
@property (nonatomic, assign) BOOL isHaveSignature;
//绘画区域
@property (nonatomic, assign) CGFloat minX;
@property (nonatomic, assign) CGFloat minY;
@property (nonatomic, assign) CGFloat maxX;
@property (nonatomic, assign) CGFloat maxY;
@end

@implementation HJSignatureView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self config];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
       [self config];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    self.signaturePath.lineWidth = 2;
    [[UIColor blackColor] setStroke];
    [self.signaturePath stroke];
}

#pragma mark - 基础配置
- (void)config {
    self.backgroundColor = [UIColor whiteColor];
    self.oldPoint = CGPointZero;
    self.isHaveSignature = NO;
    self.minX = 0;
    self.maxX = 0;
    self.minY = 0;
    self.maxY = 0;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    [self.signaturePath moveToPoint:currentPoint];
    self.oldPoint = currentPoint;
    self.touchIn = YES;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    [self.signaturePath addQuadCurveToPoint:currentPoint controlPoint:self.oldPoint];
    self.oldPoint = currentPoint;
    //设置剪切图片的区域
    [self getImageRect:currentPoint];
    //设置签名存在
    if (!self.isHaveSignature) {
        self.isHaveSignature = YES;
    }
    [self setNeedsDisplay];
}
//手指离开屏幕时，调用一次
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.touchIn = NO;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.5f repeats:NO block:^(NSTimer * _Nonnull timer) {
         if (self.completeSignatureBlock) {
             self.completeSignatureBlock();
         }
    }];
}

- (void)setTouchIn:(BOOL)touchIn {
    _touchIn = touchIn;
    if (touchIn && self.timer) {
        [self.timer invalidate];
    }
}

- (void)getImageRect:(CGPoint)currentPoint {
    if (self.maxX == 0 && self.minX == 0) {
        self.maxX = currentPoint.x;
        self.minX = currentPoint.x;
    } else {
        if (self.maxX <= currentPoint.x) {
            self.maxX = currentPoint.x;
        }
        if (self.minX >= currentPoint.x) {
            self.minX = currentPoint.x;
        }
    }
    if (self.maxY == 0 && self.minY == 0) {
        self.maxY = self.minY = currentPoint.y;
    } else {
        if (self.maxY <= currentPoint.y) {
            self.maxY = currentPoint.y;
        }
        if (self.minY >= currentPoint.y) {
            self.minY = currentPoint.y;
        }
    }
    
}

#pragma mark - 清理
- (void)clear {
    self.signaturePath = [UIBezierPath bezierPath];
    self.isHaveSignature = NO;
    self.oldPoint = CGPointZero;
    self.minX = 0;
    self.maxX = 0;
    self.minY = 0;
    self.maxY = 0;
    [self setNeedsDisplay];
}

#pragma mark - 确认
- (NSString *)saveTheSignatureWithError:(void(^)(NSString *errorMsg))errorBlock {
    if (self.isHaveSignature) {
        //开启上下文
        UIGraphicsBeginImageContextWithOptions(self.bounds.size,NO, [UIScreen mainScreen].scale);
        //获取上下文
        CGContextRef ref = UIGraphicsGetCurrentContext();
        //截图
        [self.layer drawInContext:ref];
        //获取整个视图图片
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        //关闭上下文
        UIGraphicsEndImageContext();
        //获取绘画区域图片
        //需要获取图片真正的像素，求出比例
        NSInteger scale = CGImageGetHeight(image.CGImage) / image.size.height;
        //区域
        CGFloat space = 4;
        CGFloat x = self.minX * scale - space;
        CGFloat y = self.minY * scale - space;
        CGFloat width = (self.maxX - self.minX + space) * scale;
        CGFloat height = (self.maxY - self.minY + space) * scale;
        UIImage *drawImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect(image.CGImage, CGRectMake(x, y, width, height))];
        //压缩图片 将图片压缩到100kb以内
        NSData *imageData = [drawImage compressImageToSize:100 * 1024];
        //保存到本地
        NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *fileName = [NSUUID UUID].UUIDString;
        NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",fileName]];
        [imageData writeToFile:filePath atomically:YES];
        //清除签名
        [self clear];
       
        return filePath;
    } else {
        if (errorBlock) {
            errorBlock(@"签名不存在");
        }
        return nil;
    }
    
}

#pragma mark ================ 生成图片并返回 ================
- (UIImage *)saveImageTheSignatureWithError:(void(^)(NSString *errorMsg))errorBlock {

    if (self.isHaveSignature) {
        //开启上下文
        UIGraphicsBeginImageContextWithOptions(self.bounds.size,NO, [UIScreen mainScreen].scale);
        //获取上下文
        CGContextRef ref = UIGraphicsGetCurrentContext();
        //截图
        [self.layer drawInContext:ref];
        //获取整个视图图片
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        //关闭上下文
        UIGraphicsEndImageContext();
        //获取绘画区域图片
        //需要获取图片真正的像素，求出比例
        NSInteger scale = CGImageGetHeight(image.CGImage) / image.size.height;
        //区域
        CGFloat space = 4;
        CGFloat x = self.minX * scale - space;
        CGFloat y = self.minY * scale - space;
        CGFloat width = (self.maxX - self.minX + space) * scale;
        CGFloat height = (self.maxY - self.minY + space) * scale;
        UIImage *drawImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect(image.CGImage, CGRectMake(x, y, width, height))];
        //压缩图片 将图片压缩到100kb以内
        NSData *imageData = [drawImage compressImageToSize:100 * 1024];
        //清除签名
        [self clear];
        return [UIImage imageWithData:imageData];
    } else {
        if (errorBlock) {
            errorBlock(@"签名不存在");
        }
        return nil;
    }
}

#pragma mark - set & get
- (UIBezierPath *)signaturePath {
    if (!_signaturePath) {
        _signaturePath = [UIBezierPath bezierPath];
    }
    return _signaturePath;
}

@end
