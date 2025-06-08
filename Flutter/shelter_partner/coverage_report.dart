#!/usr/bin/env dart

import 'dart:io';
import 'dart:math';

class CoverageData {
  final String filePath;
  final int linesFound;
  final int linesHit;
  
  CoverageData({
    required this.filePath,
    required this.linesFound,
    required this.linesHit,
  });
  
  double get percentage => linesFound > 0 ? (linesHit / linesFound) * 100 : 0.0;
}

class DirectoryCoverage {
  final String dirPath;
  final List<CoverageData> files = [];
  final Map<String, DirectoryCoverage> subdirectories = {};
  
  DirectoryCoverage({required this.dirPath});
  
  int get totalLinesFound => files.fold(0, (sum, file) => sum + file.linesFound) +
      subdirectories.values.fold(0, (sum, dir) => sum + dir.totalLinesFound);
  
  int get totalLinesHit => files.fold(0, (sum, file) => sum + file.linesHit) +
      subdirectories.values.fold(0, (sum, dir) => sum + dir.totalLinesHit);
  
  double get percentage => totalLinesFound > 0 ? (totalLinesHit / totalLinesFound) * 100 : 0.0;
  
  bool get hasContent => files.isNotEmpty || subdirectories.values.any((dir) => dir.hasContent);
}

void main() async {
  final lcovFile = File('coverage/lcov.info');
  
  if (!await lcovFile.exists()) {
    print('Error: coverage/lcov.info not found. Run "flutter test --coverage" first.');
    exit(1);
  }
  
  final content = await lcovFile.readAsString();
  final coverageData = parseLcovData(content);
  
  final dirStructure = buildDirectoryStructure(coverageData);
  
  printCoverageReport(dirStructure);
}

List<CoverageData> parseLcovData(String content) {
  final List<CoverageData> coverageList = [];
  final lines = content.split('\n');
  
  String? currentFile;
  int linesFound = 0;
  int linesHit = 0;
  
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      // Source file
      currentFile = line.substring(3);
    } else if (line.startsWith('LF:')) {
      // Lines found
      linesFound = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      // Lines hit
      linesHit = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && currentFile != null) {
      // Only include files in lib/ directory, exclude test files
      if (currentFile.startsWith('lib/') && currentFile.endsWith('.dart')) {
        coverageList.add(CoverageData(
          filePath: currentFile,
          linesFound: linesFound,
          linesHit: linesHit,
        ));
      }
      
      // Reset for next file
      currentFile = null;
      linesFound = 0;
      linesHit = 0;
    }
  }
  
  return coverageList;
}

DirectoryCoverage buildDirectoryStructure(List<CoverageData> coverageData) {
  final root = DirectoryCoverage(dirPath: 'lib');
  
  for (final data in coverageData) {
    final pathParts = data.filePath.split('/');
    
    // Remove 'lib' from the beginning since it's our root
    final relativeParts = pathParts.skip(1).toList();
    
    // Navigate to the correct directory
    DirectoryCoverage currentDir = root;
    
    // Process all directory parts except the filename
    for (int i = 0; i < relativeParts.length - 1; i++) {
      final dirName = relativeParts[i];
      
      if (!currentDir.subdirectories.containsKey(dirName)) {
        final dirPath = 'lib/' + relativeParts.take(i + 1).join('/');
        currentDir.subdirectories[dirName] = DirectoryCoverage(dirPath: dirPath);
      }
      
      currentDir = currentDir.subdirectories[dirName]!;
    }
    
    // Add the file to the current directory
    currentDir.files.add(data);
  }
  
  return root;
}

void printCoverageReport(DirectoryCoverage root) {
  print('Flutter Code Coverage Report');
  print('============================');
  print('');
  
  _printDirectory(root, '', true);
}

void _printDirectory(DirectoryCoverage dir, String prefix, bool isRoot) {
  // Don't print empty directories
  if (!dir.hasContent) return;
  
  final dirName = isRoot ? 'lib' : dir.dirPath.split('/').last;
  final percentage = dir.percentage;
  
  print('$prefix$dirName - ${percentage.toStringAsFixed(1)}%');
  
  // Sort subdirectories by name
  final sortedSubdirs = dir.subdirectories.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  
  // Sort files by name
  final sortedFiles = dir.files.toList()
    ..sort((a, b) {
      final aName = a.filePath.split('/').last;
      final bName = b.filePath.split('/').last;
      return aName.compareTo(bName);
    });
  
  final totalItems = sortedSubdirs.length + sortedFiles.length;
  var itemIndex = 0;
  
  // Print subdirectories first
  for (final subdir in sortedSubdirs) {
    if (!subdir.value.hasContent) continue;
    
    itemIndex++;
    final isLast = itemIndex == totalItems;
    final newPrefix = prefix + (isLast ? '└─ ' : '├─ ');
    final nextPrefix = prefix + (isLast ? '   ' : '│  ');
    
    print('$newPrefix${subdir.key} - ${subdir.value.percentage.toStringAsFixed(1)}%');
    
    // Recursively print subdirectory contents
    _printDirectoryContents(subdir.value, nextPrefix);
  }
  
  // Then print files
  for (final file in sortedFiles) {
    itemIndex++;
    final isLast = itemIndex == totalItems;
    final newPrefix = prefix + (isLast ? '└─ ' : '├─ ');
    
    final fileName = file.filePath.split('/').last;
    print('$newPrefix$fileName - ${file.percentage.toStringAsFixed(1)}%');
  }
}

void _printDirectoryContents(DirectoryCoverage dir, String prefix) {
  // Sort subdirectories by name
  final sortedSubdirs = dir.subdirectories.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  
  // Sort files by name
  final sortedFiles = dir.files.toList()
    ..sort((a, b) {
      final aName = a.filePath.split('/').last;
      final bName = b.filePath.split('/').last;
      return aName.compareTo(bName);
    });
  
  final contentItems = <dynamic>[];
  
  // Add subdirectories with content
  for (final subdir in sortedSubdirs) {
    if (subdir.value.hasContent) {
      contentItems.add(subdir);
    }
  }
  
  // Add files
  contentItems.addAll(sortedFiles);
  
  for (int i = 0; i < contentItems.length; i++) {
    final isLast = i == contentItems.length - 1;
    final newPrefix = prefix + (isLast ? '└─ ' : '├─ ');
    final nextPrefix = prefix + (isLast ? '   ' : '│  ');
    
    final item = contentItems[i];
    
    if (item is MapEntry<String, DirectoryCoverage>) {
      // It's a subdirectory
      print('$newPrefix${item.key} - ${item.value.percentage.toStringAsFixed(1)}%');
      _printDirectoryContents(item.value, nextPrefix);
    } else if (item is CoverageData) {
      // It's a file
      final fileName = item.filePath.split('/').last;
      print('$newPrefix$fileName - ${item.percentage.toStringAsFixed(1)}%');
    }
  }
}