import 'ai_models.dart';

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.operation,
    required this.originalPath,
    required this.processedPath,
    required this.createdAt,
  });

  final String id;
  final AiOperation operation;
  final String originalPath;
  final String processedPath;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'operation': operation.name,
        'originalPath': originalPath,
        'processedPath': processedPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      operation: AiOperation.fromString(json['operation'] as String),
      originalPath: json['originalPath'] as String,
      processedPath: json['processedPath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum EntitlementType { free, proMonthly, proYearly, lifetime }

extension EntitlementTypeX on EntitlementType {
  bool get isPro => this != EntitlementType.free;

  String get storageKey {
    switch (this) {
      case EntitlementType.free:
        return 'free';
      case EntitlementType.proMonthly:
        return 'pro_monthly';
      case EntitlementType.proYearly:
        return 'pro_yearly';
      case EntitlementType.lifetime:
        return 'lifetime';
    }
  }

  static EntitlementType fromStorage(String? value) {
    switch (value) {
      case 'pro_monthly':
        return EntitlementType.proMonthly;
      case 'pro_yearly':
        return EntitlementType.proYearly;
      case 'lifetime':
        return EntitlementType.lifetime;
      default:
        return EntitlementType.free;
    }
  }
}

enum ThemeModeOption { system, light, dark }

class ResultArgs {
  const ResultArgs({
    required this.originalPath,
    required this.processedPath,
    required this.operation,
  });

  final String originalPath;
  final String processedPath;
  final AiOperation operation;
}

class ToolScreenArgs {
  const ToolScreenArgs({this.initialImagePath});

  final String? initialImagePath;
}
