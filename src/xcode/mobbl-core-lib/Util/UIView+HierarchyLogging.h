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

@interface UIView (ViewHierarchyLogging)
- (void)logViewHierarchy;
- (void)logViewHierarchy:(int)index;
@end

// UIView+HierarchyLogging.m
@implementation UIView (ViewHierarchyLogging)
- (void)logViewHierarchy
{
    NSLog(@"LEVEL:0---%@", self);
    for (UIView *subview in self.subviews)
    {
        [subview logViewHierarchy:0];
    }
}

- (void)logViewHierarchy:(int)index
{
    NSString *level = [NSString stringWithFormat:@"%d---", index];
    for (int i=0; i<index; i++) level = [level stringByAppendingString:@"---"];
    NSLog(@"LEVEL:%@%@", level, self);
    for (UIView *subview in self.subviews)
    {
        [subview logViewHierarchy:index+1];
    }
}
@end

