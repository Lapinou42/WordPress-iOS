//
//  ReaderPostDetailView.m
//  WordPress
//
//  Created by Eric J on 5/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostDetailView.h"
#import <DTCoreText/DTCoreText.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "ReaderMediaView.h"
#import "ReaderImageView.h"
#import "ReaderVideoView.h"
#import "WPImageViewController.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "WPWebVideoViewController.h"
#import "UIImageView+Gravatar.h"
#import "UILabel+SuggestSize.h"

@interface ReaderPostDetailView()<DTAttributedTextContentViewDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIView *authorView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *blogLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, weak) id<ReaderPostDetailViewDelegate>delegate;

- (void)_updateLayout;
- (void)updateMediaLayout:(ReaderMediaView *)mediaView;
- (void)handleAuthorViewTapped:(id)sender;
- (void)handleImageLinkTapped:(id)sender;
- (void)handleLinkTapped:(id)sender;
- (void)handleVideoTapped:(id)sender;
- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView;
- (void)handleFollowButtonTapped:(id)sender;
- (void)handleFollowButtonInteraction:(id)sender;

@end

@implementation ReaderPostDetailView

- (id)initWithFrame:(CGRect)frame post:(ReaderPost *)post delegate:(id<ReaderPostDetailViewDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {

		self.post = post;
		self.delegate = delegate;
		
		self.mediaArray = [NSMutableArray array];

		CGFloat width = frame.size.width;
        CGFloat padding = 20.0f;
        CGFloat labelWidth = width - 100.0f;
        CGFloat labelHeight = 20.0f;
        CGFloat avatarSize = 60.0f;
		
		self.authorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 80.0f)];
		_authorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:_authorView];
		
		
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		button.frame = _authorView.frame;
		[button addTarget:self action:@selector(handleAuthorViewTapped:) forControlEvents:UIControlEventTouchUpInside];
		[_authorView addSubview:button];
		
		self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, avatarSize, avatarSize)];
		_avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
				
		if ([post avatar] != nil) {
			[self.avatarImageView setImageWithURL:[NSURL URLWithString:[post avatar]] placeholderImage:[UIImage imageNamed:@"gravatar.jpg"]];
		} else {
			NSString *img = ([post isWPCom]) ? @"wpcom_blavatar.png" : @"wporg_blavatar.png";
			[self.avatarImageView setImageWithURL:[self.avatarImageView blavatarURLForHost:[[NSURL URLWithString:post.blogURL] host]] placeholderImage:[UIImage imageNamed:img]];
		}
		
		[_authorView addSubview:_avatarImageView];
		
		self.authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(avatarSize + padding + 10.0f, padding, labelWidth, labelHeight)];
		_authorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_authorLabel.backgroundColor = [UIColor clearColor];
		_authorLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];//[UIFont boldSystemFontOfSize:14.0f];
		_authorLabel.text = (self.post.author != nil) ? self.post.author : self.post.authorDisplayName;
		_authorLabel.textColor = [UIColor colorWithHexString:@"404040"];
		[_authorView addSubview:_authorLabel];
		
		self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(avatarSize + padding + 10.0f, padding + labelHeight, labelWidth, labelHeight)];
		_dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_dateLabel.backgroundColor = [UIColor clearColor];
		_dateLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];//[UIFont systemFontOfSize:14.0f];
		_dateLabel.text = [NSString stringWithFormat:@"%@ on", [self.post prettyDateString]];
		_dateLabel.textColor = [UIColor colorWithHexString:@"404040"];//[UIColor colorWithHexString:@"aaaaaa"];
		[_authorView addSubview:_dateLabel];
		
		self.blogLabel = [[UILabel alloc] initWithFrame:CGRectMake(avatarSize + padding + 10.0f, padding + labelHeight * 2, labelWidth, labelHeight)];
		_blogLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_blogLabel.backgroundColor = [UIColor clearColor];
		_blogLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];//[UIFont systemFontOfSize:14.0f];
		_blogLabel.text = self.post.blogName;
		_blogLabel.textColor = [UIColor colorWithHexString:@"278dbc"];
		[_authorView addSubview:_blogLabel];
		
		CGRect followFrame = _blogLabel.frame;
		followFrame.origin.y += 2.0f;
		followFrame.size.height += 4.0f;
		self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_followButton.frame = followFrame; // Arbitrary width and x. The height and y are correct.
		[_followButton setSelected:[post.isFollowing boolValue]];
		_followButton.layer.cornerRadius = 3.0f;
		_followButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		_followButton.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:234.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
		_followButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10.0f];
		[_followButton setTitle:NSLocalizedString(@"FOLLOW", @"Prompt to follow a blog.") forState:UIControlStateNormal];
		[_followButton setTitle:NSLocalizedString(@"FOLLOWING", @"User is following the blog.") forState:UIControlStateSelected];
		[_followButton setImage:[UIImage imageNamed:@"reader-postaction-follow"] forState:UIControlStateNormal];
		[_followButton setImage:[UIImage imageNamed:@"reader-postaction-following"] forState:UIControlStateSelected];
		[_followButton setTitleColor:[UIColor colorWithRed:116.0f/255.0f green:116.0f/255.0f blue:116.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
		[_followButton addTarget:self action:@selector(handleFollowButtonInteraction:) forControlEvents:UIControlEventAllTouchEvents];
		
		[_authorView addSubview:_followButton];
		
		CGFloat contentY = _authorView.frame.size.height;
		
		if ([self.post.postTitle length]) {		
			CGRect titleFrame = CGRectMake(padding, contentY + padding, width - (padding * 2), 44.0f);
			self.titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
			_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			_titleLabel.backgroundColor = [UIColor clearColor];
			_titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0f];
			_titleLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0f];
			_titleLabel.lineBreakMode = UILineBreakModeWordWrap;
			_titleLabel.numberOfLines = 0;
			_titleLabel.text = self.post.postTitle;
			[self addSubview:_titleLabel];
			titleFrame.size.height = [_titleLabel suggestedSizeForWidth:_titleLabel.frame.size.width].height;
			_titleLabel.frame = titleFrame;
			contentY = titleFrame.origin.y + titleFrame.size.height;
		}
		
		self.textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.0f, contentY + 10.0f, width, 100.0f)]; // Starting height is arbitrary
		_textContentView.delegate = self;
		_textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_textContentView.backgroundColor = [UIColor clearColor];
		_textContentView.edgeInsets = UIEdgeInsetsMake(0.0f, padding, 0.0f, padding);
		_textContentView.shouldDrawImages = NO;
		_textContentView.shouldDrawLinks = NO;
		[self addSubview:_textContentView];
		

		NSString *str = [NSString stringWithFormat:@"<style>body{color:#404040;} a{color:#278dbc;text-decoration:none;}a:active{color:#005684;}</style>%@", [self.post.content trim]];
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
															  DTDefaultFontFamily:@"Open Sans",
													DTDefaultLineHeightMultiplier:@0.9,
																DTDefaultFontSize:@13,
											   NSTextSizeMultiplierDocumentOption:@1.1
									 }];
		_textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:[str dataUsingEncoding:NSUTF8StringEncoding]
																				 options:dict
																	  documentAttributes:NULL];
    }
    return self;
}


