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

//  MBOutcomeManager.m
//  mobbl-core-lib
//  Created by Pjotter Tommassen on 2013/29/11.

#import "MBOutcomeManager.h"
#import "MBApplicationController.h"
#import "MBOutcomeListenerProtocol.h"
#import "MBOutcome.h"
#import "MBMetadataService.h"
#import "MBDataManagerService.h"
#import "MBViewManager.h"
#import "MBViewBuilderFactory.h"
#import "MBPage.h"
#import "MBAlertController.h"
#import <CoreFoundation/CoreFoundation.h>


#ifdef DEBUG
#define THREAD_DUMP(n) CFAbsoluteTime time = CFAbsoluteTimeGetCurrent (); const char *method = n; NSLog(@"Method: %s Thread: %s Queue: %s", n, [[NSThread currentThread] isMainThread] ? "main" : "other", dispatch_queue_get_label (dispatch_get_current_queue ()));

#define THREAD_RELEASE NSLog (@"Leaving %s Time: %f", method, (CFAbsoluteTimeGetCurrent () - time));
#else
#define THREAD_DUMP(n)
#define THREAD_RELEASE
#endif


@interface MBOutcomeManager ()
@property (nonatomic, retain) NSMutableArray *outcomeListeners;
@property (nonatomic, assign, readonly) dispatch_queue_t queue;

@end

@implementation MBOutcomeManager


