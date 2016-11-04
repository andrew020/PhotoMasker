//
//  PhotoMaskerViewController.h
//  PhotoMasker
//
//  Created by Andrew Leo on 03/11/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ModifyDone)(NSData *imageData);

@interface ALOPhotoMaskerViewController : UIViewController

+ (ALOPhotoMaskerViewController *)presendPhotoMasker:(UIViewController *)sourceViewController imageData:(NSData *)imageData block:(ModifyDone)block;
- (void)setImage:(NSData *)imageData;

@property (nonatomic, strong) UIColor *bkColor;
@property (nonatomic, strong) ModifyDone block;

@end
