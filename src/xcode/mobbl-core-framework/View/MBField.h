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

#import "MBComponent.h"
@class MBFieldDefinition;
@class MBDomainDefinition;

/** smallest user interface element definition in MOBBL framework. Typically an input field, label or button */
@interface MBField  : MBComponent <UITextFieldDelegate>{
	
	@private
	UIView *_responder;
	MBAttributeDefinition *_attributeDefinition;
	BOOL _domainDetermined;
	MBDomainDefinition *_domainDefinition;
	NSString *_translatedPath;
	NSString *_label;
	NSString *_type;
	NSString *_dataType;
    NSString *_hint;
	NSString *_formatMask;
	NSString *_alignment;
	NSString *_valueIfNil;
	BOOL _hidden;
	BOOL _required;
	int _width;
	int _height;
}

@property (nonatomic, retain) UIView *responder;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *dataType;
@property (nonatomic, retain) NSString *hint;
@property (nonatomic, retain) NSString *formatMask;
@property (nonatomic, retain) NSString *alignment;
@property (nonatomic, retain) NSString *valueIfNil;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) BOOL required;

-(NSString*) value;
-(NSString*) untranslatedValue; // Added by Frank: In some cases we want to use the untranslated value of the field (e.g. for comparing to the value of the domainValidator. JIRA IQ-70)
-(void) setValue: (NSString*) value;
-(NSString*) path;
-(NSString*) label;
-(NSString*) type;
-(NSString*) dataType;
-(NSString*) text;
-(NSString*) outcomeName;
-(BOOL) required;
-(MBDomainDefinition*) domain;
-(MBAttributeDefinition*) attributeDefinition;
-(int) width;
-(int) height;
-(NSString *) formattedValue;

// for UISwitch
-(void) switchToggled:(id)sender;

// for financial apps
- (NSString *) forceUSDecimalSeparatorWithValue:(NSString *)inputString;

- (void)textFieldDoneEditing:(UITextField *)textField;
	

@end
