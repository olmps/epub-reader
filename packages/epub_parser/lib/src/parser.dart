import 'dart:convert';
import 'dart:io';

// TODO: remove any flutter-related dependency
import 'package:flutter_archive/flutter_archive.dart';

import 'entities/chapter.dart';
import 'entities/epub.dart';
import 'entities/smil.dart';
import 'entities/xml_entity.dart';

import 'package:path_provider/path_provider.dart';

class ManifestResource {
  String id;
  String href;
  String mediaOverlayId;
  String mediaType;

  ManifestResource(this.id, this.href, this.mediaOverlayId, this.mediaType);
}

typedef OnProgress = Function(double progress);
typedef OnFinish = Function(Epub epub);

class EpubParser {
  // Control Properties
  static Directory _extractedEpubDirectory;
  static XMLEntity _rootContentFile;
  static Map<String, ManifestResource> _resources;

  // Static
  /// Indicates the root path of all ebook resources
  static String get _resourcesDirectoryPath => _rootContentFile.path.substring(
        0,
        _rootContentFile.path.lastIndexOf('/'),
      );

  /// Parse epub saved at `path`.
  ///
  /// `onProgress` and `onFinish` indicates respectively the extraction progress
  /// and the finish event.
  static parse(String path, OnProgress onProgress, OnFinish onFinish) async {
    try {
      await _extractEpubContent(path, onProgress);
      await _loadContentFile();
      _readManifest();
      final chapters = await _readSpine();
      final metadata = await _readMetadata();
      final epub = Epub(metadata, chapters);

      onFinish(epub);
    } catch (error) {
      throw error;
    }
  }

