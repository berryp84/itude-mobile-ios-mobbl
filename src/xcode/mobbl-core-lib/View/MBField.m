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

#import "MBField.h"
#import "MBFieldDefinition.h"
#import "MBViewBuilderFactory.h"
#import "MBFieldViewBuilder.h"
#import "StringUtilities.h"
#import "MBMetadataService.h"
#import "MBLocalizationService.h"
#import "LocaleUtilities.h"

@implementation MBField 

@synthesize responder = _responder;
@synthesize width = _width;
@synthesize height = _height;
@synthesize label = _label;
@synthesize type = _type;
@synthesize dataType = _dataType;

@synthesize formatMask = _formatMask;
@synthesize alignment = _alignment;
@synthesize valueIfNil = _valueIfNil;
@synthesize hidden = _hidden;
@synthesize required = _required;
@synthesize custom1 = _custom1;
@synthesize custom2 = _custom2;
@synthesize custom3 = _custom3;

-(id) initWithDefinition:(id)definition document:(MBDocument*) document parent:(MBComponentContainer *) parent {
	self = [super initWithDefinition:definition document: document parent: parent];
	if (self != nil) {
		_responder = nil;
		_attributeDefinition = nil;
		_domainDetermined = FALSE;
		
		NSString *spec = [(MBFieldDefinition*)[self definition] width];	
		self.width = [[self substituteExpressions: spec] intValue];
		
		spec = [(MBFieldDefinition*)[self definition] height];	
		self.height = [[self substituteExpressions: spec] intValue];

		spec = [(MBFieldDefinition*)[self definition] style];	
		self.style = [self substituteExpressions: spec];

		spec = [(MBFieldDefinition*)[self definition] dataType];	
		self.dataType = [self substituteExpressions: spec];

        spec = [(MBFieldDefinition*)[self definition] hint];
        self.hint = [self substituteExpressions:spec];
        
		spec = [(MBFieldDefinition*)[self definition] label];
		self.label = [self substituteExpressions: spec];

		spec = [(MBFieldDefinition*)[self definition] formatMask];	
		self.formatMask = [self substituteExpressions: spec];

		spec = [(MBFieldDefinition*)[self definition] alignment];	
		self.alignment = [self substituteExpressions: spec];
		
		spec = [(MBFieldDefinition*)[self definition] valueIfNil];	
		self.valueIfNil = [self substituteExpressions: spec];
		
		spec = [(MBFieldDefinition*)[self definition] hidden];	
		self.hidden = [[self substituteExpressions: spec] boolValue];
		
		spec = [(MBFieldDefinition*)[self definition] required];	
		self.required = [[self substituteExpressions: spec] boolValue];

		spec = [(MBFieldDefinition*)[self definition] custom1];	
		self.custom1 = [self substituteExpressions: spec];

		spec = [(MBFieldDefinition*)[self definition] custom2];	
		self.custom2 = [self substituteExpressions: spec];
		
		spec = [(MBFieldDefinition*)[self definition] custom3];	
		self.custom3 = [self substituteExpressions: spec];
	}
	return self;
}

- (void) dealloc
{
	[_responder release];
	[_label release];
	[_type release];
	[_dataType release];
	[_translatedPath release];
	[_formatMask release];
	[_alignment release];
	[_valueIfNil release];
	[_custom1 release];
	[_custom2 release];
	[_custom3 release];
	[super dealloc];
}

-(NSString*) value {
    MBDocument *doc = self.document;
	return MBLocalizedStringWithoutLoggingWarnings([doc valueForPath: [self absoluteDataPath]]);
}

// Returns the untranslated value of the field. In some cases we want to use the untranslated value of the field (e.g. for comparing to the value of the domainValidator. JIRA IQ-70)
-(NSString*) untranslatedValue { 
	return [[self document] valueForPath:[self absoluteDataPath]];
}

-(void) setValue:(NSString*) value {
	NSString *path = [self absoluteDataPath];
	NSString *originalValue = [[self document] valueForPath:path];
	BOOL valueChanged = (value == nil && originalValue != nil) || (value != nil && originalValue == nil) || ![value isEqualToString:originalValue];
	
	if(valueChanged && [self notifyValueWillChange: value originalValue: originalValue forPath: path]) {	
		[[self document] setValue:value forPath: path];	
		[self notifyValueChanged: value originalValue: originalValue forPath: path];	
	}
}

