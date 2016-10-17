//
//  DHQRCodeViewController.m
//  DHQRCodeController
//
//  Created by team1 on 16/10/17.
//  Copyright © 2016年 DH. All rights reserved.
//

#import "DHQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "QRView.h"

static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface DHQRCodeViewController () <AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UIView    *bgView;    // 初始进入页面时黑色背景
    UILabel   *_tipLabel; // 提示文字
    UIButton  *turnBtn;   // 闪光灯按钮
    
    QRView    *_previewViewLayer;
}

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDevice *device;
@property (nonatomic) AVCaptureDeviceInput *input;
@property (nonatomic) AVCaptureMetadataOutput *output;
@property (nonatomic) AVCaptureVideoPreviewLayer *previewView;

// Utilities.
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;

@property (strong, nonatomic) CIDetector *detector;

@property (nonatomic) BOOL isPush;

@end

@implementation DHQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self rightBarButtonItem];
    
    // 初始进入扫描页
    bgView                  = [[UIView alloc] initWithFrame:self.view.bounds];
    bgView.backgroundColor  = [UIColor blackColor];
    [self.view addSubview:bgView];
    
    // 提示文字
    _tipLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
    _tipLabel.text      = @"请稍候...";
    _tipLabel.textColor = [UIColor grayColor];
    [_tipLabel sizeToFit];
    _tipLabel.center    = self.view.center;
    [bgView addSubview:_tipLabel];
    
    // 初始化相机
    [self sessionConfiguration];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.sessionQueue) {
        self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    }
    
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case AVCamSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                //        [self addObservers];
                self.sessionRunning = self.session.isRunning;
                
                break;
            }
            case AVCamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self addTipLabel:@"请在\"设置-隐私-相机\"中允许访问相机"];
                } );
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self addTipLabel:@"请在\"设置-隐私-相机\"中允许访问相机"];
                } );
                break;
            }
        }
    } );
    
    if (_isPush) {
        _isPush = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.sessionRunning && !_isPush) {
        if (_previewView) {
            [_previewView removeFromSuperlayer];
        }
        
        dispatch_async( self.sessionQueue, ^{
            if ( self.setupResult == AVCamSetupResultSuccess ) {
                for(AVCaptureInput *input1 in self.session.inputs) {
                    [self.session removeInput:input1];
                }
                
                for(AVCaptureOutput *output1 in self.session.outputs) {
                    [self.session removeOutput:output1];
                }
                [self.session stopRunning];
                [self removeObservers];
            }
        } );
    }
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark -
- (void)setTitleString:(NSString *)titleString {
    self.title = titleString;
}

- (void)addTipLabel:(NSString *)text {
    if (_tipLabel) {
        [_tipLabel removeFromSuperview];
        _tipLabel = nil;
    }
    _tipLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
    _tipLabel.text      = text;
    _tipLabel.textColor = [UIColor grayColor];
    [_tipLabel sizeToFit];
    _tipLabel.center    = self.view.center;
    [self.view addSubview:_tipLabel];
}

- (void)rightBarButtonItem {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"相册" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(localPicData) forControlEvents:UIControlEventTouchUpInside];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button sizeToFit];
    UIBarButtonItem *positionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = positionBarButtonItem;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark -
- (void)stopQRView {
    [self.session stopRunning];
    self.sessionRunning = self.session.isRunning;
    
    if (bgView) {
        [bgView removeFromSuperview];
        bgView = nil;
    }
    bgView = [[UIView alloc] initWithFrame:self.view.bounds];
    bgView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:bgView];
    
    if (turnBtn.selected) {
        turnBtn.selected = NO;
        [self turnTorchOn:NO];
    }
}

- (void)reStartQRView {
    [self.session startRunning];
    
    if (bgView) {
        [bgView removeFromSuperview];
        bgView = nil;
    }
    
    self.sessionRunning = self.session.isRunning;
}

#pragma mark - KVO and Notifications

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRunning) name:AVCaptureSessionDidStartRunningNotification object:self.session];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sessionRunning
{
    NSLog(@"--- didRunning");
}

