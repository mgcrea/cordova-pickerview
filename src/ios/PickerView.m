//
//  PickerView.m
//
// Created by Olivier Louvignes on 2011-11-28
// Updated on 2012-08-04 for Cordova ARC-2.1+
//
// Copyright 2011-2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import "PickerView.h"
#import <Cordova/CDVDebug.h>

// Private interface
@interface PickerView()

@property (nonatomic, strong) UIPickerView *pickerView;

@end

@implementation PickerView

@synthesize callbackIds = _callbackIds;
@synthesize pickerView = _pickerView;
@synthesize actionSheet = _actionSheet;
@synthesize popoverController = _popoverController;
@synthesize items = _items;

- (NSMutableDictionary *)callbackIds {
	if(_callbackIds == nil) {
		_callbackIds = [[NSMutableDictionary alloc] init];
	}
	return _callbackIds;
}

- (int)getComponentWithName:(NSString * )name {
	for(int i = 0; i < [self.items count]; i++) {
        NSDictionary *slot = [self.items objectAtIndex:i];
		if([name isEqualToString:[slot objectForKey:@"name"]]) {
			return i;
		}
    }
	return -1;
}

- (int)getRowWithValue:(NSString *)value inComponent:(int)i {
	NSArray *slotData = [[self.items objectAtIndex:i] objectForKey:@"data"];
	for(int j = 0; j < [slotData count]; j++) {
		NSDictionary *slotDataItem = [slotData objectAtIndex:j];
		NSString *slotDataItemValue = [NSString stringWithFormat:@"%@", [slotDataItem objectForKey:@"value"]];
		if([slotDataItemValue isEqualToString:value]) {
			return j;
		}
	}
	return -1;
}

- (void)create:(CDVInvokedUrlCommand*)command {

	[self.callbackIds setValue:command.callbackId forKey:@"create"];
	NSDictionary *options = [command.arguments objectAtIndex:0];
	DLog(@"options:%@", options);

	// Compiling options with defaults
	NSString *title = [options objectForKey:@"title"] ?: @" ";
	NSString *style = [options objectForKey:@"style"] ?: @"default";
	NSString *doneButtonLabel = [options objectForKey:@"doneButtonLabel"] ?: @"Done";
	NSString *cancelButtonLabel = [options objectForKey:@"cancelButtonLabel"] ?: @"Cancel";

    // Hold slots items in an instance variable
	self.items = [options objectForKey:@"items"];

    // Initialize PickerView
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 40.0f, 320.0f, 162.0f)];
	self.pickerView.showsSelectionIndicator = YES;
	self.pickerView.delegate = self;

    // Loop through slots to define default value
    for(int i = 0; i < [self.items count]; i++) {
        NSDictionary *slot = [self.items objectAtIndex:i];
		if([slot objectForKey:@"value"]) {
			int j = [self getRowWithValue:[NSString stringWithFormat:@"%@", [slot objectForKey:@"value"]] inComponent:i];
			if(j != -1) [self.pickerView selectRow:j inComponent:i animated:NO];
		}
    }

	// Check if device is iPad as we won't be able to use an ActionSheet there
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		return [self createForIpad:command];
	}

	// Create actionSheet
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:title
												   delegate:self
										  cancelButtonTitle:nil
									 destructiveButtonTitle:nil
										  otherButtonTitles:nil];

	// Style actionSheet, defaults to UIActionSheetStyleDefault
	if([style isEqualToString:@"black-opaque"]) self.actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	else if([style isEqualToString:@"black-translucent"]) self.actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	else self.actionSheet.actionSheetStyle = UIActionSheetStyleDefault;

	// Append pickerView
	[self.actionSheet addSubview:self.pickerView];

	// Create segemented cancel button
	UISegmentedControl *cancelButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:cancelButtonLabel]];
	cancelButton.momentary = YES;
	cancelButton.frame = CGRectMake(5.0f, 7.0f, 50.0f, 30.0f);
	cancelButton.segmentedControlStyle = UISegmentedControlStyleBar;
	cancelButton.tintColor = [UIColor blackColor];
	[cancelButton addTarget:self action:@selector(segmentedControl:didDismissWithCancelButton:) forControlEvents:UIControlEventValueChanged];
	// Append close button
	[self.actionSheet addSubview:cancelButton];

	// Create segemented done button
	UISegmentedControl *doneButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:doneButtonLabel]];
	doneButton.momentary = YES;
	doneButton.frame = CGRectMake(265.0f, 7.0f, 50.0f, 30.0f);
	doneButton.segmentedControlStyle = UISegmentedControlStyleBar;
	doneButton.tintColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
	[doneButton addTarget:self action:@selector(segmentedControl:didDismissWithDoneButton:) forControlEvents:UIControlEventValueChanged];
	// Append done button
	[self.actionSheet addSubview:doneButton];

	//[actionSheet sendSubviewToBack:pickerView];

	// Toggle ActionSheet
    [self.actionSheet showInView:self.webView.superview];

	// Resize actionSheet was 360
	float actionSheetHeight;
	int systemMajorVersion = [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
	if(systemMajorVersion >= 5) {
		actionSheetHeight = 360.0f;
	} else {
		actionSheetHeight = 472.0f;
	}
	[self.actionSheet setBounds:CGRectMake(0, 0, 320.0f, actionSheetHeight)];

}

