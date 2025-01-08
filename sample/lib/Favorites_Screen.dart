import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'View_Recipe_Screen.dart'; // Import ViewRecipeScreen

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> favoriteRecipes = [];
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    currentUser = _auth.currentUser;
    if (currentUser == null) {
      _redirectToLogin();
    } else {
      await _loadFavorites();
    }
  }

  Future<void> _redirectToLogin() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  Future<void> _loadFavorites() async {
    if (currentUser != null) {
      final doc = await _firestore
          .collection('favorites')
          .doc(currentUser!.email) // Using email as the document ID
          .get();
      final recipeIds = List<String>.from(doc.data()?['recipes'] ?? []);

      // Fetch detailed data for each recipe
      List<Map<String, dynamic>> recipes = [];
      for (String id in recipeIds) {
        final recipeDoc = await _firestore.collection('recipes').doc(id).get();
        if (recipeDoc.exists) {
          recipes.add(recipeDoc.data() as Map<String, dynamic>);
        }
      }

      setState(() {
        favoriteRecipes = recipes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: favoriteRecipes.isEmpty
            ? Center(child: Text('No favorite recipes found.'))
            : ListView.builder(
          itemCount: favoriteRecipes.length,
          itemBuilder: (context, index) {
            final recipe = favoriteRecipes[index];
            return _buildRecipeCard(recipe);
          },
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final imageUrl = recipe['imageUrl'] ?? '';
    final name = recipe['name'] ?? 'Unknown Recipe';
    final time = recipe['cookingTime'] ?? 'N/A';
    final calories = recipe['calories'] ?? 'N/A';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
              : Icon(Icons.image, size: 60, color: Colors.grey),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$time min • $calories Cal'),
        trailing: Icon(
          Icons.favorite,
          color: Colors.red,
        ),
        onTap: () {
          // Navigate to ViewRecipeScreen when clicked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewRecipeScreen(
                recipe: recipe,
                isFavorite: true, // Favorites are already marked as favorite
                toggleFavorite: () {}, // No toggle needed in the view screen
              ),
            ),
          );
        },
      ),
    );
  }
}
