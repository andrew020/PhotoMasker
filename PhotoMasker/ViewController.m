//
//  ViewController.m
//  PhotoMasker
//
//  Created by Andrew Leo on 03/11/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

#import "ViewController.h"
#import "ALOPhotoMaskerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)start:(id)sender {
    ALOPhotoMaskerViewController *controller = [[ALOPhotoMaskerViewController alloc] init];
    [controller setImage:UIImagePNGRepresentation([UIImage imageNamed:@"girls_PNG6448"])];
    [self presentViewController:controller animated:YES completion:nil];
}


@end
