import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_config.dart';

const _navy = Color(0xFF07172E);
const _gold = Color(0xFFD4AF37);

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override String toString() => message;
}

class NativeApi {
  NativeApi(this.token);
  String? token;

  Map<String, String> get headers => {
    'Accept': 'application/json', 'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> request(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConfig.apiUrl}$path');
    final response = method == 'POST'
        ? await http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 25))
        : await http.get(uri, headers: headers).timeout(const Duration(seconds: 25));
    dynamic data;
    try { data = jsonDecode(response.body); } catch (_) { throw ApiException('Server response samajh nahi aa saka.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data is Map ? (data['message']?.toString() ?? 'Request failed') : 'Request failed');
    }
    return data;
  }
}

class NativeGate extends StatefulWidget {
  const NativeGate({super.key});
  @override State<NativeGate> createState() => _NativeGateState();
}

class _NativeGateState extends State<NativeGate> {
  bool loading = true;
  String? token;
  @override void initState() { super.initState(); _restore(); }
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('flx_native_token');
    if (saved != null) {
      try { await NativeApi(saved).request('/me'); token = saved; } catch (_) { await prefs.remove('flx_native_token'); }
    }
    if (mounted) setState(() => loading = false);
  }
  Future<void> _signedIn(String value) async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('flx_native_token', value);
    setState(() => token = value);
  }
  Future<void> _logout() async {
    try { await NativeApi(token).request('/logout', method: 'POST'); } catch (_) {}
    final prefs = await SharedPreferences.getInstance(); await prefs.remove('flx_native_token');
    if (mounted) setState(() => token = null);
  }
  @override Widget build(BuildContext context) {
    if (loading) return const _Splash();
    return token == null ? LoginScreen(onSignedIn: _signedIn) : NativeShell(api: NativeApi(token), onLogout: _logout);
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override Widget build(BuildContext context) => const Scaffold(backgroundColor: _navy, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 38, backgroundColor: _gold, child: Text('FL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _navy))), SizedBox(height: 18), Text('FOREXLANCER', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 1.5)), SizedBox(height: 18), CircularProgressIndicator(color: _gold)])));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignedIn}); final ValueChanged<String> onSignedIn;
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final user = TextEditingController(), pass = TextEditingController(); bool busy = false, hide = true; String? error;
  Future<void> submit() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) { setState(() => error = 'Email/username aur password enter karein.'); return; }
    setState(() { busy = true; error = null; });
    try {
      final data = await NativeApi(null).request('/login', method: 'POST', body: {'username': user.text.trim(), 'password': pass.text});
      widget.onSignedIn(data['token'].toString());
    } catch (e) { if (mounted) setState(() => error = e is ApiException ? e.message : 'Connection error. Dobara koshish karein.'); }
    if (mounted) setState(() => busy = false);
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const CircleAvatar(radius: 34, backgroundColor: _gold, child: Text('FL', style: TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 23))), const SizedBox(height: 18),
    const Text('Welcome to Forexlancer', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: _navy)), const SizedBox(height: 7),
    const Text('Apne existing student account se login karein.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)), const SizedBox(height: 28),
    TextField(controller: user, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email or Username', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())), const SizedBox(height: 14),
    TextField(controller: pass, obscureText: hide, onSubmitted: (_) => submit(), decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility : Icons.visibility_off)))),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))), const SizedBox(height: 18),
    FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(backgroundColor: _navy, padding: const EdgeInsets.all(16)), child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w800))),
    TextButton(onPressed: () => launchUrl(Uri.parse(AppConfig.signUpUrl), mode: LaunchMode.externalApplication), child: const Text('New student? Create Account')),
  ]))))));
}

