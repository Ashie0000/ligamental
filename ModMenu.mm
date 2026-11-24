#import "ModMenu.h"
#import "ProductCatalog.h"
#import "StoreKitHooks.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kFragAutoGrantKey  = @"FragUnlock.AutoGrant";
static NSString *const kFragChipOriginKey = @"FragUnlock.ChipOrigin";

#pragma mark - Floating chip (always-on handle)

@interface FragChipView : UIView
@property (nonatomic, copy) void (^onTap)(void);
@end
@implementation FragChipView {
    CGPoint   _dragStart;
    CGPoint   _originStart;
    UILabel  *_label;
}
- (instancetype)init {
    self = [super initWithFrame:CGRectMake(20, 180, 86, 86)];
    if (!self) return nil;
    self.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.09 alpha:0.92];
    self.layer.cornerRadius = 20;
    self.layer.borderWidth = 1.5;
    self.layer.borderColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.78 alpha:1.0].CGColor;
    self.layer.shadowOpacity = 0.6;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 10;

    _label = [[UILabel alloc] initWithFrame:self.bounds];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    _label.textColor = [UIColor whiteColor];
    _label.numberOfLines = 2;
    _label.text = @"FRAG\nUNLOCK";
    [self addSubview:_label];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(onPan:)];
    [self addGestureRecognizer:pan];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(onTapGesture:)];
    [self addGestureRecognizer:tap];

    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kFragChipOriginKey];
    if (saved) {
        CGPoint pt = CGPointFromString(saved);
        self.frame = CGRectMake(pt.x, pt.y, self.bounds.size.width, self.bounds.size.height);
    }
    return self;
}
- (void)onPan:(UIPanGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) {
        _originStart = self.frame.origin;
        _dragStart   = [g locationInView:self.superview];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint cur = [g locationInView:self.superview];
        CGRect f = self.frame;
        f.origin.x = _originStart.x + (cur.x - _dragStart.x);
        f.origin.y = _originStart.y + (cur.y - _dragStart.y);
        self.frame = f;
    } else if (g.state == UIGestureRecognizerStateEnded ||
               g.state == UIGestureRecognizerStateCancelled) {
        [[NSUserDefaults standardUserDefaults]
            setObject:NSStringFromCGPoint(self.frame.origin) forKey:kFragChipOriginKey];
    }
}
- (void)onTapGesture:(UITapGestureRecognizer *)g { if (self.onTap) self.onTap(); }
@end

#pragma mark - Panel VC

@interface FragPanelVC : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                            UISearchBarDelegate>
@property (nonatomic, copy)   NSArray<NSString *> *allProducts;
@property (nonatomic, strong) NSMutableArray<NSString *> *filtered;
@property (nonatomic, strong) NSMutableSet<NSString *>    *selected;
@property (nonatomic, strong) UITableView *tv;
@property (nonatomic, strong) UISearchBar *search;
@property (nonatomic, strong) UISwitch    *autoSwitch;
@end