- (id) init
{
	self = [super init];
	if (self != nil) {
		_outcomeListeners = [[NSMutableArray array] retain];
		_queue = dispatch_queue_create("com.itude.mobbl.OutcomeQueue", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}


-(void) dealloc {
	dispatch_release(_queue);
	[_outcomeListeners release];
	[super dealloc];
}



-(void) handleOutcome:(MBOutcome *)outcome {
	THREAD_DUMP("handleOutcome")

	@try {
		[self doHandleOutcome: outcome];
	}
	@catch (NSException *e) {
		[[MBApplicationController currentInstance] handleException: e outcome: outcome];
	};

	THREAD_RELEASE
}

void runOnMain(void (^block)(void)) {
	if ([NSThread isMainThread])
		block ();
	else dispatch_sync(dispatch_get_main_queue(), block);
}

- (void) doHandleOutcome:(MBOutcome *)outcome {
	THREAD_DUMP("doHandleOutcome");
	NSLog(@"MBApplicationController:handleOutcome: %@", outcome);

	// notify all outcome listeners
	for(id<MBOutcomeListenerProtocol> lsnr in self.outcomeListeners) {
		if ([lsnr respondsToSelector:@selector(outcomeProduced:)])
			[lsnr outcomeProduced:outcome];
	}

	// Make sure that the (external) document cache of the document itself is cleared since this
	// might interfere with the preconditions that are evaluated later on. Also: if the document is transferred
	// the next page / action will also have fresh copies
	[outcome.document clearAllCaches];

	MBMetadataService *metadataService = [MBMetadataService sharedInstance];

	NSArray *outcomeDefinitions = [metadataService outcomeDefinitionsForOrigin:outcome.originName outcomeName:outcome.outcomeName throwIfInvalid:FALSE];
    if([outcomeDefinitions count] == 0) {
        NSString *msg = [NSString stringWithFormat:@"No outcome defined for origin=%@ outcome=%@", outcome.originName, outcome.outcomeName];
        @throw [NSException exceptionWithName:@"NoOutcomesDefined" reason:msg userInfo:nil];
    }

    BOOL shouldPersist = FALSE;
    for(MBOutcomeDefinition *outcomeDef in outcomeDefinitions) {
        shouldPersist |= outcomeDef.persist;
    }

    if(shouldPersist) {
		if([outcome document] == nil) {
			NSLog(@"WARNING: origin=%@ and name=%@ has persistDocument=TRUE but there is no document (probably the outcome originates from an action; which cannot have a document)", outcome.originName, outcome.outcomeName);
		}
		else [[MBDataManagerService sharedInstance] storeDocument: outcome.document];
	}

    NSMutableArray *pageStacks = [NSMutableArray array];

	// We need to make sure that the order of the dialog tabs conforms to the order of the outcomes
	// This is not necessarily the case because preparing of page A might take longer in the background than page B
	// Because of this, page B migh be places on a tab prior to page A which is undesired. We handle this by
	// notifying the view handler of the dialogs used by the outcome in sequental order. The viewmanager will then
	// use this information to sort the tabs

    for(MBOutcomeDefinition *outcomeDef in outcomeDefinitions) {

		if([@"RESET_CONTROLLER" isEqualToString:outcomeDef.action]) {
			[[MBApplicationController currentInstance] resetController];
		}
		else {

			// Create a working copy of the outcome; we manipulate the outcome below and we want the passed outcome to be left unchanged (good practise)
			MBOutcome *outcomeToProcess = [[[MBOutcome alloc] initWithOutcomeDefinition: outcomeDef] autorelease];

			outcomeToProcess.path = outcome.path;
			outcomeToProcess.document = outcome.document;
            if (outcomeToProcess.pageStackName.length == 0) outcomeToProcess.pageStackName = outcome.pageStackName;
            if (outcomeToProcess.pageStackName.length == 0) outcomeToProcess.pageStackName = outcome.originPageStackName;
			if (outcome.displayMode != nil) outcomeToProcess.displayMode = outcome.displayMode;
			outcomeToProcess.noBackgroundProcessing = outcome.noBackgroundProcessing || outcomeDef.noBackgroundProcessing;


			void (^actuallyProcessOutcome)(void) = ^{
				if([outcomeToProcess isPreConditionValid]) {

					// Update a possible switch of pageStack/display mode set by the outcome definition
					if(outcomeDef.pageStackName != nil) outcomeToProcess.pageStackName = outcomeDef.pageStackName;
					if(outcomeToProcess.displayMode.length == 0) outcomeToProcess.displayMode = outcomeDef.displayMode;
					if(outcomeToProcess.originPageStackName == nil) outcomeToProcess.originPageStackName = outcomeToProcess.pageStackName;

					if(outcomeToProcess.pageStackName != nil) [pageStacks addObject: outcomeToProcess.pageStackName];

					runOnMain(^{
						if([@"ENDMODAL" isEqualToString: outcomeToProcess.displayMode]) {
							MBDialogController *dialog = [[MBApplicationController currentInstance].viewManager.dialogManager dialogForPageStackName:outcomeToProcess.pageStackName];
							[[[MBViewBuilderFactory sharedInstance] dialogDecoratorFactory] dismissDialog:dialog withTransitionStyle:outcomeToProcess.transitionStyle];
						}

						else if([@"POP" isEqualToString: outcomeToProcess.displayMode]) {
							// TODO: This causes a bug when the user desides to pop the rootViewController
							[[MBApplicationController currentInstance].viewManager.dialogManager popPageOnPageStackWithName: outcomeToProcess.pageStackName];
						}
						else if([@"POPALL" isEqualToString: outcomeToProcess.displayMode]) {
							[[MBApplicationController currentInstance].viewManager.dialogManager endPageStackWithName: outcomeToProcess.pageStackName keepPosition:TRUE];
						}
						else if([@"CLEAR" isEqualToString: outcomeToProcess.displayMode]) {
							[[MBApplicationController currentInstance].viewManager resetView];
						}
						else if([@"END" isEqualToString: outcomeToProcess.displayMode]) {
							[[MBApplicationController currentInstance].viewManager.dialogManager endPageStackWithName: outcomeToProcess.pageStackName keepPosition: FALSE];
							[pageStacks removeObject:outcomeToProcess.pageStackName];
						}
					});


					// Action
					MBActionDefinition *actionDef = [metadataService definitionForActionName:outcomeDef.action throwIfInvalid: FALSE];
					if(actionDef != nil) {
						if(!outcomeToProcess.noBackgroundProcessing)
							[[MBApplicationController currentInstance].viewManager showActivityIndicatorWithMessage:outcomeToProcess.processingMessage];

							[self performActionInBackground:[NSArray arrayWithObjects:[[[MBOutcome alloc] initWithOutcome:outcomeToProcess] autorelease], actionDef,  nil]];
					}

					// Page
					MBPageDefinition *pageDef = [metadataService definitionForPageName:outcomeDef.action throwIfInvalid: FALSE];
					if(pageDef != nil) {
						if(!outcomeToProcess.noBackgroundProcessing)
							[[MBApplicationController currentInstance].viewManager showActivityIndicatorWithMessage:outcomeToProcess.processingMessage];

						[self preparePageInBackground:@[[[[MBOutcome alloc] initWithOutcome:outcomeToProcess]autorelease], pageDef.name]];
					}

					// Alert
					MBAlertDefinition *alertDef = [metadataService definitionForAlertName:outcomeDef.action throwIfInvalid:FALSE];
					if (alertDef != nil) {
						[[MBApplicationController currentInstance].alertController handleAlert:alertDef forOutcome:outcomeToProcess];
					}

					if(actionDef == nil && pageDef == nil && alertDef == nil && ![outcomeDef.action isEqualToString:@"none"]) {
						NSString *msg = [NSString stringWithFormat:@"Invalid outcome; no action or page with name %@ defined. See outcome origin=%@ action=%@. Check \n%@", outcomeDef.action, outcomeDef.origin, outcomeDef.name, [outcomeDef asXmlWithLevel:5]];
						@throw [NSException exceptionWithName:@"InvalidOutcome" reason:msg userInfo:nil];
					}
				}
			};

			if ( outcomeToProcess.noBackgroundProcessing) {
				if (dispatch_get_current_queue() == self.queue) actuallyProcessOutcome();
				else dispatch_sync(self.queue, actuallyProcessOutcome);
			} else {
				dispatch_async(self.queue, actuallyProcessOutcome);
			}
		}
	}

	dispatch_async(self.queue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			// notify all outcome listeners
			for(id<MBOutcomeListenerProtocol> lsnr in self.outcomeListeners) {
				if ([lsnr respondsToSelector:@selector(outcomeHandled:)])
					[lsnr outcomeHandled:outcome];
			}
		});
	});
	THREAD_RELEASE
}



