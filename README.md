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
* set WatermarkCreatorModel
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

##Description
###WatermarkItem
A specific WatermarkItem represents a watermark, it can be a image watermark with WatermarkImageItem, or a string watermark with WatermarkStringItem.

You can use specific WatermarkItem to create the watermark item you want, only a few step to configure the item.

A WatermarkImageItem need to be configured with a **watermark image** and the **frame** you want to put it on the original image.

A WatermarkStringItem need to be configured with a **watermark string** and the **frame**.Optionaly, you can specific the attribute of the string with the property **attributes**.

###WatermarkCreatorModel
A WatermarkCreatorModel represents a creation context, it contains all infomation needed in a specific watermark procession, like the **originalImage** or **originVideoURLString** you want to put watermark on, the **outPutPath** of the processed media, and the watermark **itemArray**.

You can set mutiple WatermarkItem in a WatermarkCreatorModel by add them to the **itemArray** array object. They will be created all in one procession.

The property **originalImageSize** represents the size of the original image, while the **originalImageViewSize** represents the imageview size. Since the image size we see in our eyes doesn't means the real size of the image, but also limited to the UIImageView container size.So, if the watermark frame you give is based on a UIImageView, you should also pass the **originalImageViewSize** property, and if it is based on the real image size, just ignore the property, only set the **originalImageSize** is OK.

Set the **successBlock** and **failedBlock** to track the result.

###WatermarkCreator
Pass a NSArray<WatermarkCreatorModel *> object to a WatermarkCreator object to begin the processions. 

Every WatermarkCreator has a build-in NSOperaionQueue to handle the management of the procession operation. So in most occasions, you only need **one** WatermarkCreator to create all your needed watermark context.

All the processions runs async, you can set the blocks in WatermarkCreatorModel to handle the result. Don't forget to *dispatch the UI setting to the main queue*.
