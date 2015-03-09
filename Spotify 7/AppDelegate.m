// TutorialApp
// Created by Spotify on 04/09/14.
// Copyright (c) 2014 Spotify. All rights reserved.

// Import Spotify API header file
#import <Spotify/Spotify.h>
#import "AppDelegate.h"

// Constants
static NSString * const kClientId = @"40ac927645d64a6da53521bb6287db19";
static NSString * const kCallbackURL = @"spotifytutorial://returnAfterLogin";
static NSString * const kTokenSwapServiceURL = @"https://hidden-hollows-1983.herokuapp.com/swap";

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Create SPTAuth instance; create login URL and open it
    SPTAuth *auth = [SPTAuth defaultInstance];
    NSURL *loginURL = [auth loginURLForClientId:kClientId
                            declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                                         scopes:@[SPTAuthStreamingScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistReadPrivateScope]];
    
    // Opening a URL in Safari close to application launch may trigger
    // an iOS bug, so we wait a bit before doing so.
    [application performSelector:@selector(openURL:)
                      withObject:loginURL afterDelay:0.1];
    
    return YES;
}

// Handle auth callback
-(BOOL)application:(UIApplication *)application
           openURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation {
    
    // Ask SPTAuth if the URL given is a Spotify authentication callback
    if ([[SPTAuth defaultInstance]
         canHandleURL:url
         withDeclaredRedirectURL:[NSURL URLWithString:kCallbackURL]]) {
        
        // Call the token swap service to get a logged in session
        [[SPTAuth defaultInstance]
         handleAuthCallbackWithTriggeredAuthURL:url
         tokenSwapServiceEndpointAtURL:[NSURL URLWithString:kTokenSwapServiceURL]
         callback:^(NSError *error, SPTSession *session) {
             
             if (error != nil) {
                 NSLog(@"*** Auth error: %@", error);
                 return;
             }
             
             NSDictionary *aDict=[NSDictionary dictionaryWithObject:session forKey:@"SpotifySession"];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccessful" object:Nil userInfo:aDict];
             
        }];
        return YES;
    }
    
    return NO;
}

@end