import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer';

void main() => runApp(DebuggerApp());

class DebuggerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Debugger',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: WebDebuggerHome(),
    );
  }
}

class WebDebuggerHome extends StatefulWidget {
  @override
  State<WebDebuggerHome> createState() => _WebDebuggerHomeState();
}

class _WebDebuggerHomeState extends State<WebDebuggerHome> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: "https://example.com");
  final List<String> _logs = [];

  final String _debuggerScript = '''
    (function () {
      const dict = ['user', 'login', 'map', 'chat', 'button', 'treasure'];
      window.onerror = function(msg, src, line, col, err) {
        window.flutter_inappwebview.callHandler('logHandler', '❌ ' + msg + ' at ' + line + ':' + col);
      };
      const origConsoleError = console.error;
      console.error = function(...args) {
        window.flutter_inappwebview.callHandler('logHandler', '🚫 ' + args.join(' '));
        origConsoleError(...args);
      };
      setTimeout(() => {
        const words = document.body.innerText.split(/\\s+/);
        words.forEach(word => {
          if (word.length > 4 && !dict.includes(word.toLowerCase())) {
            window.flutter_inappwebview.callHandler('logHandler', '🔍 Typo: "' + word + '"');
          }
        });
      }, 3000);
    })();
  ''';

  void _injectScript() async {
    await _controller.runJavaScript(_debuggerScript);
  }

  void _loadWebsite() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('logHandler', onMessageReceived: (msg) {
        setState(() => _logs.add(msg.message));
      })
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) {
          _injectScript();
        }),
      )
      ..loadRequest(Uri.parse(_urlController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Website Debugger'),
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: _loadWebsite,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter URL',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _loadWebsite,
                ),
              ),
              onSubmitted: (_) => _loadWebsite(),
            ),
          ),
          Expanded(
            flex: 2,
            child: WebViewWidget(controller: _controller),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(_logs[index], style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