- (void)layoutSubviews {
	[super layoutSubviews];
	
	NSString *str = _followButton.currentTitle;
	CGSize sz = [str sizeWithFont:_followButton.titleLabel.font];
	[_followButton sizeToFit];
	sz = _followButton.frame.size;
	sz.width += 2.0f; // just a little extra width so the text has better padding on the right.
	
	CGFloat desiredWidth = [_blogLabel.text sizeWithFont:_blogLabel.font].width;
	CGFloat availableWidth = (_authorView.frame.size.width - _blogLabel.frame.origin.x) - 20.0f;
	availableWidth -= (sz.width + 5.0f);

	CGRect frame = _blogLabel.frame;
	frame.size.width = MIN(availableWidth, desiredWidth);
	_blogLabel.frame = frame;
	
	frame = _followButton.frame;
	frame.origin.x = _blogLabel.frame.origin.x + _blogLabel.frame.size.width + 5.0f;
	frame.size.width = sz.width;
	_followButton.frame = frame;

}


- (void)updateLayout {
	// Figure out image sizes after orientation change.
	for (ReaderMediaView *mediaView in _mediaArray) {
		[self updateMediaLayout:mediaView];
	}

	if (_titleLabel) {
		CGRect titleFrame = _titleLabel.frame;
		titleFrame.size.height = [_titleLabel suggestedSizeForWidth:titleFrame.size.width].height;
		_titleLabel.frame = titleFrame;
		
		CGRect contentFrame = _textContentView.frame;
		contentFrame.origin.y = titleFrame.origin.y + titleFrame.size.height + 10.0f;
		_textContentView.frame = contentFrame;
	}
	
	// Then update the layout
	// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
	_textContentView.layouter = nil;

	// layout might have changed due to image sizes
	[_textContentView relayoutText];

	[self _updateLayout];
}


