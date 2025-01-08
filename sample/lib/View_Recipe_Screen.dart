import 'package:flutter/material.dart';

class ViewRecipeScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool isFavorite;
  final VoidCallback toggleFavorite;

  ViewRecipeScreen({
    required this.recipe,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final ingredients = recipe['ingredients'] is String
        ? [recipe['ingredients']]
        : (recipe['ingredients'] as List<dynamic>?) ?? [];

    final instructions = recipe['instructions'] is String
        ? [recipe['instructions']]
        : (recipe['instructions'] as List<dynamic>?) ?? [];

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Image.network(
                recipe['imageUrl'] ?? '',
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
                  onPressed: toggleFavorite,
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
                  recipe['name'] ?? 'Recipe Name',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${recipe['cookingTime']} min • ${recipe['calories']} Cal',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16),
                Text(
                  recipe['description'] ?? 'Description',
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
                                leading: Icon(Icons.check_circle, color: Colors.green),
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
    );
  }
}
