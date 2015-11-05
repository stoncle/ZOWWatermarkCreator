//
//  WaterMarkCreator.m
//  InstaGrab
//
//  Created by stoncle on 10/15/15.
//  Copyright © 2015 JellyKit Inc. All rights reserved.
//

#import "WaterMarkCreator.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>


@implementation WaterMarkCreator
{
    void(^_successBlock)(NSURL *);
    void(^_failureBlock)(NSError *);
    CGSize _naturalSize;
    UIImage *_watermark;
    CGRect _watermarkFrame;
    CGSize _playerViewSize;
    NSString *_outputPath;
    
    NSOperationQueue *_processQueue;
}

#pragma mark - PUBLIC

- (void)createWatermarkWithCreatorModels:(NSArray<WaterMarkCreatorModel *> *)models
{
    if(!models || ![models isKindOfClass:[NSArray class]] || models.count == 0)
    {
        NSLog(@"illegal model array");
        return;
    }
    for(WaterMarkCreatorModel *model in models)
    {
        [self createWatermarkWithCreatorModel:model];
    }
}

- (void)createWatermarkWithCreatorModel:(WaterMarkCreatorModel *)model
{
    if(!model)
    {
        NSLog(@"model is nil.");
        return;
    }
    [self enableProcessQueue];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [self createWatermarkOnWatermarkModel:model
                                 successBlock:model.successBlock
                                  failedBlock:model.failedBlock];
    }];
    [_processQueue addOperation:operation];
    if(_processQueue.isSuspended)
    {
        [_processQueue setSuspended:NO];
    }
}

#pragma mark - PRIVATE

- (CALayer *)getWaterMarkLayerFromImage:(UIImage *)markImage
                     withWatermarkFrame:(CGRect)watermarkFrame
                         withVisualSize:(CGSize)visualSize
                           withRealSize:(CGSize)realSize
{
    CALayer *layer = [CALayer layer];
    layer.frame = [self caculateFrameFromOriginalFrameInCoreGrafic:watermarkFrame VisualSize:visualSize RealSize:realSize];
    layer.contents = (id)markImage.CGImage;
    
    return layer;
}

- (CALayer *)getWaterMarkLayerFromString:(NSAttributedString *)string
                      withWatermarkFrame:(CGRect)watermarkFrame
                          withVisualSize:(CGSize)visualSize
                            withRealSize:(CGSize)realSize
{
    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.string = string;
    titleLayer.frame = [self caculateFrameFromOriginalFrameInCoreGrafic:watermarkFrame VisualSize:visualSize RealSize:realSize];
    titleLayer.alignmentMode = kCAAlignmentLeft;
    return titleLayer;
}

- (CGRect)caculateFrameFromOriginalFrameInCoreGrafic:(CGRect)originalFrame
                                          VisualSize:(CGSize)visualSize
                                            RealSize:(CGSize)realSize;
{
    CGFloat realOriginX = (originalFrame.origin.x/visualSize.width)*realSize.width;
    CGFloat realOriginY = realSize.height*(1-(originalFrame.origin.y+originalFrame.size.height)/visualSize.height);
    CGFloat realWidth = (originalFrame.size.width/visualSize.width)*realSize.width;
    CGFloat realHeight = (originalFrame.size.height/visualSize.height)*realSize.height;
    CGRect rect = CGRectMake(realOriginX, realOriginY, realWidth, realHeight);
    return rect;
}

- (CGRect)caculateFrameFromOriginalFrameInUIKit:(CGRect)originalFrame
                                     visualSize:(CGSize)visualSize
                                       realSize:(CGSize)realSize
{
    CGFloat realOriginX = (originalFrame.origin.x/visualSize.width)*realSize.width;
    CGFloat realOriginY = (originalFrame.origin.y/visualSize.height)*realSize.height;
    CGFloat realWidth = (originalFrame.size.width/visualSize.width)*realSize.width;
    CGFloat realHeight = (originalFrame.size.height/visualSize.height)*realSize.height;
    CGRect rect = CGRectMake(realOriginX, realOriginY, realWidth, realHeight);
    return rect;
}

