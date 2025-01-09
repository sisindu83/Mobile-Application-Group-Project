import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart';
import 'create_recipe_screen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> favoriteRecipes = [];
  User? currentUser;
  int _currentIndex = 2; 

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
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> _loadFavorites() async {
    if (currentUser != null) {
      final doc = await _firestore
          .collection('favorites')
          .doc(currentUser!.email) 
          .get();
      final recipeIds = List<String>.from(doc.data()?['recipes'] ?? []);

      // Fetch detailed data for each recipe
      List<Map<String, dynamic>> recipes = [];
      for (String id in recipeIds) {
        final recipeDoc = await _firestore.collection('recipes').doc(id).get();
        if (recipeDoc.exists) {
          recipes.add({...recipeDoc.data() as Map<String, dynamic>, 'id': id});
        }
      }

      setState(() {
        favoriteRecipes = recipes;
      });
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CreateRecipe()),
      );
    } else if (index == 2) {
      // Stay on Favorites screen
    }
  }

  Future<void> _removeFromFavorites(String recipeId) async {
    if (currentUser != null) {
      final docRef = _firestore.collection('favorites').doc(currentUser!.email);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        List<String> recipes = List<String>.from(docSnapshot.data()?['recipes'] ?? []);
        recipes.remove(recipeId);

        await docRef.set({'recipes': recipes});

        setState(() {
          favoriteRecipes.removeWhere((recipe) => recipe['id'] == recipeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipe removed from favorites.')),
        );
      }
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
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
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 60, color: Colors.grey),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          )
              : Icon(Icons.image, size: 60, color: Colors.grey),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$time min • $calories Cal'),
        trailing: IconButton(
          icon: Icon(Icons.favorite, color: Colors.red),
          onPressed: () async {
            await _removeFromFavorites(recipe['id']);
          },
        ),
      ),
    );
  }
}