class NativeShell extends StatefulWidget {
  const NativeShell({super.key, required this.api, required this.onLogout}); final NativeApi api; final VoidCallback onLogout;
  @override State<NativeShell> createState() => _NativeShellState();
}
class _NativeShellState extends State<NativeShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    final pages = [DashboardScreen(api: widget.api, openCourses: () => setState(() => index = 1)), CoursesScreen(api: widget.api), SignalsScreen(api: widget.api), NotificationsScreen(api: widget.api), MoreScreen(api: widget.api, onLogout: widget.onLogout)];
    return Scaffold(appBar: AppBar(backgroundColor: _navy, foregroundColor: Colors.white, title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FOREXLANCER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)), Text('Learn • Trade • Grow', style: TextStyle(fontSize: 11, color: _gold))])), body: IndexedStack(index: index, children: pages), bottomNavigationBar: NavigationBar(selectedIndex: index, indicatorColor: const Color(0x33D4AF37), onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'), NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Courses'), NavigationDestination(icon: Icon(Icons.candlestick_chart_rounded), label: 'Signals'), NavigationDestination(icon: Icon(Icons.notifications_rounded), label: 'Alerts'), NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'More')]));
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.api, required this.openCourses}); final NativeApi api; final VoidCallback openCourses;
  @override Widget build(BuildContext context) => FutureBuilder(future: Future.wait([api.request('/dashboard'), api.request('/courses')]), builder: (context, snap) {
    if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snap.hasError) return _Retry(message: snap.error.toString());
    final dash = snap.data![0] as Map<String, dynamic>, me = dash['user'] as Map<String, dynamic>, courses = (snap.data![1]['courses'] as List);
    final active = (me['memberships'] as List? ?? []).where((m) => m['status'] == 'active').length;
    final progress = (dash['learning']?['percent'] as num?)?.toInt() ?? 0;
    return RefreshIndicator(onRefresh: () async {}, child: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, Color(0xFF123A67)]), borderRadius: BorderRadius.circular(20)), child: Row(children: [CircleAvatar(radius: 31, backgroundImage: NetworkImage(me['avatar'] ?? '')), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('WELCOME BACK', style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w800)), Text(me['name'] ?? 'Student', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), Text(me['email'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12))]))])),
      const SizedBox(height: 16), Row(children: [Expanded(child: _Stat(label: 'Overall Progress', value: '$progress%', icon: Icons.speed_rounded)), const SizedBox(width: 12), Expanded(child: _Stat(label: 'Active Access', value: '$active', icon: Icons.workspace_premium_rounded))]),
      const SizedBox(height: 12), Row(children: [Expanded(child: _Stat(label: 'Unread Alerts', value: '${dash['unread_notifications'] ?? 0}', icon: Icons.notifications_active_rounded)), const SizedBox(width: 12), Expanded(child: _Stat(label: 'Affiliate Rank', value: '${dash['affiliate']?['rank'] ?? 'Basic'}'.toUpperCase(), icon: Icons.hub_rounded))]),
      const SizedBox(height: 22), const Text('Continue Learning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _navy)), const SizedBox(height: 10),
      ...courses.take(3).map((c) => Card(child: ListTile(onTap: c['locked'] == true ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(api: api, courseId: c['id']))), leading: const CircleAvatar(backgroundColor: Color(0x22D4AF37), child: Icon(Icons.play_lesson_rounded, color: _navy)), title: Text(c['title'], style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: LinearProgressIndicator(value: ((c['progress']['percent'] as num).toDouble()) / 100, color: _gold), trailing: Icon(c['locked'] == true ? Icons.lock : Icons.chevron_right)))),
      const SizedBox(height: 8), OutlinedButton.icon(onPressed: openCourses, icon: const Icon(Icons.school), label: const Text('View All Courses')),
    ]));
  });
}

class _Stat extends StatelessWidget { const _Stat({required this.label, required this.value, required this.icon}); final String label,value; final IconData icon; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _gold), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _navy)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))])); }

class CoursesScreen extends StatefulWidget { const CoursesScreen({super.key, required this.api}); final NativeApi api; @override State<CoursesScreen> createState()=>_CoursesScreenState(); }
class _CoursesScreenState extends State<CoursesScreen> {
  late Future<dynamic> future;
  @override void initState() { super.initState(); future = widget.api.request('/courses'); }
  void reload() => setState(() => future = widget.api.request('/courses'));
  @override Widget build(BuildContext context) => FutureBuilder(
    future: future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return _Retry(message: snap.error.toString(), onRetry: reload);
      final courses = snap.data['courses'] as List;
      return RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('My Courses', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _navy)),
          const Text('Apni access aur learning progress yahan manage karein.'),
          const SizedBox(height: 14),
          ...courses.map((c) => Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: c['locked'] == true ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(api: widget.api, courseId: c['id']))),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(c['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Icon(c['locked'] == true ? Icons.lock_rounded : Icons.play_circle_fill_rounded, color: c['locked'] == true ? Colors.grey : _gold)]),
                const SizedBox(height: 8),
                Text(c['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: ((c['progress']['percent'] as num).toDouble()) / 100, color: _gold),
                const SizedBox(height: 5),
                Text(c['locked'] == true ? 'Membership required' : '${c['progress']['completed']} of ${c['progress']['total']} completed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ])),
            ),
          )),
        ]),
      );
    },
  );
}

