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

#import "StringUtilitiesHelper.h"
#import "LocaleUtilities.h"

static StringUtilitiesHelper *_instance = nil;

@implementation StringUtilitiesHelper

@synthesize dateFormatterToFormatDateFromXml = _dateFormatterToFormatDateFromXml;
@synthesize dateFormatterToFormatDateDependingOnCurrentDate = _dateFormatterToFormatDateDependingOnCurrentDate;
@synthesize volumeNumberFormatter = _volumeNumberFormatter;
@synthesize priceWithMinimalDecimalsNumberFormatter = _priceWithMinimalDecimalsNumberFormatter;
@synthesize priceWithTwoDecimalsNumberFormatter = _priceWithTwoDecimalsNumberFormatter;
@synthesize priceWithThreeDecimalsNumberFormatter = _priceWithThreeDecimalsNumberFormatter;
@synthesize numberWithOriginalNumberOfDecimalsNumberFormatter = _numberWithOriginalNumberOfDecimalsNumberFormatter;
@synthesize numberWithTwoDecimalsNumberFormatter = _numberWithTwoDecimalsNumberFormatter;
@synthesize numberWithThreeDecimalsNumberFormatter = _numberWithThreeDecimalsNumberFormatter;

+ (void) createInstance {
	@synchronized(self) {
		if(_instance == nil) {
			_instance = [[self alloc] init];
		}
	}	
}

