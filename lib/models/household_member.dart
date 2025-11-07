import 'package:hive/hive.dart';

part 'household_member.g.dart';

@HiveType(typeId: 4)
class HouseholdMember extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int memberIndex; // 1, 2, 3, etc.

  @HiveField(2)
  double averageDailyCalories;

  @HiveField(3)
  String? name; // Optional member name

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  HouseholdMember({
    required this.id,
    required this.memberIndex,
    required this.averageDailyCalories,
    this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Azure Table Storage
  Map<String, dynamic> toAzureEntity(String userId) {
    return {
      'PartitionKey': userId,
      'RowKey': id,
      'MemberIndex': memberIndex,
      'AverageDailyCalories': averageDailyCalories,
      'Name': name ?? '',
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Azure Table Storage entity
  factory HouseholdMember.fromAzureEntity(Map<String, dynamic> entity) {
    return HouseholdMember(
      id: entity['RowKey'] as String,
      memberIndex: entity['MemberIndex'] as int,
      averageDailyCalories: (entity['AverageDailyCalories'] as num).toDouble(),
      name: entity['Name'] as String? ?? '',
      createdAt: DateTime.parse(entity['CreatedAt'] as String),
      updatedAt: DateTime.parse(entity['UpdatedAt'] as String),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'memberIndex': memberIndex,
      'averageDailyCalories': averageDailyCalories,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory HouseholdMember.fromFirestore(String id, Map<String, dynamic> data) {
    return HouseholdMember(
      id: id,
      memberIndex: data['memberIndex'] as int,
      averageDailyCalories: (data['averageDailyCalories'] as num).toDouble(),
      name: data['name'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }
}
