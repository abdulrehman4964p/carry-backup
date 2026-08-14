import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_config.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _web;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  int _progress = 0;
  int _selectedIndex = 0;
  bool _offline = false;
  bool _pageError = false;

  static const _tabs = <_AppTab>[
    _AppTab('Home', Icons.home_rounded, AppConfig.homeUrl),
    _AppTab('Courses', Icons.school_rounded, AppConfig.myCoursesUrl),
    _AppTab('Signals', Icons.candlestick_chart_rounded, AppConfig.signalsUrl),
    _AppTab('Dashboard', Icons.dashboard_rounded, AppConfig.dashboardUrl),
    _AppTab('Login', Icons.person_rounded, AppConfig.loginUrl),
  ];

  static const _menuGroups = <_MenuGroup>[
    _MenuGroup('LEARNING', [
      _AppTab('Learning Center', Icons.auto_stories_rounded, AppConfig.learningCenterUrl),
      _AppTab('My Courses', Icons.school_rounded, AppConfig.myCoursesUrl),
      _AppTab('Free Forex Course', Icons.play_circle_rounded, AppConfig.freeCourseUrl),
      _AppTab('Basic Premium', Icons.workspace_premium_rounded, AppConfig.basicCourseUrl),
      _AppTab('Advance Premium', Icons.military_tech_rounded, AppConfig.advanceCourseUrl),
    ]),
    _MenuGroup('STUDENT SERVICES', [
      _AppTab('Memberships', Icons.card_membership_rounded, AppConfig.membershipsUrl),
      _AppTab('Payment History', Icons.receipt_long_rounded, AppConfig.paymentHistoryUrl),
      _AppTab('Certificates', Icons.verified_rounded, AppConfig.certificatesUrl),
      _AppTab('Affiliate Program', Icons.hub_rounded, AppConfig.affiliateUrl),
      _AppTab('Notifications', Icons.notifications_rounded, AppConfig.notificationsUrl),
      _AppTab('Support Center', Icons.support_agent_rounded, AppConfig.supportUrl),
      _AppTab('Profile & Settings', Icons.manage_accounts_rounded, AppConfig.profileUrl),
    ]),
    _MenuGroup('MARKET TOOLS', [
      _AppTab('Trading Chart', Icons.show_chart_rounded, AppConfig.tradingChartUrl),
      _AppTab('Technical Analysis', Icons.analytics_rounded, AppConfig.technicalAnalysisUrl),
      _AppTab('Fundamental Analysis', Icons.account_balance_rounded, AppConfig.fundamentalAnalysisUrl),
      _AppTab('Forex News', Icons.newspaper_rounded, AppConfig.forexNewsUrl),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F7FA))
      ..setUserAgent('ForexlancerMobile/1.0 Android-iOS')
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (value) => mounted ? setState(() => _progress = value) : null,
        onPageStarted: (_) {
          if (mounted) setState(() => _pageError = false);
        },
        onPageFinished: (_) => _injectMobilePolish(),
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() => _pageError = true);
          }
        },
        onNavigationRequest: _handleNavigation,
      ))
      ..loadRequest(Uri.parse(AppConfig.homeUrl));

    _networkSubscription = Connectivity().onConnectivityChanged.listen((result) {
      final offline = result.every((item) => item == ConnectivityResult.none);
      if (mounted) setState(() => _offline = offline);
    });
  }

  Future<NavigationDecision> _handleNavigation(NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (AppConfig.allowedHosts.contains(uri.host.toLowerCase())) {
        return NavigationDecision.navigate;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    if (<String>{'mailto', 'tel', 'sms', 'whatsapp'}.contains(uri.scheme)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return NavigationDecision.prevent;
  }

  Future<void> _injectMobilePolish() async {
    await _web.runJavaScript('''
      (function () {
        var id = 'forexlancer-native-app-css';
        if (document.getElementById(id)) return;
        var style = document.createElement('style');
        style.id = id;
        style.textContent = `
          html, body { max-width: 100%; overflow-x: hidden; }
          img, video, iframe, table { max-width: 100% !important; }
          input, select, textarea, button { font-size: 16px !important; }
          .forexlancer-app-hide, .mobile-app-hide { display:none !important; }
        `;
        document.head.appendChild(style);
      })();
    ''');
  }

  Future<void> _openTab(int index) async {
    setState(() => _selectedIndex = index);
    await _web.loadRequest(Uri.parse(_tabs[index].url));
  }

  Future<void> _openUrl(String url, {bool closeDrawer = false}) async {
    if (closeDrawer) Navigator.of(context).pop();
    final tabIndex = _tabs.indexWhere((tab) => tab.url == url);
    if (tabIndex >= 0) setState(() => _selectedIndex = tabIndex);
    await _web.loadRequest(Uri.parse(url));
  }

  Future<bool> _handleBack() async {
    if (await _web.canGoBack()) {
      await _web.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _handleBack() && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        drawer: Drawer(
          backgroundColor: const Color(0xFFF8FAFC),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF07172E), Color(0xFF123A67)]),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: Color(0xFFD4AF37),
                        child: Text('FL', style: TextStyle(color: Color(0xFF07172E), fontWeight: FontWeight.w900, fontSize: 19)),
                      ),
                      SizedBox(height: 13),
                      Text('FOREXLANCER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.3)),
                      SizedBox(height: 3),
                      Text('Complete Student Ecosystem', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      _DrawerItem(tab: const _AppTab('Student Dashboard', Icons.dashboard_rounded, AppConfig.dashboardUrl), onTap: (url) => _openUrl(url, closeDrawer: true)),
                      for (final group in _menuGroups) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 17, 20, 5),
                          child: Text(group.label, style: const TextStyle(color: Color(0xFF8A6B12), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.1)),
                        ),
                        for (final tab in group.tabs) _DrawerItem(tab: tab, onTap: (url) => _openUrl(url, closeDrawer: true)),
                      ],
                      const Divider(height: 24),
                      _DrawerItem(tab: const _AppTab('Create Account', Icons.person_add_alt_1_rounded, AppConfig.signUpUrl), onTap: (url) => _openUrl(url, closeDrawer: true)),
                      _DrawerItem(tab: const _AppTab('Login', Icons.login_rounded, AppConfig.loginUrl), onTap: (url) => _openUrl(url, closeDrawer: true)),
                      _DrawerItem(tab: const _AppTab('Privacy Policy', Icons.privacy_tip_rounded, AppConfig.privacyUrl), onTap: (url) => _openUrl(url, closeDrawer: true)),
                      _DrawerItem(tab: const _AppTab('Risk Warning', Icons.warning_amber_rounded, AppConfig.riskWarningUrl), onTap: (url) => _openUrl(url, closeDrawer: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF07172E),
          foregroundColor: Colors.white,
          titleSpacing: 16,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FOREXLANCER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              Text('Learn Forex Trading', style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
            ],
          ),
          actions: [
            IconButton(tooltip: 'Refresh', onPressed: _web.reload, icon: const Icon(Icons.refresh_rounded)),
          ],
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    color: const Color(0xFFD4AF37),
                    backgroundColor: Colors.white12,
                  ),
                )
              : null,
        ),
        body: _offline || _pageError
            ? _ErrorView(offline: _offline, onRetry: _web.reload)
            : SafeArea(child: WebViewWidget(controller: _web)),
        bottomNavigationBar: NavigationBar(
          height: 68,
          selectedIndex: _selectedIndex,
          indicatorColor: const Color(0x33D4AF37),
          onDestinationSelected: _openTab,
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(icon: Icon(tab.icon), label: tab.label),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.offline, required this.onRetry});
  final bool offline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded, size: 64, color: const Color(0xFF07172E)),
            const SizedBox(height: 18),
            Text(offline ? 'Internet connection available nahi hai' : 'Page load nahi ho saka', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Connection check karke dobara koshish karein.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class _AppTab {
  const _AppTab(this.label, this.icon, this.url);
  final String label;
  final IconData icon;
  final String url;
}

class _MenuGroup {
  const _MenuGroup(this.label, this.tabs);
  final String label;
  final List<_AppTab> tabs;
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.tab, required this.onTap});
  final _AppTab tab;
  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(tab.icon, color: const Color(0xFF123A67), size: 21),
      title: Text(tab.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () => onTap(tab.url),
    );
  }
}