@implementation FragPanelVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.allProducts = FragKnownProductIdentifiers();
    self.filtered    = [self.allProducts mutableCopy];
    self.selected    = [NSMutableSet set];
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.07 alpha:1.0];
    [self buildChrome];
}
- (void)buildChrome {
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.12 alpha:1.0];
    [self.view addSubview:header];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"FRAG — IAP UNLOCK";
    title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightHeavy];
    title.textColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.78 alpha:1.0];
    [header addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:close];

    UILabel *autoLbl = [[UILabel alloc] init];
    autoLbl.translatesAutoresizingMaskIntoConstraints = NO;
    autoLbl.text = @"Auto-grant any purchase";
    autoLbl.textColor = [UIColor whiteColor];
    autoLbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.view addSubview:autoLbl];

    self.autoSwitch = [[UISwitch alloc] init];
    self.autoSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoSwitch.onTintColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.78 alpha:1.0];
    self.autoSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kFragAutoGrantKey] ||
                         ![[NSUserDefaults standardUserDefaults] objectForKey:kFragAutoGrantKey];
    FragSetAutoGrantEnabled(self.autoSwitch.on);
    [self.autoSwitch addTarget:self action:@selector(onAutoChanged:)
              forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.autoSwitch];

    self.search = [[UISearchBar alloc] init];
    self.search.translatesAutoresizingMaskIntoConstraints = NO;
    self.search.placeholder = @"Filter product ids (diamonds, vip, speoffer…)";
    self.search.delegate = self;
    self.search.barStyle = UIBarStyleBlack;
    self.search.searchBarStyle = UISearchBarStyleMinimal;
    [self.view addSubview:self.search];

    self.tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tv.translatesAutoresizingMaskIntoConstraints = NO;
    self.tv.backgroundColor = [UIColor clearColor];
    self.tv.separatorColor  = [UIColor colorWithWhite:1.0 alpha:0.08];
    self.tv.dataSource = self;
    self.tv.delegate   = self;
    self.tv.allowsMultipleSelection = YES;
    [self.tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"c"];
    [self.view addSubview:self.tv];

    UIStackView *btns = [[UIStackView alloc] init];
    btns.translatesAutoresizingMaskIntoConstraints = NO;
    btns.axis = UILayoutConstraintAxisHorizontal;
    btns.distribution = UIStackViewDistributionFillEqually;
    btns.spacing = 10;
    [self.view addSubview:btns];

    [btns addArrangedSubview:[self pillTitled:@"Select All"    action:@selector(onSelectAll)]];
    [btns addArrangedSubview:[self pillTitled:@"Clear"         action:@selector(onClear)]];
    [btns addArrangedSubview:[self pillTitled:@"Grant Picked"  action:@selector(onGrantPicked)]];
    [btns addArrangedSubview:[self pillTitled:@"Grant ALL"     action:@selector(onGrantAll)]];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor      constraintEqualToAnchor:g.topAnchor],
        [header.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [header.heightAnchor   constraintEqualToConstant:48],
        [title.leadingAnchor   constraintEqualToAnchor:header.leadingAnchor constant:16],
        [title.centerYAnchor   constraintEqualToAnchor:header.centerYAnchor],
        [close.trailingAnchor  constraintEqualToAnchor:header.trailingAnchor constant:-12],
        [close.centerYAnchor   constraintEqualToAnchor:header.centerYAnchor],

        [autoLbl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [autoLbl.topAnchor     constraintEqualToAnchor:header.bottomAnchor constant:10],
        [self.autoSwitch.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.autoSwitch.centerYAnchor  constraintEqualToAnchor:autoLbl.centerYAnchor],

        [self.search.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor constant:8],
        [self.search.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],
        [self.search.topAnchor      constraintEqualToAnchor:autoLbl.bottomAnchor constant:6],

        [self.tv.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tv.topAnchor      constraintEqualToAnchor:self.search.bottomAnchor],
        [self.tv.bottomAnchor   constraintEqualToAnchor:btns.topAnchor constant:-8],

        [btns.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [btns.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [btns.bottomAnchor   constraintEqualToAnchor:g.bottomAnchor constant:-12],
        [btns.heightAnchor   constraintEqualToConstant:44],
    ]];
}
- (UIButton *)pillTitled:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.backgroundColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.22 alpha:1.0];
    b.layer.cornerRadius = 10;
    b.layer.borderWidth  = 1;
    b.layer.borderColor  = [UIColor colorWithRed:1.0 green:0.42 blue:0.78 alpha:0.9].CGColor;
    b.titleLabel.font    = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [b setTitle:t forState:UIControlStateNormal];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark TV
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.filtered.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"c" forIndexPath:ip];
    c.backgroundColor = [UIColor clearColor];
    c.textLabel.textColor = [UIColor whiteColor];
    c.textLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    NSString *pid = self.filtered[ip.row];
    c.textLabel.text = pid;
    c.accessoryType = [self.selected containsObject:pid] ? UITableViewCellAccessoryCheckmark
                                                         : UITableViewCellAccessoryNone;
    c.selectionStyle = UITableViewCellSelectionStyleDefault;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    NSString *pid = self.filtered[ip.row];
    if ([self.selected containsObject:pid]) [self.selected removeObject:pid];
    else                                    [self.selected addObject:pid];
    [t deselectRowAtIndexPath:ip animated:YES];
    [t reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark Search
- (void)searchBar:(UISearchBar *)sb textDidChange:(NSString *)text {
    if (text.length == 0) { self.filtered = [self.allProducts mutableCopy]; }
    else {
        NSPredicate *p = [NSPredicate predicateWithFormat:
                          @"SELF CONTAINS[cd] %@", text];
        self.filtered = [[self.allProducts filteredArrayUsingPredicate:p] mutableCopy];
    }
    [self.tv reloadData];
}

#pragma mark Actions
- (void)onClose { [[FragModMenu shared] dismiss]; }
- (void)onAutoChanged:(UISwitch *)s {
    FragSetAutoGrantEnabled(s.on);
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:kFragAutoGrantKey];
}
- (void)onSelectAll {
    for (NSString *pid in self.filtered) [self.selected addObject:pid];
    [self.tv reloadData];
}
- (void)onClear { [self.selected removeAllObjects]; [self.tv reloadData]; }
- (void)onGrantPicked {
    NSArray *picked = self.selected.allObjects;
    if (picked.count == 0) { [self toast:@"nothing picked"]; return; }
    FragGrantProducts(picked);
    [self toast:[NSString stringWithFormat:@"granted %lu", (unsigned long)picked.count]];
}
- (void)onGrantAll {
    FragGrantProducts(self.allProducts);
    [self toast:[NSString stringWithFormat:@"granted all %lu", (unsigned long)self.allProducts.count]];
}
- (void)toast:(NSString *)msg {
    UILabel *l = [[UILabel alloc] init];
    l.text = msg;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    l.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.3 alpha:0.95];
    l.textAlignment = NSTextAlignmentCenter;
    l.alpha = 0.0;
    l.layer.cornerRadius = 12;
    l.clipsToBounds = YES;
    CGFloat w = MIN(260, self.view.bounds.size.width - 60);
    l.frame = CGRectMake((self.view.bounds.size.width - w)/2, 90, w, 36);
    [self.view addSubview:l];
    [UIView animateWithDuration:0.18 animations:^{ l.alpha = 1.0; } completion:^(BOOL _) {
        [UIView animateWithDuration:0.4 delay:1.0 options:0 animations:^{ l.alpha = 0; }
                         completion:^(BOOL _2) { [l removeFromSuperview]; }];
    }];
}
@end

