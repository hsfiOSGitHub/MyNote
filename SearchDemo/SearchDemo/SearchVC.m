//
//  SearchVC.m
//  SearchDemo
//
//  Created by JuZhenBaoiMac on 2017/4/8.
//  Copyright © 2017年 JuZhenBaoiMac. All rights reserved.
//

#import "SearchVC.h"

#import "MBProgressHUD+JDragon.h"

#import "SearchDBManage.h"
#import "SearchModel.h"
//导入你的自定义cell
#import "SearchResultCell.h"
#import "SearchHistoryCell.h"

//获取屏幕宽度与高度
#define kScreenWidth ([[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)] ? [UIScreen mainScreen].nativeBounds.size.width/[UIScreen mainScreen].nativeScale : [UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)] ? [UIScreen mainScreen].nativeBounds.size.height/[UIScreen mainScreen].nativeScale : [UIScreen mainScreen].bounds.size.height)
#define kScreenSize ([[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)] ? CGSizeMake([UIScreen mainScreen].nativeBounds.size.width/[UIScreen mainScreen].nativeScale,[UIScreen mainScreen].nativeBounds.size.height/[UIScreen mainScreen].nativeScale) : [UIScreen mainScreen].bounds.size)
//颜色
#define kRGBColor(r, g, b)     [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define kRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(r)/255.0 blue:(r)/255.0 alpha:a]
#define kRandomColor  KRGBColor(arc4random_uniform(256)/255.0,arc4random_uniform(256)/255.0,arc4random_uniform(256)/255.0)
#define kColorWithHex(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 blue:((float)(rgbValue & 0xFF)) / 255.0 alpha:1.0]
// 最大存储的搜索历史 条数
#define MAX_COUNT 20

@interface SearchVC ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) UIView *inputToolView;//回收键盘
@property (nonatomic,strong) NSMutableArray *source;//数据源
@property (nonatomic,strong)NSMutableArray *historySource;//搜索历史
@end

static NSString *identifierCell1 = @"identifierCell1";
static NSString *identifierCell2 = @"identifierCell2";
@implementation SearchVC

#pragma mark -懒加载
-(UIView *)inputToolView{
    if (!_inputToolView) {
        _inputToolView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 40)];
        _inputToolView.backgroundColor = kRGBColor(230, 230, 230);
        UIButton *downBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        downBtn.frame = CGRectMake(kScreenWidth - 60, 0, 40, 40);
        [downBtn setImage:[UIImage imageNamed:@"down"] forState:UIControlStateNormal];
        [downBtn addTarget:self action:@selector(fingerTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_inputToolView addSubview:downBtn];
    }
    return _inputToolView;
}

#pragma mark -viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化数据
    [self initData];
    //配置导航栏
    [self setUpNavi];
    //配置搜索框
    [self setUpSearchBar];
    //配置tableView
    [self setUpTableView];
    //点击空白处回收键盘
    [self addTapGestureToGetBackKeyboard];
    
}
//配置导航栏
-(void)setUpNavi{
    self.navigationItem.title = @"搜索";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[[UIImage imageNamed:@"back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(backACTION)];
}
-(void)backACTION{
    [self.navigationController popViewControllerAnimated:YES];
}
//配置按钮
-(void)setUpSearchBar{
    self.searchBar.delegate = self;
    [self.searchBar setImage:[UIImage imageNamed:@"search_bar"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    self.searchBar.placeholder = @"请输入搜索内容";
    self.searchBar.showsCancelButton = YES;
    for(UIView *view in  [[[self.searchBar subviews] objectAtIndex:0] subviews]) {
        if([view isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
            UIButton * cancel =(UIButton *)view;
            [cancel setTitle:@"搜索" forState:UIControlStateNormal];
            [cancel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            cancel.titleLabel.font = [UIFont systemFontOfSize:14];
        }
    }
    self.searchBar.inputAccessoryView = self.inputToolView;
}

//配置tableView
-(void)setUpTableView{
    //代理设置
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //高度
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    //注册cell
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([SearchResultCell class]) bundle:nil] forCellReuseIdentifier:identifierCell1];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([SearchHistoryCell class]) bundle:nil] forCellReuseIdentifier:identifierCell2];

    
    // 清空历史搜索按钮
    UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 104)];
    
    UIButton *clearButton = [[UIButton alloc] init];
    clearButton.frame = CGRectMake(60, 60, kScreenWidth - 120, 44);
    [clearButton setTitle:@"清空历史搜索" forState:UIControlStateNormal];
    [clearButton setTitleColor:[UIColor colorWithRed:242/256 green:242/256 blue:242/256 alpha:1] forState:UIControlStateNormal];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [clearButton addTarget:self action:@selector(clearButtonClick) forControlEvents:UIControlEventTouchDown];
    clearButton.layer.cornerRadius = 3;
    clearButton.layer.borderWidth = 1;
    clearButton.layer.borderColor = [UIColor colorWithRed:242/256 green:242/256 blue:242/256 alpha:1].CGColor;
    [footView addSubview:clearButton];
    self.tableView.tableFooterView = footView;
}
/**
 *  清空搜索历史操作
 */
