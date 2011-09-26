//
//  MBDataManager.m
//  Core
//
//  Created by Wido on 5/20/10.
//  Copyright 2010 Itude. All rights reserved.
//

#import "MBDataManagerService.h"
#import "MBMetadataService.h"
#import "MBRESTServiceDataHandler.h"
#import "MBMemoryDataHandler.h"
#import "MBFileDataHandler.h"
#import "MBMobbl1ServerDataHandler.h"
#import "MBDocumentOperation.h"
#import "MBSystemDataHandler.h"

static MBDataManagerService *_instance = nil;

@interface MBDataManagerService()
- (MBDataHandlerBase *) handlerForDocument:(NSString *)documentName;

@end


@implementation MBDataManagerService

+ (MBDataManagerService *) sharedInstance {
	@synchronized(self) {
		if(_instance == nil) {
			_instance = [[self alloc] init];
		}
	}
	return _instance;
}

- (id) init {
	if (self = [super init])
	{
		_operationQueue = [[NSOperationQueue alloc] init]; 
		[_operationQueue setMaxConcurrentOperationCount: MAX_CONCURRENT_OPERATIONS];
		
    	_registeredHandlers = [NSMutableDictionary new];
        [self registerDataHandler:[[MBFileDataHandler new] autorelease] withName: DATA_HANDLER_FILE];
        [self registerDataHandler:[[MBSystemDataHandler new] autorelease] withName: DATA_HANDLER_SYSTEM];
        [self registerDataHandler:[[MBMemoryDataHandler new] autorelease] withName: DATA_HANDLER_MEMORY];
        [self registerDataHandler:[[MBRESTServiceDataHandler new] autorelease] withName: DATA_HANDLER_WS_REST];
		[self registerDataHandler:[[MBMobbl1ServerDataHandler new] autorelease] withName: DATA_HANDLER_WS_MOBBL];	
	}
	return self;
}

- (void) dealloc {
	[_operationQueue release];
	[_registeredHandlers release];
	[super dealloc];
}

- (MBDocumentOperation*) loaderForDocumentName:(NSString*) documentName arguments:(MBDocument*) arguments {
	return [[[MBDocumentOperation alloc] initWithDataHandler: [self handlerForDocument:documentName] documentName:documentName arguments:arguments] autorelease];
}

- (MBDocument *) createDocument:(NSString *)documentName {
	MBDocumentDefinition *def = [[MBMetadataService sharedInstance] definitionForDocumentName:documentName];
	return [[[MBDocument alloc] initWithDocumentDefinition:def] autorelease];
}

- (MBDocument *) loadDocument:(NSString *)documentName {
	return [[self loaderForDocumentName: documentName arguments: nil] load];
}

- (MBDocument *) loadDocument:(NSString *)documentName withArguments:(MBDocument*) args {
	return [[self loaderForDocumentName: documentName arguments: args] load];
}

- (void) loadDocument:(NSString *)documentName withArguments:(MBDocument*) args forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector {
	MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: args];
	[loader setDelegate: delegate resultCallback: resultSelector errorCallback: errorSelector];
	[_operationQueue addOperation:loader];
}

- (void) loadDocument:(NSString *)documentName forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector {
	MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: nil];
	[loader setDelegate: delegate resultCallback: resultSelector errorCallback: errorSelector];
	[_operationQueue addOperation:loader];
}

- (void) storeDocument:(MBDocument *)document {
	[[self handlerForDocument:[document name]] storeDocument:document];
}

- (void) storeDocument:(MBDocument *)document forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector {
	MBDocumentOperation *storer = [[[MBDocumentOperation alloc] initWithDataHandler: [self handlerForDocument:[document name]] document:document] autorelease];

	[storer setDelegate: delegate resultCallback: resultSelector errorCallback: errorSelector];
	[_operationQueue addOperation:storer];
}

- (void) deregisterDelegate: (id) delegate {
  	for(MBDocumentOperation *operation in [_operationQueue operations]) {
		if(delegate == [operation delegate]) { 
			[operation setDelegate:nil resultCallback:nil errorCallback:nil];
			[operation cancel];
		}
	}
}

- (MBDataHandlerBase *) handlerForDocument:(NSString *)documentName {
	NSString *dataManagerName = [[MBMetadataService sharedInstance] definitionForDocumentName:documentName].dataManager;

	id handler = [_registeredHandlers objectForKey: dataManagerName];
	if(handler == nil) {
		NSString *msg = [NSString stringWithFormat:@"No datamanager (%@) found for document %@", dataManagerName, documentName];
		@throw [[NSException alloc]initWithName:@"NoDataManager" reason:msg userInfo:nil];
	}
	return handler;
}

- (void) registerDataHandler:(id<MBDataHandler>) handler withName:(NSString*) name {
    [_registeredHandlers setObject: handler forKey: name];
}

- (void) setMaxConcurrentOperations:(int) max {
	[_operationQueue setMaxConcurrentOperationCount:max];	
}


@end
