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

#import "MBViewBuilder.h"
#import "MBFieldTypes.h"
@class MBField;

@interface MBFieldViewBuilder : MBViewBuilder
-(UIView*) buildFieldView:(MBField *)field withMaxBounds:(CGRect)bounds;
-(UIView*) buildFieldView:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds;
-(UIView*) buildFieldView:(MBField *)field forTableCell:(UITableViewCell *)cell withMaxBounds:(CGRect)bounds;
-(CGFloat) heightForField:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds;
@end
