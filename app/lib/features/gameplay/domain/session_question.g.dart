// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionQuestion _$SessionQuestionFromJson(Map<String, dynamic> json) =>
    _SessionQuestion(
      id: json['id'] as String,
      textAr: json['textAr'] as String,
      textEn: json['textEn'] as String? ?? '',
      packId: json['packId'] as String? ?? '',
    );

Map<String, dynamic> _$SessionQuestionToJson(_SessionQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'textAr': instance.textAr,
      'textEn': instance.textEn,
      'packId': instance.packId,
    };
