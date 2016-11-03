//
//  PhotoMaskerViewController.m
//  PhotoMasker
//
//  Created by Andrew Leo on 03/11/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

#import "ALOPhotoMaskerViewController.h"

typedef enum : NSUInteger {
    EditingTypeLine = 0,
    EditingTypeText,
} EditingType;

typedef enum : NSUInteger {
    OptionTypeUnknown = 0,
    OptionTypeAdd,
    OptionTypeRevert,
} OptionType;

@interface PanIndicator : UIImageView {}
@property (nonatomic, weak) NSArray *pointData;
@end

@implementation PanIndicator

- (void)drawRect:(CGRect)aRect {
    [super drawRect:aRect];
    
    UIBezierPath *pathToDraw = [UIBezierPath bezierPath];
    pathToDraw.lineWidth = 2.;
    UIColor *color = [UIColor redColor];
    [color set];
    
    for (NSInteger index = 0; index < _pointData.count; index++) {
        if (index == 0) {
            [pathToDraw moveToPoint:[_pointData[index] CGPointValue]];
        }
        else {
            [pathToDraw addLineToPoint:[_pointData[index] CGPointValue]];
        }
    }
    
    [pathToDraw stroke];
}

@end

@interface EditOption : NSObject
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) OptionType type;
@property (nonatomic, assign) BOOL selected;

+ (instancetype)optionWithType:(OptionType)type color:(UIColor *)color;

@end

@implementation EditOption

+ (instancetype)optionWithType:(OptionType)type color:(UIColor *)color {
    return [self optionWithType:type color:color selected:NO];
}

+ (instancetype)optionWithType:(OptionType)type color:(UIColor *)color selected:(BOOL)selected {
    EditOption *option = [[EditOption alloc] init];
    option.type = type;
    option.color = color;
    option.selected = selected;
    return option;
}

@end

@interface ALOPhotoMaskerViewController ()
<
UICollectionViewDelegate
,UICollectionViewDataSource
,UIGestureRecognizerDelegate
> {
    EditingType currentEditingType;
    NSMutableArray *optionData;
    
    NSMutableArray *pointData;
}

@property (strong, nonatomic) UIScrollView *imageContainer;
@property (strong, nonatomic) PanIndicator *drawView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UICollectionView *editContainer;
@property (strong, nonatomic) UIView *toolContainer;

@property (strong, nonatomic) UIButton *pencelButton;
@property (strong, nonatomic) UIButton *textButton;
@property (strong, nonatomic) UIView *arrowView;
@property (strong, nonatomic) NSLayoutConstraint *arrowViewCenterX;

@property (nonatomic, strong) NSData *imageData;

@end

