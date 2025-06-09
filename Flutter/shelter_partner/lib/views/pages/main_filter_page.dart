import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/filter_condition.dart';
import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/view_models/filter_view_model.dart';

enum LogicalOperator { and, or }

enum OperatorType {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  isTrue,
  isFalse,
}

class MainFilterPage extends ConsumerStatefulWidget {
  final String title;
  final String collection;
  final String documentID;
  final String filterFieldPath;

  const MainFilterPage({
    super.key,
    required this.title,
    required this.collection,
    required this.documentID,
    required this.filterFieldPath,
  });
  @override
  _MainFilterPageState createState() => _MainFilterPageState();
}

class _MainFilterPageState extends ConsumerState<MainFilterPage> {
  List<FilterElement> filterElements = [];
  Map<int, LogicalOperator> operatorsBetween = {};
  bool groupWithPrevious = false; // State of the "Group with Previous" checkbox

  final Map<String, String> attributeDisplayNames = {
    'Name': 'name',
    'Notes': 'notes',
    'Tags': 'tags',
    'Sex': 'sex',
    'Breed': 'breed',
    'Location': 'location',
    'Description': 'description',
    'Take Out Alert': 'takeOutAlert',
    'Put Back Alert': 'putBackAlert',
    'Adoption Category': 'adoptionCategory',
    'Behavior Category': 'behaviorCategory',
    // 'Location Category': 'locationCategory',
    'Medical Category': 'medicalCategory',
    'Volunteer Category': 'volunteerCategory',
    'Months Old': 'monthsOld',
    'In Kennel': 'inKennel',
    'Let Out Type': 'letOutType',
    'Early Put Back Reason': 'earlyPutBackReason',
  };

  @override
  void initState() {
    super.initState();
    _loadFilterExpression();
  }