class CourseDetailScreen extends StatefulWidget { const CourseDetailScreen({super.key,required this.api,required this.courseId});final NativeApi api;final int courseId;@override State<CourseDetailScreen> createState()=>_CourseDetailScreenState(); }
class _CourseDetailScreenState extends State<CourseDetailScreen>{late Future<dynamic> future;@override void initState(){super.initState();future=widget.api.request('/courses/${widget.courseId}');}void reload()=>setState(()=>future=widget.api.request('/courses/${widget.courseId}'));@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Course Lessons')),body:FutureBuilder(future:future,builder:(context,snap){if(snap.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(snap.hasError)return _Retry(message:snap.error.toString(),onRetry:reload);final c=snap.data as Map<String,dynamic>,lessons=c['lessons'] as List;return ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:_navy,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('FOREXLANCER LEARNING',style:TextStyle(color:_gold,fontSize:11,fontWeight:FontWeight.w800)),Text(c['title'],style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),const SizedBox(height:10),LinearProgressIndicator(value:((c['progress']['percent'] as num).toDouble())/100,color:_gold),const SizedBox(height:5),Text('${c['progress']['percent']}% completed',style:const TextStyle(color:Colors.white70))])),const SizedBox(height:14),...lessons.map((l)=>Card(child:ListTile(onTap:l['unlocked']==true?()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(api:widget.api,courseTitle:c['title'],lesson:Map<String,dynamic>.from(l)))).then((_){reload();}):null,leading:CircleAvatar(backgroundColor:l['completed']==true?Colors.green:_navy,child:Icon(l['completed']==true?Icons.check:Icons.play_arrow,color:Colors.white)),title:Text('Lecture #${l['number']}: ${l['title']}',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(l['unlocked']==true?(l['completed']==true?'Completed':'Ready to watch'):'Locked'),trailing:Icon(l['unlocked']==true?Icons.chevron_right:Icons.lock))))]);}));}

class LessonScreen extends StatefulWidget {const LessonScreen({super.key,required this.api,required this.courseTitle,required this.lesson});final NativeApi api;final String courseTitle;final Map<String,dynamic> lesson;@override State<LessonScreen> createState()=>_LessonScreenState();}
class _LessonScreenState extends State<LessonScreen>{late Map<String,dynamic> lesson;WebViewController? web;bool busy=false;String playerUrl='';@override void initState(){super.initState();lesson=Map.of(widget.lesson);final id=lesson['video_id']?.toString()??'';final raw=id.isNotEmpty?'https://www.youtube-nocookie.com/embed/$id?playsinline=1&rel=0':((lesson['player_url']?.toString().isNotEmpty??false)?lesson['player_url'].toString():lesson['video_url']?.toString()??'');playerUrl=_embed(raw);if(playerUrl.isNotEmpty)web=_player(playerUrl);}
WebViewController _player(String url)=>WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..setBackgroundColor(Colors.black)..setNavigationDelegate(NavigationDelegate(onNavigationRequest:(request){final host=Uri.tryParse(request.url)?.host.toLowerCase()??'';if(host.contains('youtube.com')||host.contains('youtube-nocookie.com')||host.contains('googlevideo.com')||request.url=='about:blank')return NavigationDecision.navigate;return NavigationDecision.prevent;}))..loadHtmlString(_playerHtml(url),baseUrl:'https://forexlancer.com');
String _playerHtml(String url)=>'''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"><style>html,body{margin:0;background:#000;height:100%;overflow:hidden}iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style></head><body><iframe src="$url" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen referrerpolicy="strict-origin-when-cross-origin"></iframe></body></html>''';
String _embed(String raw){final uri=Uri.tryParse(raw);if(uri==null)return'';String? id;if(uri.host.contains('youtu.be'))id=uri.pathSegments.isNotEmpty?uri.pathSegments.first:null;else if(uri.host.contains('youtube')){id=uri.queryParameters['v'];if(id==null&&uri.pathSegments.contains('embed')){final i=uri.pathSegments.indexOf('embed');if(i+1<uri.pathSegments.length)id=uri.pathSegments[i+1];}}if(id!=null)return'https://www.youtube-nocookie.com/embed/$id?playsinline=1&rel=0&modestbranding=1&origin=https%3A%2F%2Fforexlancer.com';return raw;}
Future<void>markComplete()async{setState(()=>busy=true);try{await widget.api.request('/lessons/${lesson['id']}/progress',method:'POST',body:{'percent':100,'seconds':lesson['video_seconds']??0,'completed':true});setState(()=>lesson['completed']=true);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}if(mounted)setState(()=>busy=false);}
Future<void>bookmark()async{try{final r=await widget.api.request('/lessons/${lesson['id']}/bookmark',method:'POST');setState(()=>lesson['bookmarked']=r['bookmarked']);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Lecture #${lesson['number']}'),actions:[if(playerUrl.isNotEmpty)IconButton(tooltip:'Full Screen',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_FullPlayer(url:playerUrl))),icon:const Icon(Icons.fullscreen_rounded))]),body:ListView(children:[Container(color:Colors.black,child:AspectRatio(aspectRatio:16/9,child:web==null?const Center(child:Text('Video is not configured',style:TextStyle(color:Colors.white))):WebViewWidget(controller:web!))),Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:const Color(0x1AD4AF37),borderRadius:BorderRadius.circular(30)),child:Text(widget.courseTitle,style:const TextStyle(color:_gold,fontWeight:FontWeight.w800))),const SizedBox(height:8),Text(lesson['title'],style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:_navy)),const SizedBox(height:10),Text(lesson['content']??''),const SizedBox(height:20),Row(children:[Expanded(child:OutlinedButton.icon(onPressed:bookmark,icon:Icon(lesson['bookmarked']==true?Icons.bookmark:Icons.bookmark_border),label:Text(lesson['bookmarked']==true?'Bookmarked':'Bookmark'))),const SizedBox(width:10),Expanded(child:FilledButton.icon(onPressed:busy||lesson['completed']==true?null:markComplete,icon:const Icon(Icons.check_circle),label:Text(lesson['completed']==true?'Completed':'Mark Complete')))]),const SizedBox(height:12),const Text('Protected educational content. Account sharing and unauthorized copying are prohibited.',style:TextStyle(fontSize:11,color:Colors.black54))]))]));}

class _FullPlayer extends StatefulWidget{const _FullPlayer({required this.url});final String url;@override State<_FullPlayer> createState()=>_FullPlayerState();}
class _FullPlayerState extends State<_FullPlayer>{late final WebViewController controller;@override void initState(){super.initState();SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]);controller=WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..setBackgroundColor(Colors.black)..loadHtmlString('''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body{margin:0;background:#000;height:100%;overflow:hidden}iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style></head><body><iframe src="${widget.url}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe></body></html>''',baseUrl:'https://forexlancer.com');}@override void dispose(){SystemChrome.setPreferredOrientations(DeviceOrientation.values);super.dispose();}@override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.black,body:SafeArea(child:Stack(children:[Positioned.fill(child:WebViewWidget(controller:controller)),Positioned(top:8,left:8,child:IconButton(style:IconButton.styleFrom(backgroundColor:Colors.black54),onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close,color:Colors.white)))])));}

