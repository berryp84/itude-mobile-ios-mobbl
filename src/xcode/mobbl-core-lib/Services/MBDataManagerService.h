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

#import "MBDataHandlerBase.h"
#import "MBDocument.h"
#import "MBDataHandler.h"

#define DATA_HANDLER_MEMORY @"MBMemoryDataHandler"
#define DATA_HANDLER_FILE @"MBFileDataHandler"
#define DATA_HANDLER_SYSTEM @"MBSystemDataHandler"
#define DATA_HANDLER_SQL @"MBSQLDataHandler"
#define DATA_HANDLER_WS_REST @"MBRESTServiceDataHandler"
#define DATA_HANDLER_WS_MOBBL @"MBMobbl1ServerDataHandler"

#define MAX_CONCURRENT_OPERATIONS 5

/** Service class for loading and storing MBDocument instances.
 
 The MBDataManagerService handles MBDocument instantiation and storage. Depending on the options defined in the configuration and endpoints files it (and the MBDataHandlers it uses) also handles:
 - caching
 - background threading and callback on completion
 - concurrent requests
 - network errors
 - reachability
 - cancellable network requests
 
 Every MBDocument is associated with a specific MBDataHandler in the document definition (see MBDocumentDefinition). When accessing
 documents using for instance loadDocument: , its associated DataHandler is used to perform the actual operation. For this to work, the
 name of the DataHandler must be registered using registerDataHandler:withName: first.
 
 */
@interface MBDataManagerService : NSObject {
	NSMutableDictionary *_registeredHandlers;
	NSOperationQueue *_operationQueue;
}

/// @name Getting a service instance
/** The shared instance */
+ (MBDataManagerService *) sharedInstance;

/// @name Configuring the service

/** Registers a MBDataHandler.
 @param handler the MBDataHandler instance
 @param name registration name.
 */
- (void) registerDataHandler:(id<MBDataHandler>) handler withName:(NSString*) name;

/** Removes the given MBDataHandler from the list of supported DataHandlers. */
- (void) deregisterDelegate: (id) delegate;

/** Sets the maximum number of asynchronous operations that can be active at the same time. */
- (void) setMaxConcurrentOperations:(int) max;

/// @name Creating a document

/** Creates a new MBDocument.
 @param documentName name of the document as defined in `documents.xmlx`.
 */
- (MBDocument *) createDocument:(NSString *)documentName;

/// @name Accessing a document synchronously

/** See [MBDataHandler loadDocument:] */
- (MBDocument *) loadDocument:(NSString *)documentName;

/** See [MBDataHandler loadDocument:withArguments:] */
- (MBDocument *) loadDocument:(NSString *)documentName withArguments:(MBDocument*) args;

/** See [MBDataHandler loadFreshDocument:] */
- (MBDocument *) loadFreshDocument:(NSString *)documentName;

/** See [MBDataHandler loadFreshDocument:withArguments:] */
- (MBDocument *) loadFreshDocument:(NSString *)documentName withArguments:(MBDocument*) args;

/** See [MBDataHandler storeDocument:] */
- (void) storeDocument:(MBDocument *)document;

/// @name Accessing a document asynchronously

/** See [MBDataHandler loadDocument:].
 @param delegate delegate object that is called on completion
 @param resultSelector selector on delegate that is called on success. Selector is called with the loaded MBDocument as parameter.
 @param errorSelector selector on delegate that is called on error. No parameters are passed.
 */
- (void) loadDocument:(NSString *)documentName forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector;

/** See [MBDataHandler loadDocument:withArguments] and loadDocument:forDelegate:resultSelector:errorSelector: */
- (void) loadDocument:(NSString *)documentName withArguments:(MBDocument*) args forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector;

/** See [MBDataHandler loadFreshDocument:] and loadDocument:forDelegate:resultSelector:errorSelector: */
- (void) loadFreshDocument:(NSString *)documentName forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector;

/** See [MBDataHandler loadFreshDocument:withArguments:] and loadDocument:forDelegate:resultSelector:errorSelector: */
- (void) loadFreshDocument:(NSString *)documentName withArguments:(MBDocument*) args forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector;

/** See [MBDataHandler storeDocument:] and loadDocument:forDelegate:resultSelector:errorSelector: */
- (void) storeDocument:(MBDocument *)document forDelegate:(id) delegate resultSelector:(SEL) resultSelector errorSelector:(SEL) errorSelector;

/** Sets a request parameter on an arguments Document for a webservice [MBDataHandler loadDocument: withArguments] and returns the result.
 @param value Value
 @param key Name of the request parameter
 @param doc Document that will be used as arguments in [MBDataHandler loadDocument: withArguments]. If nil, then a Document is auto-created.
 
 This method accepts Documents in two formats:
 1. Simple parameter list (legacy)
 <Request name="">
    <Parameter key="sessionID" value="1234567890" />
    <Parameter key="customer" value="Acme apps">
        <Subparameter key="address" "123 Industry street" />
        <Subparameter key="city" "Appville" />
        <Subparameter key="country" "United States of App" />
    </Parameter>
 </Request>
 
 2. REST Webservice operation plus parameters
 <Operation name="/customer" httpMethod="POST">
     <Parameter key="sessionID" value="1234567890" />
     <Parameter key="customer" value="Acme apps" />
     <Parameter key="address" "123 Industry street" />
     <Parameter key="city" "Appville" />
     <Parameter key="country" "United States of App" />
 </Request>
 
 */
+ (MBDocument*) setRequestParameter:(NSString *)value forKey:(NSString *)key forDocument:(MBDocument *)doc;


@end
