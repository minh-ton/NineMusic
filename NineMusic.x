#import "NineMusic.h"

static MediaControlsTimeControl *playerTimeControl;
static CSMainPageView *mainPageView;
static CSCoverSheetView *coverSheetView;
static MediaControlsVolumeSlider *volumeSlider;
static MediaControlsTransportStackView *mediaControls;
static SBUIProudLockIconView* proudLockView;

BOOL isCurrentlyActive = NO;
BOOL isRoundLockScreenInstalled;
BOOL enabled;

void loadprefs() {
  NSMutableDictionary const *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.minhton.ninemusicpref.plist"];

  if (!prefs) {
    NSURL *source = [NSURL fileURLWithPath:@"/Library/PreferenceBundles/NineMusicPref.bundle/defaults.plist"];
    NSURL *destination = [NSURL fileURLWithPath:@"/var/mobile/Library/Preferences/me.minhton.ninemusicpref.plist"];
    [[NSFileManager defaultManager] copyItemAtURL:source toURL:destination error:nil];
    enabled = YES;
  } else {
    enabled = [[prefs objectForKey:@"enabled"] boolValue];
  }
}

// ----- POSITIONING BUTTONS / VIEWS -------
// -----------------------------------------

%group NineMusic
%hook CSMainPageView

// Use auto-scroll label (marquee label) for long song names / artist names
// https://github.com/cbpowell/MarqueeLabel-ObjC/

%property (nonatomic, retain) MarqueeLabel *songTitleLabel;
%property (nonatomic, retain) MarqueeLabel *artistTitleLabel;
%property (nonatomic, retain) UIImageView *artworkImageView;
%property (nonatomic, retain) UIView *epicBlurView;
%property (nonatomic, retain) UIVisualEffectView *blurEffect;

-(id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    mainPageView = self;
    return orig;
}