@implementation ALOPhotoMaskerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadSubviews];
    [self loadOptionData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self adjustImageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Config

- (void)loadOptionData {
    currentEditingType = EditingTypeLine;
    optionData =
    [@[[@[[EditOption optionWithType:OptionTypeAdd color:[UIColor redColor] selected:YES]
        ,[EditOption optionWithType:OptionTypeAdd color:[UIColor orangeColor]]
        ,[EditOption optionWithType:OptionTypeAdd color:[UIColor yellowColor]]
        ,[EditOption optionWithType:OptionTypeAdd color:[UIColor greenColor]]
        ,[EditOption optionWithType:OptionTypeAdd color:[UIColor blueColor]]
        ,[EditOption optionWithType:OptionTypeAdd color:[UIColor purpleColor]]
        ] mutableCopy]
      ,[@[[EditOption optionWithType:OptionTypeAdd color:[UIColor redColor] selected:YES]
         ,[EditOption optionWithType:OptionTypeAdd color:[UIColor orangeColor]]
         ,[EditOption optionWithType:OptionTypeAdd color:[UIColor yellowColor]]
         ,[EditOption optionWithType:OptionTypeAdd color:[UIColor greenColor]]
         ,[EditOption optionWithType:OptionTypeAdd color:[UIColor blueColor]]
         ,[EditOption optionWithType:OptionTypeAdd color:[UIColor purpleColor]]
         ] mutableCopy]
      ] mutableCopy];
}

- (void)loadSubviews {
    /*
     TOOL VIEW
     */
    self.toolContainer = [[UIView alloc] init];
    self.toolContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.toolContainer.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:self.toolContainer];
    NSLayoutConstraint *toolContianerBottom = [NSLayoutConstraint
                                               constraintWithItem:self.toolContainer
                                               attribute:NSLayoutAttributeBottom
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.bottomLayoutGuide
                                               attribute:NSLayoutAttributeTop
                                               multiplier:1
                                               constant:0];
    NSLayoutConstraint *toolContianerLeft = [NSLayoutConstraint
                                             constraintWithItem:self.toolContainer
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.view
                                             attribute:NSLayoutAttributeLeft
                                             multiplier:1
                                             constant:0];
    NSLayoutConstraint *toolContianerRight = [NSLayoutConstraint
                                              constraintWithItem:self.toolContainer
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:self.view
                                              attribute:NSLayoutAttributeRight
                                              multiplier:1
                                              constant:0];
    NSLayoutConstraint *toolContianerHeight = [NSLayoutConstraint
                                               constraintWithItem:self.toolContainer
                                               attribute:NSLayoutAttributeHeight
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:nil
                                               attribute:NSLayoutAttributeNotAnAttribute
                                               multiplier:1
                                               constant:60];
    [self.view addConstraints:@[toolContianerLeft, toolContianerRight, toolContianerBottom]];
    [self.toolContainer addConstraint:toolContianerHeight];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setContentEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
    [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.toolContainer addSubview:cancelButton];
    NSLayoutConstraint *cancelButtonLeft = [NSLayoutConstraint
                                            constraintWithItem:cancelButton
                                            attribute:NSLayoutAttributeLeft
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.toolContainer
                                            attribute:NSLayoutAttributeLeft
                                            multiplier:1
                                            constant:0];
    NSLayoutConstraint *cancelButtonTop = [NSLayoutConstraint
                                           constraintWithItem:cancelButton
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.toolContainer
                                           attribute:NSLayoutAttributeTop
                                           multiplier:1
                                           constant:0];
    NSLayoutConstraint *cancelButtonBottom = [NSLayoutConstraint
                                              constraintWithItem:cancelButton
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:self.toolContainer
                                              attribute:NSLayoutAttributeBottom
                                              multiplier:1
                                              constant:0];
    [self.toolContainer addConstraints:@[cancelButtonTop, cancelButtonLeft, cancelButtonBottom]];
    
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [sendButton setContentEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
    [sendButton addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.toolContainer addSubview:sendButton];
    NSLayoutConstraint *sendButtonRight = [NSLayoutConstraint
                                           constraintWithItem:sendButton
                                           attribute:NSLayoutAttributeRight
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.toolContainer
                                           attribute:NSLayoutAttributeRight
                                           multiplier:1
                                           constant:0];
    NSLayoutConstraint *sendButtonTop = [NSLayoutConstraint
                                         constraintWithItem:sendButton
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:self.toolContainer
                                         attribute:NSLayoutAttributeTop
                                         multiplier:1
                                         constant:0];
    NSLayoutConstraint *sendButtonBottom = [NSLayoutConstraint
                                            constraintWithItem:sendButton
                                            attribute:NSLayoutAttributeBottom
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.toolContainer
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1
                                            constant:0];
    [self.toolContainer addConstraints:@[sendButtonTop, sendButtonRight, sendButtonBottom]];
    
    self.pencelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pencelButton addTarget:self action:@selector(selectPencel:) forControlEvents:UIControlEventTouchUpInside];
    self.pencelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pencelButton setTitle:@"P" forState:UIControlStateNormal];
    [self.pencelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.toolContainer addSubview:self.pencelButton];
    NSLayoutConstraint *pencelButtonWidth = [NSLayoutConstraint
                                             constraintWithItem:self.pencelButton
                                             attribute:NSLayoutAttributeWidth
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:nil
                                             attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                             constant:60];
    NSLayoutConstraint *pencelButtonTop = [NSLayoutConstraint
                                           constraintWithItem:self.pencelButton
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.toolContainer
                                           attribute:NSLayoutAttributeTop
                                           multiplier:1
                                           constant:0];
    NSLayoutConstraint *pencelButtonBottom = [NSLayoutConstraint
                                              constraintWithItem:self.pencelButton
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:self.toolContainer
                                              attribute:NSLayoutAttributeBottom
                                              multiplier:1
                                              constant:0];
    NSLayoutConstraint *pencelButtonCenterX = [NSLayoutConstraint
                                               constraintWithItem:self.pencelButton
                                               attribute:NSLayoutAttributeCenterX
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.toolContainer
                                               attribute:NSLayoutAttributeCenterX
                                               multiplier:0.75
                                               constant:0];
    [self.toolContainer addConstraints:@[pencelButtonTop, pencelButtonBottom, pencelButtonCenterX]];
    [self.pencelButton addConstraint:pencelButtonWidth];
    
    self.textButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.textButton addTarget:self action:@selector(selectText:) forControlEvents:UIControlEventTouchUpInside];
    self.textButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.textButton setTitle:@"A" forState:UIControlStateNormal];
    [self.textButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.toolContainer addSubview:self.textButton];
    NSLayoutConstraint *textButtonWidth = [NSLayoutConstraint
                                           constraintWithItem:self.textButton
                                           attribute:NSLayoutAttributeWidth
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:nil
                                           attribute:NSLayoutAttributeNotAnAttribute
                                           multiplier:1
                                           constant:60];
    NSLayoutConstraint *textButtonTop = [NSLayoutConstraint
                                         constraintWithItem:self.textButton
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:self.toolContainer
                                         attribute:NSLayoutAttributeTop
                                         multiplier:1
                                         constant:0];
    NSLayoutConstraint *textButtonBottom = [NSLayoutConstraint
                                            constraintWithItem:self.textButton
                                            attribute:NSLayoutAttributeBottom
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.toolContainer
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1
                                            constant:0];
    NSLayoutConstraint *textButtonCenterX = [NSLayoutConstraint
                                             constraintWithItem:self.textButton
                                             attribute:NSLayoutAttributeCenterX
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.toolContainer
                                             attribute:NSLayoutAttributeCenterX
                                             multiplier:1.25
                                             constant:0];
    [self.toolContainer addConstraints:@[textButtonTop, textButtonBottom, textButtonCenterX]];
    [self.textButton addConstraint:textButtonWidth];
    
    /*
     EDIT OPTION VIEW
     */
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.itemSize = CGSizeMake(30, 30);
    collectionViewLayout.minimumLineSpacing = 20;
    collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.editContainer = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    [self.editContainer registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"kUICollectionViewCell"];
    self.editContainer.delegate = self;
    self.editContainer.dataSource = self;
    self.editContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.editContainer.showsVerticalScrollIndicator = NO;
    self.editContainer.showsHorizontalScrollIndicator = NO;
    self.editContainer.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.editContainer];
    NSLayoutConstraint *editContianerBottom = [NSLayoutConstraint
                                               constraintWithItem:self.editContainer
                                               attribute:NSLayoutAttributeBottom
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.toolContainer
                                               attribute:NSLayoutAttributeTop
                                               multiplier:1
                                               constant:0];
    NSLayoutConstraint *editContianerLeft = [NSLayoutConstraint
                                             constraintWithItem:self.editContainer
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.view
                                             attribute:NSLayoutAttributeLeft
                                             multiplier:1
                                             constant:0];
    NSLayoutConstraint *editContianerRight = [NSLayoutConstraint
                                              constraintWithItem:self.editContainer
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:self.view
                                              attribute:NSLayoutAttributeRight
                                              multiplier:1
                                              constant:0];
    NSLayoutConstraint *editContianerHeight = [NSLayoutConstraint
                                               constraintWithItem:self.editContainer
                                               attribute:NSLayoutAttributeHeight
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:nil
                                               attribute:NSLayoutAttributeNotAnAttribute
                                               multiplier:1
                                               constant:60];
    [self.view addConstraints:@[editContianerLeft, editContianerRight, editContianerBottom]];
    [self.editContainer addConstraint:editContianerHeight];
    
    self.arrowView = [[UIView alloc] init];
    self.arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    self.arrowView.backgroundColor = [UIColor grayColor];
    [self.toolContainer addSubview:self.arrowView];
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:(CGPoint){0, 0}];
    [path addLineToPoint:(CGPoint){10, 10}];
    [path addLineToPoint:(CGPoint){20, 0}];
    [path addLineToPoint:(CGPoint){0, 0}];
    CAShapeLayer *mask = [CAShapeLayer new];
    mask.frame = self.arrowView.bounds;
    mask.path = path.CGPath;
    self.arrowView.layer.mask = mask;
    self.arrowViewCenterX = [NSLayoutConstraint
                             constraintWithItem:self.arrowView
                             attribute:NSLayoutAttributeCenterX
                             relatedBy:NSLayoutRelationEqual
                             toItem:self.pencelButton
                             attribute:NSLayoutAttributeCenterX
                             multiplier:1
                             constant:0];
    NSLayoutConstraint *arrowTop = [NSLayoutConstraint
                                    constraintWithItem:self.arrowView
                                    attribute:NSLayoutAttributeTop
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:self.toolContainer
                                    attribute:NSLayoutAttributeTop
                                    multiplier:1
                                    constant:0];
    NSLayoutConstraint *arrowWidth = [NSLayoutConstraint
                                      constraintWithItem:self.arrowView
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:nil
                                      attribute:NSLayoutAttributeNotAnAttribute
                                      multiplier:1
                                      constant:20];
    NSLayoutConstraint *arrowHeight = [NSLayoutConstraint
                                       constraintWithItem:self.arrowView
                                       attribute:NSLayoutAttributeHeight
                                       relatedBy:NSLayoutRelationEqual
                                       toItem:nil
                                       attribute:NSLayoutAttributeNotAnAttribute
                                       multiplier:1
                                       constant:10];
    [self.toolContainer addConstraints:@[self.arrowViewCenterX, arrowTop]];
    [self.arrowView addConstraints:@[arrowWidth, arrowHeight]];
    
    /*
     IMAGE VIEW
     */
    self.imageContainer = [[UIScrollView alloc] init];
    self.imageContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageContainer.showsVerticalScrollIndicator = NO;
    self.imageContainer.showsHorizontalScrollIndicator = NO;
    self.imageContainer.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.imageContainer];
    NSLayoutConstraint *imageContianerTop = [NSLayoutConstraint
                                             constraintWithItem:self.imageContainer
                                             attribute:NSLayoutAttributeTop
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.topLayoutGuide
                                             attribute:NSLayoutAttributeBottom
                                             multiplier:1
                                             constant:0];
    NSLayoutConstraint *imageContianerLeft = [NSLayoutConstraint
                                              constraintWithItem:self.imageContainer
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:self.view
                                              attribute:NSLayoutAttributeLeft
                                              multiplier:1
                                              constant:0];
    NSLayoutConstraint *imageContianerRight = [NSLayoutConstraint
                                               constraintWithItem:self.imageContainer
                                               attribute:NSLayoutAttributeRight
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.view
                                               attribute:NSLayoutAttributeRight
                                               multiplier:1
                                               constant:0];
    NSLayoutConstraint *imageContianerBottom = [NSLayoutConstraint
                                                constraintWithItem:self.imageContainer
                                                attribute:NSLayoutAttributeBottom
                                                relatedBy:NSLayoutRelationEqual
                                                toItem:self.editContainer
                                                attribute:NSLayoutAttributeTop
                                                multiplier:1
                                                constant:0];
    [self.view addConstraints:@[imageContianerLeft, imageContianerRight, imageContianerBottom, imageContianerTop]];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = [UIColor blackColor];
    [self.imageContainer addSubview:self.imageView];
    
    self.drawView = [[PanIndicator alloc] init];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [panGesture setMaximumNumberOfTouches:1];
    [panGesture setDelegate:self];
    [self.drawView addGestureRecognizer:panGesture];
    self.drawView.opaque = YES;
    self.drawView.userInteractionEnabled = YES;
    self.drawView.translatesAutoresizingMaskIntoConstraints = NO;
    self.drawView.backgroundColor = [UIColor yellowColor];
    [self.imageContainer addSubview:self.drawView];
    NSLayoutConstraint *layoutTop = [NSLayoutConstraint
                                     constraintWithItem:self.drawView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.imageView
                                     attribute:NSLayoutAttributeTop
                                     multiplier:1
                                     constant:0];
    NSLayoutConstraint *layoutBottom = [NSLayoutConstraint
                                     constraintWithItem:self.drawView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.imageView
                                     attribute:NSLayoutAttributeBottom
                                     multiplier:1
                                     constant:0];
    NSLayoutConstraint *layoutRight = [NSLayoutConstraint
                                     constraintWithItem:self.drawView
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.imageView
                                     attribute:NSLayoutAttributeRight
                                     multiplier:1
                                     constant:0];
    NSLayoutConstraint *layoutLeft = [NSLayoutConstraint
                                     constraintWithItem:self.drawView
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.imageView
                                     attribute:NSLayoutAttributeLeft
                                     multiplier:1
                                     constant:0];
    [self.imageContainer addConstraints:@[layoutTop, layoutLeft, layoutRight, layoutBottom]];
}

