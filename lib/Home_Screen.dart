import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import the cached_network_image package
import 'profile.dart';
import 'login.dart';
import 'View_Recipe_Screen.dart';

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

  Database? _database;

  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _filteredRecipes = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeDatabase();
    _loadRecipes();
  }

  Future<void> _initializeUser() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadFavorites();
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'recipes.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE recipes (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              cookingTime TEXT,
              calories TEXT,
              ingredients TEXT,
              instructions TEXT,
              imageUrl TEXT,
              subCategory TEXT
            )
          ''');
        },
      );
      print('Database initialized at $path');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  Future<void> _loadFavorites() async {
    if (currentUser == null) return;

    try {
      final doc = await _firestore.collection('favorites').doc(currentUser!.email).get();
      setState(() {
        _favoriteRecipes = List<String>.from(doc.data()?['recipes'] ?? []);
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _loadRecipes() async {
    final recipes = await _fetchRecipes();
    setState(() {
      _recipes = recipes;
      _filteredRecipes = _applyFilters();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchRecipes() async {
    try {
      final querySnapshot = await _firestore.collection('recipes').get();
      final recipes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'cookingTime': data['cookingTime'] ?? '',
          'calories': data['calories'] ?? '',
          'ingredients': (data['ingredients'] is List<dynamic>)
              ? (data['ingredients'] as List<dynamic>).join(', ')
              : data['ingredients'] ?? '',
          'instructions': (data['instructions'] is List<dynamic>)
              ? (data['instructions'] as List<dynamic>).join(', ')
              : data['instructions'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'subCategory': data['subCategory'] ?? '',
        };
      }).toList();

      await _cacheRecipes(recipes);
      return recipes;
    } catch (e) {
      if (_database != null) {
        final cachedRecipes = await _database!.query('recipes');
        return cachedRecipes;
      }
      return [];
    }
  }

  Future<void> _cacheRecipes(List<Map<String, dynamic>> recipes) async {
    try {
      if (_database != null) {
        await _database!.transaction((txn) async {
          await txn.delete('recipes');
          for (var recipe in recipes) {
            await txn.insert('recipes', recipe);
          }
        });
      }
    } catch (e) {
      print('Error caching recipes: $e');
    }
  }

  List<Map<String, dynamic>> _applyFilters() {
    return _recipes.where((recipe) {
      final matchesCategory = _selectedCategory == 'All' ||
          (recipe['subCategory']?.toLowerCase() ?? '') == _selectedCategory.toLowerCase();
      final matchesSearch = recipe['name']?.toLowerCase().contains(_searchQuery) ?? false;
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _updateFilters() {
    setState(() {
      _filteredRecipes = _applyFilters();
    });
  }

  Future<void> _toggleFavorite(String recipeId) async {
    if (currentUser == null) {
      _showLoginPrompt();
      return;
    }

    try {
      final userEmail = currentUser!.email ?? '';
      final docRef = _firestore.collection('favorites').doc(userEmail);

      setState(() {
        if (_favoriteRecipes.contains(recipeId)) {
          _favoriteRecipes.remove(recipeId);
        } else {
          _favoriteRecipes.add(recipeId);
        }
      });

      await docRef.set({
        'userEmail': userEmail,
        'recipes': _favoriteRecipes,
      });
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      setState(() {
        _currentIndex = index; // Home Screen
      });
    } else if (index == 1) {
      // Check login for Create Recipe
      if (currentUser == null) {
        _showLoginPrompt();
      } else {
        Navigator.pushNamed(context, '/createRecipe');
      }
    } else if (index == 2) {
      // Check login for Favorites
      if (currentUser == null) {
        _showLoginPrompt();
      } else {
        Navigator.pushNamed(context, '/favorites');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QuickBites'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              if (currentUser == null) {
                _showLoginPrompt();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          _buildCategoryFilters(),
          Expanded(child: _buildRecipeList()),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for recipes...',
          prefixIcon: Icon(Icons.search, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
            _updateFilters();
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['All', 'Smoothies', 'Breakfasts', 'Desserts', 'Healthy Eats'];
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
                _updateFilters();
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
                style: TextStyle(color: isSelected ? Colors.white : Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeList() {
    if (_filteredRecipes.isEmpty) {
      return Center(child: Text('No recipes match your criteria.'));
    }

    return ListView.builder(
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        final isFavorite = _favoriteRecipes.contains(recipe['id']);
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: recipe['imageUrl'].isNotEmpty
                ? CachedNetworkImage(
              imageUrl: recipe['imageUrl'],
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 50, color: Colors.grey),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : Icon(Icons.image, size: 50, color: Colors.grey),
          ),
          title: Text(recipe['name']),
          subtitle: Text('${recipe['cookingTime']} • ${recipe['calories']} Cal'),
          trailing: IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => _toggleFavorite(recipe['id']),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewRecipeScreen(
                recipe: recipe,
                isFavorite: isFavorite,
                toggleFavorite: () => _toggleFavorite(recipe['id']),
              ),
            ),
          ),
        );
      },
    );
  }
}
