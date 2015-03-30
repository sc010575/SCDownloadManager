//
//  SCDownloadManager.m
//  SCDownloadManager
//
//  Created by Suman Chatterjee on 29/03/2015.
//  Copyright (c) 2015 Suman Chatterjee. All rights reserved.
//

#import "SCDownloadManager.h"
#import "SCUtilityManager.h"
#import "AppDelegate.h"


NSString * const kMZDownloadKeyURL = @"URL";
NSString * const kMZDownloadKeyStartTime = @"startTime";
NSString * const kMZDownloadKeyFileName = @"fileName";
NSString * const kMZDownloadKeyProgress = @"progress";
NSString * const kMZDownloadKeyTask = @"downloadTask";
NSString * const kMZDownloadKeyStatus = @"requestStatus";
NSString * const kMZDownloadKeyDetails = @"downloadDetails";
NSString * const kMZDownloadKeyResumeData = @"resumedata";

NSString * const RequestStatusDownloading = @"RequestStatusDownloading";
NSString * const RequestStatusPaused = @"RequestStatusPaused";
NSString * const RequestStatusFailed = @"RequestStatusFailed";


@interface SCDownloadManager()<NSURLSessionDelegate>


@end

@implementation SCDownloadManager

- (NSURLSession *)backgroundSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.iosDevelopment.VDownloader.SimpleBackgroundTransfer.BackgroundSession"];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    });
    return session;
}

- (NSArray *)tasks
{
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)dataTasks
{
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)uploadTasks
{
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}
- (NSArray *)downloadTasks
{
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)tasksForKeyPath:(NSString *)keyPath
{
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.sessionManager getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(dataTasks))]) {
            tasks = dataTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadTasks))]) {
            tasks = uploadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(downloadTasks))]) {
            tasks = downloadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(tasks))]) {
            tasks = [@[dataTasks, uploadTasks, downloadTasks] valueForKeyPath:@"@unionOfArrays.self"];
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return tasks;
}
- (void)addDownloadTask:(NSString *)fileName fileURL:(NSString *)fileURL
{
    NSURL *url = [NSURL URLWithString:fileURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithRequest:request];
    
    [downloadTask resume];
    
    NSMutableDictionary *downloadInfo = [NSMutableDictionary dictionary];
    [downloadInfo setObject:fileURL forKey:kMZDownloadKeyURL];
    [downloadInfo setObject:fileName forKey:kMZDownloadKeyFileName];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:downloadInfo options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [downloadTask setTaskDescription:jsonString];
    
    [downloadInfo setObject:[NSDate date] forKey:kMZDownloadKeyStartTime];
    [downloadInfo setObject:RequestStatusDownloading forKey:kMZDownloadKeyStatus];
    [downloadInfo setObject:downloadTask forKey:kMZDownloadKeyTask];
    
    [self.downloadingArray addObject:downloadInfo];
    
    if([self.delegate respondsToSelector:@selector(downloadRequestStarted:)])
        [self.delegate downloadRequestStarted:downloadTask];
}

