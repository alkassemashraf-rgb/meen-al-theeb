// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PresenceState _$PresenceStateFromJson(Map<String, dynamic> json) =>
    _PresenceState(
      isPresent: json['isPresent'] as bool,
      lastActiveAt:
          json['lastActiveAt'] == null
              ? null
              : DateTime.parse(json['lastActiveAt'] as String),
    );

Map<String, dynamic> _$PresenceStateToJson(_PresenceState instance) =>
    <String, dynamic>{
      'isPresent': instance.isPresent,
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
    };
