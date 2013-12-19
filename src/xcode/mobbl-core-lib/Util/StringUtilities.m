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

#import "StringUtilities.h"
#import "StringUtilitiesHelper.h"
#import "LocaleUtilities.h"
#import "MBLocalizationService.h"


@implementation NSString(StringUtilities)

- (NSComparisonResult)compareInt:(NSString *)other {
	int result = [self intValue] - [other intValue];
	if(result < 0) return NSOrderedDescending;
	if(result == 0) return NSOrderedSame;
	return NSOrderedAscending;
}

- (NSComparisonResult)compareDouble:(NSString *)other {
	double result = [self doubleValue] - [other doubleValue];
	if(result < 0) return NSOrderedDescending;
	if(result == 0) return NSOrderedSame;
	return NSOrderedAscending;
}

- (NSComparisonResult)compareFloat:(NSString *)other {
	float result = [self floatValue] - [other floatValue];
	if(result < 0) return NSOrderedDescending;
	if(result == 0) return NSOrderedSame;
	return NSOrderedAscending;
}

- (NSComparisonResult)compareBoolean:(NSString *)other {
	if([self boolValue] && [other boolValue]) return NSOrderedSame;
	if([self boolValue]) return NSOrderedAscending;
	return NSOrderedDescending;
}

- (NSNumber*) asNumber {
	return [NSNumber numberWithInt:[self intValue]];
}

-(NSString*) stripCharacters:(NSString*) characters {
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSString *subPart;
	NSMutableString *stripped = [NSMutableString stringWithString:@""];
	NSCharacterSet *stripSet = [NSCharacterSet characterSetWithCharactersInString:characters];
	NSCharacterSet *set = [stripSet invertedSet];

	while([scanner scanUpToCharactersFromSet:stripSet intoString:&subPart]) {
		[stripped appendString:subPart];
		[scanner scanUpToCharactersFromSet:set intoString:&subPart];
	}
	return stripped;
}

- (NSMutableArray*) splitPath {
	
	NSMutableArray *components = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray *pathComponents = [self pathComponents];
	for(NSString *component in pathComponents) {
		if([component isEqualToString:@"/"] || [component isEqualToString:@"."] || [component isEqualToString:@""]) {
			// skip
     	}
		else if([component isEqualToString:@".."]) {
			if([components count] == 0) @throw [NSException exceptionWithName: @"InvalidRelativePath" reason:self userInfo:nil];
			[components removeLastObject];
		}
		else {
			[components addObject:component];
		}
	}	  
	return components;
}	

- (NSString*) normalizedPath {
	
	BOOL isRelative = ![self hasPrefix:@"/"];
	
	NSMutableString *result = [NSMutableString stringWithString:@""];

	// try to prevent work in the normal case (the path is already normalized)
	// especially the splitPath method-call is expensive.
	NSRange dotRange = [self rangeOfString: @"."];
	NSRange slashRange = [self rangeOfString:@"//"];
	// Only normalize the path if a dot (.) or double slashes (//) are found
	if (dotRange.location != NSNotFound || slashRange.location != NSNotFound) {
		NSMutableArray *splittedPath = [self splitPath];
		for(NSString *component in splittedPath) {
			[result appendFormat:@"/%@", component];
		}
	}
	else {
		[result appendFormat:@"%@", self];
	}


	if(isRelative && [result hasPrefix:@"/"]) return  [result substringFromIndex:1];	
	else return result;
}

// create a date assuming the receiver is a date string read from XML
- (NSDate *)dateFromXML
{
	NSDate *date = nil;
    if ([self length] > 0) {
        NSString *dateString = [self substringToIndex:19];
        if (dateString) { 
            NSDateFormatter *dateFormatter = [StringUtilitiesHelper dateFormatterToFormatDateFromXml]; // Added for optimization: The dateformatter in the StringUtilitiesHelper is reused all the time. Otherwise a new one would have to be created which is costly in time.
            date = [dateFormatter dateFromString:dateString];
            //NSLog(@"dateString=%@, dateFormatter=%@, date=%@",dateString,dateFormatter,date);
        }
    }
	return date;
}	