  /// Extract the content from epub located at `path`
  ///
  /// Extract all epub content to the Temporary Directory.
  static _extractEpubContent(String path, OnProgress onProgress) async {
    final zipFile = File(path);
    final epubFileName = path.substring(path.lastIndexOf("/") + 1, path.lastIndexOf("."));
    _extractedEpubDirectory = await getTemporaryDirectory();
    _extractedEpubDirectory = _extractedEpubDirectory.createTempSync("${epubFileName}_unzipped");

    try {
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: _extractedEpubDirectory,
        onExtracting: (zipEntry, progress) {
          onProgress(progress);
          return ExtractOperation.extract;
        },
      );
    } catch (e) {
      throw e;
    }
  }

  /// Extract Epub root file content
  ///
  /// Gets the resources main file - which has its absolute path located at
  /// `META-INF/container.xml` file.
  ///
  /// This root resources file indicates where all other epub resources files
  /// are located. It also presents the epub structure - like media files that
  /// must be played, which page these media files are associated with,
  /// the timestamp that they must be played, etc.
  static _loadContentFile() async {
    try {
      final manifestContainerPath = 'META-INF/container.xml';
      final manifestPath = "${_extractedEpubDirectory.path}/$manifestContainerPath";
      final manifestXml = XMLEntity(manifestPath);
      await manifestXml.load();

      final rootfileTagAttributes = manifestXml["rootfiles"]["rootfile"].attributes();
      final rootFilePath = rootfileTagAttributes['full-path'];

      final contentFilePath = "${_extractedEpubDirectory.path}/$rootFilePath";
      final contentFile = XMLEntity(contentFilePath);
      await contentFile.load();

      _rootContentFile = contentFile;
    } catch (error) {
      throw error;
    }
  }

  /// Reads Manifest file
  ///
  /// The manifest `item` tags indicates the ebook resources with their
  /// respective paths - like pages, media files, etc.
  static _readManifest() {
    var resources = Map<String, ManifestResource>();
    final allItems = _rootContentFile["manifest"].all();

    allItems.forEach((item) {
      final attributes = item.attributes();
      final id = attributes["id"];
      final href = attributes["href"];
      final mediaOverlay = attributes["media-overlay"];
      final mediaType = attributes["media-type"];

      resources[id] = ManifestResource(id, href, mediaOverlay, mediaType);
    });

    _resources = resources;
  }

  /// Read Epub Spine structure
  ///
  /// The `spine` tag indicates the ebook chapters order.
  static Future<List<Chapter>> _readSpine() async {
    List<Chapter> chapters = [];
    final chaptersReferences = _rootContentFile["spine"].all();

    for (var reference in chaptersReferences) {
      final chapterIdentifier = reference.attributes()["idref"];
      final chapterResource = _resources[chapterIdentifier];

      final chapterContentPath = "$_resourcesDirectoryPath/${chapterResource.href}";

      final chapterContent = await _chapterContent(chapterContentPath);
      final chapterSmil = await _chapterSmil(chapterResource);

      final chapter = Chapter(chapterContent, chapterContentPath, chapterSmil);

      chapters.add(chapter);
    }

    return chapters;
  }

  static Future<String> _chapterContent(String path) async {
    final pageDirectory = path.substring(0, path.lastIndexOf('/'));
    String chapterContent = await File(path).readAsString();

    final hrefRegex = RegExp(r'(href=")[^"]*"');
    final srcRegex = RegExp(r'(src=")[^"]*"');

    // CSS

    final cssRegex = RegExp(r'(<link)(.*)(rel="stylesheet")(.*)(\/>)');
    final allCss = cssRegex.allMatches(chapterContent).map((e) => e[0]);

    for (var css in allCss) {
      final fileReference = hrefRegex.firstMatch(css)[0];
      final filePath = fileReference.substring(6, fileReference.length - 1);
      final cssContent = await File("$pageDirectory/$filePath").readAsString();

      chapterContent =
          chapterContent.replaceAllMapped("<head>", (match) => "${match.group(0)} <style>$cssContent</style>");
      chapterContent = chapterContent.replaceAll(css, "");
    }

    // IMAGES

    final imageRegex = RegExp(r'(<img)(.*)(src=")(.*)(\/>)');
    final allImages = imageRegex.allMatches(chapterContent).map((e) => e[0]);

    for (var image in allImages) {
      final fileReference = srcRegex.firstMatch(image)[0];
      final filePath = fileReference.substring(5, fileReference.length - 1);
      final imageContent = await File("$pageDirectory/$filePath").readAsBytes();

      final newImageSrc = image.replaceAll(fileReference, 'src="data:image/png;base64,${base64Encode(imageContent)}"');
      chapterContent = chapterContent.replaceAll(image, newImageSrc);
    }

    // JAVASCRIPT

    final jsRegex = RegExp(r'(<script)(.*)(type="text/javascript")(.*)(src=")(.*)(>)');
    final allJs = jsRegex.allMatches(chapterContent).map((e) => e[0]);

    for (var js in allJs) {
      final fileReference = srcRegex.firstMatch(js)[0];
      final filePath = fileReference.substring(5, fileReference.length - 1);
      final jsContent = await File("$pageDirectory/$filePath").readAsString();

      chapterContent =
          chapterContent.replaceAllMapped("<head>", (match) => "${match.group(0)} <script>$jsContent</script>");
      chapterContent = chapterContent.replaceAll(js, "");
    }

    // META
    final viewportRegex = RegExp(r'<meta(.*)name="viewport"(.*)\/>');
    final viewportReference = viewportRegex.firstMatch(chapterContent);
    final desiredViewport = "<meta name\"viewport\" content=\"width=device-width, user-scalable=no\" />";

    if (viewportReference != null) {
      chapterContent = chapterContent.replaceAll(viewportReference[0], desiredViewport);
    } else {
      chapterContent = chapterContent.replaceAllMapped("<head>", (match) => "${match.group(0)} $desiredViewport");
    }

    return chapterContent;
  }

  static Future<Smil> _chapterSmil(ManifestResource chapterResources) async {
    final smilIdentifier = chapterResources.mediaOverlayId;
    Smil chapterSmil;
    if (smilIdentifier != null) {
      final smilResource = _resources[smilIdentifier];
      final smilAbsolutePath = "$_resourcesDirectoryPath/${smilResource.href}";
      chapterSmil = await Smil.fromFilePath(smilAbsolutePath);
    }

    return chapterSmil;
  }

  static Future<EpubMetadata> _readMetadata() async {
    final metadata = _rootContentFile["metadata"];
    final allMetas = metadata.allOfTag("meta");

    // Cover Page
    final coverMeta = allMetas.firstWhere((meta) => meta.attributes()["name"] == "cover");
    final coverIdentifier = coverMeta.attributes()["content"];
    final coverImagePath = _resources[coverIdentifier].href;
    final coverAbsolutePath = "$_resourcesDirectoryPath/$coverImagePath";

    // Highlight Class Name
    final highlightClassMeta = allMetas.firstWhere((meta) {
      return meta.attributes().containsKey("property") && meta.attributes()["property"] == "media:active-class";
    }, orElse: () => null);

    final highlightClassName = highlightClassMeta != null ? highlightClassMeta.value : "";

    final epubMetadata = EpubMetadata(coverAbsolutePath, highlightClassName);
    await epubMetadata.load();

    return epubMetadata;
  }
}
