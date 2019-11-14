//
//  HJSignatureView.h
//  HJSignatureDemo
//
//  Created by Ju on 2018/11/22.
//  Copyright © 2018 HJ. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJSignatureView : UIView


/**
 清除签名
 */
- (void)clear;



/**
 保存签名

 @return 保存在本地的图片路径
 */
- (NSString *)saveTheSignatureWithError:(void(^)(NSString *errorMsg))errorBlock;

/**
 保存签名

 @return 返回签名的图片
 */
- (UIImage *)saveImageTheSignatureWithError:(void(^)(NSString *errorMsg))errorBlock;


/// 完成签字的block回调
@property (nonatomic, copy) void(^completeSignatureBlock)(void);

@end

NS_ASSUME_NONNULL_END