- (void)populateOtherDownloadTasks
{
    NSArray *downloadTasks = [self downloadTasks];
    
    for(int i=0;i<downloadTasks.count;i++)
    {
        NSURLSessionDownloadTask *downloadTask = [downloadTasks objectAtIndex:i];
        
        NSError *error = nil;
        NSData *taskDescription = [downloadTask.taskDescription dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *downloadInfo = [[NSJSONSerialization JSONObjectWithData:taskDescription options:NSJSONReadingAllowFragments error:&error] mutableCopy];
        
        if(error)
            NSLog(@"Error while retreiving json value: %@",error);
        
        [downloadInfo setObject:downloadTask forKey:kMZDownloadKeyTask];
        [downloadInfo setObject:[NSDate date] forKey:kMZDownloadKeyStartTime];
        
        NSURLSessionTaskState taskState = downloadTask.state;
        if(taskState == NSURLSessionTaskStateRunning)
            [downloadInfo setObject:RequestStatusDownloading forKey:kMZDownloadKeyStatus];
        else if(taskState == NSURLSessionTaskStateSuspended)
            [downloadInfo setObject:RequestStatusPaused forKey:kMZDownloadKeyStatus];
        else
            [downloadInfo setObject:RequestStatusFailed forKey:kMZDownloadKeyStatus];
        
        if(!downloadInfo)
        {
            [downloadTask cancel];
        }
        else
        {
            [self.downloadingArray addObject:downloadInfo];
        }
    }
}
/**Post local notification when all download tasks are finished
 */
- (void)presentNotificationForDownload:(NSString *)fileName
{
    UIApplication *application = [UIApplication sharedApplication];
    UIApplicationState appCurrentState = [application applicationState];
    if(appCurrentState == UIApplicationStateBackground)
    {
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody = [NSString stringWithFormat:@"Downloading complete of %@",fileName];
        localNotification.alertAction = @"Background Transfer Download!";
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = [application applicationIconBadgeNumber] + 1;
        [application presentLocalNotificationNow:localNotification];
    }
}

#pragma mark - NSURLSession Delegates -
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    for(NSMutableDictionary *downloadDict in self.downloadingArray)
    {
        if([downloadTask isEqual:[downloadDict objectForKey:kMZDownloadKeyTask]])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                float progress = (double)downloadTask.countOfBytesReceived/(double)downloadTask.countOfBytesExpectedToReceive;
                
                NSTimeInterval downloadTime = -1 * [[downloadDict objectForKey:kMZDownloadKeyStartTime] timeIntervalSinceNow];
                
                float speed = totalBytesWritten / downloadTime;
                
                NSInteger indexOfDownloadDict = [self.downloadingArray indexOfObject:downloadDict];
//                NSIndexPath *indexPathToRefresh = [NSIndexPath indexPathForRow:indexOfDownloadDict inSection:0];
//                MZDownloadingCell *cell = (MZDownloadingCell *)[bgDownloadTableView cellForRowAtIndexPath:indexPathToRefresh];
//                
//                [cell.progressDownload setProgress:progress];
                
                NSMutableString *remainingTimeStr = [[NSMutableString alloc] init];
                
                unsigned long long remainingContentLength = totalBytesExpectedToWrite - totalBytesWritten;
                
                int remainingTime = (int)(remainingContentLength / speed);
                int hours = remainingTime / 3600;
                int minutes = (remainingTime - hours * 3600) / 60;
                int seconds = remainingTime - hours * 3600 - minutes * 60;
                
                if(hours>0)
                    [remainingTimeStr appendFormat:@"%d Hours ",hours];
                if(minutes>0)
                    [remainingTimeStr appendFormat:@"%d Min ",minutes];
                if(seconds>0)
                    [remainingTimeStr appendFormat:@"%d sec",seconds];
                
                NSString *fileSizeInUnits = [NSString stringWithFormat:@"%.2f %@",
                                             [SCUtilityManager calculateFileSizeInUnit:(unsigned long long)totalBytesExpectedToWrite],
                                             [SCUtilityManager calculateUnit:(unsigned long long)totalBytesExpectedToWrite]];
                
                NSMutableString *detailLabelText = [NSMutableString stringWithFormat:@"File Size: %@\nDownloaded: %.2f %@ (%.2f%%)\nSpeed: %.2f %@/sec\n",fileSizeInUnits,
                                                    [SCUtilityManager calculateFileSizeInUnit:(unsigned long long)totalBytesWritten],
                                                    [SCUtilityManager calculateUnit:(unsigned long long)totalBytesWritten],progress*100,
                                                    [SCUtilityManager calculateFileSizeInUnit:(unsigned long long) speed],
                                                    [SCUtilityManager calculateUnit:(unsigned long long)speed]
                                                    ];
                
                if(progress == 1.0)
                    [detailLabelText appendFormat:@"Time Left: Please wait..."];
                else
                    [detailLabelText appendFormat:@"Time Left: %@",remainingTimeStr];
                
                
                [downloadDict setObject:[NSString stringWithFormat:@"%f",progress] forKey:kMZDownloadKeyProgress];
                [downloadDict setObject:detailLabelText forKey:kMZDownloadKeyDetails];
            });
            break;
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    for(NSMutableDictionary *downloadInfo in self.downloadingArray)
    {
        if([[downloadInfo objectForKey:kMZDownloadKeyTask] isEqual:downloadTask])
        {
            NSString *fileName = [downloadInfo objectForKey:kMZDownloadKeyFileName];
            NSString *destinationPath = [fileDest stringByAppendingPathComponent:fileName];
            NSURL *fileURL = [NSURL fileURLWithPath:destinationPath];
            NSLog(@"directory Path = %@",destinationPath);
            
            if (location) {
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error];
                if (error)
                    [SCUtilityManager showAlertViewWithTitle:kAlertTitle msg:error.localizedDescription];
            }
            
            break;
        }
    }
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSInteger errorReasonNum = [[error.userInfo objectForKey:@"NSURLErrorBackgroundTaskCancelledReasonKey"] integerValue];
    
    if([error.userInfo objectForKey:@"NSURLErrorBackgroundTaskCancelledReasonKey"] &&
       (errorReasonNum == NSURLErrorCancelledReasonUserForceQuitApplication ||
        errorReasonNum == NSURLErrorCancelledReasonBackgroundUpdatesDisabled))
    {
        NSString *taskInfo = task.taskDescription;
        
        NSError *error = nil;
        NSData *taskDescription = [taskInfo dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *taskInfoDict = [[NSJSONSerialization JSONObjectWithData:taskDescription options:NSJSONReadingAllowFragments error:&error] mutableCopy];
        
        if(error)
            NSLog(@"Error while retreiving json value: %@",error);
        
        NSString *fileName = [taskInfoDict objectForKey:kMZDownloadKeyFileName];
        NSString *fileURL = [taskInfoDict objectForKey:kMZDownloadKeyURL];
        
        NSMutableDictionary *downloadInfo = [[NSMutableDictionary alloc] init];
        [downloadInfo setObject:fileName forKey:kMZDownloadKeyFileName];
        [downloadInfo setObject:fileURL forKey:kMZDownloadKeyURL];
        
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        if(resumeData)
            task = [self.sessionManager downloadTaskWithResumeData:resumeData];
        else
            task = [self.sessionManager downloadTaskWithURL:[NSURL URLWithString:fileURL]];
        [task setTaskDescription:taskInfo];
        
        [downloadInfo setObject:task forKey:kMZDownloadKeyTask];
        
        [self.downloadingArray addObject:downloadInfo];
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.bgDownloadTableView reloadData];
//            [self dismissAllActionSeets];
        });
        return;
    }
    for(NSMutableDictionary *downloadInfo in self.downloadingArray)
    {
        if([[downloadInfo objectForKey:kMZDownloadKeyTask] isEqual:task])
        {
            NSInteger indexOfObject = [self.downloadingArray indexOfObject:downloadInfo];
            
            if(error)
            {
                if(error.code != NSURLErrorCancelled)
                {
                    NSString *taskInfo = task.taskDescription;
                    
                    NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                    if(resumeData)
                        task = [self.sessionManager downloadTaskWithResumeData:resumeData];
                    else
                        task = [self.sessionManager downloadTaskWithURL:[NSURL URLWithString:[downloadInfo objectForKey:kMZDownloadKeyURL]]];
                    [task setTaskDescription:taskInfo];
                    
                    [downloadInfo setObject:RequestStatusFailed forKey:kMZDownloadKeyStatus];
                    [downloadInfo setObject:(NSURLSessionDownloadTask *)task forKey:kMZDownloadKeyTask];
                    
                    [self.downloadingArray replaceObjectAtIndex:indexOfObject withObject:downloadInfo];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SCUtilityManager showAlertViewWithTitle:kAlertTitle msg:error.localizedDescription];
//                        [self.bgDownloadTableView reloadData];
//                        [self dismissAllActionSeets];
                    });
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *fileName = [[downloadInfo objectForKey:kMZDownloadKeyFileName] copy];
                    
                    [self presentNotificationForDownload:[downloadInfo objectForKey:kMZDownloadKeyFileName]];
                    
                    [self.downloadingArray removeObjectAtIndex:indexOfObject];
                    
                    
                    if([self.delegate respondsToSelector:@selector(downloadRequestFinished:)])
                        [self.delegate downloadRequestFinished:fileName];
                    
                });
            }
            break;
        }
    }
}
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    
    NSLog(@"All tasks are finished");
}
#pragma mark - SCDownloadManagerDelegate Delegate -

@end
