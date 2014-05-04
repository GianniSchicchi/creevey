//Copyright 2005 Dominic Yu. Some rights reserved.
//This work is licensed under the Creative Commons
//Attribution-NonCommercial-ShareAlike License. To view a copy of this
//license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send
//a letter to Creative Commons, 559 Nathan Abbott Way, Stanford,
//California 94305, USA.

//  DYVersChecker.m
//  creevey
//  Created by d on 2005.07.29.

#import "DYVersChecker.h"

@implementation DYVersChecker

- initWithNotify:(BOOL)b {
	if (self = [super init]) {
		notify = b;
		SInt32 v1, v2, v3;
		Gestalt(gestaltSystemVersionMajor,&v1);
		Gestalt(gestaltSystemVersionMinor,&v2);
		Gestalt(gestaltSystemVersionBugFix,&v3);
		NSURLRequest *theRequest
			= [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:
				@"http://blyt.net/cgi-bin/vers.cgi?v=%@&s=%i&t=%i&u=%i",
				[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
				v1, v2, v3]]
							   cachePolicy:NSURLRequestUseProtocolCachePolicy
						   timeoutInterval:60.0];
		NSURLConnection *theConnection
			= [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
		if (theConnection) {
			receivedData = [[NSMutableData data] retain];
		} else {
			if (notify)
				NSRunAlertPanel(nil,NSLocalizedString(@"Could not check for update - unable to connect to server.",@""),nil,nil,nil);
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		responseCode = [httpResponse statusCode];
	}
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}


- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error
{
    [connection release];
    [receivedData release];
    if (notify)
		NSRunAlertPanel(nil,NSLocalizedString(@"Could not check for update - an error occurred while connecting to the server.",@""),nil,nil,nil);
    [self release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// check the HTTP status code and make sure it was successful
	if (responseCode != 200) {
		if (notify)
			NSRunAlertPanel(nil,NSLocalizedString(@"Could not check for update - an error occurred while connecting to the server.",@""),nil,nil,nil);
		return;
	}

	NSString *responseText = [[[NSString alloc] initWithData:receivedData encoding:NSMacOSRomanStringEncoding] autorelease];
	NSScanner *scanner = [NSScanner scannerWithString:responseText];
	[scanner setCharactersToBeSkipped:nil]; // don't skip whitespace
	NSInteger latestBuild = 0;
	// the response should be a number followed by a single space
	if (!([scanner scanInteger:&latestBuild] && [scanner scanString:@" " intoString:NULL] && [scanner isAtEnd]) || latestBuild == 0) {
		if (notify)
			NSRunAlertPanel(nil,NSLocalizedString(@"Could not check for update - an error occurred while connecting to the server.",@""),nil,nil,nil);
		return;
	}
	
	NSInteger currentBuild = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] integerValue];
	if (latestBuild > currentBuild) {
		if (NSRunInformationalAlertPanel([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
										 NSLocalizedString(@"A new version of Phoenix Slides is available.", @""),
										 NSLocalizedString(@"More Info", @""),
										 NSLocalizedString(@"Not Now", @""),nil)
			== NSAlertDefaultReturn)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://blyt.net/phxslides/"]];
	} else if (notify) {
		NSRunInformationalAlertPanel([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
									 NSLocalizedString(@"You have the latest version of Phoenix Slides.", @""),
									 nil,nil,nil);
	}
	[connection release];
    [receivedData release];
	[self release];
}
@end