- (id) init {
	if (self =[super init]) {
		
		NSString *decimalSeparator = [[NSLocale currentLocale] getDecimalSeparator];
		NSString *groupingSeparator = [[NSLocale currentLocale] getGroupingSeparator];
		
		// XML date formatter
		self.dateFormatterToFormatDateFromXml = [[[NSDateFormatter alloc] init] autorelease];
		[self.dateFormatterToFormatDateFromXml setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];

		// Date or time date formatter
		self.dateFormatterToFormatDateDependingOnCurrentDate = [[[NSDateFormatter alloc] init] autorelease];

        //
        // Financial number formatters
        //
        
		// Volume
		self.volumeNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.volumeNumberFormatter setUsesGroupingSeparator:YES];
		[self.volumeNumberFormatter setDecimalSeparator:decimalSeparator]; 
		[self.volumeNumberFormatter setGroupingSeparator:groupingSeparator]; 
		[self.volumeNumberFormatter setGroupingSize:3];
		
		// Price with minimal decimals
		self.priceWithMinimalDecimalsNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.priceWithMinimalDecimalsNumberFormatter setMinimumIntegerDigits:1];
		[self.priceWithMinimalDecimalsNumberFormatter setMaximumFractionDigits:3];
		[self.priceWithMinimalDecimalsNumberFormatter setMinimumFractionDigits:0];
		[self.priceWithMinimalDecimalsNumberFormatter setUsesGroupingSeparator:YES];
		[self.priceWithMinimalDecimalsNumberFormatter setGroupingSize:3];
		[self.priceWithMinimalDecimalsNumberFormatter setDecimalSeparator:decimalSeparator]; 
		[self.priceWithMinimalDecimalsNumberFormatter setGroupingSeparator:groupingSeparator]; 
		
		// Price with two decimals
		self.priceWithTwoDecimalsNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.priceWithTwoDecimalsNumberFormatter setMinimumIntegerDigits:1];
		[self.priceWithTwoDecimalsNumberFormatter setMaximumFractionDigits:2];
		[self.priceWithTwoDecimalsNumberFormatter setMinimumFractionDigits:2];
		[self.priceWithTwoDecimalsNumberFormatter setUsesGroupingSeparator:YES];
		[self.priceWithTwoDecimalsNumberFormatter setGroupingSize:3];
		[self.priceWithTwoDecimalsNumberFormatter setDecimalSeparator:decimalSeparator]; 
		[self.priceWithTwoDecimalsNumberFormatter setGroupingSeparator:groupingSeparator]; 
		
		// Price with trhee decimals
		self.priceWithThreeDecimalsNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.priceWithThreeDecimalsNumberFormatter setMinimumIntegerDigits:1];
		[self.priceWithThreeDecimalsNumberFormatter setMaximumFractionDigits:3];
		[self.priceWithThreeDecimalsNumberFormatter setMinimumFractionDigits:3];
		[self.priceWithThreeDecimalsNumberFormatter setUsesGroupingSeparator:YES];
		[self.priceWithThreeDecimalsNumberFormatter setGroupingSize:3];
		[self.priceWithThreeDecimalsNumberFormatter setDecimalSeparator:decimalSeparator]; 
		[self.priceWithThreeDecimalsNumberFormatter setGroupingSeparator:groupingSeparator]; 
		
		// Number with original number of decimals
		self.numberWithOriginalNumberOfDecimalsNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.numberWithOriginalNumberOfDecimalsNumberFormatter setMinimumIntegerDigits:1];
        [self.numberWithOriginalNumberOfDecimalsNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[self.numberWithOriginalNumberOfDecimalsNumberFormatter setGeneratesDecimalNumbers:YES];
		//[self.numberWithOriginalNumberOfDecimalsNumberFormatter setMinimumFractionDigits:3];
		//[self.numberWithOriginalNumberOfDecimalsNumberFormatter setMaximumFractionDigits:3];
		[self.numberWithOriginalNumberOfDecimalsNumberFormatter setUsesGroupingSeparator:NO];
		[self.numberWithOriginalNumberOfDecimalsNumberFormatter setDecimalSeparator:decimalSeparator]; 
		
		// Number with two decimals
		self.numberWithTwoDecimalsNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.numberWithTwoDecimalsNumberFormatter setMinimumIntegerDigits:1];
		[self.numberWithTwoDecimalsNumberFormatter setMaximumFractionDigits:2];
		[self.numberWithTwoDecimalsNumberFormatter setUsesGroupingSeparator:YES];
		[self.numberWithTwoDecimalsNumberFormatter setDecimalSeparator:decimalSeparator]; 
		[self.numberWithTwoDecimalsNumberFormatter setGroupingSeparator:groupingSeparator]; 
		[self.numberWithTwoDecimalsNumberFormatter setGroupingSize:3];
		
		// Number with three decimals
		self.numberWithThreeDecimalsNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.numberWithThreeDecimalsNumberFormatter setMinimumIntegerDigits:1];
		[self.numberWithThreeDecimalsNumberFormatter setMaximumFractionDigits:3];
		[self.numberWithThreeDecimalsNumberFormatter setUsesGroupingSeparator:YES];
		[self.numberWithThreeDecimalsNumberFormatter setDecimalSeparator:decimalSeparator]; 
		[self.numberWithThreeDecimalsNumberFormatter setGroupingSeparator:groupingSeparator]; 
		[self.numberWithThreeDecimalsNumberFormatter setGroupingSize:3];

	}
	return self;
}


- (void) dealloc
{
	[_dateFormatterToFormatDateFromXml release];
	[_dateFormatterToFormatDateDependingOnCurrentDate release];
	[_volumeNumberFormatter release];
	[_priceWithMinimalDecimalsNumberFormatter release];
	[_priceWithTwoDecimalsNumberFormatter release];
	[_priceWithThreeDecimalsNumberFormatter release];
	[_numberWithOriginalNumberOfDecimalsNumberFormatter release];
	[_numberWithTwoDecimalsNumberFormatter release];
	[_numberWithThreeDecimalsNumberFormatter release];
	[super dealloc];
}


#pragma mark -
#pragma mark Getters

+ (NSDateFormatter *)dateFormatterToFormatDateFromXml {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = [threadDictionary objectForKey: @"DateFromXmlDateFormatter"];
    if (dateFormatter == nil)
    {
		dateFormatter = [[[_instance dateFormatterToFormatDateFromXml] copy] autorelease];
		[threadDictionary setObject: dateFormatter forKey: @"DateFromXmlDateFormatter"];
    }
    return dateFormatter;
}

