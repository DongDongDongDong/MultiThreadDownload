//
//  OBDDownloadListViewController.m
//  obdDownloader
//
//  Created by andylau on 16/1/25.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import "OBDDownloadList.h"
#import "DownListCell.h"
#import "DownListModel.h"
#import "DownLoadMission.h"
#import "DownloadMissionList.h"
#import "soapRequestTools.h"
#import "Util.h"
#import "FinishDownCell.h"
#import "StorageSpace.h"
#import "UIViewController+BackButtonHandler.h"
#import "MJRefresh.h"
//#import "UIView+EXtension.h"
#import "DXAlertView.h"
@interface OBDDownloadList ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *brandSegment;

/** cell */
@property (nonatomic, strong) NSMutableDictionary *downloadCellDict;
@property (nonatomic, strong) StorageSpace *storageView;
@property (nonatomic, assign) CGFloat usedStorage;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *obdListTableBottomHieght;
/** 下载品牌按钮 */
@property (nonatomic, strong) UIButton *rightBtn;


@end

@implementation OBDDownloadList
static id instance;

- (NSDictionary *)statusDict{
    if (_statusDict == nil) {
        _statusDict = [NSMutableDictionary dictionary];
    }
    return  _statusDict;
}

- (NSMutableDictionary *)downloadCellDict{
    if (_downloadCellDict == nil) {
        _downloadCellDict = [NSMutableDictionary dictionary];
    }
    return _downloadCellDict;
}

- (ThreadSafetyArray *)downListArray{
    if (_downListArray == nil) {
        _downListArray = [[ThreadSafetyArray alloc] init];
    }else{
        [_downListArray traversal:^(NSObject *obj, BOOL *stop) {
            DownListModel *model = (DownListModel *)obj;
            model.brandProgress = [[NSUserDefaults standardUserDefaults] objectForKey:model.brandName];
        }];
        
//        for (DownListModel *model in _downListArray) {
//            model.brandProgress = [[NSUserDefaults standardUserDefaults] objectForKey:model.brandName];
//        }
    }
    return _downListArray;
}


- (StorageSpace *)storageView{
    if (_storageView == nil) {
        _storageView = [[[NSBundle mainBundle]loadNibNamed:@"StorageSpace"owner:nil options:nil] lastObject];
        _storageView.frame = CGRectMake(0, SCREENHEIGHT - 44, SCREENWIDTH, 44);
        [[UIApplication sharedApplication].keyWindow addSubview:_storageView];
    }
    CGFloat overPlus = [self getStorageSpace];
    _storageView.spaceLabel.text = [NSString stringWithFormat:@"已下载%.fM,手机剩余空间%.1fG",self.usedStorage,overPlus];
    return _storageView;
}

- (void)refreshStorage{
    self.storageView.spaceLabel.text = [NSString stringWithFormat:@"已下载%.fM,手机剩余空间%.1fG",self.usedStorage,[self getStorageSpace]];
}
- (void)addRefresh{
    
    self.obdListTable.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(getVehiclesList)];
    
    [self.obdListTable.mj_header beginRefreshing];
    
}

