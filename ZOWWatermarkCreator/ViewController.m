//
//  ViewController.m
//  ZOWWatermarkCreator
//
//  Created by stoncle on 11/5/15.
//  Copyright © 2015 stoncle. All rights reserved.
//

#import "ViewController.h"
#import "WaterMarkCreator.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIImageView *originImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 375, 200)];
    UIImageView *watermarkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 200, 100, 100)];
    UIImageView *mixedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 300, 375, 200)];
    [self.view addSubview:originImageView];
    [self.view addSubview:watermarkImageView];
    [self.view addSubview:mixedImageView];
    
    UIImage *originImage = [UIImage imageNamed:@"lufy-origin.jpg"];
    UIImage *watermarkImage = [UIImage imageNamed:@"lufy.jpg"];
    originImageView.image = originImage;
    watermarkImageView.image = watermarkImage;
    
    WaterMarkImageItem *imageItem = [[WaterMarkImageItem alloc] init];
    imageItem.watermarkImage = watermarkImage;
    imageItem.watermarkFrameOnOriginalImageView = CGRectMake(50, 50, 50, 50);
    
    WaterMarkStringItem *stringItem = [[WaterMarkStringItem alloc] init];
    stringItem.watermarkString = @"I am a WaterMark!";
    stringItem.watermarkFrameOnOriginalImageView = CGRectMake(50, 100, 200, 50);
    stringItem.attributes = @{NSForegroundColorAttributeName:[UIColor purpleColor], NSFontAttributeName:[UIFont systemFontOfSize:50]};
    
    WaterMarkCreatorModel *model = [[WaterMarkCreatorModel alloc] init];
    model.originalImage = originImage;
    model.originalImageSize = originImage.size;
    model.originalImageViewSize = originImageView.bounds.size;
    model.itemArray = @[imageItem, stringItem];
    model.successBlock = ^(WaterMarkCreatorModel *originItem, UIImage *processedImage, NSURL *processedVideoUrl) {
        if(processedImage)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                mixedImageView.image = processedImage;
            });
        }
    };
    [[[WaterMarkCreator alloc] init] createWatermarkWithCreatorModels:@[model]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