//
// Apply a formatmask
-(NSString *) formattedValue{
	NSString *fieldValue = nil;
    if (self.path) {
        fieldValue = self.value;
    }
    else {
        fieldValue= self.label;
    }

	if (self.formatMask != nil && [self.dataType isEqualToString:@"dateTime"]) {

		// Get a NSDate from a xml-dateFormat
		NSString *xmlDate = fieldValue;
		
		// Formats the date depending on the current date. 
		if ([self.formatMask isEqualToString:@"dateOrTimeDependingOnCurrentDate"]) {
			fieldValue = [xmlDate formatDateDependingOnCurrentDate];
		}
		else 
		{
			NSDate *date = [xmlDate dateFromXML];
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setDateFormat:self.formatMask];
			fieldValue = [dateFormatter stringFromDate:date];
		}
		
	} else if ((fieldValue != self.valueIfNil) && [self.dataType isEqualToString:@"numberWithTwoDecimals"]) {
		fieldValue = [fieldValue formatNumberWithTwoDecimals];
	} else if ((fieldValue != self.valueIfNil) && [self.dataType isEqualToString:@"numberWithThreeDecimals"]) {
		fieldValue = [fieldValue formatNumberWithThreeDecimals];
	} else if ((fieldValue != self.valueIfNil) && [self.dataType isEqualToString:@"priceWithTwoDecimals"]) {
		fieldValue = [fieldValue formatPriceWithTwoDecimals];
	} else if ((fieldValue != self.valueIfNil) && [self.dataType isEqualToString:@"priceWithThreeDecimals"]) {
		fieldValue = [fieldValue formatPriceWithThreeDecimals];
	} else if ([self.dataType isEqualToString:@"volume"]) {
		fieldValue = [fieldValue formatVolume];
	} else if ([self.dataType isEqualToString:@"formatPercentageWithTwoDecimals"]) {
		fieldValue = [fieldValue formatPercentageWithTwoDecimals];
	}
    
    
    // Un-escape newline characters
    fieldValue = [fieldValue stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    fieldValue = [fieldValue stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];

	
	// CURRENCY Symbols
	if ([@"EURO" isEqualToString:self.style]) {
		fieldValue = [NSString stringWithFormat:@"€ %@", fieldValue];
	}
	
	return fieldValue;
	
}

-(NSString*) dataType {
	if(_dataType == nil) {
		NSString *tp = [self domain].type;
		if(tp == nil) tp = [self attributeDefinition].type;
		return tp;	
	}
	return _dataType;
}

-(BOOL) isNumeric {
	
	NSString *tp = [self dataType];
	
	return [@"int" isEqualToString:tp] ||
	[@"float" isEqualToString:tp] ||
	[@"double" isEqualToString:tp];
}

-(MBDomainDefinition*) domain {
	if(!_domainDetermined) {
		MBAttributeDefinition *attrDef = [self attributeDefinition];
		_domainDefinition = [[MBMetadataService sharedInstance] definitionForDomainName:attrDef.type throwIfInvalid: FALSE];
		_domainDetermined = TRUE;
	}
	return _domainDefinition;
}

-(MBAttributeDefinition*) attributeDefinition {
	if(_attributeDefinition == nil) {
		NSString *path = [[[self absoluteDataPath] stripCharacters:@"[]0123456789"] normalizedPath];
		if(path == nil) return nil;
		_attributeDefinition =  [[[self document] definition] attributeWithPath: path];
	}
	return _attributeDefinition;
}

-(UIView*) buildViewWithMaxBounds:(CGRect) bounds forParent:(UIView*) parent  viewState:(MBViewState) viewState {
	return [[[MBViewBuilderFactory sharedInstance] fieldViewBuilderFactory] buildFieldView: self forParent: parent withMaxBounds: bounds];
}

// This will translate any expression that are part of the path to their actual values
- (void) translatePath {
	_translatedPath =  [[self substituteExpressions:[self absoluteDataPath]] retain];
}

-(NSString *) componentDataPath {
	NSString *path = [(MBFieldDefinition*)[self definition] path];
	if(path == nil || [@"" isEqualToString: path]) return nil;
	return [self substituteExpressions: path];
}

-(NSString *) absoluteDataPath {
	if(_translatedPath != nil) return _translatedPath;
	return [super absoluteDataPath];
}


-(BOOL) resignFirstResponder {
	return [self resignFirstResponder: _responder];
}

// UITextFieldDelegate methods
- (void)KeyboardWillShow:(NSNotification*)note {
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

	// Do some validation depending on the dataType of the field
	BOOL shouldChangeCharacterInRange = TRUE;
	NSString *textFieldText = textField.text;
	NSString *charactersToValidate = nil;
	if ([self.dataType isEqualToString:@"int"]) {
		charactersToValidate = @"0123456789";
	}
	
	// When we check for a double of float character, we need to take
	else if ([self.dataType isEqualToString:@"double"] || 
		[self.dataType isEqualToString:@"float"]) {
		charactersToValidate = @"0123456789";
		
		// Take localization into account (allow a dot OR comma, depending on the locale settings)
		NSString *decimalSeparator = [[NSLocale currentLocale] getDecimalSeparator];
		
		// Check if the double or float already has a decimalSeperator (it can only have one)
		NSRange decimalSeparatorPresent = [textFieldText rangeOfString:decimalSeparator];
		if (decimalSeparatorPresent.location == NSNotFound) {
			charactersToValidate = [charactersToValidate stringByAppendingString:decimalSeparator];
		}
	}
	
	if (charactersToValidate != nil) {
		NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:charactersToValidate] invertedSet];
		NSString *filtered = [[string componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
		shouldChangeCharacterInRange = [string isEqualToString:filtered];
		textFieldText = filtered;
	}
	
	
	// make sure value is saved during user input, not just when the keyboard is dismissed
    [self setValue: textFieldText];
	return shouldChangeCharacterInRange;
}

