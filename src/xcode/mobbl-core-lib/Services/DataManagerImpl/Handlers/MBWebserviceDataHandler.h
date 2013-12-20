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
#import "MBWebservicesConfigurationParser.h"

@interface MBWebserviceDataHandler : MBDataHandlerBase {
	MBWebservicesConfiguration *_webServiceConfiguration;
}

// Initialize with configuration read from config files
- (id) init;

// Initialize with custom configuration
- (id) initWithConfiguration:(MBWebservicesConfiguration *)configuration;

- (MBDocument *) loadDocument:(NSString *)documentName;
- (MBDocument *) loadDocument:(NSString *)documentName withArguments:(MBDocument *)args;
- (void) storeDocument:(MBDocument *)document;

- (MBEndPointDefinition *) getEndPointForDocument:(NSString*)name;

/** override this method to influence the URL used by the client.
 @param url The URL specified by the EndPointDefinition linked to the Document
 @param args A Document containing arguments for the call to the Webservice
 */
-(NSString *)url:(NSString *)url WithArguments:(MBDocument*)args;

/** override this method to influence the HTTP headers sent to the webservice.
 @param doc A Document containing arguments for the call to the Webservice
 */
-(void) setHTTPHeaders:(NSMutableURLRequest *)request withArguments:(MBDocument*) args;
/** override this method to influence the HTTP request body sent to the webservice.
 @param request The request object for the call to the Webservice
 @param doc A Document containing arguments for the call to the Webservice
 */
-(void) setHTTPRequestBody:(NSMutableURLRequest *)request withArguments:(MBDocument*) args;

/** Template method that retrieves the data from the webservice.
 @param request The request object for the call to the Webservice
 @param documentName The name of the Document being requested from the webservice
 @param endpoint The EndPointDefinition linked to the Document
 */
-(NSData *) dataFromRequest:(NSURLRequest *)request withDocumentName:(NSString*) documentName andEndpoint:(MBEndPointDefinition*)endPoint;

/** Template method that checks the response against ResultListeners specified in the endpoint definitions and fires the ones that match.
 @param endpoint The EndPointDefinition linked to the Document
 @param args A Document containing arguments for the call to the Webservice
 @param dataString the result of the webservice call in string format.
 */
-(BOOL) checkResultListenerMatchesInEndpoint:(MBEndPointDefinition *)endpoint withArguments:(MBDocument*)args withResponse:(NSString*)dataString;

/** Template method that parses the response and builds a Document. Override to implement or specify a custom parser
 @param endpoint The EndPointDefinition linked to the Document
 @param data The webservice response
 @param documentName The name of the Document being requested from the webservice
 */
-(MBDocument *) documentWithData:(NSData *)data andDocumentName:(NSString *)documentName;

/** override this method to influence the format of the data sent to the webservice.
 @param doc A Document containing arguments for the call to the Webservice
 */
-(MBDocument *) reformatRequestArgumentsForServer:(MBDocument * )doc;

/** convenience method to add housekeeping information to the request arguments
 @param element An Element in the Document containing the request arguments
 */
-(void) addAttributesToRequestArguments:(MBDocument *)doc;

/** convenience method to add a checksum to the request arguments
 @param element An Element in the Document containing the request arguments
 */
-(void) addChecksumToRequestArguments:(MBElement *)element;

@end

// Delegate used for callbacks in asynchronous http request. //
@interface MBRequestDelegate : NSObject // <NSURLConnectionDelegate> from iOS 5 on
{
	
	BOOL _finished;
	NSMutableData *_data;
	NSURLConnection *_connection;
	NSError *_err;
	NSURLResponse *_response;
	
}

@property BOOL finished;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSError *err;
@property (nonatomic, retain) NSURLResponse *response;
@property (nonatomic, retain) NSMutableData *data;

@end

