#import "FKBrowserViewController.h"
#import "FKShorthands.h"
#import "UIViewController+FKLoading.h"
#import "UIWebView+FKAdditions.h"
#import "UIView+FKAdditions.h"
#import "UIView+FKAnimations.h"
#import "FKiOSMetrics.h"
#import "UIBarButtonItem+FKConcise.h"
#import "UIInterfaceOrientation+FKAdditions.h"
#import "FKNetworkActivityManager.h"
#import "FKInterApp.h"
#import <MessageUI/MessageUI.h>

#define kFKBrowserFixedSpaceItemWidth      12.f
#define kFKBrowserDefaultTintColor         nil
#define kFKBrowserDefaultBackgroundColor   [UIColor scrollViewTexturedBackgroundColor]


@interface FKBrowserViewController () <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong, readwrite) UIToolbar *toolbar;
@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, strong) UIBarButtonItem *backItem;
@property (nonatomic, strong) UIBarButtonItem *forwardItem;
@property (nonatomic, strong) UIBarButtonItem *loadItem;
@property (nonatomic, strong) UIBarButtonItem *actionItem;

- (void)updateAddress:(NSString *)address;

- (void)customize;
- (void)updateUI;
- (void)showActionSheet;
- (void)handleDoneButtonPress:(id)sender;

@end


@implementation FKBrowserViewController

@synthesize address = address_;
@synthesize url = url_;
@synthesize tintColor = tintColor_;
@synthesize backgroundColor = backgroundColor_;
@synthesize fadeAnimationEnabled = fadeAnimationEnabled_;
@synthesize webView = webView_;
@synthesize toolbar = toolbar_;
@synthesize backItem = backItem_;
@synthesize forwardItem = forwardItem_;
@synthesize loadItem = loadItem_;
@synthesize actionItem = actionItem_;
@synthesize presentedModally = presentedModally_;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

+ (id)browserWithAddress:(NSString *)address {
    return [[[self class] alloc] initWithAddress:address];
}

+ (id)modalBrowserWithAddress:(NSString *)address {
    FKBrowserViewController *viewController = [self browserWithAddress:address];
    viewController.presentedModally = YES;
    
    return viewController;
}

- (id)initWithAddress:(NSString *)address {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        fadeAnimationEnabled_ = YES;
        tintColor_ = kFKBrowserDefaultTintColor;
        backgroundColor_ = kFKBrowserDefaultBackgroundColor;
        
        // Initialize toolbar here to make it customizable before view is created
        toolbar_ = [[UIToolbar alloc] initWithFrame:CGRectZero];
        
        [self updateAddress:address];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)url {
    return [self initWithAddress:[url absoluteString]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithAddress:nil];
}

- (void)dealloc {
    self.webView.delegate = nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
	[super viewDidLoad];
    
    CGFloat toolbarHeight = FKToolbarHeightForOrientation(UIInterfaceOrientationPortrait);
    
    self.webView = [[UIWebView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0.f, 0.f, toolbarHeight, 0.f))];
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    self.toolbar.frame = CGRectMake(0.f, self.view.boundsHeight - toolbarHeight, self.view.boundsWidth, toolbarHeight);
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.toolbar];
    
    if (self.fadeAnimationEnabled) {
        self.webView.alpha = 0.f;
    }
    
    [self customize];
	[self reload];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.webView.delegate = nil;
	self.webView = nil;
    self.toolbar = nil;
	self.backItem = nil;
	self.forwardItem = nil;
	self.loadItem = nil;
	self.actionItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	[self updateUI];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self stopLoading];
    
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return FKRotateToAllSupportedOrientations(toInterfaceOrientation);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    CGFloat toolbarHeight = FKToolbarHeightForOrientation(UIInterfaceOrientationPortrait);
    
    self.webView.frameHeight = self.view.boundsHeight - toolbarHeight;
    self.toolbar.frameTop = self.webView.frameBottom;
    self.toolbar.frameHeight = toolbarHeight;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - FKBrowserViewController
////////////////////////////////////////////////////////////////////////

