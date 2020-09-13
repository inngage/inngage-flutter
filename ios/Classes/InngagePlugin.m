#import "InngagePlugin.h"
#if __has_include(<inngage_plugin/inngage_plugin-Swift.h>)
#import <inngage_plugin/inngage_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "inngage_plugin-Swift.h"
#endif

@implementation InngagePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftInngagePlugin registerWithRegistrar:registrar];
}
@end
