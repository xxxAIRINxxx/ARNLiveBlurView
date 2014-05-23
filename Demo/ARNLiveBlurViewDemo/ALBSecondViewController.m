//
//  ALBSecondViewController.m
//  ARNLiveBlurViewDemo
//
//  Created by Airin on 2014/05/23.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "ALBSecondViewController.h"
#import "ARNLiveBlurView.h"

@interface ALBSecondViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView    *tableView;
@property (nonatomic, strong) NSMutableArray *items;

@end

@implementation ALBSecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    backgroundView.frame       = self.view.bounds;
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:backgroundView];
    
    ARNLiveBlurView *blurView = [[ARNLiveBlurView alloc] initWithFrame:backgroundView.bounds];
    blurView.viewToBlur = backgroundView;
    [self.view addSubview:blurView];
    blurView.alpha = 0;
    
    self.tableView                  = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)) style:UITableViewStylePlain];
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource       = self;
    self.tableView.delegate         = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.separatorColor   = [UIColor clearColor];
    self.tableView.backgroundColor  = [UIColor clearColor];
    self.tableView.rowHeight        = 44;
    [self.view addSubview:self.tableView];
    
    __weak typeof(self) weakSelf = self;
    
    [blurView setObservingScrollView:self.tableView observingBlock: ^(ARNLiveBlurView *blurredView, UIScrollView *observingView) {
        [blurredView updateBlur];
        blurredView.alpha = (observingView.contentOffset.y + observingView.contentInset.top) / (2 * CGRectGetHeight(weakSelf.view.bounds) / 3);
    }];
    
    self.items = [NSMutableArray array];
    NSArray *countryCodes = [NSLocale ISOCountryCodes];
    for (NSString *countryCode in countryCodes) {
        NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode forKey:NSLocaleCountryCode]];
        NSString *country    = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
        [self.items addObject:country];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell           = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell                     = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.backgroundColor     = [UIColor clearColor];
        cell.selectionStyle      = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = self.items[indexPath.row];
    
    return cell;
}

@end
