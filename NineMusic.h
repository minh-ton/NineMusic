#import "substrate.h"
#import <UIKit/UIKit.h>
#import "support/MarqueeLabel.h"
#import <MediaRemote/MediaRemote.h>
#import <notify.h>

@interface UIView (Private)
- (UIViewController *)_viewControllerForAncestor;
@end

@interface MRPlatterViewController : UIViewController
@property (assign,nonatomic) id delegate;
@end

@interface CSMediaControlsViewController : UIViewController
@end

@interface CSCoverSheetView : UIView
@end

@interface NCNotificationListSectionRevealHintView : UIView
@end

@interface MediaControlsTimeControl : UIView
@end

@interface MediaControlsTransportStackView : UIView
@end

@interface CSMainPageView : UIView
@property (nonatomic, retain) MarqueeLabel *songTitleLabel;
@property (nonatomic, retain) MarqueeLabel *artistTitleLabel;
@property (nonatomic, retain) UIImageView *artworkImageView;
@property (nonatomic, retain) UIView *epicBlurView;
@property (nonatomic, retain) UIVisualEffectView *blurEffect;
-(void)updateNineMusicState;
@end

@interface MediaControlsVolumeSlider : UIView
@end

@interface MediaControlsHeaderView : UIView
@end

@interface CSAdjunctItemView : UIView
@end

@interface CSAdjunctListView : UIView
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (void)setNowPlayingInfo:(id)arg1;
@end

@interface PLPlatterView : UIView
@property (nonatomic,retain) UIView * backgroundView;
@end

@interface SBUIProudLockIconView : UIView
@end

@interface CSTeachableMomentsContainerView : UIView
@property(nonatomic, strong, readwrite)UIView* controlCenterGrabberContainerView;
@end

@interface NCNotificationListStalenessEventTracker : NSObject
@end