#pragma mark - Menu host

@interface FragModMenu ()
@property (nonatomic, strong) UIWindow      *window;
@property (nonatomic, strong) FragChipView  *chip;
@property (nonatomic, strong) UIView        *scrim;
@property (nonatomic, strong) UIView        *panel;
@property (nonatomic, strong) FragPanelVC   *panelVC;
@property (nonatomic, assign) BOOL           open;
@end

@implementation FragModMenu

+ (instancetype)shared {
    static FragModMenu *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ m = [FragModMenu new]; });
    return m;
}

- (void)present {
    if (self.window) return;
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]] &&
            s.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)s; break;
        }
    }
    UIWindow *w = scene ? [[UIWindow alloc] initWithWindowScene:scene]
                        : [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    w.windowLevel = UIWindowLevelAlert + 10;
    w.backgroundColor = [UIColor clearColor];
    w.rootViewController = [UIViewController new];
    w.rootViewController.view.backgroundColor = [UIColor clearColor];
    w.hidden = NO;
    self.window = w;

    self.chip = [FragChipView new];
    __weak typeof(self) weakSelf = self;
    self.chip.onTap = ^{ [weakSelf toggle]; };
    [w.rootViewController.view addSubview:self.chip];

    // Pass-through for anything outside the chip until the panel opens.
    [self installHitTestPassthrough:w];
}

