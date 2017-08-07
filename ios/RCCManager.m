#import "RCCManager.h"
#import "RCCViewController.h"
#import <React/RCTBridge.h>
#import <React/RCTRedBox.h>
#import <Foundation/Foundation.h>
#import <React/RCTRootView.h>

static const int SPLASH_TAG = 54379;

@interface RCCManager() <RCTBridgeDelegate>
@property (nonatomic, strong) NSMutableDictionary *modulesRegistry;
@property (nonatomic, strong) RCTBridge *sharedBridge;
@property (nonatomic, strong) NSURL *bundleURL;
@end

@implementation RCCManager

+ (instancetype)sharedInstance
{
  static RCCManager *sharedInstance = nil;
  static dispatch_once_t onceToken = 0;

  dispatch_once(&onceToken,^{
    if (sharedInstance == nil)
    {
      sharedInstance = [[RCCManager alloc] init];
    }
  });

  return sharedInstance;
}

+ (instancetype)sharedIntance
{
  return [RCCManager sharedInstance];
}

- (instancetype)init
{
  self = [super init];
  if (self)
  {
    self.modulesRegistry = [@{} mutableCopy];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRNReload) name:RCTReloadNotification object:nil];
  }
  return self;
}

-(void)clearModuleRegistry
{
  [self.modulesRegistry removeAllObjects];
}

-(void)onRNReload
{
  id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
  appDelegate.window.rootViewController = nil;
  [self clearModuleRegistry];
}

-(void)registerController:(UIViewController*)controller componentId:(NSString*)componentId componentType:(NSString*)componentType
{
  if (controller == nil || componentId == nil)
  {
    return;
  }

  NSMutableDictionary *componentsDic = self.modulesRegistry[componentType];
  if (componentsDic == nil)
  {
    componentsDic = [@{} mutableCopy];
    self.modulesRegistry[componentType] = componentsDic;
  }

  /*
  TODO: we really want this error, but we need to unregister controllers when they dealloc
  if (componentsDic[componentId])
  {
    [self.sharedBridge.redBox showErrorMessage:[NSString stringWithFormat:@"Controllers: controller with id %@ is already registered. Make sure all of the controller id's you use are unique.", componentId]];
  }
  */
   
  componentsDic[componentId] = controller;
}

-(void)unregisterController:(UIViewController*)vc
{
  if (vc == nil) return;
  
  for (NSString *key in [self.modulesRegistry allKeys])
  {
    NSMutableDictionary *componentsDic = self.modulesRegistry[key];
    for (NSString *componentID in [componentsDic allKeys])
    {
      UIViewController *tmpVc = componentsDic[componentID];
      if (tmpVc == vc)
      {
        [componentsDic removeObjectForKey:componentID];
      }
    }
  }
}

-(id)getControllerWithId:(NSString*)componentId componentType:(NSString*)componentType
{
  if (componentId == nil)
  {
    return nil;
  }

  id component = nil;

  NSMutableDictionary *componentsDic = self.modulesRegistry[componentType];
  if (componentsDic != nil)
  {
    component = componentsDic[componentId];
  }

  return component;
}

-(id)getDrawerController
{
  NSDictionary *drawers = self.modulesRegistry[@"DrawerControllerIOS"];
  return drawers.allValues.firstObject;
}

-(NSString*) getIdForController:(UIViewController*)vc
{
  if([vc isKindOfClass:[RCCViewController class]])
  {
    NSString *controllerId = ((RCTRootView *)((RCCViewController*)vc).view).moduleName;
    if(controllerId != nil)
    {
      return controllerId;
    }
  }
  
  for (NSString *key in [self.modulesRegistry allKeys])
  {
    NSMutableDictionary *componentsDic = self.modulesRegistry[key];
    for (NSString *componentID in [componentsDic allKeys])
    {
      UIViewController *tmpVc = componentsDic[componentID];
      if (tmpVc == vc)
      {
        return componentID;
      }
    }
  }
  return nil;
}

-(void)initBridgeWithBundleURL:(NSURL *)bundleURL
{
  [self initBridgeWithBundleURL :bundleURL launchOptions:nil];
}

-(void)initBridgeWithBundleURL:(NSURL *)bundleURL launchOptions:(NSDictionary *)launchOptions
{
  if (self.sharedBridge) return;

  self.bundleURL = bundleURL;
  self.sharedBridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  
  [self rootSplashScreen];
}

-(void)rootSplashScreen
{
  UIView *splashView = [self generateSplashScreen];

  if (splashView != nil)
  {
    UIViewController *splashVC = [[UIViewController alloc] init];
    splashVC.view = splashView;

    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = splashVC;
    [appDelegate.window makeKeyAndVisible];
  }
}

-(void)addSplashScreen
{
  UIView *splashView = [self generateSplashScreen];

  if (splashView != nil)
  {
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    UIWindow *window = appDelegate.window;
  	[self removeSplashScreen];
    splashView.tag = SPLASH_TAG;
 	[window addSubview:splashView];
  }
}

-(void)removeSplashScreen
{
  id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
  UIWindow *window = appDelegate.window;
  [[window viewWithTag:SPLASH_TAG] removeFromSuperview];
}

-(UIView *)generateSplashScreen
{
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  UIView *splashView = nil;
  
  NSString* launchStoryBoard = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchStoryboardName"];
  if (launchStoryBoard != nil)
  {//load the splash from the storyboard that's defined in the info.plist as the LaunchScreen
    @try
    {
      splashView = [[NSBundle mainBundle] loadNibNamed:launchStoryBoard owner:self options:nil][0];
      if (splashView != nil)
      {
        splashView.frame = CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height);
      }
    }
    @catch(NSException *e)
    {
      splashView = nil;
    }
  }
  else
  {//load the splash from the DEfault image or from LaunchImage in the xcassets
    CGFloat screenHeight = screenBounds.size.height;
    
    NSString* imageName = @"Default";
    if (screenHeight == 568)
      imageName = [imageName stringByAppendingString:@"-568h"];
    else if (screenHeight == 667)
      imageName = [imageName stringByAppendingString:@"-667h"];
    else if (screenHeight == 736)
      imageName = [imageName stringByAppendingString:@"-736h"];
    
    //xcassets LaunchImage files
    UIImage *image = [UIImage imageNamed:imageName];
    if (image == nil)
    {
      imageName = @"LaunchImage";
      
      if (screenHeight == 480)
        imageName = [imageName stringByAppendingString:@"-700"];
      if (screenHeight == 568)
        imageName = [imageName stringByAppendingString:@"-700-568h"];
      else if (screenHeight == 667)
        imageName = [imageName stringByAppendingString:@"-800-667h"];
      else if (screenHeight == 736)
        imageName = [imageName stringByAppendingString:@"-800-Portrait-736h"];
      
      image = [UIImage imageNamed:imageName];
    }
    
    if (image != nil)
    {
      splashView = [[UIImageView alloc] initWithImage:image];
    }
  }

  return splashView;
}

-(RCTBridge*)getBridge
{
  return self.sharedBridge;
}

-(UIWindow*)getAppWindow
{
  UIApplication *app = [UIApplication sharedApplication];
  UIWindow *window = (app.keyWindow != nil) ? app.keyWindow : app.windows[0];
  return window;
}

#pragma mark - RCTBridgeDelegate methods

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return self.bundleURL;
}

@end
