import 'package:flutter/material.dart';

// Enums and classes for filter conditions and groups
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

abstract class FilterElement {}

class FilterCondition extends FilterElement {
  String attribute;
  OperatorType operatorType;
  dynamic value;

  FilterCondition({
    required this.attribute,
    required this.operatorType,
    this.value,
  });
}

class FilterGroup extends FilterElement {
  LogicalOperator logicalOperator;
  List<FilterElement> elements;

  FilterGroup({
    required this.logicalOperator,
    required this.elements,
  });
}

class MainFilterPage extends StatefulWidget {
  const MainFilterPage({super.key});

  @override
  _MainFilterPageState createState() => _MainFilterPageState();
}

class _MainFilterPageState extends State<MainFilterPage> {
  List<FilterElement> filterElements = [];
  Map<int, LogicalOperator> operatorsBetween = {};
  bool groupWithPrevious = false; // State of the "Group with Previous" checkbox

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Filter"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Save the filter configuration
              Navigator.pop(context, filterElements);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Display the expression string at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
              text: buildExpressionSpan(filterElements),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: filterElements.length,
                itemBuilder: (context, index) {
                  final element = filterElements[index];
                  LogicalOperator? logicalOperatorBetween = index > 0 ? getOperatorBetween(index) : null;
                  return _buildFilterElementUI(element, index, indentLevel: 0, logicalOperatorBetween: logicalOperatorBetween);
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
                          _showAddConditionDialog(logicalOperator: LogicalOperator.and);
                        },
                        child: const Text('And'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showAddConditionDialog(logicalOperator: LogicalOperator.or);
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
    );
  }

  Widget _buildFilterElementUI(FilterElement element, int index, {int indentLevel = 0, LogicalOperator? logicalOperatorBetween}) {
    if (element is FilterCondition) {
      return _buildConditionCard(element, index, indentLevel: indentLevel, logicalOperatorBetween: logicalOperatorBetween);
    } else if (element is FilterGroup) {
      return _buildGroupCard(element, index, indentLevel: indentLevel, logicalOperatorBetween: logicalOperatorBetween);
    } else {
      return const SizedBox();
    }
  }

  Widget _buildConditionCard(FilterCondition condition, int index, {int indentLevel = 0, LogicalOperator? logicalOperatorBetween}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logicalOperatorBetween != null)
          _buildOperatorCard(logicalOperatorBetween, indentLevel),
        Padding(
          padding: EdgeInsets.only(left: indentLevel * 16.0, right: 8.0, top: 4.0, bottom: 4.0),
          child: Card(
            color: Colors.blue[50],
            elevation: 2,
            child: ListTile(
              title: Text(
                '${condition.attribute} ${_operatorToString(condition.operatorType)} ${condition.value}',
                style: const TextStyle(fontSize: 16.0),
              ),
              trailing: indentLevel == 0 // Only show delete button for top-level conditions
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

  Widget _buildGroupCard(FilterGroup group, int index, {int indentLevel = 0, LogicalOperator? logicalOperatorBetween}) {
    List<Widget> groupWidgets = [];

    for (int i = 0; i < group.elements.length; i++) {
      if (i > 0) {
        // Add operator card between group elements
        groupWidgets.add(_buildOperatorCard(group.logicalOperator, indentLevel + 1));
      }
      groupWidgets.add(_buildFilterElementUI(
        group.elements[i],
        i,
        indentLevel: indentLevel + 1,
        logicalOperatorBetween: null, // Operators between group elements are handled here
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logicalOperatorBetween != null)
          _buildOperatorCard(logicalOperatorBetween, indentLevel),
        Padding(
          padding: EdgeInsets.only(left: indentLevel * 16.0, right: 8.0, top: 4.0, bottom: 4.0),
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
      padding: EdgeInsets.only(left: indentLevel * 16.0 + 8.0, right: 8.0, top: 4.0, bottom: 4.0),
      child: Card(
        color: Colors.grey[200],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _logicalOperatorToString(operator).toUpperCase(),
              style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
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
  void addElement(FilterElement element, LogicalOperator logicalOperator, bool groupWithPrevious) {
    if (groupWithPrevious && filterElements.isNotEmpty) {
      final previousElement = filterElements.removeLast();

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
    // Remove operator if not first element
    if (index > 0) {
      removeOperatorBetween(index);
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

  InlineSpan buildExpressionSpan(List<FilterElement> elements, {LogicalOperator? groupOperator}) {
    List<InlineSpan> spans = [];
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];

      if (i > 0) {
        // Determine the operator between elements
        LogicalOperator op = groupOperator ?? getOperatorBetween(i);
        spans.add(TextSpan(
          text: ' ${_logicalOperatorToString(op)} ',
          style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
        ));
      }

      if (element is FilterCondition) {
        // Build the condition span
        spans.add(TextSpan(
          children: [
            TextSpan(text: element.attribute, style: const TextStyle(color: Colors.blue)),
            TextSpan(text: ' ${_operatorToString(element.operatorType)} ', style: const TextStyle(color: Colors.red)),
            TextSpan(text: '${element.value}', style: const TextStyle(color: Colors.green)),
          ],
        ));
      } else if (element is FilterGroup) {
        // Add opening parenthesis
        spans.add(const TextSpan(text: '(', style: TextStyle(color: Colors.black)));

        // Recursively build the group
        spans.add(buildExpressionSpan(element.elements, groupOperator: element.logicalOperator));

        // Add closing parenthesis
        spans.add(const TextSpan(text: ')', style: TextStyle(color: Colors.black)));
      }
    }

    return TextSpan(children: spans);
  }

  String _operatorToString(OperatorType operatorType) {
    switch (operatorType) {
      case OperatorType.equals:
        return '==';
      case OperatorType.notEquals:
        return '!=';
      case OperatorType.contains:
        return 'contains';
      case OperatorType.notContains:
        return 'not contains';
      case OperatorType.greaterThan:
        return '>';
      case OperatorType.lessThan:
        return '<';
      case OperatorType.greaterThanOrEqual:
        return '>=';
      case OperatorType.lessThanOrEqual:
        return '<=';
      case OperatorType.isTrue:
        return 'is true';
      case OperatorType.isFalse:
        return 'is false';
      default:
        return '';
    }
  }

  String _logicalOperatorToString(LogicalOperator operator) {
    return operator == LogicalOperator.and ? 'and' : 'or';
  }
}

class AddConditionDialog extends StatefulWidget {
  final bool hasPrevious;
  final LogicalOperator? logicalOperator;
  final bool groupWithPrevious;
  final Function(FilterElement element, LogicalOperator logicalOperator) onAdd;

  const AddConditionDialog({super.key, 
    required this.onAdd,
    required this.hasPrevious,
    this.logicalOperator,
    required this.groupWithPrevious,
  });

  @override
  _AddConditionDialogState createState() => _AddConditionDialogState();
}

class _AddConditionDialogState extends State<AddConditionDialog> {
  String selectedAttribute = 'name';
  OperatorType? selectedOperator;
  dynamic value;

  late LogicalOperator selectedLogicalOperator;

  final Map<String, List<OperatorType>> attributeOperators = {
    'name': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains
    ],
    'sex': [OperatorType.equals, OperatorType.notEquals],
    'age': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.greaterThan,
      OperatorType.lessThan
    ],
    'species': [OperatorType.equals, OperatorType.notEquals],
    'breed': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains
    ],
    'location': [
      OperatorType.equals,
      OperatorType.notEquals,
      OperatorType.contains,
      OperatorType.notContains
    ],
    'inKennel': [OperatorType.isTrue, OperatorType.isFalse],
    // Add other attributes and their valid operators
  };

  @override
  void initState() {
    super.initState();
    selectedLogicalOperator = widget.logicalOperator ?? LogicalOperator.and;
  }

  @override
  Widget build(BuildContext context) {
    List<String> attributes = attributeOperators.keys.toList();
    List<OperatorType> operators = attributeOperators[selectedAttribute]!;

    return AlertDialog(
      title: const Text('Add Condition'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Attribute Dropdown
            DropdownButtonFormField<String>(
              value: selectedAttribute,
              decoration: const InputDecoration(labelText: 'Attribute'),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedAttribute = value;
                    selectedOperator = null;
                    this.value = null;
                  });
                }
              },
              items: attributes.map((attr) {
                return DropdownMenuItem(
                  value: attr,
                  child: Text(attr),
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
                ![OperatorType.isTrue, OperatorType.isFalse]
                    .contains(selectedOperator))
              TextFormField(
                decoration: const InputDecoration(labelText: 'Value'),
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
              widget.onAdd(
                FilterCondition(
                  attribute: selectedAttribute,
                  operatorType: selectedOperator!,
                  value: value,
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
        return '==';
      case OperatorType.notEquals:
        return '!=';
      case OperatorType.contains:
        return 'contains';
      case OperatorType.notContains:
        return 'not contains';
      case OperatorType.greaterThan:
        return '>';
      case OperatorType.lessThan:
        return '<';
      case OperatorType.greaterThanOrEqual:
        return '>=';
      case OperatorType.lessThanOrEqual:
        return '<=';
      case OperatorType.isTrue:
        return 'is true';
      case OperatorType.isFalse:
        return 'is false';
      default:
        return '';
    }
  }
}