- (void)getVehiclesList{
    
    [[SoapRequestTools shareSoapTools] getVehiclesListSuccessBlock:^(NSDictionary *dic) {
        [self.obdListTable.mj_header endRefreshing];
        NSArray *result = dic[@"result"];
            [self.downListArray removeAllObjects];
            [self.downloadedListArray removeAllObjects];
        for (NSDictionary *dict in result) {
            DownListModel *model = [[DownListModel alloc] init];
            model.brandName = dict[@"ChineseName"];
            model.brandProgress = [[NSUserDefaults standardUserDefaults] objectForKey:model.brandName];
            model.originName = dict[@"OriginalName"];
            model.brandSize = [NSString stringWithFormat:@"%.1f",[dict[@"FileSize"] floatValue] / 1024.00];
            NSString *encodingUrl = [dict[@"FilePath"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            model.downloadUrl = encodingUrl;
            model.uniqueMark = dict[@"OriginalName"];
            if([model.brandProgress isEqualToString:@"1.000000"]){
                    [self.downloadedListArray addObject:model];
            }else{
                    [self.downListArray addObject:model];
            }
        }
        [self.obdListTable reloadData];
        self.obdListTable.mj_header = nil;
        if(!self.downListArray.count){
            self.rightBtn.hidden = YES;
        }
    } failBlock:^(NSError *error) {
        [self.obdListTable.mj_header endRefreshing];
//        [MBProgressHUD showError:@"加载品牌列表失败，请重试"];
        if(!self.downListArray.count){
            self.rightBtn.hidden = YES;
        }
    }];
}

- (NSString *)generateUniqueIDWith:(NSString *)i{
    NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
    [formatter setDateFormat:@"YYYYMMddHHmmssSSS"];
    NSString *date =  [formatter stringFromDate:[NSDate date]];
    NSString *timeLocal = [[NSString alloc] initWithFormat:@"%@%@", date,i];
    return timeLocal;
}

- (ThreadSafetyArray *)downloadedListArray{
    if (_downloadedListArray == nil) {
        _downloadedListArray = [[ThreadSafetyArray alloc] init];
    }
    return _downloadedListArray;
}

//- (NSMutableArray *)downloadedListArray{
//    if (_downloadedListArray == nil) {
//        _downloadedListArray = [NSMutableArray array];
//    }
//    return _downloadedListArray;
//}

+ (OBDDownloadList *)shareDownloadList{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = (OBDDownloadList *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"OBDDownloadList_ID"];
    });
    
    return instance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addRightBarButton];
    [self addRefresh];
    self.obdListTable.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.obdListTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.brandSegment addTarget:self action:@selector(segmentClick:) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteFinishCell:) name:AIOBDDownloadDeleteUploadCellNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(self.brandSegment.selectedSegmentIndex){
        self.storageView.hidden = NO;
    }
}

- (void)addRightBarButton{
    self.rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 90, 30)];
    [self.rightBtn setTitle:@"全部下载" forState:UIControlStateNormal];
    UIFont *btnFont = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
    self.rightBtn.titleLabel.font = btnFont;
    self.rightBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.rightBtn.layer.borderWidth = 1.0;
    [self.rightBtn setBackgroundColor:[UIColor colorWithRed:65.0/255.0 green:140.0/255.0 blue:214.0/255.0 alpha:1.0]];
    [self.rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.rightBtn addTarget:self action:@selector(downloadAllTask) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *RightItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtn];
    self.navigationItem.rightBarButtonItem = RightItem;
    
}

- (void)deleteFinishCell:(NSNotification *)note{
    DownListModel *model = note.userInfo[@"model"];
//    NSInteger row = [self.downListArray indexOfObject:model];
    __block typeof(self) weakSelf = self;
        [self.downListArray traversal:^(NSObject *obj, BOOL *stop) {
            DownListModel *downModel = (DownListModel *)obj;
                if ([downModel.brandName isEqualToString:model.brandName]) {
                    [weakSelf.downListArray removeObject:downModel];
                    if(stop){
                        *stop = YES;
                    }
                }
        }];
//        for (DownListModel *downModel in self.downListArray) {
//            if ([downModel.brandName isEqualToString:model.brandName]) {
//                [self.downListArray removeObject:downModel];
//                break;
//            }
//        }
        [self.downloadedListArray addObject:model];
//        NSIndexPath *tmpIndexpath=[NSIndexPath indexPathForRow:row inSection:0];
//        if(!self.isDownloaded){
            [self.obdListTable reloadData];
//            [self.obdListTable deleteRowsAtIndexPaths:[NSArray arrayWithObjects:tmpIndexpath, nil] withRowAnimation:UITableViewRowAnimationTop];
//        }
    
    if(!self.downListArray.count){
        self.rightBtn.hidden = YES;
    }
}


