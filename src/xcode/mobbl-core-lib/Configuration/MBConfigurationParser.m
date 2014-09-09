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

#import "MBMacros.h"
#import "MBConfigurationParser.h"

@implementation MBConfigurationParser

@synthesize documentName = _documentName;

- (void) dealloc
{
	[_documentName release];
	[super dealloc];
}

- (id) parseData:(NSData*)data ofDocument:(NSString*) documentName {
    self.documentName = documentName;
    
    _stack = [[NSMutableArray alloc] init];
    _characters = nil;
    
    // IMPORTANT FIX FOR IOS8
    // http://stackoverflow.com/questions/25363560/ios8-nsxmlparser-crash
    dispatch_queue_t reentrantAvoidanceQueue = dispatch_queue_create("reentrantAvoidanceQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(reentrantAvoidanceQueue, ^{
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        [parser setDelegate:self];
        if([parser parse] == NO) {
            NSError *error = [parser parserError];
            @throw [NSException exceptionWithName:@"ParseError" reason: [error description] userInfo:nil];
        }
        [parser release];
    });
    dispatch_sync(reentrantAvoidanceQueue, ^{ });
    
    id config = [[_stack lastObject] retain];
    [_stack release];
    [_characters release];
    
    return [config autorelease];
}

- (void) notifyProcessed:(id) object usingSelector:(SEL) selector {
    if(![[_stack lastObject] respondsToSelector: selector]) {
        NSString *msg = [NSString stringWithFormat:@"Document %@: Element %@ does not support %@. Cannot add %@", _documentName, [_stack lastObject], NSStringFromSelector(selector), object];
        [NSException exceptionWithName:@"InvalidHierarchy" reason: msg userInfo: nil];                
    }
    id parent = [_stack lastObject];
    [parent performSelector:selector withObject:object];
    [_stack addObject:object];
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[_characters appendString:string];
}

- (BOOL) processElement:(NSString*)elementName attributes:(NSDictionary*)attributeDict {
	return NO;
}

- (void) didProcessElement:(NSString*)elementName {
}

- (BOOL) checkAttributesForElement:(NSString*) elementName withAttributes:(NSDictionary*) attributes withValids:(NSArray*) valids {
    BOOL result = TRUE;
    for(NSString* attrName in [attributes allKeys]) {
        if(![valids containsObject:attrName]) {
            WLog(@"****WARNING Invalid attribute %@ for element %@ in document %@", attrName, elementName, _documentName);
            result = FALSE;
        }
    }
    return result;
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	
	NSString *msg = [NSString stringWithFormat:@"Error parsing document %@ at line %i column %i: %@", 
					 _documentName, [parser lineNumber], [parser columnNumber],  [parseError description]];
	
	@throw [NSException exceptionWithName:@"ParseError" reason: msg userInfo:nil];

}

// begin element
- (void) parser:(NSXMLParser*)parser 
didStartElement:(NSString*)elementName 
   namespaceURI:(NSString*)namespaceURI 
  qualifiedName:(NSString*)qName 
	 attributes:(NSDictionary*)attributeDict {
	
	[_characters release];
	_characters = [NSMutableString new];

	if (![self isConcreteElement:elementName])
		return;
	
	if (![self processElement:elementName attributes:attributeDict]) {
        NSString *msg = [NSString stringWithFormat:@"Document %@: Element %@ not defined", _documentName, elementName];
		@throw [NSException exceptionWithName: @"UnknownElementException" reason:msg userInfo:nil];
	}

	[[_stack lastObject] performSelector:@selector(validateDefinition)];
}

// end element
-(void) parser:(NSXMLParser*)parser 
 didEndElement:(NSString*)elementName 
  namespaceURI:(NSString*)namespaceURI 
 qualifiedName:(NSString*)qName {
	
	if ([self isIgnoredElement:elementName])
		return;
	
	if(![self isConcreteElement:elementName]) {
        NSString *msg = [NSString stringWithFormat:@"Document %@: Element %@ not defined", _documentName, elementName];
		@throw [NSException exceptionWithName: @"UnknownElementException" reason:msg userInfo:nil];
	}
	
	[self didProcessElement:elementName];
	[_characters release];
	_characters = nil;
}

- (BOOL)isConcreteElement:(NSString*)element {
	return NO;
}

- (BOOL)isIgnoredElement:(NSString*)element {
	return NO;
}

@end
