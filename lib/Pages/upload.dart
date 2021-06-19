import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'package:flutter_gram/Models/user.dart';
import 'package:flutter_gram/Pages/home.dart';
import 'package:flutter_gram/Widgets/progress.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();
  TextEditingController _locationConroller = TextEditingController();
  TextEditingController _captionController = TextEditingController();

  handleTakePhoto() async {
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    Navigator.pop(context);
    setState(() {
      this.file = file;
    });
  }

  handleChoosefromGallery() async {
    File file = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    Navigator.pop(context);
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text('Create Post'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Camera'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text('Image from gallery'),
              onPressed: handleChoosefromGallery,
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Scaffold buildSplashScreen() {
    return Scaffold(
      body: Container(
        color: Theme.of(context).primaryColor.withOpacity(0.6),
        child: Column(
          children: <Widget>[
            isUploading ? linearProgress() : Text(''),
            Flexible(
              child: SvgPicture.asset(
                'assets/images/upload.svg',
                fit: BoxFit.scaleDown,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: RaisedButton(
                onPressed: () => selectImage(context),
                child: Text(
                  'Upload Image',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
    storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore({String mediaUrl, String location, String caption}) {
    postsRef
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'ownerId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'description': caption,
      'location': location,
      'timestamp': timestamp,
      'likes': {},
    });
  }

  clearImage() async {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_postId.jpg')
      ..writeAsBytesSync(
        Im.encodeJpg(
          imageFile,
          quality: 85,
        ),
      );
    setState(() {
      file = compressedImageFile;
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      caption: _captionController.text,
      location: _locationConroller.text,
    );
    _captionController.clear();
    _locationConroller.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String formattedAddress = '${placemark.locality}, ${placemark.country}';
    _locationConroller.text = formattedAddress;
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Caption Post'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: clearImage,
        ),
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 22, left: 10, right: 10),
        child: ListView(
          children: <Widget>[
            Container(
              height: 220,
              width: MediaQuery.of(context).size.width * 0.8,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.contain,
                        image: FileImage(file),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
                ),
                title: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextFormField(
                    controller: _captionController,
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.pin_drop,
                size: 35,
                color: Colors.orange,
              ),
              title: Container(
                child: TextFormField(
                  controller: _locationConroller,
                  decoration: InputDecoration(
                    hintText: 'Where was this image taken ?',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(top: 30),
              height: 70,
              width: 40,
              child: RaisedButton.icon(
                onPressed: getUserLocation,
                icon: Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
                label: Text(
                  'Use Current Location',
                  style: TextStyle(color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