+ (NSDateFormatter *)dateFormatterToFormatDateDependingOnCurrentDate{
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = [threadDictionary objectForKey: @"DateDependingOnDateDateFormatter"];
    if (dateFormatter == nil)
    {
		dateFormatter = [[[_instance dateFormatterToFormatDateDependingOnCurrentDate] copy] autorelease];
		[threadDictionary setObject: dateFormatter forKey: @"DateDependingOnDateDateFormatter"];
    }
    return dateFormatter;
}

+ (NSNumberFormatter *)numberFormatterToFormatPriceWithMinimalDecimals {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSNumberFormatter *numberFormatter = [threadDictionary objectForKey: @"priceWithMinimalDecimalsNumberFormatter"];
    if (numberFormatter == nil)
    {
		numberFormatter = [[[_instance priceWithMinimalDecimalsNumberFormatter] copy] autorelease];
		[threadDictionary setObject: numberFormatter forKey: @"priceWithMinimalDecimalsNumberFormatter"];
    }
    return numberFormatter;
}

+ (NSNumberFormatter *)numberFormatterToFormatPriceWithTwoDecimals {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSNumberFormatter *numberFormatter = [threadDictionary objectForKey: @"priceWithTwoDecimalsNumberFormatter"];
    if (numberFormatter == nil)
    {
		numberFormatter = [[[_instance priceWithTwoDecimalsNumberFormatter] copy] autorelease];
		[threadDictionary setObject: numberFormatter forKey: @"priceWithTwoDecimalsNumberFormatter"];
    }
    return numberFormatter;
}

+ (NSNumberFormatter *)numberFormatterToFormatPriceWithThreeDecimals {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSNumberFormatter *numberFormatter = [threadDictionary objectForKey: @"priceWithThreeDecimalsNumberFormatter"];
    if (numberFormatter == nil)
    {
		numberFormatter = [[[_instance priceWithThreeDecimalsNumberFormatter] copy] autorelease];
		[threadDictionary setObject: numberFormatter forKey: @"priceWithThreeDecimalsNumberFormatter"];
    }
    return numberFormatter;
}

+ (NSNumberFormatter *)numberFormatterToFormatVolume {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSNumberFormatter *numberFormatter = [threadDictionary objectForKey: @"volumeNumberFormatter"];
    if (numberFormatter == nil)
    {
		numberFormatter = [[[_instance volumeNumberFormatter] copy] autorelease];
		[threadDictionary setObject: numberFormatter forKey: @"volumeNumberFormatter"];
    }
    return numberFormatter;
}

+ (NSNumberFormatter *)numberFormatterToFormatNumberWithOriginalNumberOfDecimals {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSNumberFormatter *numberFormatter = [threadDictionary objectForKey: @"numberWithOriginalNumberOfDecimalsNumberFormatter"];
    if (numberFormatter == nil)
    {
		numberFormatter = [[[_instance numberWithOriginalNumberOfDecimalsNumberFormatter] copy] autorelease];
		[threadDictionary setObject: numberFormatter forKey: @"numberWithOriginalNumberOfDecimalsNumberFormatter"];
	}
    return numberFormatter;
}

+ (NSNumberFormatter *)numberFormatterToFormatNumberWithTwoDecimals {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSNumberFormatter *numberFormatter = [threadDictionary objectForKey: @"numberWithTwoDecimalsNumberFormatter"];
    if (numberFormatter == nil)
    {
		numberFormatter = [[[_instance numberWithTwoDecimalsNumberFormatter] copy] autorelease];
		[threadDictionary setObject: numberFormatter forKey: @"numberWithTwoDecimalsNumberFormatter"];
    }
    return numberFormatter;
}

+ (NSNumberFormatter *)numberFormatterToFormatNumberWithThreeDecimals {
	
	// To make it threadSafe, create a formatter for each thread that is calling this method
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSNumberFormatter *numberFormatter = [threadDictionary objectForKey: @"numberWithThreeDecimalsNumberFormatter"];
    if (numberFormatter == nil)
    {
		numberFormatter = [[[_instance numberWithThreeDecimalsNumberFormatter] copy] autorelease];
		[threadDictionary setObject: numberFormatter forKey: @"numberWithThreeDecimalsNumberFormatter"];
    }
    return numberFormatter;
}

@end