- (void)segmentClick:(UISegmentedControl *)segment{
    NSLog(@"%ld",(long)segment.selectedSegmentIndex);
    switch (segment.selectedSegmentIndex) {
        case 0:{
            self.isDownloaded = NO;
            self.storageView.hidden = YES;
            self.obdListTableBottomHieght.constant = 0;
            [self.obdListTable reloadData];
            self.rightBtn.hidden = NO;
            if(!self.downListArray.count){
                self.rightBtn.hidden = YES;
            }
        }
            break;
        case 1:{
            // 已完成
            self.isDownloaded = YES;
            self.storageView.hidden = NO;
            self.obdListTableBottomHieght.constant = 44;
            [self.obdListTable reloadData];
            self.rightBtn.hidden = YES;
        }
            break;
            
    }
}

- (CGFloat) getStorageSpace {
    self.usedStorage = 0.0;
    __block typeof(self) weakSelf = self;
    [self.downloadedListArray traversal:^(NSObject *obj, BOOL *stop) {
        DownListModel *model = (DownListModel *)obj;
        weakSelf.usedStorage += [model.brandSize floatValue];
    }];
    
//    for (DownListModel *model in self.downloadedListArray) {
//        self.usedStorage += [model.brandSize floatValue];
//    }
    NSDictionary *fsAttr = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    CGFloat diskFreeSize = [fsAttr[NSFileSystemFreeSize] doubleValue] / (1024 * 1024 * 1024.00);
    return diskFreeSize;
}

- (void)downloadAllTask{
    
    __block typeof(self) weakSelf = self;
    if([Util getNetworkTypeFromStatusBar] == 0){
        [Util showTips:@"似乎已断开与互联网的连接" forSecond:1.0 onView:nil];
        return;
    }else if([Util getNetworkTypeFromStatusBar] != 5){
        DXAlertView *alert = [[DXAlertView alloc] initWithTitle:@"警告" contentText:@"确定要使用手机流量下载全部任务吗?" leftButtonTitle:@"确定" rightButtonTitle:@"取消"];
        [alert show];
        alert.leftBlock = ^(){
            [weakSelf permitDownLoadAllTask];
        };
    }else{
        NSLog(@"确定要使用WIFI进行下载吗？");
        [weakSelf permitDownLoadAllTask];
    }
    
}

- (void)permitDownLoadAllTask{
    
    if(![Util haveEnoughSpace]){
        DXAlertView *alert = [[DXAlertView alloc]initWithTitle:@"存储空间不足" contentText:@"请清理空间后重试" leftButtonTitle:nil rightButtonTitle:@"确定"];
        [alert show];
        DownListModel *model = [[DownListModel alloc] init];
        model.errorDescription = @"存储空间不足";
        [AINoteCenter postNotificationName:AIOBDDownloadFailedNotification object:self userInfo:@{@"MODEL":model}];
        return;
    }

    //    NSMutableArray *unAddTaskArray = [NSMutableArray arrayWithArray:self.downListArray];
    NSMutableArray *unAddTaskArray = [self.downListArray copyCurrentArray];
    
    for (DownLoadMission *tasked in [DownloadMissionList shareDownload].allTasks) {
        [unAddTaskArray removeObject:tasked.model];
        NSLog(@"已存在的任务%@",tasked.model.brandName);
    }
    
    NSLog(@"新添加的任务长度%luld",(unsigned long)unAddTaskArray.count);
    if(!unAddTaskArray.count){
        [Util showTips:@"所有任务已全部添加!" forSecond:1.0 onView:nil];
        return;
    }
    for (DownListModel *model in unAddTaskArray) {
        NSLog(@"本次添加了任务%@",model.brandName);
        
        DownLoadMission *mission = [[DownLoadMission alloc]initWithUID:model.uniqueMark];
        mission.model = model;
        [[DownloadMissionList shareDownload] addMission:mission];
        
        [mission changeValueText:^(CGFloat progressValue, DownListModel *model) {
            [[NSNotificationCenter defaultCenter] postNotificationName:AIOBDDownloadChangeCellStatusNotification object:nil userInfo:@{@"uid":model.uniqueMark, @"progress":@(progressValue)} ];
        }];
        
        [mission didFinishDownload:^(DownListModel *finishModal) {
            NSLog(@"下载完毕 %@-%@",finishModal.brandName,finishModal.brandSize);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:AIOBDDownloadDeleteUploadCellNotification object:nil userInfo:@{@"model":finishModal}];
        }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AIOBDDownloadAllTaskChangeStatusNotification object:nil userInfo:nil ];
}


