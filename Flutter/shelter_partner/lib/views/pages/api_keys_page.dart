import 'package:flutter/material.dart';

class ApiKeysPage extends StatefulWidget {
  @override
  _ApiKeysPageState createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  final TextEditingController _keyNameController = TextEditingController();
  bool _showAlert = false;
  String? _generatedKey;
  bool _showCopied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Keys'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Implement edit functionality here
            },
          ),
        ],
      ),
      body: Form(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            // Generate New Key Section
            Text(
              'Generate New Key',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _keyNameController,
              decoration: InputDecoration(labelText: 'Key Name'),
            ),
            SizedBox(height: 16.0),
            _keyNameController.text.trim().isNotEmpty
                ? ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _generatedKey = _generateRandomString(16);
                        _showAlert = true;
                        _keyNameController.clear();
                      });
                    },
                    child: Text('Add Key'),
                  )
                : Container(),

            // Request Count Section
            SizedBox(height: 24.0),
            Text('Requests in the last 30 days'),
            Text('10/100 requests made', // Example value
                style: Theme.of(context).textTheme.titleMedium),

            // Available Endpoints Section
            SizedBox(height: 24.0),
            Text(
              'Available Endpoints',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _buildEndpointRow('All Dogs', 'https://example.com/dogs'),
            _buildEndpointRow('All Cats', 'https://example.com/cats'),

            // Keys Section
            SizedBox(height: 24.0),
            Text(
              'Keys',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: 3, // Example: Replace with actual key count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Key ${index + 1}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Implement delete key functionality here
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build endpoint rows
  Widget _buildEndpointRow(String label, String url) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        TextButton(
          onPressed: () {
            // Copy to clipboard
            setState(() {
              _showCopied = true;
            });
          },
          child: Text('Copy to Clipboard'),
        ),
      ],
    );
  }

  // Function to generate random string
  String _generateRandomString(int length) {
    const characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => characters.codeUnitAt((characters.length * (0.1)).toInt())));
  }
}
