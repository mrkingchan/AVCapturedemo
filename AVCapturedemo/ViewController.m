//
//  ViewController.m
//  AVCapturedemo
//
//  Created by Chan on 2017/1/16.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController () {
    AVCaptureSession *_session;  //全局回话
    AVCaptureDevice *_device;   //设备
    AVCaptureDeviceInput *_input; //输入
    AVCaptureStillImageOutput *_output;  //输出
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
    BOOL _isVideo;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpCaptureSession];
    if (![_session  isRunning]) {
        [_session  startRunning];
    }
}

- (void)setUpCaptureSession {
    //初始化会话
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    //设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //此处一定要先锁定设备,否则会崩溃
    [_device lockForConfiguration:nil];
    //切换闪光灯模式
    [_device setFlashMode:AVCaptureFlashModeAuto];
    [_device unlockForConfiguration];
    //输入
    NSError *error;
    _input = [AVCaptureDeviceInput  deviceInputWithDevice:_device error:&error];
    //输出
    _output = [AVCaptureStillImageOutput new];  //此处我只需要拍照，所以有这个对象就可以了
    //这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    _output.outputSettings = _isVideo ? @{AVVideoCodecKey:AVVideoCodecH264}:@{AVVideoCodecKey:AVVideoCodecJPEG};
    //会话和输入
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    //会话和输出
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    //预览 捕捉拍摄到的画面
    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _videoPreviewLayer.frame = self.view.frame;
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:_videoPreviewLayer];
    
    //拍摄按钮
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 20, [UIScreen mainScreen].bounds.size.height - 60, 40, 40);
    [cameraButton setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    [cameraButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateSelected];
    [cameraButton addTarget:self action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraButton];
    
    //切换摄像头按钮
    UIButton *switchCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    switchCamera.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 40, 30, 20, 20);
    [switchCamera setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    [switchCamera addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:switchCamera];
}

//拍摄照片
- (IBAction)takePicture:(id)sender {
    AVCaptureConnection *connection = [_output connectionWithMediaType:AVMediaTypeVideo];
    //拍摄照片
    [_output captureStillImageAsynchronouslyFromConnection:connection
                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                             if (imageDataSampleBuffer) {
                                             NSData *imgData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                             UIImage *image = [UIImage imageWithData:imgData];
                                                 NSLog(@"imageSize--->>:%@",NSStringFromCGSize(image.size));
                                                //保存到相册
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                                                 });
                                                 //添加动画
                                                 [self addAnimationWithImage:image];
                                             } else {
                                                 return ;
                                             }
                                         }];
}

//切换闪光灯
- (void)switchFlashMode {
    if ([_device isFlashActive]) {
        //加锁保证原子操作
        [_device lockForConfiguration:nil];
        [_device setFlashMode:AVCaptureFlashModeOff];
        [_device unlockForConfiguration];
    } else {
        [_device  lockForConfiguration:nil];
        [_device setFlashMode:AVCaptureFlashModeOn];
        [_device unlockForConfiguration];
    }
}

//切换摄像头
- (void)switchCamera:(id)sender{
    /*NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *newDevice;
    AVCaptureDeviceInput *newInput;
    if (devices.count > 1) {
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionFront) {
            newDevice = device;
            break;
        }else if (device.position == AVCaptureDevicePositionBack) {
            newDevice = device;
            
            break;
        }
    }
    NSError* error;
    newInput = [[AVCaptureDeviceInput alloc] initWithDevice:newDevice
                                                      error:&error];
    //配置Session
    if (newInput!=nil) {
        //开始配置s
        [_session beginConfiguration];
        [_session  removeInput:_input];
        if ([_session canAddInput:newInput]) {
            _input = newInput;
            [_session addInput:_input];
        } else {
            [_session addInput:_input];
        }
        //提交配置
        [_session commitConfiguration];
    } else {
        NSLog(@"------>>切换摄像头错误");
    }
    }*/
    
    AVCaptureDevice *newDevice;
    AVCaptureDeviceInput *newInput;
    if (_device.position == AVCaptureDevicePositionBack) {
         newDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
    } else if (_device .position == AVCaptureDevicePositionFront) {
        newDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    NSError *error;
    _device = newDevice;
    newInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (newInput !=nil) {
        [_session removeInput:_input];
        _input = newInput;
        if ([_session canAddInput: _input]) {
            [_session addInput:_input];
        }
        [_session commitConfiguration];
    }else {
        NSLog(@"切换错误!");
    }
}

//获得制定摄像头的设备
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

//动画保存
 - (void)addAnimationWithImage:(UIImage *)image {
     puts(__func__);
 }

//保存相片
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存失败");
    } else {
        NSLog(@"保存成功");
    }
}

- (void)setUI {
    //会话
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    //设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [_device lockForConfiguration:nil];
    [_device setFlashMode:AVCaptureFlashModeAuto];
    // 解锁
    [_device unlockForConfiguration];
    
    //输入链接到设备
    NSError *error= nil;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device
                                                   error:&error];
    //输出
    _output = [AVCaptureStillImageOutput new];
    _output.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    //展示摄像头拍摄到的画面
    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _videoPreviewLayer.frame = self.view.frame;
    [self.view.layer addSublayer:_videoPreviewLayer];
}

- (void)setUp {
    //会话
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    //设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [_device lockForConfiguration:nil];
    [_device setFlashMode:AVCaptureFlashModeAuto];
    [_device unlockForConfiguration];
    
    //输入
    NSError *error;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    //输出
    _output = [AVCaptureStillImageOutput new];
    _output.outputSettings = @{AVVideoCodecKey :AVVideoCodecJPEG};
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    
    //显示摄像头捕捉到的画面
    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _videoPreviewLayer.frame=  self.view.frame;
    [self.view.layer addSublayer:_videoPreviewLayer];
}

//拍摄照片
- (void)takePicture {
    //获得输出链接
    AVCaptureConnection *connection = [_output connectionWithMediaType:AVMediaTypeVideo];
    //通过输出拿到照片数据
    [_output  captureStillImageAsynchronouslyFromConnection:connection
                                          completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                              if (!error) {
                                                  if (imageDataSampleBuffer) {
                                                      //获得图片数据
                                                      NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                      UIImage *image = [UIImage imageWithData:imageData];
                                                      //保存到系统相册
                                                      UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                                                  } else {
                                                      NSLog(@"---->>数据错误");
                                                  }
                                              } else {
                                                  NSLog(@"---->>%@",error.localizedDescription);
                                              }
                                          }];
}

@end
