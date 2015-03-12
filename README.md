## Spotify-ObjC
Quick implementation of the Spotify streaming features in iOS (ObjC), with a focus on user authentication, playlist listing and playlist creation.

# Setup
A good explanation of how to set up the environment is given at https://developer.spotify.com/technologies/spotify-ios-sdk/. The beginner tutorial covers all basics which are necessary to register the app in the Spotify Developer Console ("My Apps" section), set up the free Heroku server and complete the authentication and streaming functions.

# Login function
The app authenticates the user at the very beginning in the AppDelegate, and passes the resulting Session object to ViewController class through the defaultCenter function of the NotificationCenter.

In order to complete the authentication, a Ruby server has to be implemented 


In the AppDelegate, the following function talks to the Heroku server:
     
     -(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
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

In the implementation of the ViewController, add the following variables:

	SPTSession *session;		//Keeps track of the current session
	NSMutableArray *tableData;	//Contains the names of the playlists to be shown in the tableView
	NSMutableArray *uris;		//Contains the uris of the playlists contained in tableData
	SPTListPage *page;			//Keeps track of which SPTListPage is being dealt with

Also, add the following notification observer to the viewDidLoad() function:

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LoadRequestFromAppDel:) name:@"loginSuccessful" object:Nil];

Once triggered, the observer calls the LoadRequestFromAppDel() function, which assigns the current session value to the variable mentioned above:

    -(void)LoadRequestFromAppDel:(NSNotification*)aNotif {
    	session=[[aNotif userInfo] objectForKey:@"SpotifySession"];
    	[self loadPlaylists:session];
    }

Once called, this function also triggers the loadPlaylists() function, described in the following section.

# List all playlists
In order to keep traffic to a minimum, Spotify only returns query results in pages of 20 units (e.g. 20 playlists, 20 tracks, etc.). In order to download all pages, recursion can be used. For example, the names of all playlists are loaded through two functions:

loadPlaylists():

	-(void)loadPlaylists:(SPTSession *)session {
    	tableData = [[NSMutableArray alloc] init];
    	uris = [[NSMutableArray alloc] init];
    
    	[SPTRequest playlistsForUserInSession:session callback:^(NSError *error, id object) {
        	if(error != nil) {
           		NSLog(@"An error occurred");
            	return;
        	}
        
        	SPTListPage *page = object;
	        SPTPlaylistSnapshot *unit;
    	    int remaining_length = page.totalListLength;
        
        	for(int i = 0; i < page.items.count; i++) {
            	unit = page.items[i];
		        NSLog(unit.name);
    	        [tableData addObject:unit.name];
        	    [uris addObject: [unit.playableUri absoluteString]];
        	}
        
	        remaining_length -= 20;
    	    if (remaining_length > 0) {
        	    [self loadPage:session currentPage:page remainingLength:remaining_length];
	        } else {
    	        [tableView reloadData];
        	}
    	}];
	}

loadPage():

    -(void) loadPage:(SPTSession *)session currentPage:(SPTListPage *)page remainingLength:(int)length {
        [page requestNextPageWithSession:session callback:^(NSError *error, id object) {
            if (error != nil) {
                NSLog(@"An error occurred");
            }
            
            //NSLog(@"got to this point");
            
            SPTListPage *result = object;
            SPTListPage *pointer = object;
            SPTPlaylistSnapshot *playlist;
            
            for(int i = 0; i < pointer.items.count; i++) {
                playlist = pointer.items[i];
                NSLog(playlist.name);
                [tableData addObject:playlist.name];
                [uris addObject: [playlist.playableUri absoluteString]];
            }
            
            int temp = length - 20;
            if (temp > 0) {
                NSLog(@"%d", temp);
                [self loadPage:session currentPage: result remainingLength:temp];
            } else {
                [tableView reloadData];
            }
        }];
    }


# Create a new playlist and add tracks to it
In order to create a new playlists and add tracks to it, several steps are to be followed. In order to ensure consequentiality, callbacks can be leveraged. 

In this example, the function searches for a string trough Spotify's catalog and adds the first result to a newly-created playlist:

1. Create playlist;
2. Search for a given track;
3. Use the first result to obtain a track item from Spotify;
4. Once the item has been obtained, add it to the new playlist.

New playlists can be created through the following function:

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