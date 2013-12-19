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

#import "MBMatrixCell.h"
#import "StringUtilities.h"
#import "MBLocalizationService.h"

@implementation MBMatrixCell


@synthesize value = _value;
@synthesize field = _field;
@synthesize page = _page;
@synthesize style = _style;
@synthesize width = _width;
@synthesize height = _height;
@synthesize alignment = _alignment;
@synthesize delta = _delta;
@synthesize hidden = _hidden;

- (void) dealloc
{
	[_value release];
	[_style release];
	[_field release];
	[_page release];
	 
	[super dealloc];
}


+ (MBMatrixCell *)cellWithValue:(NSString *)value {
	MBMatrixCell *cell = [[[MBMatrixCell alloc] init] autorelease];
	cell.value = MBLocalizedStringWithoutLoggingWarnings(value);
	return cell;
}

-(void) updateValue {
	NSString *fieldValue = MBLocalizedStringWithoutLoggingWarnings(self.field.value);
	MBField *field = self.field;
	
	// If field is a emtpy string make it nil
	if ([fieldValue isEqualToString:@""]) {
		fieldValue = nil;
	}
	
	if (fieldValue == nil) {
		fieldValue = self.field.valueIfNil;
	}
	
	// If there is no field value present, check if there is a label
	if (fieldValue == nil) {
		fieldValue = self.field.label;
	}
	
	//
	// Apply a formatmask
	if (field.formatMask != nil && [field.dataType isEqualToString:@"double"]) {
		fieldValue = [NSString stringWithFormat:field.formatMask,[fieldValue floatValueDutch]];
	}
	
	else if (field.formatMask != nil && [field.dataType isEqualToString:@"dateTime"] && (fieldValue != field.valueIfNil)) {
		// Get a NSDate from a xml-dateFormat
		NSString *xmlDate = fieldValue;

		// Formats the date depending on the current date. 
		if ([field.formatMask isEqualToString:@"dateOrTimeDependingOnCurrentDate"]) {
			fieldValue = [xmlDate formatDateDependingOnCurrentDate];
		}
		else 
		{
			NSDate *date = [xmlDate dateFromXML];
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setDateFormat:field.formatMask];
			fieldValue = [dateFormatter stringFromDate:date];
		}
	}
	
	else if ((fieldValue != field.valueIfNil) && [field.dataType isEqualToString:@"numberWithTwoDecimals"]) {
		fieldValue = [fieldValue formatNumberWithTwoDecimals];
	}
	else if ((fieldValue != field.valueIfNil) && [field.dataType isEqualToString:@"numberWithThreeDecimals"]) {
		fieldValue = [fieldValue formatNumberWithThreeDecimals];
	}
	else if ((fieldValue != field.valueIfNil) && [field.dataType isEqualToString:@"volume"]) {
		fieldValue = [fieldValue formatVolume];
	}
	else if ((fieldValue != field.valueIfNil) && [field.dataType isEqualToString:@"priceWithTwoDecimals"]) {
		fieldValue = [fieldValue formatPriceWithTwoDecimals];
	}
	else if ((fieldValue != field.valueIfNil) && [field.dataType isEqualToString:@"priceWithThreeDecimals"]) {
		fieldValue = [fieldValue formatPriceWithThreeDecimals];
	}
	else if ((fieldValue != field.valueIfNil) && [field.dataType isEqualToString:@"percentageWithTwoDecimals"]) {
		fieldValue = [fieldValue formatPercentageWithTwoDecimals];
	}
	
	self.value = fieldValue;
}

+(MBMatrixCell *) cellForField:(MBField *)field {
	MBMatrixCell *cell = [[[MBMatrixCell alloc] init] autorelease];
	
	cell.field = field;
	cell.page = [field page];
	
	// make it possible to update the cell appearance without affecting the underlying field:
	cell.width = field.width;
	cell.height = field.height;
	cell.alignment = field.alignment;
	cell.style = field.style;
	cell.hidden = field.hidden;
	[cell updateValue];
	
	return cell;
}

+ (void) fixCellWidths:(NSArray *)cells forViewWidth:(int) viewWidth
{
	int totalCellWidth = 0;
	int cellCount = 0;
	
	for (MBMatrixCell *cell in cells) {
		// Draw only visible cells so hidden must be false
		if (cell.hidden == FALSE) {
			totalCellWidth += [cell width];
			if ([cell width] == 0) cellCount ++;
		}
	}
	
	int restValue = viewWidth - totalCellWidth;
	
	if (restValue > 0 && cellCount > 0) {
		for (MBMatrixCell *cell in cells) {
			if ([cell width] == 0) [cell setWidth:restValue/cellCount];
		}
	}
	
}

@end
