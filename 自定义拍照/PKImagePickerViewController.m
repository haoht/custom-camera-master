//
//  MyImagePickerViewController.m
//  cameratestapp
//
//  Created by liman on 6/24/14.
//  Copyright (c) 2014 liman. All rights reserved.
//
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#import "PKImagePickerViewController.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface PKImagePickerViewController ()

@property(nonatomic,strong) AVCaptureSession *captureSession;
@property(nonatomic,strong) AVCaptureStillImageOutput *stillImageOutput;
@property(nonatomic,strong) AVCaptureDevice *captureDevice;
@property(nonatomic,strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property(nonatomic,assign) BOOL isCapturingImage;
@property(nonatomic,strong) UIImageView *capturedImageView;
@property(nonatomic,strong) UIView *imageSelectedView;
@property(nonatomic,strong) UIImage *selectedImage;

@end

@implementation PKImagePickerViewController
{
    UIButton *flashBtn;//闪光灯
    UIButton *cameraBtn;//切换摄像头
    
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
}

#pragma mark - init
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)loadView
{
    self.view = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    preLayerWidth = SCREEN_WIDTH;
    preLayerHeight = SCREEN_HEIGHT;
    preLayerHWRate =SCREEN_HEIGHT/SCREEN_WIDTH;
    
    // 初始化配置
    [self setupConfiguration];
    
    // 初始化整个屏幕UI
    [self initCaptureUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [_captureSession startRunning];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [_captureSession stopRunning];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

#pragma mark - private
// 初始化配置
- (void)setupConfiguration
{
    _captureSession = [[AVCaptureSession alloc]init];
    _captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    _capturedImageView = [[UIImageView alloc]init];
    _capturedImageView.frame = self.view.frame; // just to even it out
    _capturedImageView.backgroundColor = [UIColor clearColor];
    _capturedImageView.userInteractionEnabled = YES;
    _capturedImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captureSession];
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _captureVideoPreviewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:_captureVideoPreviewLayer];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (devices.count > 0) {
        _captureDevice = devices[0];
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
        
        [_captureSession addInput:input];
        
        _stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
        NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [_stillImageOutput setOutputSettings:outputSettings];
        [_captureSession addOutput:_stillImageOutput];
        
        
//        if (_interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
//            _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
//        }
//        else if (_interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
//            _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
//        }
    }
}

// 初始化整个屏幕UI
-(void)initCaptureUI
{
    // 顶部透明视图
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44)];
    topView.backgroundColor = UIColorFromRGB(0x1d1e20);
    topView.alpha = 0.5;
    [self.view addSubview:topView];
    
    // 底部透明视图
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-80, SCREEN_WIDTH, 80)];
    bottomView.backgroundColor = UIColorFromRGB(0x1d1e20);
    bottomView.alpha = 0.5;
    [self.view addSubview:bottomView];
    
    
    // 拍摄按钮
    _captureBtn = [[LeafButton alloc]initWithFrame:CGRectMake(0, 0, 132/2, 132/2)];
    _captureBtn.center = CGPointMake(SCREEN_WIDTH/2, preLayerHeight-39);
    _captureBtn.type = LeafButtonTypeCamera;
    [self.view addSubview:_captureBtn];
    
    __weak PKImagePickerViewController *weakSelf = self;
    [_captureBtn setClickedBlock:^(LeafButton *button) {
        // 拍摄按钮 点击
        [weakSelf captureBtnClick];
    }];
    
    //闪光灯
    flashBtn = [[UIButton alloc]initWithFrame:CGRectMake(6, 4, 34, 34)];
    [flashBtn setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [flashBtn makeCornerRadius:34/2 borderColor:nil borderWidth:0];
    [flashBtn addTarget:self action:@selector(flashBtTap:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:flashBtn];
    
    //切换摄像头
    cameraBtn = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-40, 4, 34, 34)];
    [cameraBtn setBackgroundImage:[UIImage imageNamed:@"changeCamer"] forState:UIControlStateNormal];
    [cameraBtn makeCornerRadius:34/2 borderColor:nil borderWidth:0];
    [cameraBtn addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:cameraBtn];
    
    // 返回按钮
    _dismissBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    _dismissBtn.center = CGPointMake(35, SCREEN_HEIGHT - 36);
    [_dismissBtn setTitle:@"返回" forState:UIControlStateNormal];
    [_dismissBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_dismissBtn addTarget:self action:@selector(dismissBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_dismissBtn];
    // 扩大点击区域
    [_dismissBtn setEnlargeEdge:20];
    
    
    // 照片展示(已拍好)
    [self initImageSelectedView];
}

