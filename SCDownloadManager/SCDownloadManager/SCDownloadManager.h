//
//  SCDownloadManager.h
//  SCDownloadManager
//
//  Created by Suman Chatterjee on 29/03/2015.
//  Copyright (c) 2015 Suman Chatterjee. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCDownloadManagerDelegate <NSObject>
@optional
/**A delegate method called each time whenever new download task is start downloading
 */
- (void)downloadRequestStarted:(NSURLSessionDownloadTask *)downloadTask;
/**A delegate method called each time whenever any download task is cancelled by the user
 */
- (void)downloadRequestCanceled:(NSURLSessionDownloadTask *)downloadTask;
/**A delegate method called each time whenever any download task is finished successfully
 */
- (void)downloadRequestFinished:(NSString *)fileName;
@end


@interface SCDownloadManager : NSObject

/**An array that holds the information about all downloading tasks.
 */
@property(nonatomic, strong) NSMutableArray *downloadingArray;

/**A session manager for background downloading.
 */
@property(nonatomic, strong) NSURLSession *sessionManager;
/**A delegate for doing the download
 */
@property (nonatomic, weak) id<SCDownloadManagerDelegate> delegate;

- (NSURLSession *)backgroundSession;
/**A method for adding new download task.
 @param NSString* file name
 @param NSString* file url
 */
- (void)addDownloadTask:(NSString *)fileName fileURL:(NSString *)fileURL;
/**A method for restoring any interrupted download tasks e.g user force quits the app or any network error occurred.
 */
- (void)populateOtherDownloadTasks;

@end
