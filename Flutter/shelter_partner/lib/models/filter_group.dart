import 'package:shelter_partner/models/filter_condition.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';

class FilterGroup extends FilterElement {
  LogicalOperator logicalOperator;
  List<FilterElement> elements;

  FilterGroup({
    required this.logicalOperator,
    required this.elements,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'group',
      'logicalOperator': logicalOperator.toString().split('.').last,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    return FilterGroup(
      logicalOperator: LogicalOperator.values.firstWhere(
        (e) => e.toString().split('.').last == json['logicalOperator'],
      ),
      elements: (json['elements'] as List<dynamic>)
          .map((e) =>
              FilterElement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

abstract class FilterElement {
  Map<String, dynamic> toJson();

  static FilterElement fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'condition') {
      return FilterCondition.fromJson(json);
    } else if (json['type'] == 'group') {
      return FilterGroup.fromJson(json);
    } else {
      throw Exception('Unknown FilterElement type: ${json['type']}');
    }
  }
}
