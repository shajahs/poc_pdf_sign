import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pdfWidget;
import 'package:signature/signature.dart';
import 'package:signature_poc/pdf_editor_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Sign My Pdf'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.red,
    exportBackgroundColor: Colors.transparent,
    exportPenColor: Colors.black,
    onDrawStart: () => print('onDrawStart called!'),
    onDrawEnd: () => print('onDrawEnd called!'),
  );

  String? _signatureImage;

  void _edit() async {

    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No signature content')));
      return;
    }

    _signatureImage = _controller.toRawSVG();

    PdfMutableDocument doc = await PdfMutableDocument.asset("assets/sample.pdf");
    _editDocument(doc);
    await doc.save(filename: "modified.pdf");
    final dir = (await getExternalStorageDirectory())?.path;
    final filename = '$dir${Platform.pathSeparator}modified.pdf';
    await OpenFilex.open(filename);

    print("PDF Edition Done");
  }

  void _editDocument(PdfMutableDocument document) {

    var page = document.getPage(0);
    page.add(item: pdfWidget.Positioned(
      right: 20.0,
      bottom: 20.0,
      child: pdfWidget.SvgImage(svg: _signatureImage ?? "", width: 100, colorFilter: pdf.PdfColors.grey)));
    /*
    var centeredText = pdfWidget.Center(
        child: pdfWidget.Text(
          "CENTERED TEXT",
          style: pdfWidget.TextStyle(
              fontSize: 40,
              color: pdf.PdfColor.fromHex("#000000"),
              background: pdfWidget.BoxDecoration(color: pdf.PdfColor.fromHex("#000000"))),
        ));
    page.add(item: centeredText);*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? ""),
      ),
      body: ListView(
        children: <Widget>[
          /*Container(
            height: 300,
            child: const Center(
              child: Text('Big container to test scrolling issues'),
            ),
          ),*/
          //SIGNATURE CANVAS
          Signature(
            controller: _controller,
            height: 300,
            backgroundColor: Colors.lightBlueAccent,
          ),
          //OK AND CLEAR BUTTONS
          Container(
            decoration: const BoxDecoration(color: Colors.black),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                //SHOW EXPORTED IMAGE IN NEW ROUTE
                IconButton(
                  icon: const Icon(Icons.image),
                  color: Colors.blue,
                  onPressed: () => exportImage(context),
                ),
                IconButton(
                  icon: const Icon(Icons.polyline),
                  color: Colors.blue,
                  onPressed: () => exportSVG(context),
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() => _controller.undo());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() => _controller.redo());
                  },
                ),
                //CLEAR CANVAS
                IconButton(
                  icon: const Icon(Icons.clear),
                  color: Colors.blue,
                  onPressed: () {
                    setState(() => _controller.clear());
                  },
                ),
              ],
            ),
          ),
          /*Container(
            height: 300,
            child: const Center(
              child: Text('Big container to test scrolling issues'),
            ),
          ),*/
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        tooltip: 'Load',
        icon: Icon(Icons.draw),
        label: Text("Sign & Open"),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _controller.addListener(() => print('Value changed'));
  }

  Future<void> exportImage(BuildContext context) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No signature content')));
      return;
    }

    final Uint8List? data = await _controller.toPngBytes();
    if (data == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Container(
                color: Colors.grey[300],
                child: Image.memory(data),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> exportSVG(BuildContext context) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No signature content')));
      return;
    }

    final SvgPicture data = _controller.toSVG()!;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Container(color: Colors.grey[300], child: data),
            ),
          );
        },
      ),
    );
  }

}
