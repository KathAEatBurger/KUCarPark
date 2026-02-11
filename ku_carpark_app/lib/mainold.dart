// import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'signup_page.dart';

// void main() {
//   runApp(const CarParkApp());
// }

// class CarParkApp extends StatelessWidget {
//   const CarParkApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'CarPark App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: const LoginPage(),
//     );
//   }
// }

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
  
//   bool _obscureText = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       resizeToAvoidBottomInset: true, 
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 30.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 60),
              
//               const Text(
//                 'Review',
//                 style: TextStyle(
//                   fontSize: 48,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF3CB38C),
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
              
//               const SizedBox(height: 60),

//               const TextField(
//                 keyboardType: TextInputType.phone,
//                 decoration: InputDecoration(
//                   labelText: 'Phone number',
//                   labelStyle: TextStyle(color: Colors.grey),
//                   enabledBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(color: Colors.grey, width: 0.5),
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 20),

              
//               TextField(
//                 obscureText: _obscureText, 
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   labelStyle: const TextStyle(color: Colors.grey),
//                   enabledBorder: const UnderlineInputBorder(
//                     borderSide: BorderSide(color: Colors.grey, width: 0.5),
//                   ),
                  
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscureText ? Icons.visibility_off : Icons.visibility,
//                       color: Colors.grey,
//                     ),
//                     onPressed: () {
                      
//                       setState(() {
//                         _obscureText = !_obscureText;
//                       });
//                     },
//                   ),
//                 ),
//               ),

//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {},
//                   child: const Text(
//                     'Forgot Password?',
//                     style: TextStyle(color: Colors.orangeAccent),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               Container(
//                 width: double.infinity,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF3CB38C).withOpacity(0.3),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const HomePage()),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF3CB38C),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Login',
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text('or ', style: TextStyle(color: Colors.grey)),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => const SignupPage()),
//                       );
//                     },
//                     child: const Text(
//                       'Signup',
//                       style: TextStyle(
//                         color: Colors.orangeAccent,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 80),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }