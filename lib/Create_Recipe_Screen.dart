import 'package:flutter/material.dart';
import 'package:Quickbites/Favorites_Screen.dart';
import 'package:Quickbites/Home_Screen.dart';
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
  int _currentIndex = 1;

  final _formKey = GlobalKey<FormState>();
  String? _recipeName;
  String? _description;
  String? _cookingTime;
  String? _calories;
  List<String> _instructions = [];
  List<String> _ingredients = [];
  String? _mainCategory;
  String? _subCategory;
  File? _imageFile;

  final List<String> _mainCategories = ['Food', 'Beverage'];
  final Map<String, List<String>> _subCategories = {
    'Food': ['Healthy Eats', 'Desserts', 'Breakfasts'],
    'Beverage': ['Smoothies', 'Hot Drinks'],
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
    const clientId = '9693e03739aacc7'; // Replace with your Imgur Client ID
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

      try {
        // Upload the image to Imgur
        final imageUrl = await _uploadImageToImgur(_imageFile!);

        if (imageUrl != null) {
          // Save recipe to Firebase Firestore
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

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recipe saved successfully!')),
          );

          // Reset the form
          _formKey.currentState!.reset();
          setState(() {
            _imageFile = null;
            _instructions.clear();
            _ingredients.clear();
            _mainCategory = null;
            _subCategory = null;
          });
        } else {
          // Image upload failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed. Please try again.')),
          );
        }
      } catch (e) {
        // Catch and display any errors
        print('Error saving recipe: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
        );
      }
    } else {
      // Validation error
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
              _buildDynamicList('Ingredients', _ingredients),
              _buildDynamicList('Instructions', _instructions),
              _buildDropdownField('Main Category', _mainCategories, (value) {
                setState(() {
                  _mainCategory = value;
                  _currentSubCategories = _subCategories[value!] ?? [];
                  _subCategory = null; // Reset sub-category when main category changes
                });
              }),
              if (_currentSubCategories.isNotEmpty)
                _buildDropdownField('Sub Category', _currentSubCategories, (value) {
                  setState(() {
                    _subCategory = value;
                  });
                }),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _saveRecipe,
                  child: Text('Create Recipe'),
                ),
              ),
            ],
          ),
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

  Widget _buildDynamicList(String label, List<String> list) {
    final TextEditingController _controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text(list[index]),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      list.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add $label',
                    prefixIcon: Icon(Icons.add, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.green),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    setState(() {
                      list.add(_controller.text.trim());
                    });
                    _controller.clear();
                  }
                },
              ),
            ],
          ),
        ],
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
}
