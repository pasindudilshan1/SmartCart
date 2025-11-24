import 'package:hive/hive.dart';

part 'household_member.g.dart';

@HiveType(typeId: 6)
class HouseholdMember extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int memberIndex; // 1, 2, 3, etc.

  @HiveField(2)
  String ageGroup; // 'infant', 'child', 'teen', 'adult', 'senior'

  @HiveField(3)
  double dailyCalories;

  @HiveField(4)
  double dailyProtein;

  @HiveField(5)
  double dailyFat;

  @HiveField(6)
  double dailyCarbs;

  @HiveField(7)
  double dailyFiber;

  @HiveField(8)
  String? name; // Optional member name

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  HouseholdMember({
    required this.id,
    required this.memberIndex,
    required this.ageGroup,
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyFat,
    required this.dailyCarbs,
    required this.dailyFiber,
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
      'AgeGroup': ageGroup,
      'DailyCalories': dailyCalories,
      'DailyProtein': dailyProtein,
      'DailyFat': dailyFat,
      'DailyCarbs': dailyCarbs,
      'DailyFiber': dailyFiber,
      'Name': name ?? '',
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Azure Table Storage entity
  factory HouseholdMember.fromAzureEntity(Map<String, dynamic> entity) {
    // Handle backward compatibility: old data has 'AverageDailyCalories', new has 'DailyCalories'
    double calories = (entity['DailyCalories'] as num?)?.toDouble() ??
        (entity['AverageDailyCalories'] as num?)?.toDouble() ??
        2250.0;
    return HouseholdMember(
      id: entity['RowKey'] as String,
      memberIndex: entity['MemberIndex'] as int,
      ageGroup: entity['AgeGroup'] as String? ?? 'adult',
      dailyCalories: calories,
      dailyProtein: (entity['DailyProtein'] as num?)?.toDouble() ?? 51.0,
      dailyFat: (entity['DailyFat'] as num?)?.toDouble() ?? 71.0,
      dailyCarbs: (entity['DailyCarbs'] as num?)?.toDouble() ?? 316.0,
      dailyFiber: (entity['DailyFiber'] as num?)?.toDouble() ?? 32.0,
      name: entity['Name'] as String? ?? '',
      createdAt: DateTime.parse(entity['CreatedAt'] as String),
      updatedAt: DateTime.parse(entity['UpdatedAt'] as String),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'memberIndex': memberIndex,
      'ageGroup': ageGroup,
      'dailyCalories': dailyCalories,
      'dailyProtein': dailyProtein,
      'dailyFat': dailyFat,
      'dailyCarbs': dailyCarbs,
      'dailyFiber': dailyFiber,
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
      ageGroup: data['ageGroup'] as String? ?? 'adult',
      dailyCalories: (data['dailyCalories'] as num?)?.toDouble() ?? 2250.0,
      dailyProtein: (data['dailyProtein'] as num?)?.toDouble() ?? 51.0,
      dailyFat: (data['dailyFat'] as num?)?.toDouble() ?? 71.0,
      dailyCarbs: (data['dailyCarbs'] as num?)?.toDouble() ?? 316.0,
      dailyFiber: (data['dailyFiber'] as num?)?.toDouble() ?? 32.0,
      name: data['name'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }
}
