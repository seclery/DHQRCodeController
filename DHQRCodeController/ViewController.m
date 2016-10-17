//
//  ViewController.m
//  DHQRCodeController
//
//  Created by team1 on 16/10/17.
//  Copyright © 2016年 DH. All rights reserved.
//

#import "ViewController.h"

#import "DHQRCodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIButton *QRCodeButton  = [UIButton buttonWithType:UIButtonTypeSystem];
    [QRCodeButton setTitle:@"扫 描" forState:UIControlStateNormal];
    [self.view addSubview:QRCodeButton];
    
    [QRCodeButton sizeToFit];
    QRCodeButton.center     = self.view.center;
    
    [QRCodeButton addTarget:self action:@selector(startQRCode:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startQRCode:(id)sender {
    DHQRCodeViewController *QRCodeView  = [[DHQRCodeViewController alloc] init];
    QRCodeView.titleString              = @"扫一扫";
    [self.navigationController pushViewController:QRCodeView animated:YES];
}

@end
