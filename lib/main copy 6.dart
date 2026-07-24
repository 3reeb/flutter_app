import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    _smokeTest();
    return const MaterialApp(
        home: Scaffold(body: Center(child: Text('Firebase test'))));
  }

  Future<void> _smokeTest() async {
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      print('Auth OK uid: ${result.user?.uid}');
    } catch (e) {
      print('Auth failed: $e');
    }
  }
}
