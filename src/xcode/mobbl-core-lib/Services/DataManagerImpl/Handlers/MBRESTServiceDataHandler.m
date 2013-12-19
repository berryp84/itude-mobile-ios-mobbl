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

//	This class is used as a singleton. 
//  Therefore the request state is put in the MBRequestDelegate, which is created for every loadDocument method

#import "MBMacros.h"
#import "MBRESTServiceDataHandler.h"
#import "MBMetadataService.h"
#import "MBDocumentFactory.h"
#import "MBOutcome.h"
#import "MBApplicationFactory.h"
#import "MBAction.h"
#import "MBLocalizationService.h"
#import "Reachability.h"
#import <Foundation/Foundation.h>
#import "MBServerException.h"

@implementation MBRESTServiceDataHandler

@synthesize documentFactoryType = _documentFactoryType;

- (void) dealloc {
	self.documentFactoryType = nil;
	[super dealloc];
}


- (id) init {
	self = [super init];
	if (self != nil) {
		self.documentFactoryType = PARSER_XML;
	}
	return self;
}

-(MBDocument *) loadDocument:(NSString *)documentName{
	return [self loadDocument:documentName withArguments: nil];
}

- (MBDocument *) loadDocument:(NSString *)documentName withArguments:(MBDocument *)args {

	MBEndPointDefinition *endPoint = [self getEndPointForDocument:documentName];
	DLog(@"loadDocument %@ from %@", documentName, endPoint.endPointUri);
	
	if (endPoint != nil)
	{
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endPoint.endPointUri] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:endPoint.timeout];
        request = [self setupHTTPRequest:request];
        
		NSString *body = [[args valueForPath:@"/*[0]"] asXmlWithLevel:0];
		if(body != nil) [request setHTTPBody: [body dataUsingEncoding:NSUTF8StringEncoding]];
		// DLog(@"Request is: %@", body);
		MBRequestDelegate *delegate = [MBRequestDelegate new];
		NSString *dataString = nil;
		MBDocument *responseDoc = nil;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:endPoint.timeout target:(delegate) selector:@selector(cancel) userInfo:nil repeats:NO];
		@try {
			delegate.err = nil;
			delegate.response = nil;
			delegate.finished = NO;
			delegate.data = [[NSMutableData new] retain];
			
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
			
			//NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
			
			// create new connection and begin loading data
			[[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
			if ((delegate.connection = [[NSURLConnection alloc] initWithRequest:request delegate:delegate])){
				while (!delegate.finished) {
					if([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable){
						// Big problem, throw Exception
						[delegate.connection cancel];
						@throw [MBServerException exceptionWithName:MBLocalizedString(@"Network error") reason:MBLocalizedString(@"No internet connection") userInfo:nil];
					}
                    
					
					// Because the application crashed here all these seperate steps are added to pinpoint the excact location of the crash.
					NSString *endPointUri = endPoint.endPointUri;
					NSURL *url = nil;
					NSString *hostName = nil;
					Reachability *reachability = nil;
					NetworkStatus networkStatus = NotReachable;
					
					if (endPointUri) {
						@try {
							url = [NSURL URLWithString:endPointUri];
						}
						@catch (NSException * e) {
							WLog(@"WARNING! MBRESTServiceDataHandler:Prevented a crash while creating an NSURL from the endpointUri while loading document %@. Exception: %@",documentName,e);
						}						
					}else {
						WLog(@"WARNING! MBRESTServiceDataHandler:The endpointUri (%@) could not be retrieved while loading document %@.",endPointUri,documentName);
					}
					
					if (url) {
						hostName = [url host];
					}else {
						WLog(@"WARNING! MBRESTServiceDataHandler:The url (%@) could not be retrieved while loading document %@.",url,documentName);
					}
					
					if (hostName && ([hostName length]>0)) {
						reachability = [Reachability reachabilityWithHostName:hostName];
					} else {
						WLog(@"WARNING! MBRESTServiceDataHandler:The hostName (%@) could not be retrieved while loading document %@.",hostName,documentName);
					}
					
					if (reachability) {
						networkStatus = [reachability currentReachabilityStatus];
					} else {
						WLog(@"WARNING! MBRESTServiceDataHandler:The reachability (%@) could not be retrieved while loading document %@.",reachability,documentName);
					}	
						
					if (networkStatus == NotReachable) {
					//if([[Reachability reachabilityWithHostName:[[NSURL URLWithString:endPoint.endPointUri] host]] currentReachabilityStatus ] == NotReachable){
						// Big problem, throw Exception
						[delegate.connection cancel];
						@throw [MBServerException exceptionWithName:MBLocalizedString(@"Network error") reason:MBLocalizedString(@"Server unreachable") userInfo:nil];
					}
					// Wait for async http request to finish, but make sure delegate methods are called, since this is executed in an NSOperation
					[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
				}
			}
			
            [timer invalidate];

			dataString = [[NSString alloc] initWithData:delegate.data encoding:NSUTF8StringEncoding];
			BOOL serverErrorHandled = NO;

			for(MBResultListenerDefinition *lsnr in [endPoint resultListeners]) {
				if([lsnr matches:dataString]) {
					id<MBResultListener> rl = [[MBApplicationFactory sharedInstance] createResultListener:lsnr.name];
					[rl handleResult:dataString requestDocument:args definition: lsnr];
					serverErrorHandled = YES;
				}
			}
			if (delegate.err != nil) {
				[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
				WLog(@"An error (%@) occured while accessing endpoint '%@'", delegate.err, endPoint.endPointUri);
				@throw [MBServerException exceptionWithName:MBLocalizedString(@"Network error") reason:[delegate.err localizedDescription] userInfo:[delegate.err userInfo]];
			}
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			
			responseDoc =  [[MBDocumentFactory sharedInstance] documentWithData:delegate.data withType:self.documentFactoryType andDefinition:[[MBMetadataService sharedInstance] definitionForDocumentName:documentName]];
			// if the response document is empty and unhandled by endpoint listeners let the user know there is a problem
			if (!serverErrorHandled && responseDoc == nil) {
				NSString *msg = MBLocalizedString(@"The server returned an error. Please try again later");
				if(delegate.err != nil) {
					msg = [NSString stringWithFormat:@"%@ %@: %ld", msg, delegate.err.domain, (long)delegate.err.code];
				}
				@throw [MBServerException exceptionWithName:@"Server Error" reason: msg userInfo:nil];
			}
		}
		@catch (NSException * e) {
			DLog(@"%@",body);
			DLog(@"%@",dataString);
			@throw e;
		}
		@finally {
			[delegate release];
            [timer invalidate];
		}
		
		//
		// animate if proper data was returned
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivity" object: nil];
		return responseDoc;
	}
	else {
		WLog(@"No endpoint defined for document name '%@'", documentName);
		return nil;
	}	
}


- (void) storeDocument:(MBDocument *)document {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivity" object: nil];
    

	MBEndPointDefinition *endPoint = [self getEndPointForDocument:[document.definition name]];
	DLog(@"storeDocument %@ from %@", [document.definition name], endPoint.endPointUri);
	
	if (endPoint != nil)
	{	
		
	}
	else {
		WLog(@"No endpoint defined for document name '%@'", [document.definition name]);
	}	
}

- (NSMutableURLRequest *) setupHTTPRequest:(NSMutableURLRequest *)request
{
    [request setHTTPMethod:@"POST"];
    // Content-Type must be set because otherwise the MidletCommandProcessor servlet cannot read the XML
    // this is related to a bug in Tomcat 6
    // MIME type application/x-www-form-encoded is the default
    // RM0412 TODO: check handling of special characters
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    return request;
}

@end
