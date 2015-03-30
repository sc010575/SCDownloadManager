//
//  AvailableDownloadsCell.m
//  SCDownloadManager
//
//  Created by Suman Chatterjee on 29/03/2015.
//  Copyright (c) 2015 Suman Chatterjee. All rights reserved.
//

#import "AvailableDownloadsCell.h"

@interface AvailableDownloadsCell()
@property (weak, nonatomic) IBOutlet UILabel *fileName;

- (IBAction)startInstall:(id)sender;

@end


@implementation AvailableDownloadsCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupCellWithText:(NSString*)text
{
    self.fileName.text = text;
    
}

- (IBAction)startInstall:(id)sender {
    NSLog(@"startInstall pressed");
}
@end
