import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin.dart';
import 'home.dart';
void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform);
runApp(MyApp());
}
class MyApp extends StatelessWidget {
const MyApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
initialRoute:
FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/home',
routes: {
'/sign-in': (context) => SigninPage(),
'/home': (context) => HomePage(),
},
);
}
}