- (void)installHitTestPassthrough:(UIWindow *)w {
    static Class dynCls = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dynCls = objc_allocateClassPair([w class], "FragPassthroughWindow", 0);
        IMP imp = imp_implementationWithBlock(^UIView *(UIWindow *_self, CGPoint pt, UIEvent *ev) {
            UIView *hit = ((UIView *(*)(id,SEL,CGPoint,UIEvent *))objc_msgSend)
                (_self, @selector(frag_hitTest:withEvent:), pt, ev);
            if (hit == _self || hit == _self.rootViewController.view) return nil;
            return hit;
        });
        Method orig = class_getInstanceMethod([UIWindow class], @selector(hitTest:withEvent:));
        class_addMethod(dynCls, @selector(frag_hitTest:withEvent:),
                        method_getImplementation(orig), method_getTypeEncoding(orig));
        class_replaceMethod(dynCls, @selector(hitTest:withEvent:),
                            imp, method_getTypeEncoding(orig));
        objc_registerClassPair(dynCls);
    });
    object_setClass(w, dynCls);
}

- (void)toggle {
    if (self.open) [self closePanel]; else [self openPanel];
}

- (void)openPanel {
    UIView *host = self.window.rootViewController.view;
    self.scrim = [[UIView alloc] initWithFrame:host.bounds];
    self.scrim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    self.scrim.alpha = 0;
    self.scrim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(closePanel)];
    [self.scrim addGestureRecognizer:tap];
    [host addSubview:self.scrim];

    CGFloat w = MIN(360, host.bounds.size.width - 20);
    CGFloat h = host.bounds.size.height * 0.80;
    self.panel = [[UIView alloc] initWithFrame:CGRectMake((host.bounds.size.width - w)/2,
                                                          host.bounds.size.height,
                                                          w, h)];
    self.panel.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.07 alpha:1.0];
    self.panel.layer.cornerRadius = 20;
    self.panel.layer.borderWidth  = 1.0;
    self.panel.layer.borderColor  = [UIColor colorWithRed:1.0 green:0.42 blue:0.78 alpha:0.9].CGColor;
    self.panel.clipsToBounds = YES;
    [host addSubview:self.panel];

    self.panelVC = [FragPanelVC new];
    [self.panelVC.view setFrame:self.panel.bounds];
    self.panelVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight;
    [self.panel addSubview:self.panelVC.view];
    [self.window.rootViewController addChildViewController:self.panelVC];
    [self.panelVC didMoveToParentViewController:self.window.rootViewController];

    [self.window.rootViewController.view bringSubviewToFront:self.chip];
    self.open = YES;

    [UIView animateWithDuration:0.28 animations:^{
        self.scrim.alpha = 1.0;
        CGRect f = self.panel.frame;
        f.origin.y = (host.bounds.size.height - f.size.height) / 2;
        self.panel.frame = f;
    }];
}

- (void)closePanel {
    if (!self.open) return;
    UIView *host = self.window.rootViewController.view;
    [UIView animateWithDuration:0.22 animations:^{
        self.scrim.alpha = 0;
        CGRect f = self.panel.frame;
        f.origin.y = host.bounds.size.height;
        self.panel.frame = f;
    } completion:^(BOOL _) {
        [self.scrim removeFromSuperview];       self.scrim = nil;
        [self.panel removeFromSuperview];       self.panel = nil;
        [self.panelVC willMoveToParentViewController:nil];
        [self.panelVC.view removeFromSuperview];
        [self.panelVC removeFromParentViewController];
        self.panelVC = nil;
        self.open = NO;
    }];
}

- (void)dismiss { [self closePanel]; }

@end
