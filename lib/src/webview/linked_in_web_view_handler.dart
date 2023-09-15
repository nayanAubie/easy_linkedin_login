import 'package:easy_linkedin_login/src/utils/configuration.dart';
import 'package:easy_linkedin_login/src/utils/logger.dart';
import 'package:easy_linkedin_login/src/utils/startup/graph.dart';
import 'package:easy_linkedin_login/src/utils/startup/injector.dart';
import 'package:easy_linkedin_login/src/webview/actions.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Class will fetch code and access token from the user
/// It will show web view so that we can access to linked in auth page
@immutable
class LinkedInWebViewHandler extends StatefulWidget {
  const LinkedInWebViewHandler({
    required this.onUrlMatch,
    this.appBar,
    this.destroySession = false,
    this.onCookieClear,
  });

  final bool? destroySession;
  final PreferredSizeWidget? appBar;
  final Function(DirectionUrlMatch) onUrlMatch;
  final Function(bool)? onCookieClear;

  @override
  State createState() => _LinkedInWebViewHandlerState();
}

class _LinkedInWebViewHandlerState extends State<LinkedInWebViewHandler> {
  late final WebViewController _webViewController;
  final _cookieManager = WebViewCookieManager();
  late final _viewModel = _ViewModel.from(context);

  @override
  void initState() {
    super.initState();

    if (widget.destroySession!) {
      log('LinkedInAuth-steps: cache clearing... ');
      _cookieManager.clearCookies().then((value) {
        widget.onCookieClear?.call(true);
        log('LinkedInAuth-steps: cache clearing... DONE');
      });
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            log('LinkedInAuth-steps: navigationDelegate ... ');
            final isMatch = _viewModel.isUrlMatchingToRedirection(
              context,
              request.url,
            );
            log(
              'LinkedInAuth-steps: navigationDelegate '
                  '[currentUrL: ${request.url}, isCurrentMatch: $isMatch]',
            );

            if (isMatch) {
              widget.onUrlMatch(_viewModel.getUrlConfiguration(request.url));
              log('Navigation delegate prevent... done');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_viewModel.initialUrl()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: Builder(
        builder: (BuildContext context) {
          return WebViewWidget(controller: _webViewController);
        },
      ),
    );
  }
}

@immutable
class _ViewModel {
  const _ViewModel._({
    required this.graph,
  });

  factory _ViewModel.from(BuildContext context) => _ViewModel._(
        graph: InjectorWidget.of(context),
      );

  final Graph? graph;

  DirectionUrlMatch getUrlConfiguration(String url) {
    final type = graph!.linkedInConfiguration is AccessCodeConfiguration
        ? WidgetType.fullProfile
        : WidgetType.authCode;
    return DirectionUrlMatch(url: url, type: type);
  }

  String initialUrl() => graph!.linkedInConfiguration.initialUrl;

  bool isUrlMatchingToRedirection(BuildContext context, String url) {
    return graph!.linkedInConfiguration.isCurrentUrlMatchToRedirection(url);
  }
}