// returns a string formatted as a number with the original amount of decimals assuming the receiver is a float 
// WARNING: Only use this method to present data to the screen
- (NSString *)formatNumberWithOriginalNumberOfDecimals
{
	NSString * result = nil;
	
	if (self && self.length > 0) {
		double doubleValue = [self doubleValue];
		NSNumber * priceNumber = [NSNumber numberWithDouble:doubleValue];
		NSNumberFormatter * nf = [StringUtilitiesHelper numberFormatterToFormatNumberWithOriginalNumberOfDecimals];
		result = [nf stringFromNumber:priceNumber];
	}

	return result;
}	

// returns a string formatted as a price with zero or max 3 decimals
// used to display neat graph data 10K, 10,1K etc.
- (NSString *)formatPriceWithMinimalDecimals
{
	NSString * result = nil;
	
	if (self && self.length > 0) {
		NSNumber * priceNumber = [NSNumber numberWithDouble:[self doubleValue]];
		NSNumberFormatter * nf = [StringUtilitiesHelper numberFormatterToFormatPriceWithMinimalDecimals];
		result = [nf stringFromNumber:priceNumber];
	}

	return result;
}	

// returns a string formatted as a price with two decimals assuming the receiver is a float string read from XML
// WARNING: Only use this method to present data to the screen 
- (NSString *)formatPriceWithTwoDecimals
{
	NSString * result = nil;

	if (self && self.length > 0) {
		NSNumber * priceNumber = [NSNumber numberWithDouble:[self doubleValue]];
		NSNumberFormatter * nf = [StringUtilitiesHelper numberFormatterToFormatPriceWithTwoDecimals];
		result = [nf stringFromNumber:priceNumber];
	}

	return result;
}	

// returns a string formatted as a price with three decimals assuming the receiver is a float string read from XML
// WARNING: Only use this method to present data to the screen 
- (NSString *)formatPriceWithThreeDecimals
{
	NSString * result = nil;
		
	if (self && self.length > 0) {
		NSNumber * priceNumber = [NSNumber numberWithDouble:[self doubleValue]];
		NSNumberFormatter * nf = [StringUtilitiesHelper numberFormatterToFormatPriceWithThreeDecimals];
		result = [nf stringFromNumber:priceNumber];
	}

	return result;
}	


// returns a string formatted as a number with two decimals assuming the receiver is a float string read from XML
// WARNING: Only use this method to present data to the screen 
- (NSString *)formatNumberWithTwoDecimals
{
	NSString * result = nil;
	
	if (self && self.length > 0) {
		NSNumber * priceNumber = [NSNumber numberWithDouble:[self doubleValue]];
		NSNumberFormatter * nf = [StringUtilitiesHelper numberFormatterToFormatNumberWithTwoDecimals];
		result = [nf stringFromNumber:priceNumber];
	}
	
	return result;
}	

// returns a string formatted as a number with three decimals assuming the receiver is a float string read from XML
// WARNING: Only use this method to present data to the screen 
- (NSString *)formatNumberWithThreeDecimals
{
	NSString * result = nil;
	
	
	if (self && self.length > 0) {
		NSNumber * priceNumber = [NSNumber numberWithDouble:[self doubleValue]];
		NSNumberFormatter * nf = [StringUtilitiesHelper numberFormatterToFormatNumberWithThreeDecimals];
		result = [nf stringFromNumber:priceNumber];
	}
	
	return result;
}	

// returns a string formatted as a percentage with two decimals assuming the receiver is a float string read from XML
// the receiver's value should be "as displayed", eg for 30%, the receiver should be 30, not 0.3
- (NSString *)formatPercentageWithTwoDecimals
{
	NSString * result;
	
	result = [self formatPriceWithTwoDecimals];
	result = [result stringByAppendingString:@"%"];
	
	return result;
}	

