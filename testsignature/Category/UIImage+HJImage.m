//
//  UIImage+HJImage.m
//  HJCamera_Demo
//
//  Created by HJ on 2018/4/18.
//  Copyright © 2018年 MDLK-HJ. All rights reserved.
//

#import "UIImage+HJImage.h"

@implementation UIImage (HJImage)

#pragma mark - 压缩图片到指定大小
- (NSData *)compressImageToSize:(NSInteger)maxSize {
    CGFloat compress = 1;
    NSData *data = UIImageJPEGRepresentation(self, compress);
    //如果图片本身大小小于maxSize就直接返回
    NSLog(@"------------%.1lu KB", data.length / 1024);
    if (data.length < maxSize) return data;
    //压缩图片的质量优点在于可以更好的保留图片的清晰度，缺点在于可能我们compress继续
    //减小，data也不会再减小，不能保证压缩后小于指定的大小
    //为了快速压缩我们使用二分法来进行优化循环
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; i++) {
        compress = (max + min) / 2;
        data = UIImageJPEGRepresentation(self, compress);
        //如果data.length小于maxSize * 0.9 代表data.length过小那么就让最小数变大
        //此处为何是0.9，因为我们需要返回data的大小在出入指定大小maxSize在90% ~ 100%
        if (data.length < maxSize * 0.9) {
            min = compress;
        } else if (data.length > maxSize) {
            //如果data.length大于maxSize 代表data.length过大那么就让最大数变小
            max = compress;
        } else {
            break;
        }
    }
    
    //当对质量进行压缩并没达到我们需要的大小时我们可以对图片大小进行压缩
    //压缩图片尺寸会达到我们理想的大小，但会让图片变得相对模糊
    //判断质量压缩后的大小是否小于maxSize
    NSLog(@"------------%.1lu KB", data.length / 1024);
    if (data.length < maxSize) return data;
    UIImage *image = [UIImage imageWithData:data];
    NSInteger lastLength = 0;
    while (data.length > maxSize && data.length != lastLength) {
        lastLength = data.length;
        //计算比例
        CGFloat ratio = (CGFloat)maxSize / data.length;
        //计算在比例下的size，注意要将宽高转变成整数，否则可能会出现图片百边的情况
        CGSize size = CGSizeMake((NSInteger)(image.size.width * sqrtf(ratio)), (NSInteger)(image.size.height * sqrtf(ratio)));
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        data = UIImageJPEGRepresentation(image, 1);
        NSLog(@"------------%.1lu KB", data.length / 1024);
    }
    NSLog(@"------------%.1lu KB", data.length / 1024);
    return data;
}

#pragma mark - 无损压缩
- (NSData *)compressImageNoAffectQuality {
    CGFloat compress = 1;
    NSData *data = UIImageJPEGRepresentation(self, compress);
    //压缩图片的质量优点在于可以更好的保留图片的清晰度，缺点在于可能我们compress继续
    //减小，data也不会再减小，不能保证压缩后小于指定的大小
    //为了快速压缩我们使用二分法来进行优化循环
    CGFloat max = 1;
    CGFloat min = 0;
    NSInteger lastLength = 0;
    //此处我们最多循环六次
    for (int i = 0; i < 6; i++) {
        compress = (max + min) / 2;
        data = UIImageJPEGRepresentation(self, compress);
        //当我们检测到上一次图片的大小和这一次图片大小一样，代表已经不能压缩了就跳出block
        if (data.length != lastLength) {
            lastLength = data.length;
            max = compress;
            NSLog(@"------------%.1lu KB", data.length / 1024);
        } else {
            break;
        }
    }
    return data;
}

#pragma mark - 拉伸图片
- (UIImage *)tensileImage {
    CGFloat top = self.size.height * 0.5;
    CGFloat bottom = self.size.height * 0.5;
    CGFloat left = self.size.width * 0.5;
    CGFloat right = self.size.width * 0.5;
    return [self resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

@end
