import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String fullName = '';
  String email = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          fullName = doc['fullName'] ?? 'No Name';
          email = user.email ?? 'No Email';
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateFullName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({'fullName': newName});
        setState(() {
          fullName = newName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Full Name updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Remove user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete the user from Firebase Authentication
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully')),
      );

      // Redirect to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _deleteAccount(); // Delete account
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showEditDialog() {
    final TextEditingController _nameController = TextEditingController(text: fullName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Full Name'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
                _updateFullName(_nameController.text.trim());
              },
              child: Text('Save'),
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
        title: Text('My Profile'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade50,
              child: Icon(Icons.person, size: 50, color: Colors.green),
            ),
            SizedBox(height: 20),
            _buildProfileItem('Full Name', fullName, Icons.person, _showEditDialog),
            _buildProfileItem('Email', email, Icons.email, null),
            Spacer(),
            Text(
              'QuickBites is an app developed by Group 11\nESOFT Mobile Dev Sept 2024 Batch',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmDeleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                'Delete Account',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon, VoidCallback? onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: onEdit,
              child: Text(
                'Edit',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}