- (void)clearButtonClick{
    [[SearchDBManage shareSearchDBManage] deleteAllSearchModel];
    [self.historySource removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    return YES;
}// return NO to not become first responder
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    
}// called when text starts editing
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    return YES;
}// return NO to not resign first responder
- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    return YES;
}// called before text changes
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if ([searchBar.text isEqualToString:@""]) {
        [MBProgressHUD showTipMessageInView:@"搜索内容不能为空！"];
    }else{
        [self insterDBData:searchBar.text]; // 将搜索的关键字插入数据库
        [self loadSearchData];//加载搜索网络请求
    }
    [searchBar resignFirstResponder];
}// called when keyboard search button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if ([searchBar.text isEqualToString:@""]) {
        [MBProgressHUD showTipMessageInView:@"搜索内容不能为空！"];
    }else{
        [self insterDBData:searchBar.text]; // 将搜索的关键字插入数据库
        [self loadSearchData];//加载搜索网络请求
    }
    [searchBar resignFirstResponder];
}// called when cancel button pressed

#pragma mark -以下用于保存搜索历史
/**
 *  数据初始化
 */
- (void)initData{
    self.historySource = [[NSMutableArray alloc] init];
    //    [[SearchDBManage shareSearchDBManage] deleteAllSearchModel];
    self.historySource = [[SearchDBManage shareSearchDBManage] selectAllSearchModel];
}
/**
 *  获取当前时间
 *
 *  @return 当前时间
 */
- (NSString *)getCurrentTime{
    NSDate *  senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"MM月dd日HH:mm"];
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    return locationString;
}

/**
 *  去除数据库中已有的相同的关键词
 *
 *  @param keyword 关键词
 */
- (void)removeSameData:(NSString *)keyword{
    NSMutableArray *array = [[SearchDBManage shareSearchDBManage] selectAllSearchModel];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SearchModel *model = (SearchModel *)obj;
        if ([model.keyWord isEqualToString:keyword]) {
            [[SearchDBManage shareSearchDBManage] deleteSearchModelByKeyword:keyword];
        }
    }];
}

/**
 *  数组左移
 *
 *  @param array   需要左移的数组
 *  @param keyword 搜索关键字
 *
 *  @return 返回新的数组
 */
- (NSMutableArray *)moveArrayToLeft:(NSMutableArray *)array keyword:(NSString *)keyword{
    [array addObject:[SearchModel creatSearchModel:keyword currentTime:[self getCurrentTime]]];
    [array removeObjectAtIndex:0];
    return array;
}
/**
 *  数组逆序
 *
 *  @param array 需要逆序的数组
 *
 *  @return 逆序后的输出
 */
- (NSMutableArray *)exchangeArray:(NSMutableArray *)array{
    NSInteger num = array.count;
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    for (NSInteger i = num - 1; i >= 0; i --) {
        [temp addObject:[array objectAtIndex:i]];
        
    }
    return temp;
}

/**
 *  多余20条数据就把第0条去除
 *
 *  @param keyword 插入数据库的模型需要的关键字
 */
- (void)moreThan20Data:(NSString *)keyword{
    // 读取数据库里面的数据
    NSMutableArray *array = [[SearchDBManage shareSearchDBManage] selectAllSearchModel];
    
    if (array.count > MAX_COUNT - 1) {
        NSMutableArray *temp = [self moveArrayToLeft:array keyword:keyword]; // 数组左移
        [[SearchDBManage shareSearchDBManage] deleteAllSearchModel]; //清空数据库
        [self.historySource removeAllObjects];
        [self.tableView reloadData];
        [temp enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SearchModel *model = (SearchModel *)obj; // 取出 数组里面的搜索模型
            [[SearchDBManage shareSearchDBManage] insterSearchModel:model]; // 插入数据库
        }];
    }
    else if (array.count <= MAX_COUNT - 1){ // 小于等于19 就把第20条插入数据库
        [[SearchDBManage shareSearchDBManage] insterSearchModel:[SearchModel creatSearchModel:keyword currentTime:[self getCurrentTime]]];
    }
}
/**
 *  关键词插入数据库
 *
 *  @param keyword 关键词
 */
