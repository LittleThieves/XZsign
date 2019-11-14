//
//  UIImage+HJImage.h
//  HJCamera_Demo
//
//  Created by HJ on 2018/4/18.
//  Copyright © 2018年 MDLK-HJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (HJImage)

/**
 压缩图片到指定大小

 @param maxSize 例如100 * 1024  100kb以内
 @return data
 */
- (NSData *)compressImageToSize:(NSInteger)maxSize;

/**
 无损压缩

 @return data
 */
- (NSData *)compressImageNoAffectQuality;

/**
 拉伸图片

 @return 返回拉伸图
 */
- (UIImage *)tensileImage;

@end