// 照片展示(已拍好)
- (void)initImageSelectedView
{
    _imageSelectedView = [[UIView alloc]initWithFrame:self.view.frame];
    [_imageSelectedView setBackgroundColor:[UIColor clearColor]];
    [_imageSelectedView addSubview:_capturedImageView];
    
    // 底部透明视图
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-80, SCREEN_WIDTH, 80)];
    bottomView.backgroundColor = UIColorFromRGB(0x1d1e20);
    bottomView.alpha = 0.5;
    [_imageSelectedView addSubview:bottomView];
    
    // 重拍按钮
    UIButton *retakeBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    retakeBtn.center = CGPointMake(35, SCREEN_HEIGHT - 36);
    [retakeBtn setTitle:@"重拍" forState:UIControlStateNormal];
    [retakeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [retakeBtn addTarget:self action:@selector(retakeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_imageSelectedView addSubview:retakeBtn];
    // 扩大点击区域
    [retakeBtn setEnlargeEdge:20];
    
    // 完成按钮
    UIButton *doneBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    doneBtn.center = CGPointMake(SCREEN_WIDTH-35, SCREEN_HEIGHT - 36);
    [doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(doneBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_imageSelectedView addSubview:doneBtn];
    // 扩大点击区域
    [doneBtn setEnlargeEdge:20];
}

#pragma mark - tool
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange
{
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([_captureDevice lockForConfiguration:&error]) {
        propertyChange(_captureDevice);
        [_captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

-(void)setTorchMode:(AVCaptureTorchMode )torchMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isTorchModeSupported:torchMode]) {
            [captureDevice setTorchMode:torchMode];
        }
    }];
}

-(void)setFocusMode:(AVCaptureFocusMode )focusMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

#pragma mark - target action
// 闪光灯按钮 点击
-(void)flashBtTap:(UIButton *)btn
{
    if (btn.selected == YES) {
        btn.selected = NO;
        //关闭闪光灯
        [flashBtn setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOff];
    }
    else
    {
        btn.selected = YES;
        //开启闪光灯
        [flashBtn setBackgroundImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOn];
    }
}

//切换摄像头
-(void)changeCamera:(id)sender
{
    // Need to reset flash btn
    AVCaptureDevicePosition currentPosition=[_captureDevice position];
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront)
    {
        flashBtn.hidden = NO;
    }
    else
    {
        flashBtn.hidden = YES;
    }
    
    
    if (_isCapturingImage != YES) {
        if (_captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0]) {
            // rear active, switch to front
            _captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];
            
            [_captureSession beginConfiguration];
            AVCaptureDeviceInput * newInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:nil];
            for (AVCaptureInput * oldInput in _captureSession.inputs) {
                [_captureSession removeInput:oldInput];
            }
            [_captureSession addInput:newInput];
            [_captureSession commitConfiguration];
        }
        else if (_captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1]) {
            // front active, switch to rear
            _captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0];
            [_captureSession beginConfiguration];
            AVCaptureDeviceInput * newInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:nil];
            for (AVCaptureInput * oldInput in _captureSession.inputs) {
                [_captureSession removeInput:oldInput];
            }
            [_captureSession addInput:newInput];
            [_captureSession commitConfiguration];
        }
    }
    
    
    //关闭闪光灯
    flashBtn.selected = NO;
    [flashBtn setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [self setTorchMode:AVCaptureTorchModeOff];
}

// 拍摄按钮 点击
-(void)captureBtnClick
{
    _isCapturingImage = YES;
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer) {
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            UIImage *capturedImage = [[UIImage alloc]initWithData:imageData scale:1];
            _isCapturingImage = NO;
            _capturedImageView.image = capturedImage;
            _selectedImage = capturedImage;
            imageData = nil;
            
            [self.view addSubview:_imageSelectedView];
        }
    }];
}

// 返回按钮 点击
- (void)dismissBtnClick:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 重拍按钮 点击
- (void)retakeBtnClick:(id)sender
{
    [_imageSelectedView removeFromSuperview];
}

// 完成按钮 点击
- (void)doneBtnClick:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        if ([_delegate respondsToSelector:@selector(imagePickerController:didFinishPickingImage:)]) {
            [_delegate imagePickerController:self didFinishPickingImage:_selectedImage];
        }
        
        [_imageSelectedView removeFromSuperview];
    }];
}

@end
