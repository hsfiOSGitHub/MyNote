//
//  ViewController.m
//  SearchDemo
//
//  Created by JuZhenBaoiMac on 2017/4/8.
//  Copyright © 2017年 JuZhenBaoiMac. All rights reserved.
//

#import "ViewController.h"

#import "SearchVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置导航栏
    self.navigationController.navigationBar.barTintColor = [UIColor orangeColor];
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont systemFontOfSize:20],
       NSForegroundColorAttributeName:[UIColor whiteColor]}];// 设置导航栏文字字体大小 文字的颜色
}
//点击搜索按钮 跳转到搜索页面
- (IBAction)searchBtnACTION:(UIButton *)sender {
    SearchVC *search_VC = [[SearchVC alloc]init];
    [self.navigationController pushViewController:search_VC animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
