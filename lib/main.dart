import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// this stuff runs the app
void main() {
  runApp(const MyApp());
}

// my app is the root of the app we want to create
// stateless widget helps us create a new UI component (widget)
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: HomePageState(),
    );
  }
}

// Where do we want the images comeing from
enum ImageSourceType { gallery, camera }

// I think this is where all the images go
List photoList = [];

// home page state
class HomePageState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePage();
  }
}

// home page (stateful widget)
class HomePage extends State<HomePageState> with WidgetsBindingObserver {
  // Tap to enter picking image view
  void getPhoto(BuildContext context, var type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImageFromGalleryEx(type)),
    ).then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    //Grid view
    Widget gridSection = GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      children: List.generate(photoList.length, (i) {
        //obtaining image
        var imgPath = photoList[i];
        var img = File(imgPath);
        Image imgFile = Image.file(img);

        return GestureDetector(
          onTap: () async {
            Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => FullScreenState(imgPath),
                ));
          },
          child: ClipRRect(
            child: SizedBox.fromSize(
              child: Image.file(img, fit: BoxFit.cover),
              size: Size.fromRadius(52),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }),
    );

    // Our two buttons - one for gallery imgs, one for camera...
    Widget buttonSection = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MaterialButton(
          color: Colors.cyan,
          child: const Text(
            "Add from Gallery",
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          onPressed: () {
            getPhoto(context, ImageSourceType.gallery);
          },
        ),
        MaterialButton(
          color: Colors.cyan,
          child: const Text(
            "Click from Camera",
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          onPressed: () {
            getPhoto(context, ImageSourceType.camera);
          },
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Gallery App"),
      ),
      body: Stack(
        children: [
          gridSection,
          Column(children: [const Spacer(), buttonSection])
        ],
      ),
    );
  }
}

// full screen image showing: two classes
class FullScreenState extends StatefulWidget {
  final path;
  FullScreenState(this.path);
  @override
  FullScreenImg createState() => FullScreenImg(this.path);
}

class FullScreenImg extends State<FullScreenState> {
  var path;
  var img;
  var width;
  var height;

  FullScreenImg(this.path);

  @override
  void initState() {
    super.initState();
    img = Image(image: FileImage(File(path)));
    // get image width and height
    img.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          width = info.image.width;
          height = info.image.height;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var infoText = "Image Width: " +
        width.toString() +
        " px\n" +
        "Image Height: " +
        height.toString() +
        " px";
    return Scaffold(
      appBar: AppBar(title: const Text("Image in Full Screen")),
      body: Center(child: Image.file(File(path))),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Text(
            infoText.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class ImageFromGalleryEx extends StatefulWidget {
  final type;
  ImageFromGalleryEx(this.type);

  @override
  ImageFromGalleryExState createState() => ImageFromGalleryExState(this.type);
}

class ImageFromGalleryExState extends State<ImageFromGalleryEx> {
  var _image;
  var imagePicker;
  var type;

  ImageFromGalleryExState(this.type);

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Insert Image")),
      body: Column(
        children: <Widget>[
          const SizedBox(
            height: 52,
          ),
          Center(
            child: GestureDetector(
              onTap: () async {
                var source = type == ImageSourceType.camera
                    ? ImageSource.camera
                    : ImageSource.gallery;
                var imageR = await imagePicker.pickImage(
                    source: source,
                    imageQuality: 50,
                    preferredCameraDevice: CameraDevice.front);

                XFile image;
                if (imageR != null) {
                  image = imageR;
                  Directory appDocumentsDirectory =
                      await getApplicationDocumentsDirectory();
                  // correct path to save file for this app
                  String prePath = appDocumentsDirectory.path;
                  var rand = Random();
                  // random int as the photo name
                  String randomInt = rand.nextInt(99999999).toString();
                  String newPath = "$prePath/$randomInt.jpg";
                  File oldImage = File(image.path);
                  // copy the image from cache to a safe place
                  final File newImage = await oldImage.copy(newPath);

                  setState(() {
                    _image = newImage;
                    // save the path to a global variable
                    // then the root view can update the grid list
                    photoList.add(newImage.path);
                  });
                }

                Navigator.pop(context);
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: Colors.red[200]),
                child: _image != null
                    ? Image.file(
                        _image,
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.fitHeight,
                      )
                    : Container(
                        decoration: BoxDecoration(color: Colors.red[200]),
                        width: 200,
                        height: 200,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[800],
                        ),
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
