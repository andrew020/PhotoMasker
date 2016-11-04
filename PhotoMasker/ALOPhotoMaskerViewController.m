//
//  PhotoMaskerViewController.m
//  PhotoMasker
//
//  Created by Andrew Leo on 03/11/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

#import "ALOPhotoMaskerViewController.h"

static NSString *kColor = @"kColor";
static NSString *kData = @"kData";

typedef enum : NSUInteger {
    EditingTypeLine = 0,
    EditingTypeText,
} EditingType;

typedef enum : NSUInteger {
    OptionTypeUnknown = 0,
    OptionTypeAdd,
    OptionTypeRevert,
} OptionType;

typedef void(^TextBoxCloseBlock)(id);

@interface TextBox : UIView {
    UILabel *textlabel;
    UIButton *closebutton;
    UIButton *resizebutton;
    
    CGPoint startLoction;
}

@property (nonatomic, weak) TextBoxCloseBlock closeBlock;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *textColor;

@end

@implementation TextBox

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect labelFrame = CGRectInset(self.bounds, 10, 10);
        textlabel = [[UILabel alloc] initWithFrame:labelFrame];
        [self addSubview:textlabel];
        
        closebutton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closebutton setTitle:@"X" forState:UIControlStateNormal];
        closebutton.frame = CGRectMake(0, 0, 20, 20);
        [closebutton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:closebutton];
        
        resizebutton = [UIButton buttonWithType:UIButtonTypeCustom];
        [resizebutton setTitle:@"*" forState:UIControlStateNormal];
        resizebutton.frame = CGRectMake(0, 0, 20, 20);
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [panGesture setMaximumNumberOfTouches:1];
        [resizebutton addGestureRecognizer:panGesture];

        [self addSubview:resizebutton];
    }
    return self;
}

- (void)panAction:(UIPanGestureRecognizer *)gR {
    if ([gR state] == UIGestureRecognizerStateBegan) {
        startLoction = [gR locationInView:resizebutton];
    }
    else if ([gR state] == UIGestureRecognizerStateEnded) {
        if (startLoction.x == 0 && startLoction.y == 0) {
            return;
        }
        CGPoint currentPoint = [gR locationInView:resizebutton];
        CGFloat increaseHeight = currentPoint.y - startLoction.y;
        CGFloat increaseWidth = currentPoint.x - startLoction.x;
    }
    else if ([gR state] == UIGestureRecognizerStateChanged) {
        startLoction = CGPointZero;
    }
}

- (void)close:(id)sender {
    if (self.closeBlock) {
        self.closeBlock(self);
    }
    [self removeFromSuperview];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGRect bounds = [self bounds];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat radius = 0.5f * CGRectGetHeight(bounds);
    
    
    // Create the "visible" path, which will be the shape that gets the inner shadow
    // In this case it's just a rounded rect, but could be as complex as your want
    CGMutablePathRef visiblePath = CGPathCreateMutable();
    CGRect innerRect = CGRectInset(bounds, radius, radius);
    CGPathMoveToPoint(visiblePath, NULL, innerRect.origin.x, bounds.origin.y);
    CGPathAddLineToPoint(visiblePath, NULL, innerRect.origin.x + innerRect.size.width, bounds.origin.y);
    CGPathAddArcToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, bounds.origin.y, bounds.origin.x + bounds.size.width, innerRect.origin.y, radius);
    CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, innerRect.origin.y + innerRect.size.height);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height, innerRect.origin.x + innerRect.size.width, bounds.origin.y + bounds.size.height, radius);
    CGPathAddLineToPoint(visiblePath, NULL, innerRect.origin.x, bounds.origin.y + bounds.size.height);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x, bounds.origin.y + bounds.size.height, bounds.origin.x, innerRect.origin.y + innerRect.size.height, radius);
    CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x, innerRect.origin.y);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x, bounds.origin.y, innerRect.origin.x, bounds.origin.y, radius);
    CGPathCloseSubpath(visiblePath);
    
    // Fill this path
    UIColor *aColor = [UIColor redColor];
    [aColor setFill];
    CGContextAddPath(context, visiblePath);
    CGContextFillPath(context);
    
    
    // Now create a larger rectangle, which we're going to subtract the visible path from
    // and apply a shadow
    CGMutablePathRef path = CGPathCreateMutable();
    //(when drawing the shadow for a path whichs bounding box is not known pass "CGPathGetPathBoundingBox(visiblePath)" instead of "bounds" in the following line:)
    //-42 cuould just be any offset > 0
    CGPathAddRect(path, NULL, CGRectInset(bounds, -42, -42));
    
    // Add the visible path (so that it gets subtracted for the shadow)
    CGPathAddPath(path, NULL, visiblePath);
    CGPathCloseSubpath(path);
    
    // Add the visible paths as the clipping path to the context
    CGContextAddPath(context, visiblePath);
    CGContextClip(context);
    
    
    // Now setup the shadow properties on the context
    aColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 3.0f, [aColor CGColor]);
    
    // Now fill the rectangle, so the shadow gets drawn
    [aColor setFill];   
    CGContextSaveGState(context);   
    CGContextAddPath(context, path);
    CGContextEOFillPath(context);
    
    // Release the paths
    CGPathRelease(path);    
    CGPathRelease(visiblePath);
}