-(void)layoutSubviews {
  %orig;

  // Song name (will add a "Tap to view Album name" feature in the future)
  if (!self.songTitleLabel) {
    self.songTitleLabel = [[MarqueeLabel alloc] init];
    [self.songTitleLabel setTextColor:[UIColor whiteColor]];
    [self.songTitleLabel setFont:[UIFont systemFontOfSize:22.0 weight:UIFontWeightMedium]];
    self.songTitleLabel.frame = CGRectMake(coverSheetView.frame.size.width/2 - ([[UIScreen mainScreen] bounds].size.width - 70)/2, 70, [[UIScreen mainScreen] bounds].size.width - 70, 30);
    self.songTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.songTitleLabel.marqueeType = MLLeftRight;
    self.songTitleLabel.rate = 60.0f;
    self.songTitleLabel.fadeLength = 10.0f;
    self.songTitleLabel.hidden = YES;
  }

  // Song artist
  if (!self.artistTitleLabel) {
    self.artistTitleLabel = [[MarqueeLabel alloc] init];
    [self.artistTitleLabel setTextColor:[UIColor lightGrayColor]];
    [self.artistTitleLabel setFont:[UIFont systemFontOfSize:21.0 weight:UIFontWeightRegular]];
    self.artistTitleLabel.frame = CGRectMake(coverSheetView.frame.size.width/2 - ([[UIScreen mainScreen] bounds].size.width - 70)/2, 100, [[UIScreen mainScreen] bounds].size.width - 70, 30);
    self.artistTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.artistTitleLabel.marqueeType = MLLeftRight;
    self.artistTitleLabel.rate = 60.0f;
    self.artistTitleLabel.fadeLength = 10.0f;
    self.artistTitleLabel.hidden = YES;
  }

  // Big artwork
  if (!self.artworkImageView) {
    float height_width = [[UIScreen mainScreen] bounds].size.width - 50;
    self.artworkImageView = [[UIImageView alloc] init];
    CGRect artworkFrame = self.frame;
    artworkFrame.size.width = height_width;
    artworkFrame.size.height = height_width;
    self.artworkImageView.frame = artworkFrame;
    [self.artworkImageView setClipsToBounds:YES];
    self.artworkImageView.frame = CGRectMake(coverSheetView.frame.size.width/2 - height_width/2, 250, height_width, height_width);
    self.artworkImageView.layer.cornerRadius = 5.0;
  }

  // The iconic player blur in iOS 9
  if (!self.epicBlurView) {
    self.epicBlurView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.epicBlurView.backgroundColor = [UIColor clearColor];
    self.epicBlurView.alpha = 0;

    self.blurEffect = [[UIVisualEffectView alloc]initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blurEffect.frame = self.epicBlurView.bounds;
    self.epicBlurView.hidden = YES;
    [self.epicBlurView addSubview:self.blurEffect];
  }

  [self updateNineMusicState];
}

%new
-(void)updateNineMusicState {
  [self addSubview:self.epicBlurView];
  [self.epicBlurView addSubview:self.artworkImageView];
  [self addSubview:playerTimeControl];
  [self addSubview:self.songTitleLabel];
  [self addSubview:self.artistTitleLabel];
  [self addSubview:volumeSlider];
  [self addSubview:mediaControls];

  // A workaround for an issue which damages the CC Module...
  playerTimeControl.frame = CGRectMake(coverSheetView.frame.size.width/2 - playerTimeControl.frame.size.width/2, 18, playerTimeControl.frame.size.width, playerTimeControl.frame.size.height);
  mediaControls.frame = CGRectMake(mainPageView.epicBlurView.frame.size.width/2 - mediaControls.frame.size.width/2, 135, mediaControls.frame.size.width, mediaControls.frame.size.height);
  volumeSlider.frame = CGRectMake(mainPageView.epicBlurView.frame.size.width/2 - volumeSlider.frame.size.width/2, 203, volumeSlider.frame.size.width, volumeSlider.frame.size.height);

  [UIView animateWithDuration:0.4 animations:^(void) {
    self.epicBlurView.alpha = 1;
  } completion:nil];

  [self sendSubviewToBack:self.epicBlurView];

  // Detect light/dark mode

  if (UIScreen.mainScreen.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
    [UIView animateWithDuration:1.0 animations:^{
      self.blurEffect.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
      [self.songTitleLabel setTextColor:[UIColor whiteColor]];
      [self.artistTitleLabel setTextColor:[UIColor lightGrayColor]];
    }];
    [volumeSlider removeFromSuperview];
    [self addSubview:volumeSlider];
  } else {
    [UIView animateWithDuration:1.0 animations:^{
      self.blurEffect.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
      [self.songTitleLabel setTextColor:[UIColor blackColor]];
      [self.artistTitleLabel setTextColor:[UIColor colorWithWhite:0 alpha:0.6]];
    }];
    [volumeSlider removeFromSuperview];
    [self addSubview:volumeSlider];
  }

  // Tell NineUnlock to hide/show slide to unlock view
  if (!isCurrentlyActive) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.minhton.ninemusic/shownineunlock"), nil, nil, true);
  } else if (isCurrentlyActive) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.minhton.ninemusic/hidenineunlock"), nil, nil, true);
  }
}

%end

%hook CSCoverSheetView
- (void)setFrame:(CGRect)frame {
    %orig;
    coverSheetView = self;
}
%end

// ---------------------------
// ---------------------------

// Track duration/time slider

%hook MediaControlsTimeControl
- (void)layoutSubviews {
  %orig;
  MRPlatterViewController *controller = (MRPlatterViewController *)[self _viewControllerForAncestor];
  if ([controller respondsToSelector:@selector(delegate)] && [controller.delegate isKindOfClass:%c(CSMediaControlsViewController)]) {
    playerTimeControl = self;
  }
}
%end

// Volume slider