- (void)_updateLayout {
	// Size the textContentView
	CGRect frame = _textContentView.frame;
	CGFloat height = [_textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:frame.size.width].height;
	frame.size.height = height;
	_textContentView.frame = frame;
	
	frame = self.frame;
	frame.size.height = height + _textContentView.frame.origin.y + 10.0f; // + bottom padding
	self.frame = frame;
	
	[self.delegate readerPostDetailViewLayoutChanged];
}


- (void)updateMediaLayout:(ReaderMediaView *)imageView {
	
	NSURL *url = imageView.contentURL;
	
	CGFloat width = _textContentView.frame.size.width;
	CGSize viewSize = imageView.image.size;
	viewSize.width = width - (_textContentView.edgeInsets.left + _textContentView.edgeInsets.right);

	if (viewSize.height > 0) {
		
		if (imageView.image.size.width > _textContentView.frame.size.width) {
			// The ReaderImageView view will conform to the width constraints of the _textContentView. We want the image itself to run out to the edges,
			// so position it offset by the inverse of _textContentView's edgeInsets.
			UIEdgeInsets edgeInsets = _textContentView.edgeInsets;
			edgeInsets.left = 0.0f - edgeInsets.left;
			edgeInsets.top = 0.0f;
			edgeInsets.right = 0.0f - edgeInsets.right;
			edgeInsets.bottom = 0.0f;
			imageView.edgeInsets = edgeInsets;
			
			viewSize.height = imageView.image.size.height * (viewSize.width / imageView.image.size.width);
		}
		
	}
NSLog(@"IMAGE SIZING - ORIGINAL: w%f h%f | ADJUSTED: w%f h%f", imageView.image.size.width, imageView.image.size.height, viewSize.width, viewSize.height);
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
	
	// update all attachments that matchin this URL (possibly multiple images with same size)
	for (DTTextAttachment *attachment in [self.textContentView.layoutFrame textAttachmentsWithPredicate:pred]) {
		attachment.originalSize = imageView.image.size;
		attachment.displaySize = viewSize;
	}
}


- (void)handleFollowButtonInteraction:(id)sender {
	[self setNeedsLayout];
}


- (void)handleFollowButtonTapped:(id)sender {
	[self.post toggleFollowingWithSuccess:^{
		// nothing to do. 
	} failure:^(NSError *error) {
		WPLog(@"Error Following Blog : %@", [error localizedDescription]);
		[_followButton setSelected:self.post.isFollowing];
		[self setNeedsLayout];
		
		NSString *title;
		NSString *description;
		if (self.post.isFollowing) {
			title = NSLocalizedString(@"Could Not Unfollow Blog", @"Title of prompt. Says a blog could not be unfollowed.");
			description = NSLocalizedString(@"There was a problem unfollowing this blog.", @"Prompts the user that there was a problem unfollowing a blog.");
		} else {
			title = NSLocalizedString(@"Could Not Follow Blog", @"Title of prompt. Says a blog could not be followed.");
			description = NSLocalizedString(@"There was a problem following this blog.", @"Prompts the user there was a problem following a blog.");
		}
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
															message:description
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", @"")
												  otherButtonTitles:nil];
		[alertView show];
		
	}];
	[_followButton setSelected:self.post.isFollowing];
	[self setNeedsLayout];
}


- (void)handleAuthorViewTapped:(id)sender {
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:[NSURL URLWithString:self.post.permaLink]];
	[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] pushViewController:controller animated:YES];
}


- (void)handleImageLinkTapped:(id)sender {
	ReaderImageView *imageView = (ReaderImageView *)sender;
	
	if(imageView.linkURL) {
		NSString *url = [imageView.linkURL absoluteString];
		
		BOOL matched = NO;
		NSArray *types = @[@".png", @".jpg", @".gif", @".jpeg"];
		for (NSString *type in types) {
			if (NSNotFound != [url rangeOfString:type].location) {
				matched = YES;
				break;
			}
		}
		
		if (matched) {
			[WPImageViewController presentAsModalWithURL:((ReaderImageView *)sender).linkURL];
		} else {
			WPWebViewController *controller = [[WPWebViewController alloc] init];
			[controller setUrl:((ReaderImageView *)sender).linkURL];
			[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] pushViewController:controller animated:YES];
		}
	} else {
		[WPImageViewController presentAsModalWithImage:imageView.image];
	}
}


- (void)handleLinkTapped:(id)sender {
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:((DTLinkButton *)sender).URL];
	[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] pushViewController:controller animated:YES];
}


