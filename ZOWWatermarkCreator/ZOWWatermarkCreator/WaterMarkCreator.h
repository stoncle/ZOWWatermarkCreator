//
//  WaterMarkCreator.h
//  InstaGrab
//
//  Created by stoncle on 10/15/15.
//  Copyright © 2015 JellyKit Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@class WaterMarkCreatorModel;

typedef void(^WaterMarkCreateSuccessBlock)(WaterMarkCreatorModel *originItem, UIImage *processedImage, NSURL *processedVideoUrl);
typedef void(^WaterMarkCreateFailedBlock)(NSError *error);

@interface WaterMarkItem : NSObject

@property (nonatomic, assign) CGRect watermarkFrameOnOriginalImageView;

@end

@interface WaterMarkImageItem : WaterMarkItem

@property (nonatomic, copy) UIImage *watermarkImage;

@end

@interface WaterMarkStringItem : WaterMarkItem

@property (nonatomic, copy) NSString *watermarkString;
@property (nonatomic, copy) NSDictionary *attributes;

@end


@interface WaterMarkCreatorModel : NSObject

@property (nonatomic, assign) CGSize originalImageSize;
@property (nonatomic, assign) CGSize originalImageViewSize;

@property (nonatomic, copy) UIImage *originalImage;
@property (nonatomic, copy) NSString *originalVideoURLString;

@property (nonatomic, strong) NSString *outputPath;

@property (nonatomic, strong) NSArray<WaterMarkItem *> *itemArray;

@property (nonatomic, strong) WaterMarkCreateSuccessBlock successBlock;
@property (nonatomic, strong) WaterMarkCreateFailedBlock failedBlock;

@end

@interface WaterMarkCreator : NSObject

- (void)createWatermarkWithCreatorModels:(NSArray<WaterMarkCreatorModel *> *)models;

@end