// returns a string formatted as a volume with group separators (eg, 131.224.000) assuming the receiver is an int string read from XML
// WARNING: Only use this method to present data to the screen 
- (NSString *)formatVolume
{
	NSNumberFormatter * volumeFormatter = [StringUtilitiesHelper numberFormatterToFormatVolume];
	NSString *result = [volumeFormatter stringFromNumber:[NSNumber numberWithInt:[self intValue]]];
	
	return result;
}

// Formats the date depending on the current date assuming the receiver is a date string 
// If the date is equal to the current date, the time is given back as a string
// If the date is NOT equal to the current date, then a a date is presented back as a string
- (NSString *)formatDateDependingOnCurrentDate
{
	NSString *result = self;
	NSDate *date = [result dateFromXML];
	
	
	NSString *dateFormatMask = @"";
	
	// We can't just compare two dates, because the time is also compared.
	// Therefore the time is removed and the two dates without time are compared
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *compareDateComponents = [calendar components:( NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit ) fromDate:date];
	NSDateComponents *currentDateComponents = [calendar components:( NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit ) fromDate:[NSDate date]];
	
	NSDate *compareDate = [calendar dateFromComponents:compareDateComponents];
	NSDate *currentDate = [calendar dateFromComponents:currentDateComponents];
	
	if ([compareDate isEqualToDate:currentDate]) dateFormatMask = @"HH:mm:ss";
	else
    {
        
        NSString *localeCode = [[MBLocalizationService sharedInstance] localeCode];
        //NSString *localeSettings = [MBProperties valueForProperty:@"localeSettings"];
        if ([localeCode isEqualToString:LOCALECODEITALIAN]) dateFormatMask = @"dd/MM/yy";
        else                                                dateFormatMask = @"dd-MM-yy";
    }
	
	// Format the date
	NSDateFormatter *dateFormatter = [StringUtilitiesHelper dateFormatterToFormatDateDependingOnCurrentDate];
	[dateFormatter setDateFormat:dateFormatMask];
	result = [dateFormatter stringFromDate:date];
	
	return result;
}

// returns a string stripped of all HTML tags from the receiver
- (NSString *)stripHTMLTags
{
	NSScanner * scanner = [NSScanner scannerWithString:self];
    NSMutableString * result = [NSMutableString stringWithCapacity:[self length]];
	NSString * partial = nil;
	
    while (![scanner isAtEnd]) {
		
		// are we on an open tag?
		if ([scanner scanString:@"<" intoString:nil]) {

			// skip to end of tag
			[scanner scanUpToString:@">" intoString:nil];
			[scanner scanString:@">" intoString:nil];
			
		} else if ([scanner scanUpToString:@"<" intoString:&partial]) {
			// scan for open tag

			[result appendString:partial];

			// skip to end of tag
			[scanner scanUpToString:@">" intoString:nil];
			[scanner scanString:@">" intoString:nil];
			
		} else {
		
			// last partial of receiver after last tag
			[result appendString:partial];
			
		}
		
    }
    
    return result;
}

// XML Encoding
- (NSString *)xmlSimpleEscape {
	self = [[[[[self stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"] stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"] stringByReplacingOccurrencesOfString: @"'" withString: @"&#39;"] stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"] stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];
	return self;
}

-(BOOL) hasHTML {
    BOOL result = NO;
    NSString * lowercaseText = [self lowercaseString];
    NSRange found = [lowercaseText rangeOfString:@"<html>"];
    if (found.location != NSNotFound) result = YES;

    found = [lowercaseText rangeOfString:@"<body>"];
    if (found.location != NSNotFound) result = YES;

    found = [lowercaseText rangeOfString:@"<b>"];
    if (found.location != NSNotFound) result = YES;

    found = [lowercaseText rangeOfString:@"<br>"];
    if (found.location != NSNotFound) result = YES;

    return result;
}

@end
