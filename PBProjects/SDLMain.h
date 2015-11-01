#import <Cocoa/Cocoa.h>

@interface SDLMain : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextField *fragCount;
    IBOutlet NSButton *fullscreen;
    IBOutlet NSButton *joinGame;
    IBOutlet NSTextField *netAddress;
    IBOutlet NSTextField *numberOfPlayers;
    IBOutlet NSButton *playDeathmatch;
    IBOutlet NSTextField *playerNumber;
    IBOutlet NSButton *realtime;
    IBOutlet NSWindow *window;
    IBOutlet NSButton *worldScores;
}
- (IBAction)cancel:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)startGame:(id)sender;
- (IBAction)startServer:(id)sender;
- (IBAction)toggleFullscreen:(id)sender;
@end