-(void)createForIpad:(CDVInvokedUrlCommand*)command {

	NSDictionary *options = [command.arguments objectAtIndex:0];

	NSArray *sourceRectArray = [options objectForKey:@"sourceRect"];
	CGRect sourceRect = CGRectNull;
	if(sourceRectArray != nil && sourceRectArray.count == 4) {
		sourceRect = CGRectFromString([NSString stringWithFormat: @"{{%f,%f},{%f,%f}}", [(NSNumber *)[sourceRectArray objectAtIndex:0] floatValue], [(NSNumber *)[sourceRectArray objectAtIndex:1] floatValue], [(NSNumber *)[sourceRectArray objectAtIndex:2] floatValue], [(NSNumber *)[sourceRectArray objectAtIndex:3] floatValue]]);
	}
	
	// Support UIPopoverArrowDirection
	NSString *arrowDirection = [options objectForKey:@"arrowDirection"] ?: @"any";
	int permittedArrowDirections = UIPopoverArrowDirectionAny;
	if([arrowDirection isEqualToString:@"up"]) {
		permittedArrowDirections = UIPopoverArrowDirectionUp;
	} else if([arrowDirection isEqualToString:@"right"]) {
		permittedArrowDirections = UIPopoverArrowDirectionRight;
	} else if([arrowDirection isEqualToString:@"down"]) {
		permittedArrowDirections = UIPopoverArrowDirectionDown;
	} else if([arrowDirection isEqualToString:@"left"]) {
		permittedArrowDirections = UIPopoverArrowDirectionLeft;
	}
	
	NSString *doneButtonLabel = [options objectForKey:@"doneButtonLabel"] ?: @"Done";
	//NSString *cancelButtonLabel = [options objectForKey:@"cancelButtonLabel"] ?: @"Cancel";

	// Create a generic content view controller
	UINavigationController* popoverContent = [[UINavigationController alloc] init];
	// Create a generic container view
	UIView* popoverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 162.0f)];
	popoverContent.view = popoverView;

	// Append pickerView
	[popoverView addSubview:self.pickerView];

	/*
	 UIBarButtonItem *okButton = [[UIBarButtonItem alloc] initWithTitle:@"Ok" style:UIBarButtonItemStyleBordered target:self action:@selector(okayButtonPressed)];
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed)];

	[popoverContent.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
	[popoverContent.navigationItem setRightBarButtonItem:okButton animated:NO];
	 popoverContent.topViewController.navigationItem.title = @"MY TITLE!";
	 popoverContent.navigationItem.title = @"MY TITLE!";
	 */

	// Create segemented cancel button ~ not working on the iPad!
	/*UISegmentedControl *cancelButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:cancelButtonLabel]];
	cancelButton.momentary = YES;
	cancelButton.frame = CGRectMake(5.0f, 7.0f, 50.0f, 30.0f);
	cancelButton.segmentedControlStyle = UISegmentedControlStyleBar;
	cancelButton.tintColor = [UIColor blackColor];
	[cancelButton addTarget:self action:@selector(segmentedControl:didDismissWithCancelButton:) forControlEvents:UIControlEventValueChanged];
	// Append close button
	[popoverView addSubview:cancelButton];*/

	// Create segemented done button
	UISegmentedControl *doneButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:doneButtonLabel]];
	doneButton.momentary = YES;
	doneButton.frame = CGRectMake(265.0f, 7.0f, 50.0f, 30.0f);
	doneButton.segmentedControlStyle = UISegmentedControlStyleBar;
	doneButton.tintColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
	[doneButton addTarget:self action:@selector(segmentedControl:didDismissWithDoneButton:) forControlEvents:UIControlEventValueChanged];
	// Append done button
	[popoverView addSubview:doneButton];

	// Resize the popover view shown
	// in the current view to the view's size
	popoverContent.contentSizeForViewInPopover = CGSizeMake(320.0f, 162.0f);

	// Create a popover controller
	self.popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
	self.popoverController.delegate = self;

	
	UIDeviceOrientation curDevOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	if(UIDeviceOrientationIsLandscape(curDevOrientation)) {
		// 1024-20 / 2 & 768 - 10
		if(CGRectIsNull(sourceRect)) sourceRect = CGRectMake(502.0f, 758.0f, 20.0f, 20.0f);
	} else {
		if(CGRectIsNull(sourceRect)) sourceRect = CGRectMake(374.0f, 1014.0f, 20.0f, 20.0f);
	}

	//present the popover view non-modal with a
	//refrence to the button pressed within the current view
	[self.popoverController presentPopoverFromRect:sourceRect
									   inView:self.webView.superview
					 permittedArrowDirections:permittedArrowDirections
									 animated:YES];

}