-(BOOL)navigationShouldPopOnBackButton
{
    self.storageView.hidden = YES;
    return YES;
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(self.isDownloaded){
        // 已下载
            return self.downloadedListArray.count;
    }else{
            return self.downListArray.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.isDownloaded) {
        static NSString *reUseInentifier2 = @"OBDLISTCELL2";
        
        FinishDownCell *cell = [tableView dequeueReusableCellWithIdentifier:reUseInentifier2];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"FinishDownCell" bundle:nil] forCellReuseIdentifier:reUseInentifier2];
            cell = [tableView dequeueReusableCellWithIdentifier:reUseInentifier2];
        }
//        DownListModel *model = self.downloadedListArray[indexPath.row];
        DownListModel *model = (DownListModel *)[self.downloadedListArray objectAtIndex:indexPath.row];
        cell.downModel = model;
        return cell;
    }else{
/*
        DownListModel *model = self.downListArray[indexPath.row];
        NSString *reUseIdentifier1 = [NSString stringWithFormat:@"Cell%ld%ld%@",indexPath.section,indexPath.row,model.brandName];
        DownListCell *cell = [tableView dequeueReusableCellWithIdentifier:reUseIdentifier1];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"DownListCell" bundle:nil] forCellReuseIdentifier:reUseIdentifier1] ;
            cell = [tableView dequeueReusableCellWithIdentifier:reUseIdentifier1];
        }

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.downModal = self.downListArray[indexPath.row];
 */
        
//        DownListModel *model = self.downListArray[indexPath.row];
        DownListModel *model = (DownListModel *)[self.downListArray objectAtIndex:indexPath.row];

        NSString *identifier = [NSString stringWithFormat:@"BrandCell%@%@",model.brandSize,@(indexPath.row)];
        DownListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"DownListCell" bundle:nil] forCellReuseIdentifier:identifier];
            cell = [tableView dequeueReusableCellWithIdentifier:identifier];

        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.downModal = model;
        return cell;

        
        
        
        /*
        DownListModel *model = self.downListArray[indexPath.row];
        NSString *reUseIdentifier1 = [NSString stringWithFormat:@"Cell%@",model.brandName];
        DownListCell *cell;
        
        if (self.downloadCellDict[reUseIdentifier1]) {
            cell = self.downloadCellDict[reUseIdentifier1];
        }else{
            cell = [[[NSBundle mainBundle] loadNibNamed:@"DownListCell" owner:self options:nil] lastObject];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.downModal = self.downListArray[indexPath.row];

        
        [self.downloadCellDict setObject:cell forKey:reUseIdentifier1];
        return cell;
         */
    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}


#pragma mark - UITableViewDelegate
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(self.isDownloaded){
        return  UITableViewCellEditingStyleDelete;
    }else{
        return  UITableViewCellEditingStyleNone;
    }
}



- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
//        DownListModel *model = self.downloadedListArray[indexPath.row];
        DownListModel *model = (DownListModel *)[self.downloadedListArray objectAtIndex:indexPath.row];

        [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:model.brandName];
            [self.downloadedListArray removeObjectAtIndex:indexPath.row];
        
            [[OBDDownloadList shareDownloadList].statusDict setObject:@"11111" forKey:model.brandName];
