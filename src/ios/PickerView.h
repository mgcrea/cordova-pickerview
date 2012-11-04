//
//  PickerView.h
//
// Created by Olivier Louvignes on 2011-11-28
// Updated on 2012-08-04 for Cordova ARC-2.1+
//
// Copyright 2011-2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface PickerView : CDVPlugin <UIActionSheetDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate> {
}

#pragma mark - Properties

@property (nonatomic, retain) NSMutableDictionary *callbackIds;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) NSArray *items;

#pragma mark - Instance methods

- (void)create:(CDVInvokedUrlCommand*)command;
- (void)setValue:(CDVInvokedUrlCommand*)command;

@end
