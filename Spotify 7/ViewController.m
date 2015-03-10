//
//  ViewController.m
//  Spotify 7
//
//  Created by Tommaso on 5/3/15.
//  Copyright (c) 2015 Tommaso. All rights reserved.
//

#import "ViewController.h"
#import <Spotify/Spotify.h>

// Constants
static NSString * const kClientId = @"40ac927645d64a6da53521bb6287db19";
static NSString * const kCallbackURL = @"spotifytutorial://returnAfterLogin";
static NSString * const kTokenSwapServiceURL = @"https://hidden-hollows-1983.herokuapp.com/swap";

@interface ViewController ()
@property (nonatomic, readwrite) SPTAudioStreamingController *player;

@end

@implementation ViewController

SPTSession *session;
NSArray *tableData;

@synthesize playlistName;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additiona  l setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LoadRequestFromAppDel:) name:@"loginSuccessful" object:Nil];
    [self loadPlalylists:session];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createButton:(id)sender {
    [self createPlaylist:session andName:self.playlistName.text];
    //[self getTrackUri:session andName:self.playlistName.text];
}

-(void)LoadRequestFromAppDel:(NSNotification*)aNotif
{
    session=[[aNotif userInfo] objectForKey:@"SpotifySession"];
    //[self playUsingSession:session];
}

-(void)loadPlalylists:(SPTSession *)session {
    tableData = [NSArray arrayWithObjects:@"Egg Benedict", @"Mushroom Risotto", @"Full Breakfast", @"Hamburger", @"Ham and Egg Sandwich", @"Creme Brelee", @"White Chocolate Donut", @"Starbucks Coffee", @"Vegetable Curry", @"Instant Noodle with Egg", @"Noodle with BBQ Pork", @"Japanese Noodle with Pork", @"Green Tea", @"Thai Shrimp Cake", @"Angry Birds Cake", @"Ham and Cheese Panini", nil];
}

-(void)playUsingSession:(SPTSession *)session {
    
    // Create a new player if needed
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:kClientId];
    }
    
    [self.player loginWithSession:session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        
        [SPTRequest requestItemAtURI:[NSURL URLWithString:@"spotify:track:1ec6IDtSwq5rJdCog7GDZz"]
                         withSession:nil
                            callback:^(NSError *error, SPTAlbum *album) {
                                
                                if (error != nil) {
                                    NSLog(@"*** Album lookup got error %@", error);
                                    return;
                                }
                                [self.player playTrackProvider:album callback:nil];
                            }];
    }];
}

-(void) getTrackUri:(SPTSession *)session andName:(NSString *)name {
    [SPTRequest requestItemAtURI:[NSURL URLWithString:@"spotify:track:1ec6IDtSwq5rJdCog7GDZz"]
                     withSession:nil
                        callback:^(NSError *error, SPTAlbum *album) {
                            if (error != nil) {
                                NSLog(@"*** Album lookup got error %@", error);
                                return;
                            }
    }];
}

-(void) createPlaylist: (SPTSession *)session andName:(NSString *)name {
    //SPTPlaylistList *list = [[SPTPlaylistList] init];
    SPTPlaylistList *playlist = [[SPTPlaylistList alloc] init];
    
    [playlist createPlaylistWithName:name publicFlag:1 session:session callback:^(NSError *error, SPTPlaylistSnapshot *playlist) {
        if (error != nil) {
            NSLog(@"An error occurred");
        }
        
        [SPTRequest performSearchWithQuery:name queryType:SPTQueryTypeTrack offset:0 session:session callback:^(NSError *error, id object) {
            if (error != nil) {
                NSLog(@"An error occurred");
            }
            
            SPTListPage *list = object;
            SPTPartialTrack *partialTrack = list.items.firstObject;
            
            if(partialTrack != nil) {
                [SPTRequest requestItemFromPartialObject:partialTrack withSession:session callback:^(NSError *error, id object) {
                    if(error != nil) {
                        NSLog(@"An error occurred");
                    }
                    
                    SPTTrack *track = object;
                    NSArray *tracks = [NSArray arrayWithObjects:track, nil];
                    
                    [playlist addTracksToPlaylist:tracks withSession:session callback:^(NSError *error) {
                        if (error != nil) {
                            NSLog(@"An error occurred");
                        }
                        
                        NSLog(@"bam");
                    }];
                }];
            }
        }];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    return cell;
}

@end
