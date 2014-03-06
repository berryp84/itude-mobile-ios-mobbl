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

#import "MBDocument.h"
#import "MBDocumentDefinition.h"
#import "MBDocumentParser.h"

#define PARSER_XML @"XML"
#define PARSER_JSON @"JSON"


@interface MBDocumentFactory : NSObject {
    NSMutableDictionary *_registeredDocumentParsers;
}

/// @name Getting a MBDocumentFactory instance
+ (MBDocumentFactory *) sharedInstance;

/// @name Registering MBDocumentParser instances
- (void) registerDocumentParser:(id<MBDocumentParser>) parser withName:(NSString*) name;
- (id <MBDocumentParser>) parserForType:(NSString *)type;

- (MBDocument*) documentWithData:(NSData *)data withType:(NSString*)type andDefinition: (MBDocumentDefinition*) definition;
	

@end
