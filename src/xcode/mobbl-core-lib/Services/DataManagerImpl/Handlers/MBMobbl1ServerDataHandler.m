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

#import "MBMobbl1ServerDataHandler.h"
#import "MBDocumentFactory.h"
#import "MBDataManagerService.h"
#import "MBMetadataService.h"
#import "MBProperties.h"
#import "MBDevice.h"

#import <CommonCrypto/CommonDigest.h>

@interface MBMobbl1ServerDataHandler (hidden)

-(MBDocument *) getRequestDocumentForApplicationID:(NSString*) applicationID;


@end

@implementation MBMobbl1ServerDataHandler



-(MBDocument *) reformatRequestArgumentsForServer:(MBDocument * )doc{
    NSString *applicationID = [doc valueForPath:@"Request[0]/@name"];
    MBDocument *mobblDoc = [self getRequestDocumentForApplicationID:applicationID];
    MBElement *mobblRequest = [mobblDoc valueForPath:@"StrayClient[0]/SendDataDetails[0]/request[0]"];
    for (MBElement *parameter in [doc valueForPath:@"Request[0]/Parameter"]) {
      MBElement *mobblParameter = [mobblRequest createElementWithName:@"parameter"];
      NSString *key = [parameter valueForAttribute:@"key"];
      NSString *value = [parameter valueForAttribute:@"value"];
      [mobblParameter setValue:key forAttribute:@"key"];
      [mobblParameter setValue:value forAttribute:@"value"];
      // subparameters
      for (MBElement *subparameter in [parameter elementsWithName:@"Subparameter"]) {
          MBElement *mobblSubparameter = [mobblParameter createElementWithName:@"subparameter"];
          NSString *key = [subparameter valueForAttribute:@"key"];
          NSString *value = [subparameter valueForAttribute:@"value"];
          [mobblSubparameter setValue:key forAttribute:@"key"];
          [mobblSubparameter setValue:value forAttribute:@"value"];
      }
    }
    return mobblDoc;
}
                 
-(MBDocument *) getRequestDocumentForApplicationID:(NSString*) applicationID{
	MBDocument *requestDoc = [[MBDataManagerService sharedInstance] loadDocument:@"MBMobbl1Request"];
	[[requestDoc valueForPath:@"StrayClient[0]"] setValue:applicationID forAttribute:@"applicationID"];
	return requestDoc;
}

-(MBDocument *) documentWithData:(NSData *)data andDocumentName:(NSString *)documentName{
    return [[MBDocumentFactory sharedInstance] documentWithData:data withType:PARSER_MOBBL1 andDefinition:[[MBMetadataService sharedInstance] definitionForDocumentName:documentName]];
}


-(void) addAttributesToRequestArguments:(MBDocument *)doc{
    MBElement *element = [doc valueForPath:@"StrayClient[0]"];
    // ======== Mobbl1 required xml attributes =========
	NSString *universeID = [MBProperties valueForProperty:@"mobblUniverseID"];
	NSString *iPhoneUIDPrefix = ([MBDevice isPad]?[MBProperties valueForProperty:@"iPadUIDPrefix"]:[MBProperties valueForProperty:@"iPhoneUIDPrefix"]);
	NSString *deviceId = [NSString stringWithFormat:@"%@ %@",iPhoneUIDPrefix,[MBDevice identifier]];
    NSString *iOSVersion = [MBDevice iOSVersionAsString];
	NSString *deviceName = [MBDevice deviceName];
	NSDate *currentDate = [[[NSDate alloc] init] autorelease];
	NSString *dateTime = [NSString stringWithFormat:@"%@ %@", [(NSString *)[currentDate description] substringToIndex:10], [(NSString *)[(NSString *)[currentDate description] substringFromIndex:11] substringToIndex:8]];
	[element setValue:@"http://straysystems.com/xsd/strayclient" forAttribute:@"xmlns"];
	[element setValue:@"SendData" forAttribute:@"command"];
	[element setValue:universeID forAttribute:@"universeID"];
	[element setValue:dateTime forAttribute:@"dateTime"];
	[element setValue:deviceId forAttribute:@"iPhoneUID"];
    [element setValue:iOSVersion forAttribute:@"iOSVersion"];
	[element setValue:deviceName forAttribute:@"deviceName"];
    [self addChecksumToRequestArguments:element];
}

-(void) addChecksumToRequestArguments:(MBElement *)element{
    NSString *dateTime = [element valueForAttribute:@"dateTime"];
	NSString *deviceId = [element valueForAttribute:@"iPhoneUID"];

	NSString *md5String = [NSString stringWithFormat:@"%@%@%@", dateTime, deviceId, [MBProperties valueForProperty:@"mobblSecret"]];
	const char *cStr = [md5String UTF8String];
	unsigned char md5Result[CC_MD5_DIGEST_LENGTH];
	CC_MD5( cStr, strlen(cStr), md5Result );
	NSString *md5Hash = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
						 md5Result[0], md5Result[1],
						 md5Result[2], md5Result[3],
						 md5Result[4], md5Result[5],
						 md5Result[6], md5Result[7],
						 md5Result[8], md5Result[9],
						 md5Result[10], md5Result[11],
						 md5Result[12], md5Result[13],
						 md5Result[14], md5Result[15]
						 ];
    [element setValue:md5Hash forAttribute:@"messageID"];
}


@end