@end

@interface PanIndicator : UIImageView {}
@property (nonatomic, weak) NSArray *panDrawData;
@end

@implementation PanIndicator

- (void)selfDraw {
    [PanIndicator drawMaskOnContext:_panDrawData];
}

+ (void)drawMaskOnContext:(NSArray *)drawData {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3.);
    
    for (NSInteger index = 0; index < drawData.count; index++) {
        CGContextBeginPath(context);
        
        NSDictionary *dataInfo = drawData[index];
        UIColor *color = [dataInfo objectForKey:kColor];
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        
        NSArray *points = [dataInfo objectForKey:kData];
        for (NSInteger indexPoint = 0; indexPoint < points.count; indexPoint++) {
            if (indexPoint == 0) {
                CGContextMoveToPoint(context, [points[indexPoint] CGPointValue].x, [points[indexPoint] CGPointValue].y);
            }
            else {
                CGContextAddLineToPoint(context, [points[indexPoint] CGPointValue].x, [points[indexPoint] CGPointValue].y);
            }
        }
        
        CGContextStrokePath(context);
    }
}

- (void)drawRect:(CGRect)aRect {
    [super drawRect:aRect];
    
    [self selfDraw];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    UIGraphicsPushContext(context);
    [self selfDraw];
    UIGraphicsPopContext();
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
    EditOption *currentOption;
    
    NSMutableArray *drawData;
    NSMutableArray *pointData;
}

@property (strong, nonatomic) UIScrollView *imageContainer;
@property (strong, nonatomic) PanIndicator *drawView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UICollectionView *editContainer;
@property (strong, nonatomic) UIView *toolContainer;

@property (strong, nonatomic) UIButton *revertButton;
@property (strong, nonatomic) UIButton *pencelButton;
@property (strong, nonatomic) UIButton *textButton;
@property (strong, nonatomic) UIView *arrowView;
@property (strong, nonatomic) NSLayoutConstraint *arrowViewCenterX;

@property (nonatomic, strong) NSData *imageData;

@end

@implementation ALOPhotoMaskerViewController

@synthesize bkColor = _bkColor;

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

#pragma mark - Property

- (UIColor *)bkColor {
    if (!_bkColor) {
        return [UIColor colorWithRed:240 / 255. green:246 / 255. blue:254 / 255. alpha:1];
    }
    return _bkColor;
}

#pragma mark - Config