class SignalsScreen extends StatefulWidget{const SignalsScreen({super.key,required this.api});final NativeApi api;@override State<SignalsScreen> createState()=>_SignalsScreenState();}
class _SignalsScreenState extends State<SignalsScreen>{late Future<dynamic> future;@override void initState(){super.initState();future=widget.api.request('/signals');}void reload()=>setState(()=>future=widget.api.request('/signals'));@override Widget build(BuildContext context)=>FutureBuilder(future:future,builder:(context,snap){if(snap.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(snap.hasError)return _Retry(message:snap.error.toString(),onRetry:reload);final data=snap.data,signals=data['signals'] as List;return RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[const Text('Trading Signals',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:_navy)),Text(data['premium_access']==true?'Premium signals access active':'Free daily signals'),const SizedBox(height:14),if(signals.isEmpty)const _Empty(message:'Abhi koi signal available nahi.'),...signals.map((s){final buy=s['direction'].toString().toLowerCase()=='buy';return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text((s['symbol']??'').toString().toUpperCase(),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900))),Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),decoration:BoxDecoration(color:buy?Colors.green:Colors.red,borderRadius:BorderRadius.circular(20)),child:Text((s['direction']??'').toString().toUpperCase(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)))]),const Divider(),Text('Entry: ${s['entry']}${(s['entry_to']??'').toString().isNotEmpty?' – ${s['entry_to']}':''}'),Text('Take Profit: ${s['take_profit']}'),Text('Stop Loss: ${s['stop_loss']}',style:const TextStyle(color:Colors.red,fontWeight:FontWeight.w700)),if((s['notes']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(s['notes']))])));})]));});}

