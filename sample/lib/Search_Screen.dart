import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'RecipeCard.dart';

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Recipes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by recipe name',
                border: OutlineInputBorder(),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  RecipeCard(),
                  RecipeCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
