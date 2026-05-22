import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingState extends Equatable {
  final int currentIndex;
  const OnboardingState(this.currentIndex);

  @override
  List<Object?> get props => [currentIndex];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  final GetStorage _box;

  OnboardingCubit(this._box) : super(const OnboardingState(0));

  void setIndex(int index) {
    emit(OnboardingState(index));
  }

  void completeOnboarding() {
    _box.write('hasSeenOnboarding', true);
  }
}
