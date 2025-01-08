import 'package:Quickbites/Signup.dart';
import 'package:Quickbites/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'Create_Recipe_Screen.dart';
import 'Favorites_Screen.dart';
import 'Home_Screen.dart';
import 'Splash_Screen.dart';
import 'package:Quickbites/View_Recipe_Screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(QuickBitesApp());
}

class QuickBitesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickBites',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/splash',
      routes: _buildRoutes(),
    );
  }

  // Define routes in a separate method for better readability
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/splash': (context) => SplashScreen(),
      '/home': (context) => HomeScreen(),
      '/viewRecipe': (context) => ViewRecipeScreen(
        recipe: {},
        isFavorite: false,
        toggleFavorite: () {},
      ),
      '/createRecipe': (context) => CreateRecipe(),
      '/favorites': (context) => FavoritesScreen(),
      '/login': (context) => LoginPage(),
      '/signup': (context) => SignUpPage(),
    };
  }
}
