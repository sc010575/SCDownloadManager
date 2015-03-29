//
//  AvailableDownloadsCell.h
//  SCDownloadManager
//
//  Created by Suman Chatterjee on 29/03/2015.
//  Copyright (c) 2015 Suman Chatterjee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AvailableDownloadsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *installBtn;

- (void)setupCellWithText:(NSString*)text;

@end