//            NSIndexPath *tmpIndexpath=[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
//            [self.obdListTable deleteRowsAtIndexPaths:[NSArray arrayWithObjects:tmpIndexpath, nil] withRowAnimation:UITableViewRowAnimationTop];
            [self.obdListTable reloadData];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self deleteLocalVehiclesWithModel:model];
            [self getVehiclesList];
            [self refreshStorage];
        });
    }
}

- (void)deleteLocalVehiclesWithModel:(DownListModel *)model{
    NSDictionary *vehicleDict = @{@"PS_BJJEEP_V6_93_CN.zip":@"China/PS_BJJEEP",
                                 @"PS_BQFT_V7_20_CN.ZIP":@"China/PS_BQFT",
                                 @"PS_CHANGAN_V8_62_CN.ZIP":@"China/PS_CHANGAN",
                                 @"PS_CHANGCHENG_V8_18_CN.ZIP":@"China/PS_CHANGCHENG",
                                 @"PS_CHANGHE_V6_94_CN.ZIP":@"China/PS_CHANGHE",
                                 @"PS_CASUZUKI_V7_21_CN.ZIP":@"China/PS_CASUZUKI",
                                 @"PS_BQZZ_V6_52_CN.ZIP":@"China/PS_BQZZ",
                                 @"PS_DFFX_V7_34_CN.ZIP":@"China/PS_DFFX",
                                 @"PS_BYD_V9_13_CN.ZIP":@"China/PS_BYD",
                                 @"PS_FUQI_V6_12_CN.ZIP":@"China/PS_FUQI",
                                 @"PS_HAFEI_V7_11_CN.ZIP":@"China/PS_HAFEI",
                                 @"PS_JILI_V7_80_CN.ZIP":@"China/PS_JILI",
                                 @"PS_HUACHEN_V8_28_CN.ZIP":@"China/PS_HUACHEN",
                                 @"PS_YONGYUANFEIDIE_V2_01_CN.ZIP":@"China/PS_YONGYUANFEIDIE",
                                 @"PS_HUAYANG_V6_13_CN.ZIP":@"China/PS_HUAYANG",
                                 @"PS_JAC_V7_30_CN.ZIP":@"China/PS_JAC",
                                 @"PS_DFWX_V6_02_CN.ZIP":@"China/PS_DFWX",
                                 @"PS_JIAO_V6_52_CN.ZIP":@"China/PS_JIAO",
                                 @"PS_JINLONG_V6_41_CN.ZIP":@"China/PS_JINLONG",
                                 @"PS_TONGBAO_V6_12_CN.ZIP":@"China/PS_TONGBAO",
                                 @"PS_YQJB_V6_61_CN.ZIP":@"China/PS_YQJB",
                                 @"PS_ALTO_V6_64_CN.ZIP":@"China/PS_ALTO",
                                 @"PS_CHANGFENG_V6_75_CN.ZIP":@"China/PS_CHANGFENG",
                                 @"PS_LIFAN_V7_08_CN.ZIP":@"China/PS_LIFAN",
                                 @"PS_SQTYWL_V7_23_CN.ZIP":@"China/PS_SQTYWL",
                                 @"PS_JIANGLING_V7_12_CN.ZIP":@"China/PS_JIANGLING",
                                 @"PS_SOYAT_V6_13_CN.ZIP":@"China/PS_SOYAT",
                                 @"PS_SAIBAO_V6_12_CN.ZIP":@"China/PS_SAIBAO",
                                 @"PS_HUIZHONG_V6_26_CN.ZIP":@"China/PS_HUIZHONG",
                                 @"PS_SPARK_V5_56_CN.ZIP":@"China/PS_SPARK",
                                 @"PS_TIANMA_V6_13_CN.ZIP":@"China/PS_TIANMA",
                                 @"PS_TJYQ_V7_81_CN.ZIP":@"China/PS_TJYQ",
                                 @"PS_ZZNISSAN_V8_51_CN.ZIP":@"China/PS_ZZNISSAN",
                                 @"PS_ZHONGTAI_V6_52_CN.ZIP":@"China/PS_ZHONGTAI",
                                 @"PS_ZHONGXIN_V6_51_CN.ZIP":@"China/PS_ZHONGXIN",
                                 @"PS_RONGWEI_V8_44_CN.ZIP":@"China/PS_RONGWEI",
                                 @"PS_SQMG_V7_94_CN.ZIP":@"China/PS_SQMG",
                                 @"PS_HUATAI_V7_33_CN.ZIP":@"China/PS_HUATAI",
                                 @"PS_YQJC_V7_24_CN.ZIP":@"China/PS_YQJC",
                                 @"PS_SHUANGHUAN_V6_16_CN.ZIP":@"China/PS_SHUANGHUAN",
                                 @"PS_YANGZI_V6_13_CN.ZIP":@"China/PS_YANGZI",
                                 @"PS_ZHONGSHUN_V6_23_CN.ZIP":@"China/PS_ZHONGSHUN",
                                 @"PS_XINDADI_V6_13_CN.ZIP":@"China/PS_XINDADI",
                                 @"PS_XINKAI_V6_16_CN.ZIP":@"China/PS_XINKAI",
                                 @"PS_FUDI_V6_23_CN.ZIP":@"China/PS_FUDI",
                                 @"PS_BAOJUN_V5_52_CN.ZIP":@"China/PS_BAOJUN",
                                 @"PS_YQSY_V5_54_CN.ZIP":@"China/PS_YQSY",
                                 @"PS_JIULONG_V1_11_CN.ZIP":@"China/PS_JIULONG",
                                 @"PS_DADI_V6_13_CN.ZIP":@"China/PS_DADI",
                                 @"PS_MEIYA_V6_22_CN.ZIP":@"China/PS_MEIYA",
                                 @"PS_YEMA_V3_01_CN.ZIP":@"China/PS_YEMA",
                                 @"PS_HBQC_V6_12_CN.ZIP":@"China/PS_HBQC",
                                 @"PS_DNQC_V7_05_CN.ZIP":@"China/PS_DNQC",
                                 @"PS_BAOLONG_V6_63_CN.ZIP":@"China/PS_BAOLONG",
                                 @"PS_BQWW_V5_51_CN.ZIP":@"China/PS_BQWW",
                                 @"PS_BJQC_V7_01_CN.ZIP":@"China/PS_BJQC",
                                 @"PS_LUFENGZY_V5_00_CN.ZIP":@"China/PS_LUFENG",
                                 @"PS_HHQC_V5_12_CN.ZIP":@"China/PS_HHQC",
                                 @"PS_HNMAZDA_V7_74_CN.ZIP":@"China/PS_HNMAZDA",
                                 @"PS_QNLH_V6_23_CN.ZIP":@"China/PS_QNLH",
                                 @"PS_YINGZHI_V6_10_CN.ZIP":@"China/PS_YINGZHI",
                                 @"PS_SQDTZY_V5_11_CN.ZIP":@"China/PS_SQDT",
                                 @"PS_LUXGEN_V1_31_CN.ZIP":@"China/PS_LUXGEN",
                                 @"PS_DFFS_V5_51_CN.ZIP":@"China/PS_DFFS",
                                 @"PS_GQCQ_V6_31_CN.ZIP":@"China/PS_GQCQ",
                                 @"PS_JINCHENG_V6_34_CN.ZIP":@"China/PS_JINCHENG",
                                 @"PS_ZJWF_V6_03_CN.ZIP":@"China/PS_ZJWF",
                                 @"PS_ZYF_V6_03_CN.ZIP":@"China/PS_ZYF",
                                 @"PS_QIRUI_V8_52_CN.ZIP":@"China/PS_QIRUI",
                                 @"PS_TOYOTA_V10_80_CN.ZIP":@"Asia/PS_TOYOTA",
                                 @"PS_HONDA_V9_62_CN.ZIP":@"Asia/PS_HONDA",
                                 @"PS_NISSAN_V9_53_CN.ZIP":@"Asia/PS_NISSAN",
                                 @"PS_MIT_V8_21_CN.ZIP":@"Asia/PS_MIT",
                                 @"PS_HYUNDAI_V10_23_CN.ZIP":@"Asia/PS_HYUNDAI",
                                 @"PS_KIA_V10_23_CN.ZIP":@"Asia/PS_KIA",
                                 @"PS_SSANGYONG_V8_15_CN.ZIP":@"Asia/PS_SSANGYONG",
                                 @"PS_SUBARU_V6_92_CN.ZIP":@"Asia/PS_SUBARU",
                                 @"PS_ISUZU_V7_10_CN.ZIP":@"Asia/PS_ISUZU",
                                 @"PS_BMW_V10_02_CN.ZIP":@"Europe/PS_BMW",
                                 @"PS_VW_V9_02_CN.ZIP":@"Europe/PS_VW",
                                 @"PS_GM_V9_01_CN.ZIP":@"America/PS_GM",
                                 @"PS_USAFORD_V9_22_CN.ZIP":@"America/PS_USAFORD",
                                 @"PS_FIAT_V7_42_CN.ZIP":@"Europe/PS_FIAT",
                                 @"PS_MAZDA_V9_12_CN.ZIP":@"Asia/PS_MAZDA",
                                 @"PS_PORSCHE_V9_20_CN.ZIP":@"Europe/PS_PORSCHE",
                                 @"PS_LANDROVER_V9_03_CN.ZIP":@"Europe/PS_LANDROVER",
                                 @"PS_CHRYSLER_V6_61_CN.ZIP":@"America/PS_CHRYSLER",
                                 @"PS_BJXD_V9_50_CN.ZIP":@"China/PS_BJXD",
                                 @"PS_YDKIA_V9_50_CN.ZIP":@"China/PS_YDKIA",
                                 @"PS_OPEL_V8_14_CN.ZIP":@"Europe/PS_OPEL",
                                 @"PS_SAAB_V5_32_CN.ZIP":@"Europe/PS_SAAB",
                                 @"PS_VOLVO_V9_01_CN.ZIP":@"Europe/PS_VOLVO",
                                 @"PS_RENAULT_V7_21_CN.ZIP":@"Europe/PS_RENAULT",
                                 @"PS_PEUGEOT_V9_21_CN.ZIP":@"Europe/PS_PEUGEOT",
                                 @"PS_CITROEN_V9_21_CN.ZIP":@"Europe/PS_CITROEN",
                                 @"PS_FQQT_V5_00_CN.ZIP":@"China/PS_FQQT",
                                 @"PS_SHGM_V11_14_CN.ZIP":@"China/PS_SHGM",
                                 @"PS_SMART_V16_02_CN.ZIP":@"Europe/PS_SMART",
                                 @"PS_TRANSPORTER_V16_10_CN.ZIP":@"Europe/PS_TRANSPORTER",
                                 @"PS_BENZ_V16_22_CN.ZIP":@"Europe/PS_BENZ"};
    
    NSString *brandFileDirectory = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"XTOOL" ] stringByAppendingPathComponent:@"Vehicles"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    
    //delete File
    NSString *fileDirectory = [brandFileDirectory stringByAppendingPathComponent:[vehicleDict objectForKey:model.originName]];
    
    BOOL bRet = [fileMgr fileExistsAtPath:fileDirectory];
        if (bRet) {
            NSError *err;
                [fileMgr removeItemAtPath:fileDirectory error:&err];
        }
    
    
    // delete Zip
    NSString *zipName = [NSString stringWithFormat:@"%@_%@",model.brandName,model.originName];
    NSString *zipPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]stringByAppendingPathComponent:@"XTOOL"] stringByAppendingPathComponent:zipName];
    BOOL isExist = [fileMgr fileExistsAtPath:zipPath];
    if (isExist) {
        NSError *err;
        [fileMgr removeItemAtPath:zipPath error:&err];
    }


    
}



@end
