//
//  MyImagePickerViewController.h
//  cameratestapp
//
//  Created by liman on 6/24/14.
//  Copyright (c) 2014 liman. All rights reserved.
//
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIViewExt.h"
#import "UIView+Utils.h"
#import "LeafButton.h"
#import "UIButton+Utils.h"

@class PKImagePickerViewController;
@protocol PKImagePickerViewControllerDelegate <NSObject>

- (void)imagePickerController:(PKImagePickerViewController *)picker didFinishPickingImage:(UIImage *)image;

@end

@interface PKImagePickerViewController : UIViewController

// 返回按钮
@property (strong, nonatomic) UIButton *dismissBtn;
// 拍摄按钮
@property (strong, nonatomic) LeafButton *captureBtn;

@property (weak,   nonatomic) id<PKImagePickerViewControllerDelegate> delegate;
@end
