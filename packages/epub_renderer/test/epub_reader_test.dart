import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epub_parser/epub_parser.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = MockPathProviderPlatform();
    // This is required because we manually register the Linux path provider when on the Linux platform.
    // Will be removed when automatic registration of dart plugins is implemented.
    // See this issue https://github.com/flutter/flutter/issues/52267 for details
    disablePathProviderPlatformOverride = true;

    final tempDir = await getTemporaryDirectory();

    // Save the epub in the local directory
    final epubData = await rootBundle.load('assets/book.epub');
    List<int> epubDataBytes = Uint8List.view(epubData.buffer);
    final epubLocalPath = "${tempDir.path}/book.epub";
    final epubFile = File(epubLocalPath);

    var raf = epubFile.openSync(mode: FileMode.write);
    raf.writeFromSync(epubDataBytes);
    await raf.close();
  });

  test('Epub is correctly unzipped', () async {
    final completer = Completer<void>();
    final tempDir = await getTemporaryDirectory();

    var epubPath = "${tempDir.path}/book.epub";

    EpubParser.parse(epubPath, (progress) {
      print("Epub progress $progress");
    }, (epub) {
      print("Finished");
      completer.complete();
    });

    expect(completer.isCompleted, isTrue);
  });
}

class MockPathProviderPlatform extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {
  Future<String> getTemporaryPath() async {
    return 'temporaryPath';
  }
}
