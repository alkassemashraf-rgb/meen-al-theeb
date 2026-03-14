import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence_state.freezed.dart';
part 'presence_state.g.dart';

@freezed
abstract class PresenceState with _$PresenceState {
  const factory PresenceState({
    required bool isPresent,
    @Default(null) DateTime? lastActiveAt,
  }) = _PresenceState;

  factory PresenceState.fromJson(Map<String, dynamic> json) => _$PresenceStateFromJson(json);
}
