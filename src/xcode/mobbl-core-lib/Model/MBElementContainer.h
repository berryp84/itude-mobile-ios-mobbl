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

@class MBElement;
@class MBDocument;

/**
* A node in a tree of MBElement instances.
*
* In MOBBL, data is represented in MBDocuments and MBElements. An MBDocument is a lightweight xml-like structure, optimised for mobile use.
*
* MBDocuments and MBElements are both MBElementContainers. Each ElementContainer has an associated MBElementDefinition which defines its structure. 
* The most frequently used methods are valueForPath:, setValue: forPath: and elementsWithName:
*/
@interface MBElementContainer : NSObject {
	NSMutableDictionary *_elements; // Dictionary of lists of elements
	MBElementContainer *_parent;
}

/// @name Creating and Initializing an Element Tree
- (id) init;

/// @name Getting ElementContainer Properties
@property (nonatomic, assign) MBElementContainer *parent;
/** MBElementDefinition for this ElementContainer */
- (id) definition;
- (NSString*) name;
- (MBDocument*) document;
- (NSString*) documentName;
- (NSString*) uniqueId;

/// @name Adding Elements to the Tree
- (MBElement*) createElementWithName: (NSString*) name;
- (MBElement*) createElementWithName: (NSString*) name atIndex:(NSInteger)index;
- (void) addElement: (MBElement*) element;
- (void) addElement: (MBElement*) element atIndex:(NSInteger)index;

/// @name Removing Elements from the Tree
- (void) deleteElementWithName: (NSString*) name atIndex:(int) index;
- (void) deleteAllChildElements;

/// @name Returns a set of MBElements
- (NSMutableDictionary*) elements;
/* Returns an array of MBElements
 *param name The (tag)name of the element to retrieve.
 */
- (NSMutableArray*) elementsWithName: (NSString*) name;
/* Gets a value from the Document or Element

 @param path an NSString with an xpath-like syntax
 Examples:
 "/CUSTOMER[0]/@name"               returns the name attribute of the first CUSTOMER element.
 "/CUSTOMER[1]/ADDRESS[0]/@street"  returns the street attribute of the first ADDRESS element nested in the second CUSTOMER element.
 "/CUSTOMER[1]"                     returns the MBElement attribute of the second CUSTOMER.
 
 For debugging purposes an MBElementContainer can easily be pretty printed with the description method (implicit default method for NSLog in objc).
 
 Return values are:
 * nil
 * An MBElement
 * An MBAtribute
 * A Dictionary of MBElements
 
 */
- (id) valueForPath:(NSString *)path;
/// Internal use only
- (id) valueForPath:(NSString*)path translatedPathComponents:(NSMutableArray*) translatedPathComponents;
/// Internal use only
- (id) valueForPathComponents:(NSMutableArray*)pathComponents withPath: (NSString*) originalPath nillIfMissing:(BOOL) nillIfMissing translatedPathComponents:(NSMutableArray*)translatedPathComponents;

/* Sets an attribute value from the Document or Element

 @param value an NSString. At the time of writing MBAttributes are intenally represented as NSStrings
 @param path an NSString with an xpath-like syntax
 Examples:
 "/CUSTOMER[0]/@name"               the name attribute of the first CUSTOMER element.
 "/CUSTOMER[1]/ADDRESS[0]/@street"  the street attribute of the first ADDRESS element nested in the second CUSTOMER element.
 "/CUSTOMER[1]/text()"              the body content of the MBElement attribute of the second CUSTOMER. The value will be inserted between the <CUSTOMER> and </CUSTOMER> tags rather than in an attribute. text() is a special keyword.
 
 For debugging purposes an MBElementContainer can easily be pretty printed with the description method (implicit default method for NSLog in objc).
*/
 - (void) setValue:(NSString*)value forPath:(NSString *)path;

/// @name Evaluating Expressions
- (NSString*) evaluateExpression:(NSString*) expression;
- (NSString*) evaluateExpression:(NSString*) expression currentPath:(NSString*) currentPath;

/// @name Reordering Elements
- (void) sortElements:(NSString*) elementName onAttributes:(NSString*) attributeNames;

/// @name Working with the Shared Context
- (NSMutableDictionary*) sharedContext;
- (void) setSharedContext:(NSMutableDictionary*) sharedContext;
- (MBDocument*) getDocumentFromSharedContext:(NSString*) documentName;
- (void) registerDocumentWithSharedContext:(MBDocument*) document;

@end