#pragma mark -
- (void)sessionConfiguration {
    
    // Create the AVCaptureSession.
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.setupResult  = AVCamSetupResultSuccess;
    
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // asking the user for audio access if video access is denied.
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        case AVAuthorizationStatusDenied: {
            // denied
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult != AVCamSetupResultSuccess ) {
            return;
        }
        
        NSError               *error        = nil;
        AVCaptureDevice       *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput  *cameraInput  = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&error];
        
        // 配置 session
        [self.session beginConfiguration];
        if ( [self.session canAddInput:cameraInput] ) {
            [self.session addInput:cameraInput];
            self.input = cameraInput;
            
            AVCaptureMetadataOutput *cameraOutput = [[AVCaptureMetadataOutput alloc] init];
            [cameraOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            
            if ([self.session canAddOutput:cameraOutput]) {
                [self.session addOutput:cameraOutput];
                self.output = cameraOutput;
                
                // 条码类型 AVMetadataObjectTypeQRCode
                if ([self.output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
                    self.output.metadataObjectTypes = [NSArray arrayWithObject:AVMetadataObjectTypeQRCode];
                }
            }
        }
        else {
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        [self.session commitConfiguration];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            self.view.backgroundColor     = [UIColor clearColor];
            
            self.previewView              = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
            self.previewView.videoGravity = AVLayerVideoGravityResize;
            self.previewView.frame        = self.view.layer.bounds;
            [self.view.layer insertSublayer:self.previewView  atIndex:0];
            
            [self.session startRunning];
            self.sessionRunning           = self.session.isRunning;
            
            [UIView animateWithDuration:0.1 animations:^{
                bgView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [bgView removeFromSuperview];
            }];
            
            CGRect screenRect           = [UIScreen mainScreen].bounds;
            QRView *qrRectView          = [[QRView alloc] initWithFrame:screenRect];
            _previewViewLayer           = qrRectView;
            qrRectView.transparentArea  = CGSizeMake(260, 260);
            qrRectView.backgroundColor  = [UIColor clearColor];
            qrRectView.center           = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
            [self.view addSubview:qrRectView];
            
            //修正扫描区域
            CGFloat screenHeight  = self.view.frame.size.height;
            CGFloat screenWidth   = self.view.frame.size.width;
            CGRect  cropRect      = CGRectMake((screenWidth - qrRectView.transparentArea.width) / 2,
                                               (screenHeight - qrRectView.transparentArea.height) / 2,
                                               qrRectView.transparentArea.width,
                                               qrRectView.transparentArea.height);
            
            [self.output setRectOfInterest:CGRectMake(cropRect.origin.y / screenHeight,
                                                      cropRect.origin.x / screenWidth,
                                                      cropRect.size.height / screenHeight,
                                                      cropRect.size.width / screenWidth)];
            
            // 提示信息
            if (_tipLabel) {
                [_tipLabel removeFromSuperview];
                _tipLabel = nil;
            }
            _tipLabel   = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth - qrRectView.transparentArea.width) / 2,
                                                                    (screenHeight - qrRectView.transparentArea.height + 120),
                                                                    qrRectView.transparentArea.width,
                                                                    30)];
            _tipLabel.numberOfLines = 3;
            _tipLabel.text          = @"将二维码放入框内，即可自动扫描";
            _tipLabel.textColor     = [UIColor whiteColor];
            [self.view addSubview:_tipLabel];
            
            //开关灯button
            turnBtn                 = [UIButton buttonWithType:UIButtonTypeCustom];
            turnBtn.backgroundColor = [UIColor clearColor];
            [turnBtn setBackgroundImage:[UIImage imageNamed:@"lightSelect"] forState:UIControlStateNormal];
            [turnBtn setBackgroundImage:[UIImage imageNamed:@"lightNormal"] forState:UIControlStateSelected];
            turnBtn.frame           = CGRectMake(0, 0, 64, 64);
            [turnBtn addTarget:self action:@selector(turnBtnEvent:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:turnBtn];
            
            CGPoint tempPoint       = _tipLabel.center;
            tempPoint.y += 50;
            turnBtn.center          = tempPoint;
        });
    } );
}

- (void)stopSession {
    // 停止扫描
    if (_previewView) {
        [_previewView removeFromSuperlayer];
    }
    
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            for(AVCaptureInput *input1 in self.session.inputs) {
                [self.session removeInput:input1];
            }
            
            for(AVCaptureOutput *output1 in self.session.outputs) {
                [self.session removeOutput:output1];
            }
            [self.session stopRunning];
            [self removeObservers];
        }
    });
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ([metadataObjects count] > 0 && !_isPush) {
        _isPush = YES;
        
        // 扫描到数据
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        
        // 移动绿角块
        AVMetadataMachineReadableCodeObject *obj = (AVMetadataMachineReadableCodeObject *)[_previewView transformedMetadataObjectForMetadataObject:metadataObject];
        NSArray *array = obj.corners;
        [_previewViewLayer moveToPoint:array];
        
        NSLog(@"QRCode:%@", metadataObject.stringValue);
    }
}

#pragma mark - 相册
- (void)localPicData {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"设备不支持访问相册，请在设置->隐私->照片中进行设置！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    _isPush = YES;
    
    [self stopQRView];
    
    self.detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType               = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.mediaTypes               = [UIImagePickerController         availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    mediaUI.allowsEditing            = NO;
    mediaUI.delegate                 = self;
//    [self presentViewController:mediaUI animated:YES completion:^{
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
//    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    NSArray *features = [self.detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if (features.count >=1) {
        // 扫描到二维码
        [picker dismissViewControllerAnimated:YES completion:^{
//            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;
            
            NSLog(@"QRCode:%@", scannedResult);
        }];
    }
    else {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"该图片没有包含一个二维码！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        
        [picker dismissViewControllerAnimated:YES completion:^{
            [self reStartQRView];
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self reStartQRView];
    }];
    
}

#pragma mark - CaptureTorch
- (void)turnBtnEvent:(UIButton *)button_
{
    button_.selected = !button_.selected;
    if (button_.selected) {
        [self turnTorchOn:YES];
    }
    else{
        [self turnTorchOn:NO];
    }
    
}

- (void)turnTorchOn:(bool)on
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}

@end
