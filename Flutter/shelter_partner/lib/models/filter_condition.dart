import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';

class FilterCondition extends FilterElement {
  String attribute;
  OperatorType operatorType;
  dynamic value;

  FilterCondition({
    required this.attribute,
    required this.operatorType,
    this.value,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'condition',
      'attribute': attribute,
      'operatorType': operatorType.toString().split('.').last,
      if (value != null) 'value': value,
    };
  }

  factory FilterCondition.fromJson(Map<String, dynamic> json) {
    return FilterCondition(
      attribute: json['attribute'],
      operatorType: OperatorType.values.firstWhere(
        (e) => e.toString().split('.').last == json['operatorType'],
      ),
      value: json.containsKey('value') ? json['value'] : null,
    );
  }
}