//////// PAGE HANDLING

- (void)preparePageInBackground:(NSArray*)args {
	THREAD_DUMP("preparePageInBackground")

    MBOutcome *causingOutcome = [args objectAtIndex:0];
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
    @try {

        NSString *pageName = [args objectAtIndex:1];

        // construct the page
        MBPageDefinition *pageDefinition = [[MBMetadataService sharedInstance] definitionForPageName:pageName];

		// Load the document from the store
		MBDocument *document = nil;

		if(causingOutcome.transferDocument) {
			if(causingOutcome.document == nil)  {
				NSString *msg = [NSString stringWithFormat:@"No document provided (nil) in outcome '%@' by action/page '%@' but transferDocument='TRUE' in outcome definition",causingOutcome.outcomeName , causingOutcome.originName];
				@throw [NSException exceptionWithName:@"InvalidOutcome" reason:msg userInfo:nil];
			}
			NSString *actualType =  [[causingOutcome.document definition] name];
			if(![actualType isEqualToString: [pageDefinition documentName]]) {
				NSString *msg = [NSString stringWithFormat:@"Document provided via outcome by action/page=%@ (transferDocument='TRUE') is of type %@ but must be of type %@",
								 causingOutcome.originName, actualType, [pageDefinition documentName]];
				@throw [NSException exceptionWithName:@"InvalidOutcome" reason:msg userInfo:nil];
			}
			document = causingOutcome.document;
		}
		else {
			document = [[MBDataManagerService sharedInstance] loadDocument:[pageDefinition documentName]];

			if(document == nil) {
				document = [[MBDataManagerService sharedInstance] loadDocument:[pageDefinition documentName]];
				NSString *msg = [NSString stringWithFormat:@"Document with name %@ not found (check filesystem/webservice)", [pageDefinition documentName]];
				@throw [NSException exceptionWithName:@"NoDocument" reason:msg userInfo:nil];
			}
		}

		[self showResultingPage:@[causingOutcome, pageDefinition, document]    ];
	}
    @catch (NSException *e) {
        [[MBApplicationController currentInstance] handleException: e outcome: causingOutcome];
    }
    @finally {
        [pool release];
		THREAD_RELEASE
    }
}

