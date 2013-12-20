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

#import "MBMacros.h"
#import "MBResourceService.h"
#import "DataUtilites.h"
#import "MBResourceConfigurationParser.h"
#import "MBResourceDefinition.h"
#import "MBCacheManager.h"
#import "MBDocumentFactory.h"
#import "MBConfigurationDefinition.h"
#import "MBBundleDefinition.h"
#import "MBMetadataService.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static MBResourceService *_instance = nil;

@implementation MBResourceService

@synthesize config = _config;

+(MBResourceService *) sharedInstance {
	@synchronized(self) {
		if(_instance == nil) {
			_instance = [[self alloc] init];
			
			MBResourceConfigurationParser *parser = [[MBResourceConfigurationParser alloc]init];
			NSData *data = [NSData dataWithEncodedContentsOfMainBundle: RESOURCE_CONFIG_FILE_NAME];
			
			// Never read??
			//NSString *resourceXml = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			_instance.config = [parser parseData:data ofDocument: RESOURCE_CONFIG_FILE_NAME];
			[parser release];
		}
	}
	return _instance;
}

- (void) dealloc
{
	[_config release];
	[super dealloc];
}


// Returns the resourceDefinition for a resourceId
- (MBResourceDefinition *)resourceDefinitionByID:(NSString *) resourceId {
    MBResourceDefinition *def = [_config getResourceWithID:resourceId];
	if(def == nil) @throw [NSException exceptionWithName:@"ResourceNotDefined" reason:resourceId userInfo:nil];
    return def;
}

// Returns a NSData object for the resourceId
- (NSData*) resourceByID:(NSString*) resourceId {
    MBResourceDefinition *def = [self resourceDefinitionByID:resourceId];    
	return [self resourceByURL: def.url cacheable: def.cacheable timeToLive: def.ttl];
}

// Returns an UIImage for a resourceId
- (UIImage *) imageByID:(NSString*) resourceId {

    if (resourceId.length == 0) {
        return nil;
    }
    
    UIImage *result = nil;
    
    // Images can have high resolution versions, which are not fetched when the image is retrieved with NSData
    // The iOS framework automaticly returns high res images when it needs to when an image is created trough [UIImage imageNamed:@"..."]
    // That's the reason we try that first. IF it fails, we try the framework way
    MBResourceDefinition *def = [self resourceDefinitionByID:resourceId];
    NSString *urlString = def.url;
    if ([urlString hasSuffix:@".png"]) {
        NSString *fileName = [urlString substringFromIndex:7];
        result = [UIImage imageNamed:fileName];
    }
    
    // If fetching the image trough the regular way failed, return the resourceId
    if (result == nil) {
        NSData *bytes = [self resourceByID:resourceId];
        if(bytes == nil) {
            WLog(@"Unable to locate resource for image with id=%@", resourceId);
            return nil;
        }
        result = [UIImage imageWithData:bytes];
        
    }
    return result;
    
}

// Plays a audiofile from a resourceId
- (void)playAudioByID:(NSString*) resourceId {
    MBResourceDefinition *def = [self resourceDefinitionByID:resourceId];
    NSURL *soundFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], [def.url substringFromIndex:7]]];
    AVAudioPlayer *player = [[[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil] autorelease];
    [player play];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [player release];
}

- (NSData*) doGetResourceByURL:(NSString*) urlString {
	if([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
        
        NSURL *url = [NSURL URLWithString:urlString];
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
        
		if(data == nil) {
			WLog(@"Warning: could not load data for URL=%@ error=%@ ", urlString, [error description]);
		}
		return data;
	}
    NSString *msg = [NSString stringWithFormat: @"Unsupported protocol; cannot handle %@", urlString];
	@throw [NSException exceptionWithName:@"UnsupportedProcol" reason:msg userInfo:nil];
}

- (NSData*) resourceByURL:(NSString*) urlString{
	return [self resourceByURL:urlString cacheable:FALSE timeToLive:0];
}

- (NSData*) resourceByURL:(NSString*) urlString cacheable:(BOOL) cacheable timeToLive:(int) ttl{
    
	if([urlString hasPrefix:@"file://"]) {
		NSString *fileName = [urlString substringFromIndex:7];
		NSData *data = [NSData dataWithEncodedContentsOfMainBundle:fileName];
		if(data == nil) {
			WLog(@"Warning: could not load file=%@ based on URL=%@", fileName, urlString);
		}
		return data;
	}
    
    if(cacheable) {
        NSData *data = [MBCacheManager dataForKey: urlString];
        if(data != nil) {
          return data;  
        } 
    }

    NSData *data = [self doGetResourceByURL: urlString];
    if(data != nil && cacheable) {
        [MBCacheManager setData: data forKey: urlString timeToLive: ttl];
    }
    return data;
}

- (NSArray*) bundlesForLanguageCode:(NSString*) languageCode {
	NSMutableArray *result = [NSMutableArray array];
	
	NSArray *bundleDefs = [_config bundlesForLanguageCode:languageCode];	
	if(bundleDefs == nil) {
		NSString *msg = [NSString stringWithFormat: @"No bundles defined for language with code %@", languageCode];
		@throw [NSException exceptionWithName:@"BundleNotFound" reason:msg userInfo:nil];
	}
	
	for(MBBundleDefinition *def in bundleDefs) {
		NSData *data = [self resourceByURL: def.url];
		if(data == nil) {
			NSString *msg = [NSString stringWithFormat: @"Bundle with url %@ could not be loaded", def.url];
			@throw [NSException exceptionWithName:@"BundleNotFound" reason:msg userInfo:nil];
		}
		MBDocument *bundleDoc =  [[MBDocumentFactory sharedInstance] documentWithData: data 
																			 withType: PARSER_XML
																		andDefinition:[[MBMetadataService sharedInstance] definitionForDocumentName: DOC_SYSTEM_LANGUAGE]];
		NSMutableDictionary *dict = [[NSMutableDictionary new] autorelease];
		[result addObject:dict];
		for(MBElement *text in [bundleDoc valueForPath:@"/Text"]) {
			[dict setValue: [text valueForAttribute:@"value"] forKey:[text valueForAttribute:@"key"]];
		}
		
	}
	return result;
}


@end