  Future<void> _loadFilterExpression() async {
    final filterViewModel = ref.read(filterViewModelProvider.notifier);
    final result = await filterViewModel.loadFilterExpression(
      widget.title,
      widget.collection,
      widget.documentID,
      widget.filterFieldPath,
    );
    if (result != null) {
      setState(() {
        final rawFilterElements =
            result['filterElements'] as List<dynamic>? ?? [];
        final rawOperatorsBetween =
            result['operatorsBetween'] as Map<String, dynamic>? ?? {};

        filterElements = rawFilterElements
            .map<FilterElement>(
              (e) => FilterElement.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        operatorsBetween = rawOperatorsBetween.map<int, LogicalOperator>((
          key,
          value,
        ) {
          return MapEntry(
            int.parse(key),
            LogicalOperator.values.firstWhere(
              (e) => e.toString().split('.').last == value,
            ),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // Serialize filterElements
              List<Map<String, dynamic>> serializedFilterElements =
                  filterElements.map((e) => e.toJson()).toList();

              // Serialize operatorsBetween
              Map<String, String> serializedOperatorsBetween = operatorsBetween
                  .map(
                    (key, value) => MapEntry(
                      key.toString(),
                      value.toString().split('.').last,
                    ),
                  );

              // Save to Firestore
              final filterViewModel = ref.read(
                filterViewModelProvider.notifier,
              );
              await filterViewModel.saveFilterExpression(
                serializedFilterElements,
                serializedOperatorsBetween,
                widget.collection,
                widget.documentID,
                widget.filterFieldPath,
              );

              Navigator.pop(context, filterElements);
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            children: [
              // Display the expression string at the top
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(text: buildExpressionSpan(filterElements)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    itemCount: filterElements.length,
                    itemBuilder: (context, index) {
                      final element = filterElements[index];
                      LogicalOperator? logicalOperatorBetween = index > 0
                          ? getOperatorBetween(index - 1)
                          : null;
                      return _buildFilterElementUI(
                        element,
                        index,
                        indentLevel: 0,
                        logicalOperatorBetween: logicalOperatorBetween,
                      );
                    },
                  ),
                ),
              ),
              // Conditional buttons and Group with Previous checkbox
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    if (filterElements.isEmpty)
                      ElevatedButton(
                        onPressed: () {
                          _showAddConditionDialog();
                        },
                        child: const Text('Add Condition'),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _showAddConditionDialog(
                                logicalOperator: LogicalOperator.and,
                              );
                            },
                            child: const Text('And'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              _showAddConditionDialog(
                                logicalOperator: LogicalOperator.or,
                              );
                            },
                            child: const Text('Or'),
                          ),
                          const SizedBox(width: 10),
                          // "Group with Previous" checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: groupWithPrevious,
                                onChanged: (value) {
                                  setState(() {
                                    groupWithPrevious = value ?? false;
                                  });
                                },
                              ),
                              const Text('Group with Previous'),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterElementUI(
    FilterElement element,
    int index, {
    int indentLevel = 0,
    LogicalOperator? logicalOperatorBetween,
  }) {
    if (element is FilterCondition) {
      return _buildConditionCard(
        element,
        index,
        indentLevel: indentLevel,
        logicalOperatorBetween: logicalOperatorBetween,
      );
    } else if (element is FilterGroup) {
      return _buildGroupCard(
        element,
        index,
        indentLevel: indentLevel,
        logicalOperatorBetween: logicalOperatorBetween,
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildConditionCard(
    FilterCondition condition,
    int index, {
    int indentLevel = 0,
    LogicalOperator? logicalOperatorBetween,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logicalOperatorBetween != null)
          _buildOperatorCard(logicalOperatorBetween, indentLevel),
        Padding(
          padding: EdgeInsets.only(
            left: indentLevel * 16.0,
            right: 8.0,
            top: 4.0,
            bottom: 4.0,
          ),
          child: Card(
            color: Colors.blue[50],
            elevation: 2,
            child: ListTile(
              title: Text(
                '${_getDisplayName(condition.attribute)} ${_operatorToString(condition.operatorType)} ${condition.value}',
                style: const TextStyle(fontSize: 16.0),
              ),
              trailing:
                  indentLevel ==
                      0 // Only show delete button for top-level conditions
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          removeElementAt(index);
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(
    FilterGroup group,
    int index, {
    int indentLevel = 0,
    LogicalOperator? logicalOperatorBetween,
  }) {
    List<Widget> groupWidgets = [];

    for (int i = 0; i < group.elements.length; i++) {
      if (i > 0) {
        // Add operator card between group elements
        groupWidgets.add(
          _buildOperatorCard(group.logicalOperator, indentLevel + 1),
        );
      }
      groupWidgets.add(
        _buildFilterElementUI(
          group.elements[i],
          i,
          indentLevel: indentLevel + 1,
          logicalOperatorBetween:
              null, // Operators between group elements are handled here
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logicalOperatorBetween != null)
          _buildOperatorCard(logicalOperatorBetween, indentLevel),
        Padding(
          padding: EdgeInsets.only(
            left: indentLevel * 16.0,
            right: 8.0,
            top: 4.0,
            bottom: 4.0,
          ),
          child: Card(
            color: Colors.green[50],
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Group header
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            removeElementAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  // Group elements
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupWidgets,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperatorCard(LogicalOperator operator, int indentLevel) {
    return Padding(
      padding: EdgeInsets.only(
        left: indentLevel * 16.0 + 8.0,
        right: 8.0,
        top: 4.0,
        bottom: 4.0,
      ),
      child: Card(
        color: Colors.grey[200],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _logicalOperatorToString(operator).toUpperCase(),
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddConditionDialog({LogicalOperator? logicalOperator}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddConditionDialog(
          hasPrevious: filterElements.isNotEmpty,
          logicalOperator: logicalOperator,
          groupWithPrevious: groupWithPrevious,
          onAdd: (newElement, logicalOperator) {
            setState(() {
              addElement(newElement, logicalOperator, groupWithPrevious);
            });
          },
        );
      },
    );
  }

  // Helper methods
  void addElement(
    FilterElement element,
    LogicalOperator logicalOperator,
    bool groupWithPrevious,
  ) {
    if (groupWithPrevious && filterElements.isNotEmpty) {
      final previousElement = filterElements.removeLast();

      // Remove the operator between the previous element and the one before it
      if (filterElements.isNotEmpty) {
        removeOperatorBetween(filterElements.length);
      }

      if (previousElement is FilterGroup &&
          previousElement.logicalOperator == logicalOperator) {
        // Add to existing group
        previousElement.elements.add(element);
        filterElements.add(previousElement);
      } else {
        // Create a new group
        FilterGroup newGroup = FilterGroup(
          logicalOperator: logicalOperator,
          elements: [previousElement, element],
        );
        filterElements.add(newGroup);
      }
    } else {
      if (filterElements.isNotEmpty) {
        setOperatorBetween(filterElements.length - 1, logicalOperator);
      }
      filterElements.add(element);
    }
  }

  void removeElementAt(int index) {
    filterElements.removeAt(index);

    if (filterElements.isEmpty) {
      operatorsBetween.clear();
    } else {
      // Remove the operator before the removed element
      if (index > 0) {
        operatorsBetween.remove(index - 1);
      }
      // Shift operatorsBetween entries after the removed element
      Map<int, LogicalOperator> newOperatorsBetween = {};
      for (int i = 0; i < filterElements.length - 1; i++) {
        int oldIndex = (i >= index - 1) ? i + 1 : i;
        if (operatorsBetween.containsKey(oldIndex)) {
          newOperatorsBetween[i] = operatorsBetween[oldIndex]!;
        }
      }
      operatorsBetween = newOperatorsBetween;
    }
  }

  void setOperatorBetween(int index, LogicalOperator operator) {
    operatorsBetween[index] = operator;
  }

  void removeOperatorBetween(int index) {
    operatorsBetween.remove(index);
  }

  LogicalOperator getOperatorBetween(int index) {
    return operatorsBetween[index] ?? LogicalOperator.and;
  }

  InlineSpan buildExpressionSpan(
    List<FilterElement> elements, {
    LogicalOperator? groupOperator,
  }) {
    List<InlineSpan> spans = [];
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];

      if (i > 0) {
        // Determine the operator between elements
        LogicalOperator op = groupOperator ?? getOperatorBetween(i - 1);
        spans.add(
          TextSpan(
            text: ' ${_logicalOperatorToString(op)} ',
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      if (element is FilterCondition) {
        // Build the condition span
        spans.add(
          TextSpan(
            children: [
              TextSpan(
                text: _getDisplayName(element.attribute),
                style: const TextStyle(color: Colors.blue),
              ),
              TextSpan(
                text: ' ${_operatorToString(element.operatorType)} ',
                style: const TextStyle(color: Colors.red),
              ),
              TextSpan(
                text: '${element.value}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        );
      } else if (element is FilterGroup) {
        // Add opening parenthesis
        spans.add(
          const TextSpan(
            text: '(',
            style: TextStyle(color: Colors.black),
          ),
        );

        // Recursively build the group
        spans.add(
          buildExpressionSpan(
            element.elements,
            groupOperator: element.logicalOperator,
          ),
        );

        // Add closing parenthesis
        spans.add(
          const TextSpan(
            text: ')',
            style: TextStyle(color: Colors.black),
          ),
        );
      }
    }

    return TextSpan(children: spans);
  }

  String _operatorToString(OperatorType operatorType) {
    switch (operatorType) {
      case OperatorType.equals:
        return 'Equals';
      case OperatorType.notEquals:
        return 'Not Equals';
      case OperatorType.contains:
        return 'Contains';
      case OperatorType.notContains:
        return 'Not Contains';
      case OperatorType.greaterThan:
        return 'Greater Than';
      case OperatorType.lessThan:
        return 'Less Than';
      case OperatorType.greaterThanOrEqual:
        return 'Greater Than Or Equal';
      case OperatorType.lessThanOrEqual:
        return 'Less Than Or Equal';
      case OperatorType.isTrue:
        return 'Is True';
      case OperatorType.isFalse:
        return 'Is False';
    }
  }

  String _logicalOperatorToString(LogicalOperator operator) {
    return operator == LogicalOperator.and ? 'AND' : 'OR';
  }

  String _getDisplayName(String attributeKey) {
    return attributeDisplayNames.entries
        .firstWhere((entry) => entry.value == attributeKey)
        .key;
  }
}

class AddConditionDialog extends StatefulWidget {
  final bool hasPrevious;
  final LogicalOperator? logicalOperator;
  final bool groupWithPrevious;
  final Function(FilterElement element, LogicalOperator logicalOperator) onAdd;

  const AddConditionDialog({
    super.key,
    required this.onAdd,
    required this.hasPrevious,
    this.logicalOperator,
    required this.groupWithPrevious,
  });

  @override
  _AddConditionDialogState createState() => _AddConditionDialogState();
}

class _AddConditionDialogState extends State<AddConditionDialog> {
  String selectedAttributeDisplayName = 'Name'; // Default display name
  String selectedAttribute = 'name'; // Corresponding attribute key
  OperatorType? selectedOperator;
  dynamic value;

  late LogicalOperator selectedLogicalOperator;

  final Map<String, String> attributeDisplayNames = {
    'Name': 'name',
    'Notes': 'notes',
    'Tags': 'tags',
    'Sex': 'sex',
    'Breed': 'breed',
    'Location': 'location',
    'Description': 'description',
    'Take Out Alert': 'takeOutAlert',
    'Put Back Alert': 'putBackAlert',
    'Adoption Category': 'adoptionCategory',
    'Behavior Category': 'behaviorCategory',
    // 'Location Category': 'locationCategory',
    'Medical Category': 'medicalCategory',
    'Volunteer Category': 'volunteerCategory',
    'Months Old': 'monthsOld',
    'In Kennel': 'inKennel',
    // Add other display names and attribute keys as needed
  };

  final Map<String, List<OperatorType>> attributeOperators = {
    'name': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'notes': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'tags': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'sex': [OperatorType.equals, OperatorType.notEquals],
    'breed': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'location': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'description': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'takeOutAlert': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'putBackAlert': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'adoptionCategory': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'behaviorCategory': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'locationCategory': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'medicalCategory': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'volunteerCategory': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'monthsOld': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.greaterThan,
      OperatorType.lessThan,
      OperatorType.greaterThanOrEqual,
      OperatorType.lessThanOrEqual,
    ],
    'inKennel': [OperatorType.isTrue, OperatorType.isFalse],

    'letOutType': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    'earlyPutBackReason': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains,
    ],
    // Add other attributes and their valid operators
  };

  @override
  void initState() {
    super.initState();
    selectedLogicalOperator = widget.logicalOperator ?? LogicalOperator.and;
  }

  @override
  Widget build(BuildContext context) {
    List<OperatorType> operators = attributeOperators[selectedAttribute] ?? [];

    return AlertDialog(
      title: const Text('Add Condition'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Attribute Dropdown
            DropdownButtonFormField<String>(
              value: selectedAttributeDisplayName,
              decoration: const InputDecoration(labelText: 'Attribute'),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedAttributeDisplayName = value;
                    selectedAttribute = attributeDisplayNames[value]!;
                    selectedOperator = null;
                    this.value = null;
                  });
                }
              },
              items: attributeDisplayNames.keys.map((displayName) {
                return DropdownMenuItem(
                  value: displayName,
                  child: Text(displayName),
                );
              }).toList(),
            ),
            // Operator Dropdown
            DropdownButtonFormField<OperatorType>(
              value: selectedOperator,
              decoration: const InputDecoration(labelText: 'Operator'),
              onChanged: (value) {
                setState(() {
                  selectedOperator = value;
                  this.value = null; // Reset value when operator changes
                });
              },
              items: operators.map((op) {
                return DropdownMenuItem(
                  value: op,
                  child: Text(_operatorToString(op)),
                );
              }).toList(),
            ),
            // Value Input
            if (selectedOperator != null &&
                ![
                  OperatorType.isTrue,
                  OperatorType.isFalse,
                ].contains(selectedOperator))
              TextFormField(
                decoration: const InputDecoration(labelText: 'Value'),
                keyboardType: selectedAttribute == 'monthsOld'
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: selectedAttribute == 'monthsOld'
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                onChanged: (val) {
                  setState(() {
                    value = val;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (selectedOperator != null &&
                (selectedOperator == OperatorType.isTrue ||
                    selectedOperator == OperatorType.isFalse ||
                    value != null)) {
              dynamic parsedValue = value;

              if (selectedAttribute == 'monthsOld') {
                parsedValue = int.tryParse(value);
                if (parsedValue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid number for Months Old',
                      ),
                    ),
                  );
                  return;
                }
              }

              widget.onAdd(
                FilterCondition(
                  attribute: selectedAttribute,
                  operatorType: selectedOperator!,
                  value: parsedValue,
                ),
                selectedLogicalOperator,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _operatorToString(OperatorType operatorType) {
    switch (operatorType) {
      case OperatorType.equals:
        return 'Equals';
      case OperatorType.notEquals:
        return 'Not Equals';
      case OperatorType.contains:
        return 'Contains';
      case OperatorType.notContains:
        return 'Not Contains';
      case OperatorType.greaterThan:
        return 'Greater Than';
      case OperatorType.lessThan:
        return 'Less Than';
      case OperatorType.greaterThanOrEqual:
        return 'Greater Than Or Equal';
      case OperatorType.lessThanOrEqual:
        return 'Less Than Or Equal';
      case OperatorType.isTrue:
        return 'Is True';
      case OperatorType.isFalse:
        return 'Is False';
    }
  }
}
