/*
 * (C) Copyright ItudeMobile.
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

#pragma mark -
#pragma mark MBFontCustomizerDelegate

@protocol MBFontCustomizerDelegate <NSObject>
@required
-(void)fontsizeIncreased:(id)sender;
-(void)fontsizeDecreased:(id)sender;
@end


#pragma mark -
#pragma mark MBFontCustomizer interface

@interface MBFontCustomizer : NSObject

- (void) addToViewController:(UIViewController<MBFontCustomizerDelegate> *)viewController animated:(BOOL)animated;

@end