- (void)reload {
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)stopLoading {
    [self.webView stopLoading];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Setter
////////////////////////////////////////////////////////////////////////

- (void)setAddress:(NSString *)address {
    if (address != address_) {
        [self updateAddress:address];
        [self reload];
    }
}

- (void)setUrl:(NSURL *)url {
    if (url != url_) {
        [self updateAddress:[url absoluteString]];
        [self reload];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    if (tintColor != tintColor_) {
        tintColor_ = tintColor;
        [self customize];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (backgroundColor != backgroundColor_) {
        backgroundColor_ = backgroundColor;
        [self customize];
    }
}

- (void)setPresentedModally:(BOOL)presentedModally {
    if (presentedModally != presentedModally_) {
        [self willChangeValueForKey:@"presentedModally"];
        presentedModally_ = presentedModally;
        [self didChangeValueForKey:@"presentedModally"];
        
        if (presentedModally) {
            UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                      target:self
                                                                                      action:@selector(handleDoneButtonPress:)];
            self.navigationItem.leftBarButtonItem = doneItem;
        } else {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Getter
////////////////////////////////////////////////////////////////////////

- (UIBarButtonItem *)backItem {
    if (backItem_ == nil) {
        backItem_ = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"iOSKit.bundle/browserBack"] 
                                                     style:UIBarButtonItemStylePlain 
                                                    target:self.webView 
                                                    action:@selector(goBack)];
    }
    
    backItem_.enabled = self.webView.canGoBack;
    
    return backItem_;
}

- (UIBarButtonItem *)forwardItem {
    if (forwardItem_ == nil) {
        forwardItem_ = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"iOSKit.bundle/browserForward"] 
                                                        style:UIBarButtonItemStylePlain 
                                                       target:self.webView 
                                                       action:@selector(goForward)];
    }
    
    forwardItem_.enabled = self.webView.canGoForward;
    
    return forwardItem_;
}

- (UIBarButtonItem *)actionItem {
    if (actionItem_ == nil) {
        actionItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                    target:self 
                                                                    action:@selector(showActionSheet)];
    }
    
    return actionItem_;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIWebViewDelegate
////////////////////////////////////////////////////////////////////////

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self updateAddress:request.URL.absoluteString];
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self showLoadingIndicatorInNavigationBar];
    [FKNetworkActivityManager addNetworkUser:self];
    
    [self updateUI];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.fadeAnimationEnabled) {
        [self.webView fadeIn];
    }
    
    [self hideLoadingIndicator];
    [FKNetworkActivityManager removeNetworkUser:self];
    
    [self updateUI];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self hideLoadingIndicator];
    [FKNetworkActivityManager removeNetworkUser:self];
    
    [self updateUI];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIActionSheetDelegate
////////////////////////////////////////////////////////////////////////

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        FKInterAppOpenSafari(self.url);
    } else if (buttonIndex == 1 && [MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init]; 
        
        composer.navigationBar.tintColor = self.tintColor;
        [composer setMailComposeDelegate:self]; 
        [composer setMessageBody:self.address isHTML:NO];
        
        if (composer != nil) {
            [self presentModalViewController:composer animated:YES];
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - MFMailComposeViewControllerDelegate
////////////////////////////////////////////////////////////////////////

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissModalViewControllerAnimated:YES];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)updateAddress:(NSString *)address {
    [self willChangeValueForKey:@"address"];
    address_ = address;
    [self didChangeValueForKey:@"address"];
    
    [self willChangeValueForKey:@"url"];
    url_ = [NSURL URLWithString:address];
    [self didChangeValueForKey:@"url"];
}

- (void)updateUI {
    if (self.webView.loading) {
        self.title = _(@"Loading...");
        self.loadItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                      target:self
                                                                      action:@selector(stopLoading)];
    } else {
        self.title = self.webView.documentTitle;
        self.loadItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                      target:self 
                                                                      action:@selector(reload)];
    }
    
    UIBarButtonItem *fixedSpaceItem = [UIBarButtonItem spaceItemWithWidth:kFKBrowserFixedSpaceItemWidth];
    UIBarButtonItem *flexibleSpaceItem = [UIBarButtonItem flexibleSpaceItem];
    
    self.toolbar.items = $array(fixedSpaceItem, self.backItem, flexibleSpaceItem, self.forwardItem, flexibleSpaceItem, 
                                self.loadItem, flexibleSpaceItem, self.actionItem, fixedSpaceItem);
}

- (void)customize {
    self.view.backgroundColor = self.backgroundColor;
    self.webView.scalesPageToFit = YES;
    self.navigationController.navigationBar.tintColor = self.tintColor;
    self.toolbar.tintColor = self.tintColor;
}

- (void)showActionSheet {
    NSString *actionSheetTitle = self.address;
    
    actionSheetTitle = [actionSheetTitle stringByReplacingOccurrencesOfString:@"(^http://)|(/$)" 
                                                                   withString:@"" 
                                                                      options:NSRegularExpressionSearch 
                                                                        range:NSMakeRange(0, actionSheetTitle.length)];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle 
                                                             delegate:self 
                                                    cancelButtonTitle:nil 
                                               destructiveButtonTitle:nil 
                                                    otherButtonTitles:nil];
    
    [actionSheet addButtonWithTitle:_(@"Open in Safari")];
    
    if ([MFMailComposeViewController canSendMail]) {
        [actionSheet addButtonWithTitle:_(@"Mail Link")];
    }
    
    [actionSheet addButtonWithTitle:_(@"Cancel")];
    [actionSheet setCancelButtonIndex:actionSheet.numberOfButtons - 1];
    
    [actionSheet showFromToolbar:self.toolbar];
}

- (void)handleDoneButtonPress:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

@end