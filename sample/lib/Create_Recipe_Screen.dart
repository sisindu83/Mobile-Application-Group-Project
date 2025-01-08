import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateRecipe extends StatefulWidget {
  @override
  _CreateRecipeState createState() => _CreateRecipeState();
}

class _CreateRecipeState extends State<CreateRecipe> {
  final _formKey = GlobalKey<FormState>();
  String? _recipeName;
  String? _description;
  String? _cookingTime;
  String? _calories;
  String? _instructions;
  String? _ingredients;
  String? _mainCategory;
  String? _subCategory;
  File? _imageFile;

  final List<String> _mainCategories = ['Food', 'Beverage'];
  final Map<String, List<String>> _subCategories = {
    'Food': ['Healty Eats', 'Desserts', 'Breakfasts'],
    'Beverage': ['Healty Eats', 'Smoothies'],
  };

  List<String> _currentSubCategories = [];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToImgur(File imageFile) async {
    const clientId = '9693e03739aacc7';
    final url = Uri.parse('https://api.imgur.com/3/image');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Client-ID $clientId';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonResponse['data']['link'];
    } else {
      print('Error uploading to Imgur: ${jsonResponse['data']['error']}');
      return null;
    }
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      _formKey.currentState!.save();

      final imageUrl = await _uploadImageToImgur(_imageFile!);
      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection('recipes').add({
          'name': _recipeName,
          'description': _description,
          'cookingTime': _cookingTime,
          'calories': _calories,
          'instructions': _instructions,
          'ingredients': _ingredients,
          'mainCategory': _mainCategory,
          'subCategory': _subCategory,
          'imageUrl': imageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipe saved successfully!')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete the form and upload an image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create a Recipe'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(90),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: _imageFile == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.green),
                        Text(
                          'Upload Image',
                          style: TextStyle(color: Colors.green, fontSize: 16),
                        ),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(90),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildStyledTextField('Recipe Name', Icons.fastfood, (value) => _recipeName = value),
              _buildStyledTextField('Description', Icons.description, (value) => _description = value),
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField('Cooking Time', Icons.timer, (value) => _cookingTime = value),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildStyledTextField('Calories', Icons.local_fire_department,
                            (value) => _calories = value),
                  ),
                ],
              ),
              _buildStyledTextField('Instructions', Icons.list, (value) => _instructions = value),
              _buildStyledTextField('Ingredients', Icons.kitchen, (value) => _ingredients = value),
              _buildDropdownField('Main Category', _mainCategories, (value) {
                setState(() {
                  _mainCategory = value;
                  _currentSubCategories = _subCategories[value!] ?? [];
                  _subCategory = null;
                });
              }),
              if (_currentSubCategories.isNotEmpty)
                _buildDropdownField('Sub Category', _currentSubCategories, (value) {
                  setState(() {
                    _subCategory = value;
                  });
                }),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Create Recipe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField(String label, IconData icon, void Function(String?) onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.green.shade50,
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
        onSaved: onSave,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.green.shade50,
        ),
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        ))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select a $label' : null,
      ),
    );
  }
}