#pragma mark - Action

- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)send:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)selectPencel:(id)sender {
    [self.toolContainer removeConstraint:self.arrowViewCenterX];
    self.arrowViewCenterX = [NSLayoutConstraint
                             constraintWithItem:self.arrowView
                             attribute:NSLayoutAttributeCenterX
                             relatedBy:NSLayoutRelationEqual
                             toItem:sender
                             attribute:NSLayoutAttributeCenterX
                             multiplier:1
                             constant:0];
    [self.toolContainer addConstraint:self.arrowViewCenterX];
    
    [self.pencelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.textButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    currentEditingType = EditingTypeLine;
    [self.editContainer reloadData];
}

- (void)selectText:(id)sender {
    [self.toolContainer removeConstraint:self.arrowViewCenterX];
    self.arrowViewCenterX = [NSLayoutConstraint
                             constraintWithItem:self.arrowView
                             attribute:NSLayoutAttributeCenterX
                             relatedBy:NSLayoutRelationEqual
                             toItem:sender
                             attribute:NSLayoutAttributeCenterX
                             multiplier:1
                             constant:0];
    [self.toolContainer addConstraint:self.arrowViewCenterX];
    
    [self.pencelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.textButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    currentEditingType = EditingTypeText;
    [self.editContainer reloadData];
}

- (void)panAction:(UIPanGestureRecognizer *)gR {
    if ([gR state] == UIGestureRecognizerStateBegan) {
        pointData = [[NSMutableArray alloc] init];
        [pointData addObject:[NSValue valueWithCGPoint:[gR locationInView:self.imageView]]];
    }
    else if ([gR state] == UIGestureRecognizerStateEnded) {
        self.drawView.pointData = pointData;
        [self.imageContainer setNeedsDisplay];
    }
    else if ([gR state] == UIGestureRecognizerStateChanged) {
        [pointData addObject:[NSValue valueWithCGPoint:[gR locationInView:self.imageView]]];
    }
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [optionData[currentEditingType] count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"kUICollectionViewCell" forIndexPath:indexPath];
    cell.layer.cornerRadius = 3.;
    cell.layer.masksToBounds = YES;
    cell.layer.borderWidth = 1.;
    EditOption *option = optionData[currentEditingType][indexPath.row];
    cell.layer.borderColor = option.selected ? [UIColor blackColor].CGColor : [UIColor clearColor].CGColor;
    cell.contentView.backgroundColor = option.color;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *data = optionData[currentEditingType];
    for (NSInteger index = 0; index < data.count; index++) {
        EditOption *option = data[index];
        option.selected = index == indexPath.row;
    }
    [collectionView reloadData];
}

#pragma mark - Method

- (void)setImage:(NSData *)imageData {
    self.imageData = imageData;
    if (self.imageView) {
        [self adjustImageView];
    }
}

- (void)adjustImageView {
    if (!self.imageData || !self.imageView) {
        return;
    }
    
    self.imageView.image = [UIImage imageWithData:self.imageData];
    
    CGRect containerBounds = self.imageContainer.bounds;
    CGSize imageSize = self.imageView.image.size;
    CGFloat scale = imageSize.width / containerBounds.size.width;
    self.imageView.frame = CGRectMake(0, 0, containerBounds.size.width, imageSize.height * scale);
    [self.imageContainer setContentSize:self.imageView.frame.size];
}

@end
