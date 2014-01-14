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

#import <Foundation/Foundation.h>

@class MBField;
@class MBFieldViewBuilder;

@interface MBFieldViewBuilderFactory : NSObject

- (void)registerFieldViewBuilder:(MBFieldViewBuilder*)fieldViewBuilder forFieldType:(NSString*)type forFieldStyle:(NSString *)style;
- (void)registerFieldViewBuilder:(MBFieldViewBuilder*)fieldViewBuilder forFieldType:(NSString*)type;

@property (nonatomic, retain) MBFieldViewBuilder *defaultBuilder;
- (MBFieldViewBuilder*)builderForType:(NSString *)type withStyle:(NSString*)style;

- (UIView*) buildFieldView:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds;
- (CGFloat) heightForField:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds;

@end
