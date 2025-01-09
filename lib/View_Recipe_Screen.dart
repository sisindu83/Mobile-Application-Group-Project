import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'create_recipe_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewRecipeScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final bool isFavorite;
  final VoidCallback toggleFavorite;

  ViewRecipeScreen({
    required this.recipe,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  _ViewRecipeScreenState createState() => _ViewRecipeScreenState();
}

class _ViewRecipeScreenState extends State<ViewRecipeScreen> {
  int _currentIndex = 0;
  bool isFavorite = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FavoritesScreen()),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // User not logged in, show login prompt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to modify favorites.')),
      );
      return;
    }

    final String userEmail = currentUser.email ?? 'Anonymous';
    final docRef = _firestore.collection('favorites').doc(userEmail);

    if (isFavorite) {
      // Remove from favorites
      await docRef.update({
        'recipes': FieldValue.arrayRemove([widget.recipe['id']])
      });
    } else {
      // Add to favorites
      await docRef.set({
        'recipes': FieldValue.arrayUnion([widget.recipe['id']])
      }, SetOptions(merge: true));
    }

    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'Recipe added to favorites!'
              : 'Recipe removed from favorites!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = widget.recipe['ingredients'] is String
        ? [widget.recipe['ingredients']]
        : (widget.recipe['ingredients'] as List<dynamic>?) ?? [];

    final instructions = widget.recipe['instructions'] is String
        ? [widget.recipe['instructions']]
        : (widget.recipe['instructions'] as List<dynamic>?) ?? [];

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: widget.recipe['imageUrl'] ?? '',
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    Icon(Icons.broken_image, size: 100, color: Colors.grey),
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 50,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: 50,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipe['name'] ?? 'Recipe Name',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${widget.recipe['cookingTime']} min • ${widget.recipe['calories']} Cal',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16),
                Text(
                  widget.recipe['description'] ?? 'Description',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.green,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.green,
                        tabs: [
                          Tab(text: 'Ingredients'),
                          Tab(text: 'Instructions'),
                        ],
                      ),
                      Container(
                        height: 200,
                        child: TabBarView(
                          children: [
                            ListView.builder(
                              itemCount: ingredients.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: Icon(Icons.check_circle,
                                    color: Colors.green),
                                title: Text(ingredients[index].toString()),
                              ),
                            ),
                            ListView.builder(
                              itemCount: instructions.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(instructions[index].toString()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
}
