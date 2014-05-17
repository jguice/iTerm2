//
//  iTermAnnouncementView.m
//  iTerm
//
//  Created by George Nachman on 5/16/14.
//
//

#import "iTermAnnouncementView.h"

static const CGFloat kMargin = 8;

@interface iTermAnnouncementInternalView : NSView
@end

@implementation iTermAnnouncementInternalView

- (void)drawRect:(NSRect)dirtyRect {
    NSColor *color1 = [NSColor colorWithCalibratedRed:241.0 / 255.0
                                                green:255.0 / 255.0
                                                 blue:187.0 / 255.0
                                                alpha:1];
    NSColor *color2 = [NSColor colorWithCalibratedRed:245.0 / 255.0
                                                green:253.0 / 255.0
                                                 blue:212.0 / 255.0
                                                alpha:1];
    NSGradient *gradient =
            [[[NSGradient alloc] initWithStartingColor:color1 endingColor:color2] autorelease];
    [gradient drawInRect:self.bounds angle:90];

    NSColor *lightBorderColor = [NSColor colorWithCalibratedRed:250.0 / 255.0
                                                          green:253.0 / 255.0
                                                           blue:240.0 / 255.0
                                                          alpha:1];

    NSColor *darkBorderColor = [NSColor colorWithCalibratedRed:220.0 / 255.0
                                                         green:233.0 / 255.0
                                                          blue:171.0 / 255.0
                                                         alpha:1];
    [darkBorderColor set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));

    [lightBorderColor set];
    NSRectFill(NSMakeRect(0, self.bounds.size.height - 1, self.bounds.size.width, 1));

    [super drawRect:dirtyRect];
}

@end

@interface iTermAnnouncementView ()
@property(nonatomic, assign) iTermAnnouncementViewStyle style;
@end

@implementation iTermAnnouncementView {
    CGFloat _buttonWidth;
    NSTextField *_textField;
    NSImageView *_icon;
    iTermAnnouncementInternalView *_internalView;
    void (^_block)(int);

}

+ (id)announcementViewWithTitle:(NSString *)title
                           style:(iTermAnnouncementViewStyle)style
                        actions:(NSArray *)actions
                          block:(void (^)(int index))block {
    iTermAnnouncementView *view = [[[self alloc] initWithFrame:NSMakeRect(0, 0, 1000, 44)] autorelease];
    view.style = style;
    [view setTitle:title];
    [view createButtonsFromActions:actions block:block];
    return view;
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        frameRect.size.height -= 10;
        frameRect.origin.y = 10;
        frameRect.origin.x = 0;
        _internalView = [[[iTermAnnouncementInternalView alloc] initWithFrame:frameRect] autorelease];
        _internalView.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_internalView];

        NSShadow *dropShadow = [[[NSShadow alloc] init] autorelease];
        [dropShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.5]];
        [dropShadow setShadowOffset:NSMakeSize(0, -2.0)];
        [dropShadow setShadowBlurRadius:2.0];

        [self setWantsLayer:YES];
        [self setShadow:dropShadow];
        
        NSImage *closeImage = [NSImage imageNamed:@"closebutton"];
        NSSize closeSize = closeImage.size;
        _buttonWidth = ceil(closeSize.width + kMargin);
        NSButton *closeButton = [[[NSButton alloc] initWithFrame:NSMakeRect(frameRect.size.width - _buttonWidth,
                                                                            floor((frameRect.size.height - closeSize.height) / 2),
                                                                            closeSize.width,
                                                                            closeSize.height)] autorelease];
        closeButton.autoresizingMask = NSViewMinXMargin;
        [closeButton setButtonType:NSMomentaryPushInButton];
        [closeButton setImage:closeImage];
        [closeButton setTarget:self];
        [closeButton setAction:@selector(close:)];
        [closeButton setBordered:NO];
        [[closeButton cell] setHighlightsBy:NSContentsCellMask];
        [closeButton setTitle:@""];
        [_internalView addSubview:closeButton];

        self.autoresizesSubviews = YES;
    }
    return self;
}