#pragma mark - context
- (void)createWatermarkOnWatermarkModel:(WaterMarkCreatorModel *)model
                           successBlock:(WaterMarkCreateSuccessBlock)successHandler
                            failedBlock:(WaterMarkCreateFailedBlock)failedandler
{
    if(!model || !model.itemArray || model.itemArray.count == 0)
    {
        return;
    }
    
    if(model.originalImage)
    {
        // image process
        dispatch_async(dispatch_get_main_queue(), ^{
            CGSize size = model.originalImageSize;
            
            
            
            
            UIGraphicsBeginImageContext(size);
            [model.originalImage drawAtPoint:CGPointMake(0, 0) blendMode:kCGBlendModeNormal alpha:1];
            for(WaterMarkItem *item in model.itemArray)
            {
                if([item isKindOfClass:[WaterMarkImageItem class]])
                {
                    WaterMarkImageItem *imageItem = (WaterMarkImageItem *)item;
                    CGRect realFrame = [self caculateFrameFromOriginalFrameInUIKit:imageItem.watermarkFrameOnOriginalImageView visualSize:model.originalImageViewSize realSize:model.originalImageSize];
                    [imageItem.watermarkImage drawInRect:realFrame];
                }
                else if([item isKindOfClass:[WaterMarkStringItem class]])
                {
                    WaterMarkStringItem *stringItem = (WaterMarkStringItem *)item;
                    CGRect realFrame = [self caculateFrameFromOriginalFrameInUIKit:stringItem.watermarkFrameOnOriginalImageView visualSize:model.originalImageViewSize realSize:model.originalImageSize];
                    [stringItem.watermarkString drawInRect:realFrame withAttributes:stringItem.attributes];
                }
            }
            
            UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if(result)
            {
                if(successHandler)
                {
                    successHandler(model, result, nil);
                }
                
                //write image to output path
                NSData *imageData = UIImagePNGRepresentation(result);
                if(![imageData writeToFile:model.outputPath atomically:YES])
                {
                    NSLog(@"WaterMarkCreator ERROR: image write to file error, file path might uncorrect");
                }
            }
            else
            {
                if(failedandler)
                {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Create watermark on image failed.", nil),
                                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Core Graphic error.", nil)
                                               };
                    NSError *error = [[NSError alloc] initWithDomain:@"NSWatermarkErrorDomain" code:-2 userInfo:userInfo];
                    failedandler(error);
                }
            }
        });
    }
    else if(model.originalVideoURLString)
    {
        // video process
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:model.originalVideoURLString isDirectory:NO] options:nil];
        
        // minor 0.1 here because that the urlAsset.duration not correct, to avoid the black frame at the end of the video.
        CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(urlAsset.duration)-0.1, urlAsset.duration.timescale);
        if (!urlAsset)
        {
            if(failedandler)
            {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Create watermark on video failed.", nil),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Can't  find video with the given url.", nil),
                                           NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Set video url correctly, or may be the video not exist.", nil)
                                           };
                NSError *error = [[NSError alloc] initWithDomain:@"NSWatermarkErrorDomain" code:-3 userInfo:userInfo];
                failedandler(error);
            }
            return;
        }
        
        AVAssetTrack *assetTrack;
        @try {
            NSArray *trackArray = [urlAsset tracksWithMediaType:AVMediaTypeVideo];
            if(trackArray && trackArray.count)
            {
                assetTrack = [trackArray objectAtIndex:0];
            }
            else
            {
                if(failedandler)
                {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Create watermark on video failed.", nil),
                                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Get video track failed", nil)
                                               };
                    NSError *error = [[NSError alloc] initWithDomain:@"NSWatermarkErrorDomain" code:-4 userInfo:userInfo];
                    failedandler(error);
                }
                return;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"WaterMark:get video track failed");
            if(failedandler)
            {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Create watermark on video failed.", nil),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Get video track failed", nil)
                                           };
                NSError *error = [[NSError alloc] initWithDomain:@"NSWatermarkErrorDomain" code:-4 userInfo:userInfo];
                failedandler(error);
            }
            return;
        }
        
        _naturalSize = [assetTrack naturalSize];
        
