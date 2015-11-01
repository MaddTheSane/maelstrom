#import <Cocoa/Cocoa.h>

@interface SDLMain : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSTextField *fragCount;
@property (assign) IBOutlet NSButton *fullscreen;
@property (assign) IBOutlet NSButton *joinGame;
@property (assign) IBOutlet NSTextField *netAddress;
@property (assign) IBOutlet NSTextField *numberOfPlayers;
@property (assign) IBOutlet NSButton *playDeathmatch;
@property (assign) IBOutlet NSTextField *playerNumber;
@property (assign) IBOutlet NSButton *realtime;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *worldScores;

- (IBAction)cancel:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)startGame:(id)sender;
- (IBAction)startServer:(id)sender;
- (IBAction)toggleFullscreen:(id)sender;
@end
