import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gram/Models/user.dart';
import 'package:flutter_gram/Pages/timeline.dart';
import 'package:flutter_gram/Pages/activity_feed.dart';
import 'package:flutter_gram/Pages/upload.dart';
import 'package:flutter_gram/Pages/search.dart';
import 'package:flutter_gram/Pages/create_account.dart';
import 'package:flutter_gram/Pages/profile.dart';

final googleSignIn = GoogleSignIn();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final activityFeedRef = Firestore.instance.collection('feed');
final commentsRef = Firestore.instance.collection('comments');
final followingRef = Firestore.instance.collection('following');
final followersRef = Firestore.instance.collection('followers');
final timelineRef = Firestore.instance.collection('timeline');
final storageRef = FirebaseStorage.instance.ref();
final timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged
        .listen((account) => handleSignIn(account))
        .onError((err) => print('Error while signing in $err'));
    googleSignIn
        .signInSilently(suppressErrors: false)
        .then((account) => handleSignIn(account))
        .catchError((err) => print('Error while signing in silently $err'));
  }

  void handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await creteUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  void creteUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user?.id).get();
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      usersRef.document(user.id).setData({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp,
      });
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});

      doc = await usersRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  void configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermission();
    _firebaseMessaging.getToken().then((token) {
      print('Firebase Messaging Token : $token\n');
      usersRef
          .document(user.id)
          .updateData({'androidNotificationToken': token});
    });
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
      print('on message : $message');
      final String recipientId = message['data']['recipient '];
      final String body = message['notification']['body'];
      if (recipientId == user.id) {
        print('Notification shown');
        SnackBar snackbar = SnackBar(
          content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ),
        );
        _scaffoldKey.currentState.showSnackBar(snackbar);
      } else {
        print('Notification not shown');
      }
    });
  }

  void getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(
      alert: true,
      badge: true,
      sound: true,
    ));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print('Setting registered : $settings');
    });
  }

  void onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  void onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Widget buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Widget buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).accentColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'FlutterGram',
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 90,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => googleSignIn.signIn(),
              child: Container(
                height: 60,
                width: 240,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