//        CALayer *markLayer = [self getWaterMarkLayerFromImage:_watermark];
        //    markLayer.opacity = 0;
        //    [self addOpacityAnimationToLayer:markLayer withTimeOffsetSeconds:3];
        
        //create composition
        AVMutableComposition *pmutableComp = [AVMutableComposition composition];
        AVMutableCompositionTrack *pmutableCompTrack = [pmutableComp addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [pmutableCompTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, time) ofTrack:assetTrack atTime:kCMTimeZero error:nil];
        
        
        AVAssetTrack *audioTrack;
        @try {
            audioTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            AVMutableCompositionTrack *pmutableAudioTrack = [pmutableComp addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [pmutableAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, time) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
        }
        @catch (NSException *exception) {
            NSLog(@"WaterMark:cannot get audio track");
        }
        
        //set instruction
        AVMutableVideoCompositionInstruction *pmutableCompInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        pmutableCompInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, time);
        
        AVMutableVideoCompositionLayerInstruction *pmutableVideoLayerInstruct = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:pmutableCompTrack];
        [pmutableVideoLayerInstruct setTransform:assetTrack.preferredTransform atTime:kCMTimeZero];
        
        pmutableCompInstruction.layerInstructions = [NSArray arrayWithObjects:pmutableVideoLayerInstruct,nil];
        
        AVMutableVideoComposition *pmutableVideoComp = [AVMutableVideoComposition videoComposition];
        pmutableVideoComp.renderSize = _naturalSize;
        pmutableVideoComp.frameDuration = CMTimeMake(1, 30);
        pmutableVideoComp.instructions = [NSArray arrayWithObject:pmutableCompInstruction];
        
        //mix video with layer
        
        CALayer *videoLayer = [CALayer layer];
        videoLayer.frame = CGRectMake(0, 0, _naturalSize.width, _naturalSize.height);
        CALayer *parentLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, _naturalSize.width, _naturalSize.height);
        [parentLayer addSublayer:videoLayer];
        
        for(WaterMarkItem *item in model.itemArray)
        {
            if([item isKindOfClass:[WaterMarkImageItem class]])
            {
                WaterMarkImageItem *imageItem = (WaterMarkImageItem *)item;
                CALayer *markLayer = [self getWaterMarkLayerFromImage:imageItem.watermarkImage
                                                   withWatermarkFrame:imageItem.watermarkFrameOnOriginalImageView
                                                       withVisualSize:model.originalImageViewSize
                                                         withRealSize:model.originalImageSize];
                [parentLayer addSublayer:markLayer];
            }
            else if([item isKindOfClass:[WaterMarkStringItem class]])
            {
                WaterMarkStringItem *stringItem = (WaterMarkStringItem *)item;
                NSAttributedString *string = [[NSAttributedString alloc] initWithString:stringItem.watermarkString attributes:stringItem.attributes];
                CALayer *stringLayer = [self getWaterMarkLayerFromString:string withWatermarkFrame:stringItem.watermarkFrameOnOriginalImageView withVisualSize:model.originalImageViewSize withRealSize:model.originalImageSize];
                
                [parentLayer addSublayer:stringLayer];
                [stringLayer display];
            }
        }
        
        
        //    UIImage *standardImage = [[SDImageCache sharedImageCache] imageFromKey:[[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:[VineClient getInstance].userLogin.avatarUrl]] fromDisk:YES];
        //    if (!standardImage)
        //    {
        //        standardImage = [UIImage imageNamed:AvatarPlaceHolder60Image];
        //    }
        //
        
        pmutableVideoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        
        
        NSString *outputPath = model.outputPath;
        if (outputPath == nil)
        {
            NSString *defaultPath = @"";
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            if (paths && [paths count])
            {
                defaultPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"MediaWithWatermark"];
            }
            BOOL isDir;
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:defaultPath isDirectory:&isDir];
            if (!exists || !isDir) {
                BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:defaultPath withIntermediateDirectories:YES attributes:nil error:nil];
                if(!success)
                {
                    NSLog(@"create dir failed");
                    return;
                }
            }
            defaultPath = [NSString stringWithFormat:@"%@/%@", defaultPath, [urlAsset.URL.path lastPathComponent]];
            
            outputPath = defaultPath;
        }
        
        NSURL *url = [NSURL fileURLWithPath:outputPath];
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:pmutableComp presetName:AVAssetExportPresetHighestQuality];
        exportSession.outputURL = url;
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.videoComposition = pmutableVideoComp;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted)
                {
                    if(successHandler)
                    {
                        successHandler(model, nil, url);
                    }
                }
                else
                {
                    NSLog(@"export video error with description %@", exportSession.error.localizedDescription);
                    
                    if(failedandler)
                    {
                        NSDictionary *userInfo = @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Create watermark on video failed.", nil),
                                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Export video file failed", nil),
                                                   };
                        NSError *error = [[NSError alloc] initWithDomain:@"NSWatermarkErrorDomain" code:-5 userInfo:userInfo];
                        failedandler(error);
                    }
                }
            });
        }];
    }
    
    
}


#pragma mark - Queue
- (void)enableProcessQueue
{
    if(!_processQueue)
    {
        _processQueue = [[NSOperationQueue alloc] init];
    }
}

@end





@implementation WaterMarkCreatorModel



@end

@implementation WaterMarkItem



@end

@implementation WaterMarkImageItem



@end

@implementation WaterMarkStringItem



@end