- (void)dealloc {
    [_block release];
    [_textField release];
    [_icon release];
    [_internalView release];
    [super dealloc];
}

- (void)close:(id)sender {
    _block(-1);
}

- (void)createButtonsFromActions:(NSArray *)actions block:(void (^)(int index))block {
    _block = [block copy];
    NSRect rect = _internalView.frame;

    for (int i = actions.count - 1; i >= 0; i--) {
        NSString *action = actions[i];
        NSButton *button = [[[NSButton alloc] init] autorelease];
        [button setButtonType:NSMomentaryPushInButton];
        [button setTarget:self];
        [button setAction:@selector(buttonPressed:)];
        [button setTag:i];
        [button setTitle:action];
        [button setBezelStyle:NSTexturedRoundedBezelStyle];
        [button sizeToFit];
        button.autoresizingMask = NSViewMinXMargin;
        _buttonWidth += kMargin;
        _buttonWidth += button.frame.size.width;
        button.frame = NSMakeRect(rect.size.width - _buttonWidth,
                                  floor((rect.size.height - button.frame.size.height) / 2),
                                  button.frame.size.width,
                                  button.frame.size.height);
        [_internalView addSubview:button];
    }
}

- (NSImage *)iconImage {
    NSString *iconString;
    switch (_style) {
        case kiTermAnnouncementViewStyleWarning:
            iconString = @"⚠";  // Warning sign
            break;
    }

    NSFont *emojiFont = [NSFont fontWithName:@"Apple Color Emoji" size:18];
    NSDictionary *attributes = @{ NSFontAttributeName: emojiFont };

    NSSize size = [iconString sizeWithAttributes:attributes];
    // This is a better estimate of the height. Maybe it doesn't include leading?
    size.height = [emojiFont ascender] - [emojiFont descender];
    NSImage *iconImage = [[NSImage alloc] initWithSize:size];
    [iconImage lockFocus];
    [iconString drawAtPoint:NSMakePoint(0, 0) withAttributes:attributes];
    [iconImage unlockFocus];
    
    return iconImage;
}

- (void)setTitle:(NSString *)title {
    NSImage *iconImage = [self iconImage];

    CGFloat y = floor((_internalView.frame.size.height - iconImage.size.height) / 2);
    _icon = [[NSImageView alloc] initWithFrame:NSMakeRect(kMargin,
                                                          y,
                                                          iconImage.size.width,
                                                          iconImage.size.height)];
    [_icon setImage:iconImage];
    [_internalView addSubview:_icon];

    NSRect rect = _internalView.frame;
    rect.origin.x += _icon.frame.size.width + _icon.frame.origin.x;
    rect.size.width -= rect.origin.x;

    rect.size.width -= _buttonWidth;
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:rect] autorelease];
    [textField setBezeled:NO];
    [textField setStringValue:title];
    [textField setEditable:NO];
    textField.autoresizingMask = NSViewWidthSizable | NSViewMaxXMargin;
    textField.drawsBackground = NO;
    NSFont *font = [NSFont systemFontOfSize:12];
    [textField setFont:font];
    [textField setSelectable:NO];

    _textField = [textField retain];
    CGFloat height = [title sizeWithAttributes:@{ NSFontAttributeName: font }].height;
    textField.frame = NSMakeRect(rect.origin.x,
                                 floor((_internalView.frame.size.height - height) / 2),
                                 rect.size.width,
                                 height);
    [_internalView addSubview:textField];
}

- (void)buttonPressed:(id)sender {
    _block([sender tag]);
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];

    NSRect rect = _textField.frame;
    rect.size.width = _internalView.frame.size.width - _buttonWidth - NSMaxX(_icon.frame) - kMargin;
    _textField.frame = rect;
}

- (void)resetCursorRects {
    [self addCursorRect:self.bounds cursor:[NSCursor arrowCursor]];
}

@end
