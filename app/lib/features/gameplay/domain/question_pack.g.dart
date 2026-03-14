// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuestionPack _$QuestionPackFromJson(Map<String, dynamic> json) =>
    _QuestionPack(
      packId: json['packId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'ar',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      icon: json['icon'] as String? ?? '🐺',
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt:
          json['createdAt'] == null
              ? null
              : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$QuestionPackToJson(_QuestionPack instance) =>
    <String, dynamic>{
      'packId': instance.packId,
      'name': instance.name,
      'description': instance.description,
      'language': instance.language,
      'questionCount': instance.questionCount,
      'icon': instance.icon,
      'isPremium': instance.isPremium,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
