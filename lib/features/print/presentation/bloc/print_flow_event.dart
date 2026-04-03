import '../../domain/entities/print_order_data.dart';

sealed class PrintFlowEvent {
  const PrintFlowEvent();
}

class PrintFlowFilesAdded extends PrintFlowEvent {
  const PrintFlowFilesAdded(this.files);

  final List<PrintDocument> files;
}

class PrintFlowFileRemoved extends PrintFlowEvent {
  const PrintFlowFileRemoved(this.path);

  final String path;
}

class PrintFlowFileConfigSaved extends PrintFlowEvent {
  const PrintFlowFileConfigSaved({required this.path, required this.config});

  final String path;
  final FilePrintConfiguration config;
}

class PrintFlowDetailsToggled extends PrintFlowEvent {
  const PrintFlowDetailsToggled(this.path);

  final String path;
}
