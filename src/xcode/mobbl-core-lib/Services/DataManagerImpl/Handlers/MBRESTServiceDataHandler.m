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

-(NSString *)url:(NSString *)url WithArguments:(MBDocument*)args{
    NSString *operationName = [args valueForPath:@"/Operation[0]/@name"];
    if(operationName){
        url = [url stringByAppendingString:operationName];
    }
    BOOL firstParam = YES;
    for (MBElement *element in [args valueForPath:@"/Operation[0]/Parameter"]) {
        NSString *key  = [element valueForAttribute:@"key"];
        NSString *value = [element valueForAttribute:@"value"];
        if (firstParam) {
            url = [url stringByAppendingString:[NSString stringWithFormat:@"?%@=%@", key, [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            firstParam = NO;
        }
        else {
            url = [url stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", key, [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        }
    }
    return url;
}

-(void) setHTTPHeaders:(NSMutableURLRequest *)request withArguments:(MBDocument*) args{
    NSString *httpMethod = [args valueForPath:@"/Operation[0]/@httpMethod"];
    [request setHTTPMethod:httpMethod];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
}
-(void) setHTTPRequestBody:(NSMutableURLRequest *)request withArguments:(MBDocument*) args{
    // do nothing
}

@end