- (void)setValue:(CDVInvokedUrlCommand*)command
{

	if(self.pickerView == nil) return;

	[self.callbackIds setValue:command.callbackId forKey:@"setValue"];
	NSDictionary *values = [command.arguments objectAtIndex:0];
	NSDictionary *options = [command.arguments objectAtIndex:1];
	bool animated = [options objectForKey:@"animated"] ? !![[options objectForKey:@"animated"] integerValue] : YES;
	DLog(@"values:%@\noptions:%@", values, options);

	for (id key in values) {
		NSString *value = [NSString stringWithFormat:@"%@", [values objectForKey:key]];
		int i = [self getComponentWithName:key];
		int j = [self getRowWithValue:value inComponent:i];
		[self.pickerView selectRow:j inComponent:i animated:animated];
	}

	// Create Plugin Result
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
	[self writeJavascript: [pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"setValue"]]];

}

//
// Dismiss methods
//

// Picker with segmentedControls dismissed with done
- (void)segmentedControl:(UISegmentedControl *)segmentedControl didDismissWithDoneButton:(NSInteger)buttonIndex
{
	//NSLog(@"didDismissWithDoneButton:%d", buttonIndex);

	// Check if device is iPad
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		// Emulate a new delegate method
		[self popoverController:self.popoverController dismissWithClickedButtonIndex:1 animated:YES];
	} else {
		[self.actionSheet dismissWithClickedButtonIndex:1 animated:YES];
	}
}

// Picker with segmentedControls dismissed with cancel
- (void)segmentedControl:(UISegmentedControl *)segmentedControl didDismissWithCancelButton:(NSInteger)buttonIndex
{
	DLog(@"didDismissWithCancelButton:%d", buttonIndex);

	// Check if device is iPad
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		// Emulate a new delegate method
		[self popoverController:self.popoverController dismissWithClickedButtonIndex:0 animated:YES];
	} else {
		[self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	}
}

// Popover generic dismiss - iPad
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	DLog(@"popoverControllerDidDismissPopover");

	// Retreive pickerView
	NSArray *subviews = [self.popoverController.contentViewController.view subviews];
	UIPickerView *pickerView = [subviews objectAtIndex:0];
	// Simulate a cancel click
	[self sendResultsFromPickerView:pickerView withButtonIndex:0];
}

// Popover emulated button-powered dismiss - iPad
- (void)popoverController:(UIPopoverController *)popoverController dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(Boolean)animated
{
	DLog(@"didDismissPopoverWithButtonIndex:%d", buttonIndex);

	// Manually dismiss the popover
	[self.popoverController dismissPopoverAnimated:animated];
	// Retreive pickerView
	NSArray *subviews = [self.popoverController.contentViewController.view subviews];
	UIPickerView *pickerView = [subviews objectAtIndex:0];
	[self sendResultsFromPickerView:pickerView withButtonIndex:buttonIndex];
}

// ActionSheet generic dismiss - iPhone
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	DLog(@"didDismissWithButtonIndex:%d", buttonIndex);

	// Retreive pickerView
  NSArray *subviews = [self.actionSheet subviews];

  int pickerPosition;

  if (systemMajorVersion == 7){
    pickerPosition = 2;
  }else{
    pickerPosition = 1;
  }

  UIPickerView *pickerView = [subviews objectAtIndex:pickerPosition];
	[self sendResultsFromPickerView:pickerView withButtonIndex:buttonIndex];
}

//
// Results
//

- (void)sendResultsFromPickerView:(UIPickerView *)pickerView withButtonIndex:(NSInteger)buttonIndex {

	// Build returned result
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *values = [[NSMutableDictionary alloc] init];

	// Loop throught slots
	for(int i = 0; i < [self.items count]; i++) {
		NSInteger selectedRow = [pickerView selectedRowInComponent:i];
		NSString *selectedValue = [[[[self.items objectAtIndex:i] objectForKey:@"data"] objectAtIndex:selectedRow] objectForKey:@"value"];
		NSString *slotName = [[self.items objectAtIndex:i] objectForKey:@"name"] ?: [NSString stringWithFormat:@"%d", i];
		[values setObject:selectedValue forKey:slotName];
	}

	[result setObject:[NSNumber numberWithInteger:buttonIndex] forKey:@"buttonIndex"];
	[result setObject:values forKey:@"values"];

	// Create Plugin Result
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];

	// Checking if cancel was clicked
	if (buttonIndex == 0) {
		//Call  the Failure Javascript function
		[self writeJavascript: [pluginResult toErrorCallbackString:[self.callbackIds valueForKey:@"create"]]];
	}else {
		//Call  the Success Javascript function
		[self writeJavascript: [pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"create"]]];
	}

}

//
// Picker delegate
//


// Listen picker selected row
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	//NSLog(@"didSelectRow %d", row);
}

// Tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [[[self.items objectAtIndex:component] objectForKey:@"data"] count];
}

// Tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return [self.items count];
}

// Tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	//NSLog(@"%d:%d", component, row);
	return [[[[self.items objectAtIndex:component] objectForKey:@"data"] objectAtIndex:row] objectForKey:@"text"];
}

// Tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	if([[self.items objectAtIndex:component] objectForKey:@"width"]) {
		return [[[self.items objectAtIndex:component] objectForKey:@"width"] floatValue];
	}
	return 300.0f/[self.items count];
}

@end
