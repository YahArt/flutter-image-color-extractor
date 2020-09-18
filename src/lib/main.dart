import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as ImageLibrary;

main() => runApp(ColorPickerApp());

class RawImageResult {
  ImageLibrary.Image rawImage;
  Uint8List rawData;

  RawImageResult({this.rawImage, this.rawData});
}

class ColorPickerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Extract Colors from Image',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: ColorPickerWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ColorPickerWidget extends StatefulWidget {
  @override
  _ColorPickerWidgetState createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  final String _imagePath = 'assets/sample-image.jpg';
  Future<RawImageResult> _loadRawImage(String imagePath) async {
    ByteData imageBytes;
    imageBytes = await rootBundle.load(imagePath);
    return Future.delayed(const Duration(seconds: 1), () {
      final image = ImageLibrary.decodeImage(imageBytes.buffer.asUint8List());
      final data = imageBytes.buffer.asUint8List();
      return RawImageResult(rawData: data, rawImage: image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Center(child: Text('Extract Colors from Image')),
      ),
      body: FutureBuilder(
        future: _loadRawImage(_imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ImageColorPickerWidget(
              result: snapshot.data,
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Text(
              'Decoding Image...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ));
          }
          return Center(
              child: Text(
            'Something went wrong...',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ));
        },
      ),
    );
  }
}

class ImageColorPickerWidget extends StatefulWidget {
  final RawImageResult result;

  ImageColorPickerWidget({
    this.result,
  });

  @override
  _ImageColorPickerWidgetState createState() => _ImageColorPickerWidgetState();
}

class _ImageColorPickerWidgetState extends State<ImageColorPickerWidget> {
  List<Widget> _colors;
  Color _getColorForPixel(int pixel) {
    // The credit for this conversion code goes to https://gist.github.com/roipeker/9315aa25301f5c0362caaebd15876c2f
    int r = (pixel >> 16) & 0xFF;
    int b = pixel & 0xFF;
    int convertedPixelColor = (pixel & 0xFF00FF00) | (b << 16) | r;
    return Color(convertedPixelColor);
  }

  _getRandomColors() {
    return List.generate(16, (index) {
      final x = Random.secure().nextInt(widget.result.rawImage.width);
      final y = Random.secure().nextInt(widget.result.rawImage.height);
      Color color = _getColorForPosition(x, y);
      return Container(
        padding: EdgeInsets.all(5),
        color: color,
      );
    });
  }

  Color _getColorForPosition(int x, int y) {
    final pixelRawColor = widget.result.rawImage.getPixelSafe(x, y);
    final color = _getColorForPixel(pixelRawColor);
    return color;
  }

  @override
  void initState() {
    _colors = _getRandomColors();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _colors = _getRandomColors();
        });
      },
      child: Container(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 16.0),
              child: GridView.count(
                  shrinkWrap: true,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  crossAxisCount: 8,
                  children: _colors),
            ),
            Expanded(child: Center(child: Image.memory(widget.result.rawData))),
          ],
        ),
      ),
    );
  }
}
