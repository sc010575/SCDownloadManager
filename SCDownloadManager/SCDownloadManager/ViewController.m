//
//  ViewController.m
//  SCDownloadManager
//
//  Created by Suman Chatterjee on 22/03/2015.
//  Copyright (c) 2015 Suman Chatterjee. All rights reserved.
//

#import "ViewController.h"
#import "SCUtilityManager.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic)NSMutableArray *availableDownloadsArray;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.availableDownloadsArray = [NSMutableArray arrayWithObjects:
                               @"http://localhost/PurpGuy.gif",
                               @"http://localhost/DSC03409.JPG",
                               @"http://localhost/DSC03417.JPG",
                               @"http://localhost/PoweredByMacOSXLarge.gif",
                               @"http://localhost/PoweredByMacOSX.gif", nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Tableview Delegate and Datasource -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.availableDownloadsArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AvailableDownloadsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    [cell.textLabel setText:[[[self.availableDownloadsArray objectAtIndex:indexPath.row] componentsSeparatedByString:@"/"] lastObject]];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *urlLastPathComponent = [[[self.availableDownloadsArray objectAtIndex:indexPath.row] componentsSeparatedByString:@"/"] lastObject];
    NSString *fileName = [SCUtilityManager getUniqueFileNameForName:urlLastPathComponent];
 //   [mzDownloadingViewObj addDownloadTask:fileName fileURL:[availableDownloadsArray objectAtIndex:indexPath.row]];
    
 //   [self updateDownloadingTabBadge];
    
 //   [availableDownloadsArray removeObjectAtIndex:indexPath.row];
 //   [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}


@end