- (BOOL)insterDBData:(NSString *)keyword{
    if (keyword.length == 0) {
        return NO;
    }
    else{//搜索历史插入数据库
        //先删除数据库中相同的数据
        [self removeSameData:keyword];
        //再插入数据库
        [self moreThan20Data:keyword];
        // 读取数据库里面的数据
        self.historySource = [[SearchDBManage shareSearchDBManage] selectAllSearchModel];
        [self.tableView reloadData];
        return YES;
    }
}

#pragma mark -点击空白处回收键盘
-(void)addTapGestureToGetBackKeyboard{
    self.view.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fingerTapped:)];
    
    [self.view addGestureRecognizer:singleTap];
}
-(void)fingerTapped:(UITapGestureRecognizer *)gestureRecognizer{
    
    [self.view endEditing:YES];
    
}



#pragma mark -以下是你需要更改的地方
#pragma mark -加载搜索数据
-(void)loadSearchData{
//    MBProgressHUD *hud = [MBProgressHUD showActivityMessageInView:nil];
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    NSMutableSet *set = [NSMutableSet setWithSet:manager.responseSerializer.acceptableContentTypes];
//    [set addObject:@"text/html"];
//    manager.responseSerializer.acceptableContentTypes = set;
//    
//    NSString *token = [kUserDefaults objectForKey:@"token"];
//    NSDictionary *param = @{@"token":token,
//                            @"sel_name":self.searchBar.text};
//    
//    NSString *baseURL = [kUserDefaults objectForKey:@"baseURL"];
//    NSString *url = [NSString stringWithFormat:kSearch_url, baseURL];
//    
//    [manager POST:url parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
//        
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        //网络请求成功
//        [hud removeFromSuperview];
//        
//        if ([responseObject[@"code"] isEqual:@200]) {
//            if (self.source.count > 0) {
//                [self.source removeAllObjects];
//            }
//            NSDictionary *data = responseObject[@"data"];
//            NSArray *list = data[@"list"];
//            self.source = [NSMutableArray arrayWithArray:list];
//            //刷新
//            [self.tableView reloadData];
//            
//        }else {
//            if ([responseObject[@"code"] isEqual:@-96]) {
//                [[ToolManager sharedManager] logoutACTIONFromSuperVC:self];
//            }
//            [MBProgressHUD showErrorMessage:responseObject[@"message"]];
//        }
//        
//        NSLog(@"%@",responseObject);
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        //网络请求失败
//        [hud removeFromSuperview];
//        [MBProgressHUD showErrorMessage:@"网络请求失败！"];
//        NSLog(@"%@",error);
//    }];
}
#pragma mark - UITableViewDelegate,UITableViewDataSource
//组数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
//行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.source.count == 0) {
        if (self.historySource.count == 0) {
            self.tableView.tableFooterView.hidden = YES; // 没有历史数据时隐藏
        }else{
            self.tableView.tableFooterView.hidden = NO; // 有历史数据时显示
        }
        return self.historySource.count;
    }else{
        self.tableView.tableFooterView.hidden = YES; // 有搜索数据时隐藏
        return self.source.count;
    }
}
//行内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.source.count == 0) {//显示搜索历史
        SearchHistoryCell *cell_history = [tableView dequeueReusableCellWithIdentifier:identifierCell2 forIndexPath:indexPath];
        SearchModel *model = (SearchModel *)[self exchangeArray:self.historySource][indexPath.row];
        cell_history.title.text = model.keyWord;
        cell_history.time.text = model.currentTime;
        return cell_history;
    }else{//显示搜索结果
        SearchResultCell *cell_result = [tableView dequeueReusableCellWithIdentifier:identifierCell1 forIndexPath:indexPath];
        
        return cell_result;
    }
}
////点击cell 》》》》这个地方点击不会响应 （具体我也不知道为什么）-> 解决办法是：在自定义的cell上添加一个透明的按钮

//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    if (self.source.count == 0) {//点击历史
//        SearchModel *model = (SearchModel *)[self exchangeArray:self.historySource][indexPath.row];
//        self.searchBar.text = model.keyWord;
//        //点击搜索
//        [self loadSearchData];
//    }else{//点击搜索结果
//       //跳转详情操作
//    }
//}

//间距
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.1;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
