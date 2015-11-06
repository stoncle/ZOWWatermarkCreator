# ZOWWatermarkCreator
add image or string water mark to your image and video media.

## Usage
* set WatermarkItem
```Objective-C
  WaterMarkImageItem *imageItem = [[WaterMarkImageItem alloc] init];
    imageItem.watermarkImage = watermarkImage;
    imageItem.watermarkFrameOnOriginalImageView = CGRectMake(50, 50, 50, 50);
    
    WaterMarkStringItem *stringItem = [[WaterMarkStringItem alloc] init];
    stringItem.watermarkString = @"I am a WaterMark!";
    stringItem.watermarkFrameOnOriginalImageView = CGRectMake(50, 100, 200, 50);
    stringItem.attributes = @{NSForegroundColorAttributeName:[UIColor purpleColor], NSFontAttributeName:[UIFont systemFontOfSize:50]};
```
* set WatermarkModel
```Objective-C
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
```
* use WatermarkCreator to create it!
```Objective-C
  [[[WaterMarkCreator alloc] init] createWatermarkWithCreatorModels:@[model]];
```