- (void)loadOptionData {
    drawData = [[NSMutableArray alloc] init];
    currentEditingType = EditingTypeLine;
    currentOption = [EditOption optionWithType:OptionTypeAdd color:[UIColor redColor] selected:YES];
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
    self.toolContainer.backgroundColor = self.bkColor;
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
    [cancelButton setContentEdgeInsets:UIEdgeInsetsMake(0, 25, 0, 10)];
    [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
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
    [sendButton setContentEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 25)];
    [sendButton addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [sendButton setTitle:@"Save" forState:UIControlStateNormal];
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
    
    self.revertButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.revertButton addTarget:self action:@selector(revert:) forControlEvents:UIControlEventTouchUpInside];
    self.revertButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.revertButton setImage:[UIImage imageNamed:@"revert"] forState:UIControlStateNormal];
    [self.revertButton setImage:[UIImage imageNamed:@"revert_disabled"] forState:UIControlStateDisabled];
    [self.revertButton setEnabled:NO];
    [self.toolContainer addSubview:self.revertButton];
    NSLayoutConstraint *revertButtonWidth = [NSLayoutConstraint
                                             constraintWithItem:self.revertButton
                                             attribute:NSLayoutAttributeWidth
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:nil
                                             attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                             constant:60];
    NSLayoutConstraint *revertButtonTop = [NSLayoutConstraint
                                           constraintWithItem:self.revertButton
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.toolContainer
                                           attribute:NSLayoutAttributeTop
                                           multiplier:1
                                           constant:0];
    NSLayoutConstraint *revertButtonBottom = [NSLayoutConstraint
                                              constraintWithItem:self.revertButton
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:self.toolContainer
                                              attribute:NSLayoutAttributeBottom
                                              multiplier:1
                                              constant:0];
    NSLayoutConstraint *revertButtonCenterX = [NSLayoutConstraint
                                               constraintWithItem:self.revertButton
                                               attribute:NSLayoutAttributeCenterX
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.toolContainer
                                               attribute:NSLayoutAttributeCenterX
                                               multiplier:0.75
                                               constant:0];
    [self.toolContainer addConstraints:@[revertButtonTop, revertButtonBottom, revertButtonCenterX]];
    [self.revertButton addConstraint:revertButtonWidth];
    
    self.pencelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pencelButton addTarget:self action:@selector(selectPencel:) forControlEvents:UIControlEventTouchUpInside];
    self.pencelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pencelButton setImage:[UIImage imageNamed:@"line"] forState:UIControlStateNormal];
    [self.pencelButton setImage:[UIImage imageNamed:@"line_selected"] forState:UIControlStateHighlighted];
    [self.toolContainer addSubview:self.pencelButton];
    [[self pencelButton] performSelector:@selector(setHighlighted:) withObject:@(YES) afterDelay:0];
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
                                               multiplier:1.25
                                               constant:0];
    [self.toolContainer addConstraints:@[pencelButtonTop, pencelButtonBottom, pencelButtonCenterX]];
    [self.pencelButton addConstraint:pencelButtonWidth];
    
//    self.textButton = [UIButton buttonWithType:UIButtonTypeSystem];
//    [self.textButton addTarget:self action:@selector(selectText:) forControlEvents:UIControlEventTouchUpInside];
//    self.textButton.translatesAutoresizingMaskIntoConstraints = NO;
//    [self.textButton setTitle:@"A" forState:UIControlStateNormal];
//    [self.textButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.toolContainer addSubview:self.textButton];
//    NSLayoutConstraint *textButtonWidth = [NSLayoutConstraint
//                                           constraintWithItem:self.textButton
//                                           attribute:NSLayoutAttributeWidth
//                                           relatedBy:NSLayoutRelationEqual
//                                           toItem:nil
//                                           attribute:NSLayoutAttributeNotAnAttribute
//                                           multiplier:1
//                                           constant:60];
//    NSLayoutConstraint *textButtonTop = [NSLayoutConstraint
//                                         constraintWithItem:self.textButton
//                                         attribute:NSLayoutAttributeTop
//                                         relatedBy:NSLayoutRelationEqual
//                                         toItem:self.toolContainer
//                                         attribute:NSLayoutAttributeTop
//                                         multiplier:1
//                                         constant:0];
//    NSLayoutConstraint *textButtonBottom = [NSLayoutConstraint
//                                            constraintWithItem:self.textButton
//                                            attribute:NSLayoutAttributeBottom
//                                            relatedBy:NSLayoutRelationEqual
//                                            toItem:self.toolContainer
//                                            attribute:NSLayoutAttributeBottom
//                                            multiplier:1
//                                            constant:0];
//    NSLayoutConstraint *textButtonCenterX = [NSLayoutConstraint
//                                             constraintWithItem:self.textButton
//                                             attribute:NSLayoutAttributeCenterX
//                                             relatedBy:NSLayoutRelationEqual
//                                             toItem:self.toolContainer
//                                             attribute:NSLayoutAttributeCenterX
//                                             multiplier:1.25
//                                             constant:0];
//    [self.toolContainer addConstraints:@[textButtonTop, textButtonBottom, textButtonCenterX]];
//    [self.textButton addConstraint:textButtonWidth];
    
    /*
     EDIT OPTION VIEW
     */
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.itemSize = CGSizeMake(40, 40);
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
    self.editContainer.backgroundColor = self.bkColor;
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
    self.arrowView.backgroundColor = self.bkColor;
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
    self.imageContainer.bounces = NO;
    self.imageContainer.backgroundColor = self.bkColor;
    [self.view addSubview:self.imageContainer];
    NSLayoutConstraint *imageContianerTop = [NSLayoutConstraint
                                             constraintWithItem:self.imageContainer
                                             attribute:NSLayoutAttributeTop
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.view
                                             attribute:NSLayoutAttributeTop
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
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [tapGesture setNumberOfTapsRequired:1];
    [tapGesture setDelegate:self];
    [self.drawView addGestureRecognizer:panGesture];
    [self.drawView addGestureRecognizer:tapGesture];
    self.drawView.userInteractionEnabled = YES;
    self.drawView.translatesAutoresizingMaskIntoConstraints = NO;
    self.drawView.backgroundColor = [UIColor clearColor];
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

- (void)revert:(id)sender {
    [drawData removeLastObject];
    [self.drawView.layer setNeedsDisplay];
    [self.drawView.layer displayIfNeeded];
    [self.revertButton setEnabled:drawData.count != 0];
}

- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)send:(id)sender {
    CGRect drawRect = self.imageView.bounds;
    UIGraphicsBeginImageContext(drawRect.size);
    [self.imageView.image drawInRect:drawRect];
    [PanIndicator drawMaskOnContext:drawData];
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *returnData = UIImagePNGRepresentation(resultingImage);
    if (_block) {
        _block(returnData);
    }
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
    
    [self.pencelButton setHighlighted:YES];
    [self.textButton setHighlighted:NO];
    
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
    
    [self.pencelButton setHighlighted:NO];
    [self.textButton setHighlighted:YES];
    
    currentEditingType = EditingTypeText;
    [self.editContainer reloadData];
}

