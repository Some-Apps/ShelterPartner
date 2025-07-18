import 'package:shelter_partner/helpers/file_loader.dart';

class MockFileLoader implements FileLoader {
  final Map<String, String> _mockFiles;
  final FileLoader _defaultFileLoader;

  MockFileLoader({FileLoader? defaultFileLoader})
    : _defaultFileLoader = defaultFileLoader ?? DefaultFileLoader(),
      _mockFiles = {
        'assets/csv/cats.csv':
            'id,name,location,isActive\n1,Whiskers,Room 1,true\n2,Fluffy,Room 2,true',
        'assets/csv/dogs.csv':
            'id,name,location,isActive\n1,Buddy,Room 3,true\n2,Max,Room 4,true',
      };

  @override
  Future<String> loadString(String filename) async {
    if (_mockFiles.containsKey(filename)) {
      return _mockFiles[filename]!;
    }
    return _defaultFileLoader.loadString(filename);
  }
}