class NotificationsScreen extends StatefulWidget { const NotificationsScreen({super.key, required this.api}); final NativeApi api; @override State<NotificationsScreen> createState()=>_NotificationsScreenState(); }
class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<dynamic> future; @override void initState(){super.initState(); reload();}
  void reload()=>setState(()=>future=widget.api.request('/notifications'));
  Future<void> markAll() async { await widget.api.request('/notifications/read',method:'POST'); reload(); }
  @override Widget build(BuildContext context)=>FutureBuilder(future:future,builder:(context,snap){
    if(snap.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(snap.hasError)return _Retry(message:snap.error.toString(),onRetry:reload);
    final data=snap.data as Map<String,dynamic>, items=data['notifications'] as List;
    return RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[const Expanded(child:Text('Notifications',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:_navy))),if((data['unread']??0)>0)TextButton(onPressed:markAll,child:const Text('Mark all read'))]),
      Text('${data['unread']??0} unread updates'),const SizedBox(height:12),if(items.isEmpty)const _Empty(message:'Abhi koi notification nahi.'),
      ...items.map((n)=>Card(color:n['status']=='unread'?const Color(0xFFFFF9E8):Colors.white,child:ListTile(leading:CircleAvatar(backgroundColor:_navy,child:Icon(_noticeIcon(n['category']?.toString()),color:_gold)),title:Text(n['title']??'',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${n['message']??''}\n${n['created_at']??''}'),isThreeLine:true)))
    ]));
  });
  IconData _noticeIcon(String? c)=>c=='payments'?Icons.payments_rounded:c=='courses'?Icons.school_rounded:c=='affiliate'?Icons.hub_rounded:c=='signals'?Icons.candlestick_chart_rounded:Icons.notifications_rounded;
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key,required this.api,required this.onLogout}); final NativeApi api; final VoidCallback onLogout;
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Student Center',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:_navy)),const SizedBox(height:12),
    _more(context,Icons.account_balance_wallet_rounded,'Payments','Payment history and status',PaymentsScreen(api:api)),
    _more(context,Icons.workspace_premium_rounded,'Certificates','Your completed-course certificates',CertificatesScreen(api:api)),
    _more(context,Icons.hub_rounded,'Affiliate Program','Rank, referrals and qualification',AffiliateScreen(api:api)),
    _more(context,Icons.person_rounded,'Profile & Memberships','Account and active access',ProfileScreen(api:api,onLogout:onLogout)),
    Card(child:ListTile(onTap:()=>launchUrl(Uri.parse(AppConfig.supportUrl),mode:LaunchMode.externalApplication),leading:const Icon(Icons.support_agent_rounded,color:_gold),title:const Text('Support Center',style:TextStyle(fontWeight:FontWeight.w800)),trailing:const Icon(Icons.open_in_new))),
  ]);
  Widget _more(BuildContext c,IconData i,String t,String s,Widget page)=>Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page)),leading:Icon(i,color:_gold),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(s),trailing:const Icon(Icons.chevron_right)));
}