%hook MediaControlsVolumeSlider
- (void)layoutSubviews {
  %orig;
  MRPlatterViewController *controller = (MRPlatterViewController *)[self _viewControllerForAncestor];
  if ([controller respondsToSelector:@selector(delegate)] && [controller.delegate isKindOfClass:%c(CSMediaControlsViewController)]) {
    volumeSlider = self;
    // Hide first, because it left an ugly blue circle on the lockscreen after respring
    volumeSlider.hidden = YES;
  }
}

%end

// Media Control buttons (play/pause/skip)

%hook MediaControlsTransportStackView
- (void)layoutSubviews {
	%orig;
  MRPlatterViewController *controller = (MRPlatterViewController *)[self _viewControllerForAncestor];
  if ([controller respondsToSelector:@selector(delegate)] && [controller.delegate isKindOfClass:%c(CSMediaControlsViewController)]) {
    %orig;
    mediaControls = self;
  }
}

%end

// ----- HIDE UGLY STUFF -------
// -----------------------------

// Hide "No older notifications" text

%hook NCNotificationListSectionRevealHintView
- (void)didMoveToWindow {
  %orig;
  self.hidden = isCurrentlyActive;
}
%end

// Hide the ugly default music player

%hook CSAdjunctItemView
- (id)initWithFrame:(CGRect)frame {
    return nil;
}
%end

// Hide Face ID Lock

%hook SBUIProudLockIconView
-(id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    proudLockView = self;
    return orig;
}
%end

// Hide CC Grabber

%hook CSTeachableMomentsContainerView
- (void)layoutSubviews {
  %orig;
  [[self controlCenterGrabberContainerView] setHidden:isCurrentlyActive];
}
%end

// ----- HOW NOTIFICATIONS BEHAVE IN IOS 9? -------
// ------------------------------------------------

// Positioning the notification scroll view

%hook CSCombinedListViewController
- (double)_minInsetsToPushDateOffScreen { // lower notifications while playing
  if (!isCurrentlyActive) return %orig;
  double orig = %orig;
  return orig + (isCurrentlyActive ? 85.0 : 0.0);
}

- (UIEdgeInsets)_listViewDefaultContentInsets { // lower notifications while playing
  if (!isCurrentlyActive) return %orig;
  UIEdgeInsets originalInsets = %orig;
  originalInsets.top += isCurrentlyActive ? 85.0 : 0.0;
  return originalInsets;
}
%end

%hook NCNotificationListView

- (void)_scrollViewWillBeginDragging { // fade elements out when scrolling and notifications are presented
	%orig;
  if (!isCurrentlyActive) return;
  [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    [mainPageView.songTitleLabel setAlpha:0];
    [mainPageView.artistTitleLabel setAlpha:0];
    [mainPageView.artworkImageView setAlpha:0];
    [volumeSlider setAlpha:0];
    [mediaControls setAlpha:0];
    [playerTimeControl setAlpha:0];
    [volumeSlider setHidden:YES];
  } completion:nil];
}

- (void)_scrollViewDidEndDraggingWithDeceleration:(BOOL)arg1 { // fade elements in when stopped scrolling
	%orig;
  if (!isCurrentlyActive) return;
  [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    [mainPageView.songTitleLabel setAlpha:1];
    [mainPageView.artistTitleLabel setAlpha:1];
    [mainPageView.artworkImageView setAlpha:1];
    [volumeSlider setAlpha:1];
    [mediaControls setAlpha:1];
    [playerTimeControl setAlpha:1];
    [volumeSlider setHidden:NO];
  } completion:nil];
}
%end

// RoundLockScreen Compatibility & Hide FaceID Lock

%hook CSCoverSheetViewController
- (void)viewWillAppear:(BOOL)animated { // roundlockscreen compatibility
	%orig;
  [proudLockView setHidden:isCurrentlyActive];
  if (isRoundLockScreenInstalled) [[mainPageView epicBlurView] setClipsToBounds:YES];
	if (isRoundLockScreenInstalled) [[[mainPageView epicBlurView] layer] setCornerRadius:38];
}

