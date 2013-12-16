/*
 * (C) Copyright Itude Mobile B.V., The Netherlands.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MBApplicationController.h"
#import "MBAlertController.h"
#import "MBDocument.h"
#import "MBAction.h"
#import "MBPage.h"
#import "MBPageStackController.h"
#import "MBMetadataService.h"
#import "MBDataManagerService.h"
#import "MBTableViewController.h"
#import "MBOutcome.h"
#import "MBDialogController.h"
#import "MBViewManager.h"
#import "MBScriptService.h"
#import "UncaughtExceptionHandler.h"
#import "GTMStackTrace.h"
#import "MBMacros.h"
#import "MBLocalizationService.h"
#import "StringUtilitiesHelper.h"
#import "MBDevice.h"
#import "MBViewBuilderFactory.h"
#import "MBOutcomeListenerProtocol.h"
#import "MBOutcomeManager.h"

static MBApplicationController *_instance = nil;

@interface MBApplicationController()

@property (nonatomic, retain) MBOutcomeManager *outcomeManager;
- (void) handleException:(NSException*) exception outcome:(MBOutcome*) outcome;
- (void) fireInitialOutcomes;
@end

@implementation MBApplicationController

@synthesize applicationActive = _applicationActive;
@synthesize viewManager = _viewManager;
@synthesize applicationFactory = _applicationFactory;

- (id) init
{
	self = [super init];
	if (self != nil) {
        _instance = self;
		_outcomeManager = [[MBOutcomeManager alloc] init];
		// Added for optimization: Make sure the MBDevice is created at startup. The createInstance method instantiate variables that only need to be gathered once in the application lifecycle
		[MBDevice createInstance];
	}
	return self;
}

- (MBViewManager *)viewManager {
    if (!_viewManager) {
        _viewManager = [[MBViewManager alloc] init];
    }
    return _viewManager;
}

-(void) dealloc {
	[_outcomeManager release];
    [_alertController release];
	[_applicationFactory release];
    [_viewManager release];
	[super dealloc];
}

+(MBApplicationController *) currentInstance {
	return _instance;
}

-(void) startApplication:(MBApplicationFactory *)applicationFactory {
	DLog(@"MBApplicationController:startApplication");
	
    _alertController = [[MBAlertController alloc] init];
    self.applicationFactory = applicationFactory;
	_viewManager = [[MBViewManager alloc] init];

	// Added for optimization: Make sure the stringUtilitiesHelper is created. The createInstance methods instantiate variables that only need to be gathered once in the application lifecycle
	[StringUtilitiesHelper createInstance]; // Added for optimization
    
    [self fireInitialOutcomes];
}

-(void) resetController {
	[UIView beginAnimations:@"resetController" context:nil];
	[_viewManager resetView];
	[self fireInitialOutcomes];
    [UIView commitAnimations];
}

-(void) resetControllerPreservingCurrentPageStack {
	[_viewManager resetViewPreservingCurrentPageStack];
}


-(void) fireInitialOutcomes {
	dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	MBOutcome *initialOutcome = [[MBOutcome alloc]init];
    initialOutcome.originName = @"Controller";
    initialOutcome.outcomeName = @"init";
    initialOutcome.pageStackName = [self activePageStackName];
	initialOutcome.noBackgroundProcessing = TRUE;
    
	_suppressPageSelection = TRUE;
    [self handleOutcome:initialOutcome];
	_suppressPageSelection = FALSE;
    
    [initialOutcome release];
	});
}

-(void)handleOutcome:(MBOutcome *)outcome {
	[self.outcomeManager handleOutcome:outcome];
}


//////// END OF ACTION HANDLING

- (NSString*) activePageStackName {
	NSString *result = nil;
	if(_viewManager != nil) {
	  	result = _viewManager.dialogManager.activePageStackName;
	}
	return result;
}

// Returns nil if the current ActiveDialog is not nested inside a DialogGroup.
- (NSString *) activeDialogName {
	NSString *result = nil;
	if (_viewManager != nil) {
		
		result = _viewManager.dialogManager.activeDialogName;
	}
	return result;
}

-(void) activatePageStackWithName:(NSString*) name {
	[_viewManager.dialogManager activatePageStackWithName: name];
}

-(void) showActivityIndicator {
	[_viewManager showActivityIndicator];
}

-(void) showActivityIndicatorWithMessage:(NSString*) message {
	[_viewManager showActivityIndicatorWithMessage:message];
}

-(void) hideActivityIndicator {
	[_viewManager hideActivityIndicator];
}

- (NSArray *)getStack:(NSException*) exception
{
	NSMutableArray *result = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString: GTMStackTraceFromException(exception)];
	NSString *line;
	
	while([scanner scanUpToString:@"\n" intoString:&line] || ![scanner isAtEnd]) [result addObject: line];
	return result;
}

-(void) handleExceptionAfterDelay:(NSArray *)args {
	NSException *exception = [args objectAtIndex:0];
	MBOutcome *outcome = [args objectAtIndex:1];
	[self handleException:exception outcome:outcome];
}

- (void) handleException:(NSException*) exception outcome:(MBOutcome*) outcome {
	
	WLog(@"________EXCEPTION RAISED______________________________________________________________");
	WLog(@"%@: %@", exception.name, exception.reason);
	NSArray *trace = [self getStack:exception];
	if(trace != nil) for(id t in trace) WLog(@"%@", t);
	WLog(@"______________________________________________________________________________________");
    
	MBDocument *exceptionDocument = [[MBDataManagerService sharedInstance] loadDocument: DOC_SYSTEM_EXCEPTION];
	[exceptionDocument setValue: MBLocalizedString(exception.name) forPath: PATH_SYSTEM_EXCEPTION_NAME];
	[exceptionDocument setValue: MBLocalizedString(exception.reason) forPath: PATH_SYSTEM_EXCEPTION_DESCRIPTION];
	[exceptionDocument setValue: outcome.originName forPath: PATH_SYSTEM_EXCEPTION_ORIGIN];
	[exceptionDocument setValue: outcome.outcomeName forPath: PATH_SYSTEM_EXCEPTION_OUTCOME];
	[exceptionDocument setValue: [[exception class] description] forPath: PATH_SYSTEM_EXCEPTION_TYPE];
	for(NSString *line in trace) {
		MBElement *stackline = [exceptionDocument createElementWithName:@"/Exception[0]/Stackline"];
		if([line length] > 52) line = [line substringFromIndex:52];
		[stackline setValue:line forPath:@"@line"];
	}
	
	[[MBDataManagerService sharedInstance] storeDocument: exceptionDocument];
    
	MBMetadataService *metadataService = [MBMetadataService sharedInstance];
	
	// We are not sure at this moment if the activity indicator is shown. But to be sure; try to hide it.
	// This might mess up the count of the activity indicators if more than one page is being constructed in the background;
	// however most of the times this will work out; so:
	[_viewManager hideActivityIndicator];
    
	// See if there is an outcome defined for this particular exception
	NSArray *outcomeDefinitions = [metadataService outcomeDefinitionsForOrigin:outcome.originName outcomeName:[exception name] throwIfInvalid:FALSE];
    if([outcomeDefinitions count] != 0) {
		MBOutcome *specificExceptionHandler = [[[MBOutcome alloc] initWithOutcome:outcome] autorelease];
		specificExceptionHandler.outcomeName = [exception name];
		specificExceptionHandler.document = exceptionDocument;
		[self handleOutcome: specificExceptionHandler];
	}
	else {
		// There is no specific exception handler defined. So fall back on the generic one
		NSArray *outcomeDefinitions = [metadataService outcomeDefinitionsForOrigin:outcome.originName outcomeName:@"exception" throwIfInvalid:FALSE];
		if([outcomeDefinitions count] == 0) {
			WLog(@"No outcome with origin=%@ name=exception defined to handle errors; so re-throwing exception", outcome.originName);
			@throw [exception retain];
		}
		if([outcome.outcomeName isEqualToString: @"exception"]) {
			WLog(@"Error in handling an outcome with name=exception (i.e. the error handling in the controller is probably misconfigured) Re-throwing exception");
			@throw [exception retain];
		}
		
		MBOutcome *genericExceptionHandler = [[[MBOutcome alloc] initWithOutcomeName:@"exception" document: exceptionDocument] autorelease];
		genericExceptionHandler.pageStackName = outcome.pageStackName;
		genericExceptionHandler.path = outcome.path;
		
		[self.outcomeManager handleOutcome: genericExceptionHandler];
	}
}


#pragma mark -
#pragma mark Private Setters and Getters

- (void)setApplicationFactory:(MBApplicationFactory *)applicationFactory {
    if (_applicationFactory != applicationFactory) {
        [_applicationFactory release];
        _applicationFactory = applicationFactory;
        [applicationFactory retain];
    }
}


@end