- (void)panAction:(UIPanGestureRecognizer *)gR {
    if (currentEditingType != EditingTypeLine) {
        return;
    }
    
    if ([gR state] == UIGestureRecognizerStateBegan) {
        pointData = [[NSMutableArray alloc] init];
        [pointData addObject:[NSValue valueWithCGPoint:[gR locationInView:self.imageView]]];
        [drawData addObject:@{kColor : currentOption.color
                              ,kData : pointData}];
    }
    else if ([gR state] == UIGestureRecognizerStateEnded) {
        [self.revertButton setEnabled:YES];
    }
    else if ([gR state] == UIGestureRecognizerStateChanged) {
        [pointData addObject:[NSValue valueWithCGPoint:[gR locationInView:self.imageView]]];
    }
    self.drawView.panDrawData = drawData;
    [self.drawView.layer setNeedsDisplay];
    [self.drawView.layer displayIfNeeded];
}

- (void)tapAction:(UIPanGestureRecognizer *)gR {
    if (currentEditingType != EditingTypeText) {
        return;
    }
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [optionData[currentEditingType] count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"kUICollectionViewCell" forIndexPath:indexPath];
    cell.layer.cornerRadius = 20;
    cell.layer.masksToBounds = YES;
    cell.layer.borderWidth = 3;
    EditOption *option = optionData[currentEditingType][indexPath.row];
    cell.layer.borderColor = option.selected ? [UIColor colorWithRed:87 / 255. green:121 / 255. blue:226 / 255. alpha:1].CGColor : [self bkColor].CGColor;
    cell.contentView.backgroundColor = option.color;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *data = optionData[currentEditingType];
    for (NSInteger index = 0; index < data.count; index++) {
        EditOption *option = data[index];
        option.selected = index == indexPath.row;
    }
    currentOption = [data filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.selected == YES"]].lastObject;
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
    self.imageView.frame = CGRectMake(0, 0, containerBounds.size.width, imageSize.height / scale);
    //[self.imageContainer setContentInset:UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0)];
    [self.imageContainer setContentSize:self.imageView.frame.size];
}

+ (ALOPhotoMaskerViewController *)presendPhotoMasker:(UIViewController *)sourceViewController imageData:(NSData *)imageData block:(ModifyDone)block {
    ALOPhotoMaskerViewController *controller = [[ALOPhotoMaskerViewController alloc] init];
    controller.block = block;
    [sourceViewController presentViewController:controller animated:YES completion:^{
        [controller setImage:imageData];
    }];
    return controller;
}

@end
