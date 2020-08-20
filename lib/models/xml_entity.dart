import 'dart:io';

import 'package:xml/xml.dart' as XML;

/// Abstraction of a XML document
///
/// Encapsulates a XML file and exposes auxiliary functions to easily navigate
/// through the XML file tags.
class XMLEntity {
  String filePath;

  /// XML navigation tree. It indicates the tag that the current entity
  /// represents.
  /// As an example, it may be: `root/child1/list/5/finalElement`,
  /// which indicates that the current entity represents the nsted `finalElement`
  /// tag, which can be found by following the path `oot/child1/list/5`
  String _treePath = "";

  /// XML root document
  XML.XmlDocument _rootDocument;

  XMLEntity(this.filePath);

  XMLEntity._(this._rootDocument, this._treePath);

  load() async {
    final localFile = File(filePath);

    try {
      String fileContent = await localFile.readAsString();
      _rootDocument = XML.parse(fileContent);
    } catch (error) {
      throw error;
    }
  }

  XMLEntity operator [](String tag) {
    if (_treePath.isNotEmpty)
      return XMLEntity._(_rootDocument, "$_treePath/$tag");
    return XMLEntity._(_rootDocument, tag);
  }

  /// Returns all tag attributes
  ///
  /// Example: `<tag attr1=value1 attr2=value2 />` returns the mapping of the
  /// properties: `{ 'attr1'='value1', 'attr2'='value2' }`
  Map<String, String> attributes() {
    XML.XmlElement nestedElement = _nestedElement();

    var attributes = Map<String, String>();
    nestedElement.attributes.toList().forEach((attribute) {
      attributes[attribute.name.local] = attribute.value;
    });

    return attributes;
  }

  String get value {
    XML.XmlElement nestedElement = _nestedElement();

    return nestedElement.text;
  }

  /// Returns a list of all children tags from current entity
  /// 
  /// Example: `xmlEntity["tag"].all()` will return all children entities from `tag`.
  /// Considering the following XML structure:
  /// 
  /// <a>
  ///   <b/>
  ///   <c/>
  ///   <d/>
  /// </a>
  ///
  /// Using `xml["a"].all()` will return the entities [b,c,d]
  List<XMLEntity> all() {
    XML.XmlElement nestedElement = _nestedElement();
    var allElements = List<XMLEntity>();
    var index = 0;

    // `children` elements returns not only XML tags, but also XML comments.
    // That's why we filter by `Element` type.
    final nodeChilds = nestedElement.children
        .toList()
        .where((element) => element.nodeType == XML.XmlNodeType.ELEMENT);

    nodeChilds.toList().forEach((element) {
      var xmlElement = element as XML.XmlElement;
      var formattedIndex = nodeChilds.length > 1 ? "/${index.toString()}" : "";
      allElements.add(XMLEntity._(
          _rootDocument, "$_treePath/${xmlElement.name.local}$formattedIndex"));
      index += 1;
    });

    return allElements;
  }

  /// Returns a list of all children tags filtered by `tag` name.
  /// 
  /// Similar to `.all()`, it return all children tags but filtering them by
  /// the tags name.
  List<XMLEntity> allOfTag(String tag) {
    XML.XmlElement nestedElement = _nestedElement();
    var allElements = List<XMLEntity>();
    var index = 0;

    final nodeChilds = nestedElement.children
        .where((element) => element.nodeType == XML.XmlNodeType.ELEMENT)
        .toList();
    for (var element in nodeChilds) {
      var xmlElement = element as XML.XmlElement;
      if (xmlElement.name.local != tag) {
        continue;
      }
      var formattedIndex = "/${index.toString()}";
      allElements
          .add(XMLEntity._(_rootDocument, "$_treePath/$tag$formattedIndex"));
      index += 1;
    }

    if (allElements.length == 1) {
      final path = allElements[0]._treePath;
      allElements[0]._treePath = path.substring(0, path.lastIndexOf('/'));
    }

    return allElements;
  }

  /// Get the tag represented by `_threePath`.
  /// 
  /// Iterates through the XML tree to find the element which is represented
  /// by `_threePath`.
  XML.XmlElement _nestedElement() {
    final splitPath = _treePath.split("/");

    XML.XmlElement currentElement = _rootDocument.rootElement;

    for (var i = 0; i < splitPath.length; i++) {
      final path = splitPath[i];
      final pathChilds = currentElement.findElements(path);

      if (pathChilds.isEmpty) throw "This child path doesn't exists";

      // If current tag has a list of childs
      if (pathChilds.length > 1) {
        // The child is represented by an index in the path.
        // Example: `root/list/5/element`, we will extract the index `5`.
        final index = int.tryParse(splitPath[++i]);
        if (index == null) throw "This is not a single child element";

        final nodeChilds = pathChilds
            .where((element) => element.nodeType == XML.XmlNodeType.ELEMENT)
            .toList();
        currentElement = nodeChilds[index];
      } else {
        currentElement = pathChilds.first;
      }
    }

    return currentElement;
  }
}