- (void)showResultingPage:(NSArray*)args {
	THREAD_DUMP("showResultingPage")

    MBOutcome *causingOutcome = [args objectAtIndex:0];
    @try {
        [[MBApplicationController currentInstance].viewManager hideActivityIndicator];
        NSString *displayMode = causingOutcome.displayMode;
        NSString *transitionStyle = causingOutcome.transitionStyle;
		MBViewState viewState = [[MBApplicationController currentInstance].viewManager currentViewState];

		if([displayMode isEqualToString:@"MODAL"] ||
		   [displayMode isEqualToString:@"MODALFORMSHEET"] ||
		   [displayMode isEqualToString:@"MODALFORMSHEETWITHCLOSEBUTTON"] ||
		   [displayMode isEqualToString:@"MODALPAGESHEET" ] ||
		   [displayMode isEqualToString:@"MODALFULLSCREEN"] ||
		   [displayMode isEqualToString:@"MODALCURRENTCONTEXT"] ){
			viewState = MBViewStateModal;
		}

		runOnMain(^{
			THREAD_DUMP("showResultingPage (inner block)")
			MBPageDefinition *pageDefinition = [args objectAtIndex:1];
			MBDocument *document = [args objectAtIndex:2];
			CGRect bounds = [MBApplicationController currentInstance].viewManager.bounds;

			MBPage *page = [[MBApplicationController currentInstance].applicationFactory createPage:pageDefinition
												  document: document
												  rootPath: causingOutcome.path
												 viewState: viewState
											 withMaxBounds: bounds];
			page.applicationController = [MBApplicationController currentInstance];
			page.pageStackName = causingOutcome.pageStackName;

	        [[MBApplicationController currentInstance].viewManager showPage: page displayMode: displayMode transitionStyle: transitionStyle];
			THREAD_RELEASE
		});
    }
    @catch (NSException *e) {
        [[MBApplicationController currentInstance] handleException: e outcome: causingOutcome];
    }
	THREAD_RELEASE
}

//////// END OF PAGE HANDLING

//////// ACTION HANDLING

- (void) performActionInBackground:(NSArray *)args {
	THREAD_DUMP("performActionInBackground")

    MBOutcome *causingOutcome = [args objectAtIndex:0];

	@autoreleasepool {
		@try {

			MBActionDefinition *actionDef = [args objectAtIndex:1];
			id<MBAction> action = [[MBApplicationController currentInstance].applicationFactory createAction: actionDef.className];
			MBOutcome *actionOutcome = [action execute: causingOutcome.document withPath:causingOutcome.path];

			if(actionOutcome == nil) {
				[[MBApplicationController currentInstance].viewManager hideActivityIndicator];
				NSLog(@"No outcome produced by action %@ (outcome == nil); no further procesing.", actionDef.name);
			}
			else {
				[self handleActionResult:[NSArray arrayWithObjects:causingOutcome, actionDef, actionOutcome, nil]];
			}
		}
		@catch (NSException *e) {
			[[MBApplicationController currentInstance] handleException: e outcome: causingOutcome];
		}
	}
	THREAD_RELEASE
}

- (void) handleActionResult:(NSArray *)args {
	THREAD_DUMP("handleActionResult")

    MBOutcome *causingOutcome = [args objectAtIndex:0];

    @try {
		[[MBApplicationController currentInstance].viewManager hideActivityIndicator];

        MBActionDefinition *actionDef = [args objectAtIndex:1];
        MBOutcome *actionOutcome = [args objectAtIndex:2];

        if(actionOutcome.pageStackName == nil) actionOutcome.pageStackName = causingOutcome.pageStackName;
        actionOutcome.originName = actionDef.name;

        [self handleOutcome:actionOutcome];
    }
    @catch (NSException *e) {
        [[MBApplicationController currentInstance] handleException: e outcome: causingOutcome];
    }
	THREAD_RELEASE
}



#pragma mark -
#pragma mark Outcome listeners

- (void) registerOutcomeListener:(id<MBOutcomeListenerProtocol>) listener {
	if(![self.outcomeListeners containsObject:listener]) [self.outcomeListeners addObject:listener];
}

- (void) unregisterOutcomeListener:(id<MBOutcomeListenerProtocol>) listener {
	[self.outcomeListeners removeObject: listener];
}


@end