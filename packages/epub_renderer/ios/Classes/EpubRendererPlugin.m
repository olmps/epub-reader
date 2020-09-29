#import "EpubRendererPlugin.h"
#if __has_include(<epub_renderer/epub_renderer-Swift.h>)
#import <epub_renderer/epub_renderer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "epub_renderer-Swift.h"
#endif

@implementation EpubRendererPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEpubRendererPlugin registerWithRegistrar:registrar];
}
@end