- (void)KeyboardWillHide:(NSNotification*)note {
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
//	[[self page] resignFirstResponder];
//	[textField becomeFirstResponder];
}

- (void)textFieldDoneEditing:(UITextField *)textField { 
    
	
	NSString *textFieldValue = textField.text;
	
	// For financial apps the internal representation needs to be with US decimal seperators irrespective of the users locale. The attribute is an NSString, so some extra work is need here to check this before we store the value
	if ([[[MBLocalizationService sharedInstance] localeCode] isEqualToString:LOCALECODEDUTCH]) {
        textFieldValue = [self forceUSDecimalSeparatorWithValue:textFieldValue];
	}
	
	[self setValue: textFieldValue];

}

- (NSString *) forceUSDecimalSeparatorWithValue:(NSString *)inputString{
    NSString *outputString = nil;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSLocale *nl_NL = [[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"];
    [numberFormatter setLocale:nl_NL];
    if ([self.dataType isEqualToString:@"double"] || [self.dataType isEqualToString:@"float"]) {            double doubleValue = [numberFormatter numberFromString:inputString].doubleValue;
        outputString = [NSString stringWithFormat:@"%f",doubleValue];
    }
    
    return outputString;

}

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
	return TRUE;	
}

-(BOOL) textFieldShouldClear:(UITextField *)textField {
	return TRUE;
}

// Keyboard hiding stuff
-(void) applyEditor: (id) msg {
	// Make sure that any keyboard becomes hidden; and that any active editor will apply it's value
	[[self page] resignFirstResponder];
}

// Button stuff
-(void) buttonPressed: (id) msg {
	// Make sure that any keyboard becomes hidden; and that any active editor will apply it's value
	[[self page] resignFirstResponder];
	[self handleOutcome:[self outcomeName] withPathArgument: [self absoluteDataPath]];
}

-(void) switchToggled:(id)sender{
	if ([sender respondsToSelector:@selector(isOn)]) {
		BOOL value = (int) [sender performSelector:@selector(isOn)];
		if (value==YES) {
			[self setValue:@"true"];
		}
		else{
			[self setValue:@"false"];
		}
	}
}

-(NSString *) label {
	return MBLocalizedStringWithoutLoggingWarnings(_label);
}

- (NSString *)hint {
    return MBLocalizedStringWithoutLoggingWarnings(_hint);
}

// Convenience methods

-(NSString*) path {
	return [(MBFieldDefinition*)[self definition] path];	
}

-(NSString*) type {
	return [(MBFieldDefinition*)[self definition] displayType];	
}

-(NSString*) text {
	return MBLocalizedStringWithoutLoggingWarnings([(MBFieldDefinition*)[self definition] text]);	
}

-(NSString*) outcomeName {
	return [(MBFieldDefinition*)[self definition] outcomeName];	
}

- (NSString *) asXmlWithLevel:(int)level {
	
	NSMutableString * result = nil;
	
	@try {
		result = [NSMutableString stringWithFormat: @"%*s<MBField%@%@%@%@%@%@%@%@%@%@%@ width='%i' height='%i'/>\n", level, "",
								   [self attributeAsXml:@"value" withValue:[self value]],
								   [self attributeAsXml:@"path" withValue: [self absoluteDataPath]],
								   [self attributeAsXml:@"style" withValue:[self style]],
								   [self attributeAsXml:@"label" withValue:[self label]],
								   [self attributeAsXml:@"type" withValue:[self type]],
								   [self attributeAsXml:@"dataType" withValue:[self dataType]],
								   [self attributeAsXml:@"outcomeName" withValue:[self outcomeName]],
								   [self attributeAsXml:@"formatMask" withValue:[self formatMask]],
								   [self attributeAsXml:@"alignment" withValue:[self alignment]],
								   [self attributeAsXml:@"valueIfNil" withValue:[self valueIfNil]],
								   [self attributeAsXml:@"required" withValue:[self required]?@"TRUE":@"FALSE" ], 
								   [self width], [self height]
								   ];
	}
	@catch (NSException *e) {
        result = [NSMutableString stringWithFormat:@"<MBField errorInDefinition='%@, %@'/>\n", e.name, e.reason];

	}
	
	return result;
}

@end
