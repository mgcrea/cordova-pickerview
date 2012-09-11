//
//  ActionSheet.h
//
// Created by Olivier Louvignes on 2011-11-28.
//
// Copyright 2011-2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface PickerView : CDVPlugin <UIActionSheetDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate> {
}

#pragma mark - Properties

@property (nonatomic, copy) NSString *callbackId;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) NSArray *items;

#pragma mark - Instance methods

- (void)create:(CDVInvokedUrlCommand*)command;

@end

#pragma mark - Logging tools

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
