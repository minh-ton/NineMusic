#import <Preferences/PSHeaderFooterView.h>

@interface NineMusicRootHeaderView : UITableViewHeaderFooterView <PSHeaderFooterView> {
	UIImageView* _headerImageView;
	CGFloat _currentWidth;
	CGFloat _aspectRatio;
}

@end