class PaymentsScreen extends StatelessWidget { const PaymentsScreen({super.key,required this.api});final NativeApi api;@override Widget build(BuildContext c)=>_DataPage(title:'Payment History',future:api.request('/payments'),keyName:'payments',builder:(p)=>ListTile(leading:const Icon(Icons.receipt_long_rounded,color:_gold),title:Text('${p['currency']} ${p['amount']}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${p['method']} • ${p['created_at']}'),trailing:_Status(value:p['status']?.toString()??'')));}
class CertificatesScreen extends StatelessWidget { const CertificatesScreen({super.key,required this.api});final NativeApi api;@override Widget build(BuildContext c)=>_DataPage(title:'My Certificates',future:api.request('/certificates'),keyName:'certificates',builder:(x)=>ListTile(onTap:()=>launchUrl(Uri.parse(x['url'].toString()),mode:LaunchMode.externalApplication),leading:const Icon(Icons.verified_rounded,color:_gold),title:Text(x['course']??'',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${x['code']}\nIssued: ${x['issued_at']}'),isThreeLine:true,trailing:const Icon(Icons.open_in_new)));}
class AffiliateScreen extends StatelessWidget { const AffiliateScreen({super.key,required this.api});final NativeApi api;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Affiliate Program')),body:FutureBuilder(future:api.request('/affiliate'),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return _Retry(message:s.error.toString());final a=s.data as Map<String,dynamic>;return ListView(padding:const EdgeInsets.all(18),children:[Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_navy,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('CURRENT STATUS',style:TextStyle(color:_gold,fontWeight:FontWeight.w800)),Text('${a['rank']}'.toUpperCase(),style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w900)),Text('${a['qualified_direct']} of ${a['next_target']} qualified direct premium referrals',style:const TextStyle(color:Colors.white70)),const SizedBox(height:10),LinearProgressIndicator(value:((a['progress_percent'] as num).toDouble())/100,color:_gold)])),const SizedBox(height:14),Card(child:ListTile(title:const Text('Referral Link',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:SelectableText(a['referral_url']??''),trailing:IconButton(icon:const Icon(Icons.share),onPressed:()=>launchUrl(Uri.parse(a['referral_url'].toString()))))),Card(child:ListTile(leading:const Icon(Icons.people,color:_gold),title:const Text('Direct Referrals'),trailing:Text('${a['direct_referrals']}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)))),OutlinedButton(onPressed:()=>launchUrl(Uri.parse(AppConfig.affiliateUrl),mode:LaunchMode.externalApplication),child:const Text('Open Full Affiliate Center'))]);}));}
class _DataPage extends StatelessWidget {const _DataPage({required this.title,required this.future,required this.keyName,required this.builder});final String title,keyName;final Future<dynamic> future;final Widget Function(dynamic) builder;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(title)),body:FutureBuilder(future:future,builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return _Retry(message:s.error.toString());final list=(s.data[keyName] as List);return list.isEmpty?const _Empty(message:'Abhi koi record available nahi.'):ListView(padding:const EdgeInsets.all(16),children:list.map((x)=>Card(child:builder(x))).toList());}));}
class _Status extends StatelessWidget {const _Status({required this.value});final String value;@override Widget build(BuildContext c){final ok=value=='approved'||value=='active'||value=='paid';return Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),decoration:BoxDecoration(color:ok?Colors.green:Colors.orange,borderRadius:BorderRadius.circular(20)),child:Text(value.toUpperCase(),style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w800)));}}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.api, required this.onLogout});
  final NativeApi api;
  final VoidCallback onLogout;
  @override Widget build(BuildContext context) => FutureBuilder(
    future: api.request('/me'),
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return _Retry(message: snap.error.toString());
      final me = snap.data as Map<String, dynamic>;
      final memberships = me['memberships'] as List? ?? [];
      return ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: CircleAvatar(radius: 48, backgroundImage: NetworkImage(me['avatar'] ?? ''))),
        const SizedBox(height: 12),
        Text(me['name'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: _navy)),
        Text(me['email'] ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ...memberships.map((m) => Card(child: ListTile(
          leading: const Icon(Icons.workspace_premium, color: _gold),
          title: Text(m['plan'].toString().replaceAll('-', ' '), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${m['status']}${m['expires_at'] != null ? ' • ${m['expires_at']}' : ''}'),
        ))),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(AppConfig.profileUrl), mode: LaunchMode.externalApplication), icon: const Icon(Icons.settings), label: const Text('Account Settings')),
        FilledButton.icon(onPressed: onLogout, style: FilledButton.styleFrom(backgroundColor: Colors.red), icon: const Icon(Icons.logout), label: const Text('Logout')),
        const SizedBox(height: 20),
        const Text('Forex trading involves substantial risk. Forexlancer provides educational material and does not guarantee profits.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
      ]);
    },
  );
}

class _Retry extends StatelessWidget{const _Retry({required this.message,this.onRetry});final String message;final VoidCallback? onRetry;@override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off,size:55,color:_navy),const SizedBox(height:12),Text(message,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton(onPressed:onRetry??(){},child:const Text('Try Again'))])));}
class _Empty extends StatelessWidget{const _Empty({required this.message});final String message;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(30),child:Column(children:[const Icon(Icons.inbox_outlined,size:50,color:Colors.grey),Text(message)]));}
