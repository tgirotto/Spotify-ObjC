//
//  ViewController.m
//  Spotify 7
//
//  Created by Tommaso on 5/3/15.
//  Copyright (c) 2015 Tommaso. All rights reserved.
//

#import "ViewController.h"
#import <Spotify/Spotify.h>

@interface ViewController ()

@end

@implementation ViewController

SPTSession *session;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additiona  l setup after loading the view, typically from a nib.
    
    //session = [[NSUserDefaults standardUserDefaults]objectForKey:@"SpotifySession"];
    
    NSLog(@"here we are");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createButton:(id)sender {
    NSLog(@"pressed button");
}

@end
