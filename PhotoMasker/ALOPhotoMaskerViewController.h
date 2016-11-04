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

- (void)setImage:(NSData *)imageData;

@property (nonatomic, strong) UIColor *bkColor;
@property (nonatomic, assign) ModifyDone block;

@end
