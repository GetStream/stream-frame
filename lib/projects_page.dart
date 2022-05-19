import 'package:flutter/material.dart';
import 'package:stream_frame/builders/activities.dart';
import 'package:stream_frame/new_project_dialog.dart';

/// Home screen of the application
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).restorablePush(_dialogBuilder);
            },
            child: const Icon(
              Icons.add,
            )),
        appBar: AppBar(
          title: const Text(
            "Stream Frame",
          ),
        ),
        body: const ProjectPreviewBuilder());
  }

  static Route<Object?> _dialogBuilder(
      BuildContext context, Object? arguments) {
    return DialogRoute<void>(
      context: context,
      builder: (BuildContext context) => const NewProjectDialog(),
    );
  }
}
