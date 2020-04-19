//
//  OpenCVWrapper.h
//  test
//
//  Created by Jessica Zhang on 4/18/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (NSString *)openCVVersionString;
+ (UIImage *)changeImageBrightness:(UIImage *)image : (float)val;
+ (UIImage *)changeSaturation: (UIImage *)image : (int) satChange : (int) colorChannel;

@end

NS_ASSUME_NONNULL_END
