//
//  ViewController.m
//  testsignature
//
//  Created by it on 2019/11/5.
//  Copyright © 2019 房趣科技. All rights reserved.
//

#define HJScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define HJScreenHeight ([UIScreen mainScreen].bounds.size.height)

#import "ViewController.h"

#import "HJSignatureView.h"
#import <Photos/Photos.h>
#import "UIImage+HJImage.h"

static CGFloat const HJButtonHeight = 45;

@interface ViewController ()

@property (nonatomic, strong) HJSignatureView *signatureView;

@property (nonatomic, strong) UIView *imgsV;

@property (nonatomic, assign) CGFloat bigW;
@property (nonatomic, assign) CGFloat bigH;

///清除重写按钮
@property (weak, nonatomic) IBOutlet UIButton *cleanBtn;
///提交签字按钮
@property (weak, nonatomic) IBOutlet UIButton *submitBtn;
///签字结果背景View
@property (weak, nonatomic) IBOutlet UIView *backV;
///签字区域的背景view
@property (weak, nonatomic) IBOutlet UIView *imgBackV;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIDevice currentDevice] setValue:@(UIDeviceOrientationLandscapeLeft) forKey:@"orientation"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"orientation" object:@(YES)];
}

#pragma mark ================ 初始化UI ================
- (void)configUI {
    
    [self.imgBackV addSubview:self.signatureView];
    
    self.backV.hidden = YES;
    
    self.cleanBtn.layer.borderWidth = 1.f;
    self.cleanBtn.layer.borderColor = [UIColor colorWithRed:249/255.0 green:139/255.0 blue:0/255.0 alpha:1.0].CGColor;
    self.cleanBtn.layer.cornerRadius = 4.f;
    self.cleanBtn.layer.masksToBounds = YES;
    
    self.submitBtn.layer.cornerRadius = 4.f;
    self.submitBtn.layer.masksToBounds = YES;
    
    self.submitBtn.superview.layer.shadowColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.1].CGColor;
    self.submitBtn.superview.layer.shadowOffset = CGSizeMake(0,-2);
    self.submitBtn.superview.layer.shadowOpacity = 1;
    self.submitBtn.superview.layer.shadowRadius = 4;
    
    
    self.signatureView.completeSignatureBlock = ^{
        [self clickSubmitBtn:self.submitBtn];
    };
}

#pragma mark ================ 清除重写按钮回调 ================
- (IBAction)clickCleanBtn:(UIButton *)sender {
    self.backV.hidden = YES;
    [self.imgsV removeFromSuperview];
    self.imgsV = nil;
    [self.signatureView clear];
}

#pragma mark ================ 提交签字按钮回调 ================
- (IBAction)clickSubmitBtn:(UIButton *)sender {
    
    UIImage *img = [self.signatureView saveImageTheSignatureWithError:^(NSString * _Nonnull errorMsg) {
        NSLog(@"%@",errorMsg);
    }];
    if (img) {
        self.backV.hidden = NO;
        [self configSignatureImgWithImg:img];
    }
}

#pragma mark ================ set & get ================
- (HJSignatureView *)signatureView {
    if (!_signatureView) {
        _signatureView = [[HJSignatureView alloc] initWithFrame:CGRectMake(0, 0, 301, 300)];
        _signatureView.backgroundColor = [UIColor clearColor];
    }
    return _signatureView;
}
- (UIView *)imgsV {
    if (!_imgsV) {
        _imgsV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 45.f)];
        _imgsV.backgroundColor = [UIColor whiteColor];
        [self.backV addSubview:_imgsV];
    }
    return _imgsV;
}

#pragma mark ================ 设置签字内容的UI ================
- (void)configSignatureImgWithImg:(UIImage *)img {
    
    CGFloat x = self.imgsV.bounds.size.width;
    UIImageView *imgV = [[UIImageView alloc] initWithImage:img];
    imgV.contentMode = UIViewContentModeScaleAspectFit;
    imgV.backgroundColor = [UIColor clearColor];
    CGFloat zoom = img.size.width/img.size.height;
    CGFloat h = 45.f;
    CGFloat w = zoom > 1 ? h : h*zoom;
    imgV.frame = CGRectMake(x, 0, w, h);
    CGRect frame = self.imgsV.frame;
    frame.size.width = frame.size.width+w;
    self.imgsV.frame = frame;
    [self.imgsV addSubview:imgV];
    self.imgsV.center = [self.view convertPoint:self.backV.center toView:self.backV];
    if (self.bigH < img.size.height) {
        self.bigH = img.size.height;
    }
}

- (IBAction)clickSaveImageBtn:(UIButton *)sender {
    
//    UIImage *resultImage = [self pinjieImage];
    UIImage *resultImage = [self convertViewToImage:self.imgsV];
    //压缩图片 将图片压缩到100kb以内
    NSData *imageData = [resultImage compressImageToSize:100 * 1024];
    resultImage = [UIImage imageWithData:imageData];
    [[PHPhotoLibrary sharedPhotoLibrary]performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:resultImage];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@",@"保存失败");
        } else {
            NSLog(@"%@",@"保存成功");
        }
    }];
}

#pragma mark ================ 拼接图片 ================
- (UIImage *)pinjieImage {
    UIImageView *imgV = self.imgsV.subviews.firstObject;
    UIImage *resultImage = imgV.image;
    for (NSInteger i = 1; i < self.imgsV.subviews.count; i++) {
        imgV = self.imgsV.subviews[i];
        UIImage *img = imgV.image;
        resultImage = [self addSlaveImage:img toMasterImage:resultImage];
    }
    return resultImage;
}

/* masterImage  主图片，生成的图片的宽度为masterImage的宽度
 * slaveImage   从图片，拼接在masterImage的下面
 */
- (UIImage *)addSlaveImage:(UIImage *)slaveImage toMasterImage:(UIImage *)masterImage {
    CGSize size;
    
    size.width = slaveImage.size.width + masterImage.size.width;
    size.height = self.bigH;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    //Draw masterImage
    [masterImage drawInRect:CGRectMake(0, (self.bigH-masterImage.size.height)/2, masterImage.size.width, masterImage.size.height)];
    
    //Draw slaveImage
    [slaveImage drawInRect:CGRectMake(masterImage.size.width, (self.bigH-slaveImage.size.height)/2, slaveImage.size.width, slaveImage.size.height)];
    NSLog(@"%f   %@   %@", self.bigH, NSStringFromCGSize(masterImage.size), NSStringFromCGSize(slaveImage.size));
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

- (UIImage *)convertViewToImage:(UIView *)view {
    // 第二个参数表示是否非透明。如果需要显示半透明效果，需传NO，否则YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(view.bounds.size.width, view.bounds.size.height), YES, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


@end