- (void)viewWillDisappear:(BOOL)animated { // roundlockscreen compatibility
	%orig;
  [proudLockView setHidden:isCurrentlyActive];
  if (isRoundLockScreenInstalled) [[mainPageView epicBlurView] setClipsToBounds:YES];
	if (isRoundLockScreenInstalled) [[[mainPageView epicBlurView] layer] setCornerRadius:38];
}

- (void)viewDidAppear:(BOOL)animated { // roundlockscreen compatibility
	%orig;
  [proudLockView setHidden:isCurrentlyActive];
  if (isRoundLockScreenInstalled) [[mainPageView epicBlurView] setClipsToBounds:YES];
	if (isRoundLockScreenInstalled) [[[mainPageView epicBlurView] layer] setCornerRadius:0];
}
%end

%hook SBBacklightController
- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 {
  %orig;
  [proudLockView setHidden:isCurrentlyActive];
}
%end

// ----- GET SONG DATA -------
// ---------------------------

%hook SBMediaController

// From Litten's Lobelias tweak
// https://github.com/Litteeen/Lobelias/

- (void)setNowPlayingInfo:(id)arg1 {
  %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information) {
            NSDictionary* dict = (__bridge NSDictionary *)information;
            NSString *songTitle = [NSString stringWithFormat:@"%@", [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoTitle]];
            NSString *artistTitle = [NSString stringWithFormat:@"%@", [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtist]];
            UIImage *currentArtwork = [UIImage imageWithData:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]];

            mainPageView.songTitleLabel.text = songTitle;
            mainPageView.artistTitleLabel.text = artistTitle;

            if (dict) {
              if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData]) {
                [UIView transitionWithView:mainPageView.artworkImageView duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    mainPageView.artworkImageView.image = currentArtwork;
                } completion:nil];
              }
              [mainPageView.epicBlurView setHidden:NO];
              [mainPageView.songTitleLabel setHidden:NO];
              [mainPageView.artistTitleLabel setHidden:NO];
              [volumeSlider setHidden:NO];
              [mediaControls setHidden:NO];
              [playerTimeControl setHidden:NO];
              isCurrentlyActive = YES;

              // Tell NineUnlock to hide
              CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.minhton.ninemusic/hidenineunlock"), nil, nil, true);
            }
        } else {
          [mainPageView.epicBlurView setHidden:YES];
          [mainPageView.songTitleLabel setHidden:YES];
          [mainPageView.artistTitleLabel setHidden:YES];
          [volumeSlider setHidden:YES];
          [mediaControls setHidden:YES];
          [playerTimeControl setHidden:YES];
          isCurrentlyActive = NO;

          // Tell NineUnlock to show
          CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.minhton.ninemusic/shownineunlock"), nil, nil, true);
        }
    });
}

%end

// Reload data after respring

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;
	[[%c(SBMediaController) sharedInstance] setNowPlayingInfo:0];
}
%end
%end

static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  if (isCurrentlyActive == YES) {
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      [mainPageView.songTitleLabel setAlpha:1];
      [mainPageView.artistTitleLabel setAlpha:1];
      [volumeSlider setAlpha:1];
      [mediaControls setAlpha:1];
      [playerTimeControl setAlpha:1];
      [volumeSlider setHidden:NO];
    } completion:nil];
  }
}

%ctor {

  loadprefs();
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadprefs, CFSTR("me.minhton.ninemusic/prefsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);

  if (enabled) {
    // Show buttons after screen on if active
    isRoundLockScreenInstalled = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/RoundLockScreen.dylib"];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, displayStatusChanged, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    %init(NineMusic);
  } else {
    %init;
  }
}

// Created this tweak during the Flooding across Central Vietnam (October 2020)
