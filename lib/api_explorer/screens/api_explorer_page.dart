import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:apidash/widgets/widgets.dart';
import 'package:apidash/consts.dart';
import 'api_explorer_sidebar.dart';
import 'api_explorer_detail.dart';

/// Top-level API Explorer page, mirrors the history page structure.
class ApiExplorerPage extends StatelessWidget {
  const ApiExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isMediumWindow) {
      return Scaffold(
        key: kExplorerScaffoldKey,
        appBar: AppBar(
          title: const Text('API Explorer'),
          centerTitle: false,
        ),
        body: const ApiExplorerSidebar(),
      );
    }
    return const Column(
      children: [
        Expanded(
          child: DashboardSplitView(
            sidebarWidget: ApiExplorerSidebar(),
            mainWidget: ApiExplorerDetail(),
          ),
        ),
      ],
    );
  }
}
