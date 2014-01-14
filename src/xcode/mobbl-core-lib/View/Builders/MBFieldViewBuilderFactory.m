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

#import "MBFieldViewBuilderFactory.h"
#import "MBFieldViewBuilder.h"
#import "MBField.h"
#import "MBButtonBuilder.h"
#import "MBInputBuilder.h"
#import "MBLabelBuilder.h"
#import "MBSubLabelBuilder.h"
#import "MBCheckboxBuilder.h"
#import "MBDropDownBuilder.h"
#import "MBDateBuilder.h"
#import "MBTextBuilder.h"
#import <Foundation/Foundation.h>


@interface MBFieldViewBuilderFactory () 
    @property(readonly,nonatomic, retain) NSMutableDictionary *registry;
@end

@implementation MBFieldViewBuilderFactory {
    NSMutableDictionary *_registry;
    MBFieldViewBuilder *_defaultBuilder;
}

@synthesize registry = _registry;
@synthesize defaultBuilder = _defaultBuilder;


- (id)init
{
    self = [super init];
    if (self) {
        _registry = [[NSMutableDictionary dictionary] retain];
        _defaultBuilder = nil;
    }
    
    MBFieldViewBuilder *buttonBuilder = [[MBButtonBuilder alloc]init];
    [self registerFieldViewBuilder:buttonBuilder forFieldType:C_FIELD_BUTTON];
    [buttonBuilder release];
    
    
    MBFieldViewBuilder* inputBuilder = [[MBInputBuilder alloc] init] ;
    [self registerFieldViewBuilder:inputBuilder forFieldType:C_FIELD_INPUT ];
    [self registerFieldViewBuilder:inputBuilder forFieldType:C_FIELD_USERNAME ];
    [self registerFieldViewBuilder:inputBuilder forFieldType:C_FIELD_PASSWORD ];
    [inputBuilder release];
    
    MBFieldViewBuilder* textBuilder = [[MBTextBuilder alloc] init] ;
    [self registerFieldViewBuilder:textBuilder forFieldType:C_FIELD_TEXT ];
        [textBuilder release];
    
    MBFieldViewBuilder* labelBuilder = [[MBLabelBuilder alloc] init] ;
    [self registerFieldViewBuilder:labelBuilder forFieldType:C_FIELD_LABEL];
    [labelBuilder release];
    
    MBFieldViewBuilder* subLabelBuilder = [[MBSubLabelBuilder alloc] init] ;
    [self registerFieldViewBuilder:subLabelBuilder forFieldType:C_FIELD_SUBLABEL];
    [subLabelBuilder release];
    
    MBFieldViewBuilder* checkboxBuilder = [[MBCheckboxBuilder alloc] init] ;
    [self registerFieldViewBuilder:checkboxBuilder forFieldType:C_FIELD_CHECKBOX];
    [checkboxBuilder release];
    
    MBDropDownBuilder *dropDownBuilder = [[MBDropDownBuilder alloc]init];
    [self registerFieldViewBuilder:dropDownBuilder forFieldType:C_FIELD_DROPDOWNLIST];
    [dropDownBuilder release];
    
    MBDateBuilder *dateBuilder = [[MBDateBuilder alloc]init];
    [self registerFieldViewBuilder:dateBuilder forFieldType:C_FIELD_DATETIMESELECTOR];
    [self registerFieldViewBuilder:dateBuilder forFieldType:C_FIELD_TIMESELECTOR];
    [self registerFieldViewBuilder:dateBuilder forFieldType:C_FIELD_DATESELECTOR];
    [self registerFieldViewBuilder:dateBuilder forFieldType:C_FIELD_BIRTHDATE];
    [dateBuilder release];
    
    
    return self;
}

- (void)dealloc
{
    [_registry release];
    [_defaultBuilder release];
    [super dealloc];
}


- (void)registerFieldViewBuilder:(MBFieldViewBuilder*)fieldViewBuilder forFieldType:(NSString*)type  {
    [self registerFieldViewBuilder:fieldViewBuilder forFieldType:type forFieldStyle:nil];
}

- (void)registerFieldViewBuilder:(MBFieldViewBuilder*)fieldViewBuilder forFieldType:(NSString*)type forFieldStyle:(NSString *)style {
    NSMutableDictionary *styleDict = [self.registry valueForKey:type];
    if (!styleDict) {
        
        styleDict = [[NSMutableDictionary dictionary] retain];
        [self.registry setValue:styleDict forKey:type];
        [styleDict release];
    }
    
    [styleDict setObject:fieldViewBuilder forKey:style ? style : [NSNull null]];
   }


- (MBFieldViewBuilder*) builderForType:(NSString *)type withStyle:(NSString*)style {
    NSMutableDictionary *styleDict = [self.registry valueForKey:type];
    if (!styleDict) return self.defaultBuilder;
    
    MBFieldViewBuilder* builder = [styleDict valueForKey:style];
    if (!builder) builder = [styleDict objectForKey:[NSNull null]];
    if (!builder) builder = self.defaultBuilder;
    
    return builder;
 
}


-(UIView*) buildFieldView:(MBField*) field withMaxBounds:(CGRect) bounds {
    MBFieldViewBuilder* builder = [self builderForType:field.type withStyle:field.style];
    if (builder) return [builder buildFieldView:field withMaxBounds:bounds];
    else {
        [NSException raise:@"BuilderNotFound" format:@"No builder found for type %@ and style %@", field.type, field.style];
        return nil;
    }
}

-(UIView *)buildFieldView:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds {
    MBFieldViewBuilder* builder = [self builderForType:field.type withStyle:field.style];
    if (builder) return [builder buildFieldView:field forParent:parent withMaxBounds:bounds];
    else {
        [NSException raise:@"BuilderNotFound" format:@"No builder found for type %@ and style %@", field.type, field.style];
        return nil;
    }
}

- (CGFloat) heightForField:(MBField *)field  forParent:(UIView *)parent withMaxBounds:(CGRect)bounds {
    MBFieldViewBuilder* builder = [self builderForType:field.type withStyle:field.style];
    if (builder) return [builder heightForField:field forParent:parent withMaxBounds:bounds];
    else {
        [NSException raise:@"BuilderNotFound" format:@"No builder found for type %@ and style %@", field.type, field.style];
        return 0;
    }
}

@end
