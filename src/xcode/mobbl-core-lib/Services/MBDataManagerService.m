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

#import "MBDataManagerService.h"
#import "MBMetadataService.h"
#import "MBSQLDataHandler.h"
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
        [self registerDataHandler:[[MBSQLDataHandler new] autorelease] withName: DATA_HANDLER_SQL];
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

- (MBDocument *) loadFreshDocument:(NSString *)documentName {
    MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: nil];
    loader.loadFreshCopy = YES;
	return [loader load];
}

- (MBDocument *) loadDocument:(NSString *)documentName withArguments:(MBDocument*) args {
	return [[self loaderForDocumentName: documentName arguments: args] load];
}

- (MBDocument *) loadFreshDocument:(NSString *)documentName withArguments:(MBDocument*) args {
    MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: args];
    loader.loadFreshCopy = YES;
	return [loader load];
}


- (void) loadDocument:(NSString *)documentName withArguments:(MBDocument*) args forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector {
	MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: args];
	[loader setDelegate: delegate resultCallback: resultSelector errorCallback: errorSelector];
	[_operationQueue addOperation:loader];
}

- (void) loadFreshDocument:(NSString *)documentName withArguments:(MBDocument*) args forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector {
	MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: args];
	[loader setDelegate: delegate resultCallback: resultSelector errorCallback: errorSelector];
    loader.loadFreshCopy = YES;
	[_operationQueue addOperation:loader];
}

- (void) loadDocument:(NSString *)documentName forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector {
	MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: nil];
	[loader setDelegate: delegate resultCallback: resultSelector errorCallback: errorSelector];
	[_operationQueue addOperation:loader];
}

- (void) loadFreshDocument:(NSString *)documentName forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector {
	MBDocumentOperation *loader = [self loaderForDocumentName: documentName arguments: nil];
	[loader setDelegate: delegate resultCallback: resultSelector errorCallback: errorSelector];
    loader.loadFreshCopy = YES;
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
		@throw [[[NSException alloc]initWithName:@"NoDataManager" reason:msg userInfo:nil] autorelease];
	}
	return handler;
}

- (void) registerDataHandler:(id<MBDataHandler>) handler withName:(NSString*) name {
    [_registeredHandlers setObject: handler forKey: name];
}

- (void) setMaxConcurrentOperations:(int) max {
	[_operationQueue setMaxConcurrentOperationCount:max];
}


/// Construction of arguments for DataHandlers

+ (MBDocumentDefinition *)argumentsDocumentDefinition
{
    MBDocumentDefinition *argumentsDocumentDefinition = [[[MBDocumentDefinition alloc] init] autorelease];
    MBElementDefinition *operationDefinition = [[MBElementDefinition alloc] init];
    operationDefinition.name = @"Operation";
    [argumentsDocumentDefinition addElement:operationDefinition];
    [self addAttribute:operationDefinition name:@"name" type:@"string"];
    [self addAttribute:operationDefinition name:@"httpMethod" type:@"string"];
    MBElementDefinition *parameterDefinition = [[MBElementDefinition alloc] init];
    parameterDefinition.name = @"Parameter";
    parameterDefinition.minOccurs = 0;
    [operationDefinition addElement:parameterDefinition];
    
    [self addAttribute:parameterDefinition name:@"key" type:@"string"];
    [self addAttribute:parameterDefinition name:@"value" type:@"string"];
    
    [parameterDefinition release];
    [operationDefinition release];
    
    return argumentsDocumentDefinition;
}

+ (void) addAttribute:(MBElementDefinition*) elementDef name:(NSString*) name type:(NSString*) type {
    MBAttributeDefinition *attributeDef = [[MBAttributeDefinition new] autorelease];
    attributeDef.name = name;
    attributeDef.type = type;
    [elementDef addAttribute: attributeDef];
}

+ (MBDocument*) setRequestParameter:(NSString *)value forKey:(NSString *)key forDocument:(MBDocument *)doc{
    if(!doc){
        doc = [[self argumentsDocumentDefinition] createDocument];
    }
    MBElement *rootElement = nil;
    rootElement = [doc valueForPath:@"Request[0]"];
    if (!rootElement) {
        rootElement = [doc valueForPath:@"Operation[0]"];
    }
    if (rootElement){
        MBElement *parameter = [rootElement createElementWithName:@"Parameter"];
        [parameter setValue:key forAttribute:@"key"];
        [parameter setValue:value forAttribute:@"value"];
    } else
    {
        NSString *msg = @"Unrecognised Document doc. View the documentation for accepted Document definitions. Leave parameter doc nil to generate a Document with the correct syntax";
		@throw [[[NSException alloc]initWithName:@"Unrecognised Document" reason:msg userInfo:nil] autorelease];
    }
    return doc;

}


@end
