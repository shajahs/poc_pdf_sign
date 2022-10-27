import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf_image_renderer/pdf_image_renderer.dart' as pdfRender;

class PdfRawImage  extends pdfWidgets.ImageProvider {
  final Uint8List data;
  final Size size;
  late pdf.PdfDocument document;


  PdfRawImage({required this.data, required this.size}) : super(size.width.toInt(), size.height.toInt(), pdf.PdfImageOrientation.topLeft, 72.0);

  @override
  pdf.PdfImage buildImage(pdfWidgets.Context context, {int? width, int? height}) {
    return pdf.PdfImage.file(
      document,
      bytes: data,
      orientation: orientation,
    );
  }
}

class _PdfFileHandler {
  static Future<File> getFileFromAssets(String filename) async {
    assert(filename != null);
    final byteData = await rootBundle.load(filename);
    var name = filename
        .split(Platform.pathSeparator)
        .last;
    var absoluteName = '${(await getApplicationDocumentsDirectory()).path}/$name';
    final file = File(absoluteName);

    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file;
  }

  static Future<List<PdfRawImage>> loadPdf(String path) async {
    var file = pdfRender.PdfImageRendererPdf(path: path);
    await file.open();
    var count = await file.getPageCount();
    var images = <PdfRawImage>[];
    for (var i = 0; i < count; i++) {
      var size = await file.getPageSize(pageIndex: 0);
      var rawImage = await file.renderPage(
        //background: Colors.transparent,
        x: 0,
        y: 0,
        width: size.width,
        height: size.height,
        scale: 1.0,
        pageIndex: i,
      );
      if(rawImage != null) {
        images.add(PdfRawImage(
          data: rawImage,
          size: Size(size.width.toDouble(), size.height.toDouble()),
        ));
      }
    }
    return images;
  }

  static Future<File> save(pdfWidgets.Document document, String filename,
      {String? directory}) async {
    final dir = directory ?? (await getExternalStorageDirectory())?.path;
    final file = File('$dir${Platform.pathSeparator}$filename');
    final data = await document.save();
    return await file.writeAsBytes(data);
  }
}

class PdfMutablePage {
  final PdfRawImage _background;
  final List<pdfWidgets.Widget> _stackedItems;

  PdfMutablePage({required PdfRawImage background})
      : _background = background,
        _stackedItems = [];

  void add({required pdfWidgets.Widget item}) {
    _stackedItems.add(item);
  }

  Size get size => _background.size;

  pdfWidgets.Page build(pdfWidgets.Document document) {
    _background.document = document.document;
    final format = pdf.PdfPageFormat(
        _background.size.width, _background.size.height);
    return pdfWidgets.Page(
        pageFormat: format,
        orientation: pdfWidgets.PageOrientation.portrait,
        build: (context) {
          return pdfWidgets.Stack(
            children: [
              pdfWidgets.Image(_background),
              ..._stackedItems,
            ],
          );
        });
  }
}

class PdfImageProvider extends ImageProvider {
  @override
  ImageStreamCompleter load(Object key, Future<
      Codec> Function(Uint8List bytes, {bool allowUpscaling, int cacheHeight, int cacheWidth}) decode) {
    // TODO: implement load
    throw UnimplementedError();
  }

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    // TODO: implement obtainKey
    throw UnimplementedError();
  }

}

class PdfMutableDocument {
  String _filePath;
  final List<PdfMutablePage> _pages;

  PdfMutableDocument._({List<PdfMutablePage>? pages, required String filePath})
      : _pages = pages ?? [],
        _filePath = filePath;

  static Future<PdfMutableDocument> asset(String assetName) async {
    var copy = await _PdfFileHandler.getFileFromAssets(assetName);
    final rawImages = await _PdfFileHandler.loadPdf(copy.path);
    final pages = rawImages.map((raw) => PdfMutablePage(background: raw))
        .toList();
    return PdfMutableDocument._(
        pages: pages, filePath: copy.uri.pathSegments.last);
  }

  void addPage(PdfMutablePage page) => _pages.add(page);

  PdfMutablePage getPage(int index) => _pages[index];

  pdfWidgets.Document build() {
    var doc = pdfWidgets.Document();
    _pages.forEach((page) => doc.addPage(page.build(doc)));
    return doc;
  }

  Future<File> save({String? filename}) async {
    File file = await _PdfFileHandler.save(build(), filename ?? _filePath);
    return file;
  }
}
