// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Question _$QuestionFromJson(Map<String, dynamic> json) => _Question(
  id: json['id'] as String,
  textAr: json['textAr'] as String,
  textEn: json['textEn'] as String,
  packId: json['packId'] as String,
);

Map<String, dynamic> _$QuestionToJson(_Question instance) => <String, dynamic>{
  'id': instance.id,
  'textAr': instance.textAr,
  'textEn': instance.textEn,
  'packId': instance.packId,
};
