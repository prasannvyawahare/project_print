import 'package:flutter_bloc/flutter_bloc.dart';

import 'print_flow_event.dart';
import 'print_flow_state.dart';

class PrintFlowBloc extends Bloc<PrintFlowEvent, PrintFlowState> {
  PrintFlowBloc() : super(const PrintFlowState()) {
    on<PrintFlowFilesAdded>(_onFilesAdded);
    on<PrintFlowFileRemoved>(_onFileRemoved);
    on<PrintFlowFileConfigSaved>(_onFileConfigSaved);
    on<PrintFlowDetailsToggled>(_onDetailsToggled);
  }

  void _onFilesAdded(PrintFlowFilesAdded event, Emitter<PrintFlowState> emit) {
    final nextFiles = [...state.files, ...event.files];
    emit(state.copyWith(files: nextFiles));
  }

  void _onFileRemoved(
    PrintFlowFileRemoved event,
    Emitter<PrintFlowState> emit,
  ) {
    final nextFiles = state.files.where((f) => f.path != event.path).toList();
    final nextConfigs = Map<String, dynamic>.from(state.configurations)
      ..remove(event.path);

    emit(
      state.copyWith(
        files: nextFiles,
        configurations: nextConfigs.cast(),
        clearExpandedPath: state.expandedPath == event.path,
      ),
    );
  }

  void _onFileConfigSaved(
    PrintFlowFileConfigSaved event,
    Emitter<PrintFlowState> emit,
  ) {
    final nextConfigs = Map<String, dynamic>.from(state.configurations)
      ..[event.path] = event.config;

    final mergedOrder = state
        .copyWith(configurations: nextConfigs.cast())
        .buildMergedOrder();

    emit(
      state.copyWith(
        configurations: nextConfigs.cast(),
        lastOrder: mergedOrder,
      ),
    );
  }

  void _onDetailsToggled(
    PrintFlowDetailsToggled event,
    Emitter<PrintFlowState> emit,
  ) {
    final shouldCollapse = state.expandedPath == event.path;
    emit(
      state.copyWith(
        expandedPath: shouldCollapse ? null : event.path,
        clearExpandedPath: shouldCollapse,
      ),
    );
  }
}