- (void)handleVideoTapped:(id)sender {
	ReaderVideoView *videoView = (ReaderVideoView *)sender;
	if(videoView.contentType == ReaderVideoContentTypeVideo) {
		
		MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:videoView.contentURL];
		controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
		[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] pushViewController:controller animated:YES];
		
	} else {
		// Should either be an iframe, or an object embed. In either case a src attribute should have been parsed for the contentURL.
		// Assume this is content we can show and try to load it.
		WPWebVideoViewController *controller = [WPWebVideoViewController presentAsModalWithURL:videoView.contentURL];
		controller.title = (videoView.title != nil) ? videoView.title : @"Video";
	}
}


- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView {
	
	[self updateMediaLayout:mediaView];
	
	// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
	self.textContentView.layouter = nil;
	
	// layout might have changed due to image sizes
	[self.textContentView relayoutText];
	
	[self _updateLayout];
}


#pragma mark - DTCoreAttributedTextContentView Delegate Methods

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:NULL];
	
	NSURL *URL = [attributes objectForKey:DTLinkAttribute];
	NSString *identifier = [attributes objectForKey:DTGUIDAttribute];
	
	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
	button.URL = URL;
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
	button.GUID = identifier;
	
	// get image with normal link text
	UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];
	[button setImage:normalImage forState:UIControlStateNormal];
	
	// get image for highlighted link text
	UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
	[button setImage:highlightImage forState:UIControlStateHighlighted];
	
	// use normal push action for opening URL
	[button addTarget:self action:@selector(handleLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}


- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame {
		
	if (attachment.contentType == DTTextAttachmentTypeImage) {

		// Starting out we'll have a real image or a placeholder, so no need to guess the right size.
		UIImage *image = ([attachment.contents isKindOfClass:[UIImage class]]) ? (UIImage*)attachment.contents : [UIImage imageNamed:@"wp_img_placeholder.png"];
		frame.size = image.size;

		if (frame.size.width > _textContentView.frame.size.width) {
			CGFloat r = _textContentView.frame.size.width / frame.size.width;
			frame.size.width = frame.size.width * r;
			frame.size.height = frame.size.height * r;
		} else {
			frame.size.width = _textContentView.frame.size.width - (_textContentView.edgeInsets.left + _textContentView.edgeInsets.right); // Match the frame width so the image is centered.
		}
		
		ReaderImageView *imageView = [[ReaderImageView alloc] initWithFrame:frame];
		[_mediaArray addObject:imageView];
		imageView.linkURL = attachment.hyperLinkURL;
		[imageView addTarget:self action:@selector(handleImageLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		if (attachment.contents) {
			[imageView setImage:(UIImage *)attachment.contents];
		} else {
			imageView.imageView.contentMode = UIViewContentModeCenter;
			imageView.backgroundColor = [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0];
			[imageView setImageWithURL:attachment.contentURL
					  placeholderImage:[UIImage imageNamed:@"wp_img_placeholder.png"]
							   success:^(id readerImageView) {
								   ReaderImageView *imageView = readerImageView;
								   imageView.imageView.contentMode = UIViewContentModeScaleAspectFit;
								   imageView.backgroundColor = [UIColor clearColor];
								   [self handleMediaViewLoaded:readerImageView];
							   } failure:^(id readerImageView, NSError *error) {
								   [self handleMediaViewLoaded:readerImageView];
							   }];
		}
		return imageView;
		
	} else {
		
		ReaderVideoContentType videoType;
		
		if (attachment.contentType == DTTextAttachmentTypeVideoURL) {
			videoType = ReaderVideoContentTypeVideo;
		} else if (attachment.contentType == DTTextAttachmentTypeIframe) {
			videoType = ReaderVideoContentTypeIFrame;
		} else if (attachment.contentType == DTTextAttachmentTypeObject) {
			videoType = ReaderVideoContentTypeEmbed;
		} else {
			return nil; // Can't handle whatever this is :P
		}
	
		// make sure we have a reasonable size.
		if (frame.size.width > _textContentView.frame.size.width) {
			CGFloat r = _textContentView.frame.size.width / frame.size.width;
			frame.size.width = frame.size.width * r;
			frame.size.height = frame.size.height * r;
		}

		
		ReaderVideoView *videoView = [[ReaderVideoView alloc] initWithFrame:frame];
		[_mediaArray addObject:videoView];
		[videoView setContentURL:attachment.contentURL ofType:videoType success:^(id readerVideoView) {
			[self handleMediaViewLoaded:readerVideoView];
			
		} failure:^(id readerVideoView, NSError *error) {
			[self handleMediaViewLoaded:readerVideoView];
			
		}];
		
		[videoView addTarget:self action:@selector(handleVideoTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		[self handleMediaViewLoaded:videoView];
		return videoView;
	}
	
}

@end
