import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Quickbites/View_Recipe_Screen.dart';
import 'profile.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<String> _favoriteRecipes = [];
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    if (currentUser != null) {
      final doc = await _firestore
          .collection('favorites')
          .doc(currentUser!.email)
          .get();
      setState(() {
        _favoriteRecipes = List<String>.from(doc.data()?['recipes'] ?? []);
      });
    }
  }

  Future<void> _toggleFavorite(String recipeId) async {
    if (currentUser == null) {
      _showLoginPrompt();
      return;
    }

    final userEmail = currentUser!.email ?? 'Anonymous';
    final docRef = _firestore.collection('favorites').doc(userEmail);

    if (_favoriteRecipes.contains(recipeId)) {
      setState(() {
        _favoriteRecipes.remove(recipeId);
      });
    } else {
      setState(() {
        _favoriteRecipes.add(recipeId);
      });
    }

    await docRef.set({
      'userEmail': userEmail,
      'recipes': _favoriteRecipes,
    });
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Login Required'),
          content: Text('You need to log in to perform this action.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Log In'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QuickBites',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            GestureDetector(
              onTap: () {
                if (currentUser == null) {
                  _showLoginPrompt();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                }
              },
              child: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.green),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          _buildCategoryFilters(),
          Expanded(child: _buildRecipeList()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for recipes...',
          prefixIcon: Icon(Icons.search, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.green),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['All', 'Smoothies', 'Breakfasts', 'Desserts',  'Healthy Eats'];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('recipes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading recipes.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No recipes found.'));
        }

        final recipes = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final matchesCategory = _selectedCategory == 'All' ||
              (data['subCategory']?.toString().toLowerCase() ?? '') == _selectedCategory.toLowerCase();
          final matchesSearch = data['name']?.toString().toLowerCase().contains(_searchQuery) ?? false;

          return matchesCategory && matchesSearch;
        }).toList();

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final data = recipe.data() as Map<String, dynamic>;
            final isFavorite = _favoriteRecipes.contains(recipe.id);

            return _buildRecipeCard(data, recipe.id, isFavorite);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> data, String recipeId, bool isFavorite) {
    final imageUrl = data['imageUrl'] ?? '';
    final name = data['name'] ?? 'Unknown Recipe';
    final time = data['cookingTime'] ?? 'N/A';
    final calories = data['calories'] ?? 'N/A';

    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
              : Icon(Icons.image, size: 50, color: Colors.grey),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$time min • $calories Cal'),
        trailing: IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey),
          onPressed: () => _toggleFavorite(recipeId),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewRecipeScreen(
              recipe: data,
              isFavorite: isFavorite,
              toggleFavorite: () => _toggleFavorite(recipeId),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
      ],
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          if (currentUser == null) {
            _showLoginPrompt();
          } else {
            Navigator.pushNamed(context, '/createRecipe');
          }
        } else if (index == 2) {
          if (currentUser == null) {
            _showLoginPrompt();
          } else {
            Navigator.pushNamed(context, '/favorites');
          }
        }
      },
    );
  }
}
