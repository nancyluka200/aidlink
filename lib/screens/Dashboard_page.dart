import 'dart:async';
import 'package:aidlinkapp/dialogs/sign_out_dialog.dart';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/screens/memo_page.dart';
import 'package:aidlinkapp/screens/saved_programs_page.dart';
import 'package:aidlinkapp/screens/complete_profile_page.dart';
import 'package:aidlinkapp/screens/program_results_page.dart';
import 'package:aidlinkapp/screens/settings_page.dart';
import 'package:aidlinkapp/services/matching_engine.dart';
import 'package:aidlinkapp/utilities/base_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

const _kBlue     = Color(0xff1A56C4);
const _kBlueDark = Color(0xff0A3080);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _verificationTimer;
  Timer? _wakeRestartTimer;
  final auth = Get.find<AuthController>();

  final FlutterTts _tts          = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening     = false;
  bool _isWakeListening = false;
  bool _speechAvail     = false;
  bool _voiceVisible    = false;
  bool _wakeTriggered   = false; // guard: prevents double-trigger
  String _spokenText        = '';
  String _assistantResponse = '';

  static const List<String> _wakeWords = [
    'aid', 'aidlink', 'hey aid', 'hey aidlink',
  ];

  @override
  void initState() {
    super.initState();
    _startVerificationPolling();
    _initVoice();
  }

  Future<void> _initVoice() async {
    _speechAvail = await _speech.initialize(
      onError: (e) => debugPrint('STT error: $e'),
      onStatus: (s) => debugPrint('STT status: $s'),
    );
    debugPrint('Speech available: $_speechAvail');
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    if (_speechAvail) {
      await Future.delayed(const Duration(milliseconds: 800));
      _startWakeWordListening();
    }
  }

  // ── Wake-word listener ────────────────────────────────────────────────────
  Future<void> _startWakeWordListening() async {
    if (!_speechAvail || !mounted) return;
    if (_isListening || _wakeTriggered) return;
    // Hard guard — stop any existing session before starting
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) return;
    setState(() => _isWakeListening = true);

    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.toLowerCase().trim();
        debugPrint('Wake heard: $words');

        // ── KEY FIX: trigger on partial result, not finalResult ───────────
        // On Flutter Web, finalResult may never fire for short words.
        // We trigger as soon as we see the wake word in any result.
        if (!_wakeTriggered &&
            _wakeWords.any((w) => words.contains(w))) {
          _wakeTriggered = true;
          _speech.stop();
          setState(() => _isWakeListening = false);
          _activateFromWakeWord();
        }
      },
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 6),
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<void> _activateFromWakeWord() async {
    if (!mounted) return;
    setState(() {
      _voiceVisible = true;
      _isListening  = false;
      _spokenText   = '';
    });
    await _readDashboard();
    await Future.delayed(const Duration(milliseconds: 600));
    _wakeTriggered = false; // reset guard before command listen
    await _startListening();
  }

  // ── Restart wake listener safely ──────────────────────────────────────────
  void _scheduleWakeRestart() {
    _wakeRestartTimer?.cancel();
    _wakeRestartTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_isListening && !_wakeTriggered) {
        _wakeTriggered = false;
        _startWakeWordListening();
      }
    });
  }

  void _startVerificationPolling() {
    if (auth.emailVerified.value) return;
    _verificationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (auth.emailVerified.value) { _verificationTimer?.cancel(); return; }
      await auth.checkProfileStatus();
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _wakeRestartTimer?.cancel();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    setState(() => _assistantResponse = text);
    await _tts.stop();
    await _tts.speak(text);
    await Future.delayed(
        Duration(milliseconds: (text.length * 55).clamp(800, 8000)));
  }

  // ── Command listen ────────────────────────────────────────────────────────
  Future<void> _startListening() async {
    if (!_speechAvail) {
      await _speak('Microphone is not available.');
      return;
    }
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 400));
    }
    setState(() { _isListening = true; _spokenText = ''; });

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: false,
      partialResults: true,
      onSoundLevelChange: (level) => debugPrint('Sound level: $level'),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _spokenText = result.recognizedWords);
    // On Flutter Web, use finalResult OR a long pause (isFinal on web)
    if (result.finalResult || result.recognizedWords.isNotEmpty && !_speech.isListening) {
      if (result.finalResult) {
        setState(() => _isListening = false);
        _handleCommand(_spokenText.toLowerCase().trim());
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_spokenText.isNotEmpty) {
      _handleCommand(_spokenText.toLowerCase().trim());
    } else {
      _scheduleWakeRestart();
    }
  }

  // ── Command handler ───────────────────────────────────────────────────────
  Future<void> _handleCommand(String command) async {
    if (command.isEmpty) {
      await _speak('I did not catch that. Say Help to hear available commands.');
      _scheduleWakeRestart();
      return;
    }
    debugPrint('Command: $command');

    final matchOutput = MatchingEngine.match(auth);
    final matches     = [matchOutput.topMatch, ...matchOutput.suggestions];
    final strong      = matches.where((m) => m.fullyEligible).toList();

    bool has(List<String> words) => words.any((w) => command.contains(w));

    if (has(['dashboard', 'summary', 'overview', 'everything', 'tell me',
             'what\'s going on', "what's going on", 'update me', 'read',
             'what do i have', 'start'])) {
      await _readDashboard();

    } else if (has(['program', 'programmes', 'match', 'matches', 'eligible',
                    'qualify', 'qualified', 'results', 'find', 'how many'])) {
      final top = matches.isNotEmpty ? matches.first : null;
      await _speak(
        'You have ${matches.length} matched programs. '
        '${strong.length} are strong matches. '
        '${top != null ? "Your top match is ${top.program.name} with ${top.matchScore} percent." : ""} '
        'Say open programs to view them.'
      );

    } else if (has(['open', 'go to', 'view', 'take me', 'show']) &&
               has(['program', 'match', 'result'])) {
      await _speak('Opening your matched programs.');
      Get.to(() => const ProgramResultsPage());

    } else if (has(['profile', 'my details', 'my info', 'about me',
                    'who am i', 'my name'])) {
      await _speak(
        'Your name is ${auth.fullName}. '
        'Email: ${auth.signedEmail.value}. '
        'Location: ${auth.location.value}. '
        'Monthly income: ${auth.income.value} Kenyan shillings.'
      );

    } else if (has(['edit', 'update', 'change']) && has(['profile', 'details'])) {
      await _speak('Opening the profile editor.');
      Get.to(() => const CompleteProfilePage());

    } else if (has(['saved', 'application', 'applied', 'bookmarked'])) {
      await _speak('Opening your saved programs.');
      Get.to(() => const SavedProgramsPage());

    } else if (has(['setting', 'settings', 'preference', 'theme'])) {
      await _speak('Opening settings.');
      Get.to(() => const SettingsPage());

    } else if (has(['sign out', 'log out', 'logout', 'signout', 'exit', 'bye'])) {
      await _speak('Showing sign out confirmation.');
      showDialog(context: Get.context!, builder: (_) => const SignOutDialog());

    } else if (has(['card', 'ncpwd', 'pwd', 'verification', 'verified',
                    'disability card', 'my card', 'council', 'warning'])) {
      final status = auth.pwdCardVerificationStatus.value;
      final msg = status == 'verified'
          ? 'Your NCPWD card has been verified. You have full access.'
          : status == 'pending'
              ? 'Your NCPWD card is pending review.'
              : status == 'rejected'
                  ? 'Your NCPWD card was rejected. Please re-upload in Update Profile.'
                  : 'No NCPWD card submitted yet. Complete your profile to upload one.';
      await _speak(msg);

    } else if (has(['location', 'where', 'county', 'region', 'area'])) {
      await _speak('You are registered in ${auth.location.value}.');

    } else if (has(['income', 'salary', 'money', 'earn', 'pay', 'wage'])) {
      await _speak('Your monthly income is ${auth.income.value} Kenyan shillings.');

    } else if (has(['email', 'mail', 'verify'])) {
      final verified = auth.emailVerified.value;
      await _speak(
        'Your email is ${auth.signedEmail.value}. '
        '${verified ? "It is verified." : "Not yet verified. Please check your inbox."}'
      );

    } else if (has(['top', 'best', 'highest', 'number one', 'first'])) {
      if (matches.isNotEmpty) {
        final top = matches.first;
        await _speak(
          'Your top match is ${top.program.name} '
          'with ${top.matchScore} percent. '
          '${top.fullyEligible ? "You are fully eligible." : "You partially meet the requirements."}'
        );
      } else {
        await _speak('No matched programs yet. Complete your profile first.');
      }

    } else if (has(['hello', 'hi', 'hey', 'good morning', 'good afternoon',
                    'good evening'])) {
      await _speak(
        'Hello ${auth.fullName.split(" ").first}! '
        'Say Help to hear what I can do.'
      );

    } else if (has(['help', 'what can you do', 'commands', 'guide', 'options'])) {
      await _speak(
        'Say: Summary for your dashboard. '
        'My programs for match count. '
        'Open programs to go to results. '
        'My card status for NCPWD status. '
        'My profile for your details. '
        'Top match for your best program. '
        'Settings, Saved programs, or Sign out to navigate. '
        'Say Aid anytime to wake me.'
      );

    } else {
      await _speak(
        'I heard: $command. '
        'Say Help to hear available commands.'
      );
    }

    _scheduleWakeRestart();
  }

  Future<void> _readDashboard() async {
    final matchOutput = MatchingEngine.match(auth);
    final matches     = [matchOutput.topMatch, ...matchOutput.suggestions];
    final strong      = matches.where((m) => m.fullyEligible).toList();
    final name        = auth.fullName.split(' ').first;

    final pwdMsg = auth.isPwdCardRejected
        ? 'Warning: your NCPWD card has been rejected. Please update it. '
        : auth.isPwdCardPending ? 'Your NCPWD card is pending verification. ' : '';
    final emailMsg =
        !auth.emailVerified.value ? 'Your email is not yet verified. ' : '';

    final summary =
        'Hello $name. Welcome to your AidLink dashboard. '
        '$pwdMsg$emailMsg'
        'You have ${matches.length} matched programs. '
        '${strong.length} are strong matches. '
        '${matches.isNotEmpty ? "Your top match is ${matches.first.program.name} with ${matches.first.matchScore} percent." : ""} '
        'Say a command or tap the microphone.';

    setState(() { _voiceVisible = true; _assistantResponse = summary; });
    await _speak(summary);
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xff111827) : const Color(0xfff8f9fc);
    final cardColor = isDark ? const Color(0xff1f2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff111827);
    final subColor  = isDark ? const Color(0xffb0b8c8) : const Color(0xff374151);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Aid',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const Text('Link',
              style: TextStyle(color: Colors.white70,
                  fontWeight: FontWeight.w300, fontSize: 16)),
        ]),
        backgroundColor: _kBlueDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isWakeListening && !_voiceVisible)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Say "Aid" to activate',
                child: Icon(Icons.mic_none,
                    color: Colors.white.withValues(alpha: 0.5), size: 16),
              ),
            ),
          Semantics(
            label: 'Open voice assistant', button: true,
            child: SizedBox(width: 44, height: 44,
              child: IconButton(
                icon: const Icon(Icons.mic_outlined),
                tooltip: 'Voice assistant',
                onPressed: () {
                  setState(() => _voiceVisible = !_voiceVisible);
                  if (_voiceVisible) _readDashboard();
                },
              ),
            ),
          ),
          Semantics(
            label: 'My Profile', button: true,
            child: SizedBox(width: 44, height: 44,
              child: IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => Get.to(() => const MemoPage()),
                tooltip: 'My Profile',
              ),
            ),
          ),
          Semantics(
            label: 'Sign Out', button: true,
            child: SizedBox(width: 44, height: 44,
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const SignOutDialog(),
                ),
                tooltip: 'Sign Out',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_voiceVisible) _VoicePanel(
            isListening: _isListening,
            isWakeListening: _isWakeListening,
            spokenText: _spokenText,
            response: _assistantResponse,
            onMicTap: _isListening ? _stopListening : _startListening,
            onClose: () async {
              await _tts.stop();
              await _speech.stop();
              setState(() {
                _voiceVisible      = false;
                _isListening       = false;
                _wakeTriggered     = false;
                _spokenText        = '';
                _assistantResponse = '';
              });
              _scheduleWakeRestart();
            },
          ),
          Expanded(
            child: Obx(() => auth.profileCompleted.value
                ? _DashboardBody(auth: auth, cardColor: cardColor,
                    textColor: textColor, subColor: subColor)
                : _IncompleteProfileView(auth: auth, cardColor: cardColor,
                    textColor: textColor, subColor: subColor)),
          ),
        ],
      ),
    );
  }
}

// ── Voice Panel ───────────────────────────────────────────────────────────────
class _VoicePanel extends StatelessWidget {
  final bool isListening;
  final bool isWakeListening;
  final String spokenText;
  final String response;
  final VoidCallback onMicTap;
  final VoidCallback onClose;

  const _VoicePanel({
    required this.isListening,
    required this.isWakeListening,
    required this.spokenText,
    required this.response,
    required this.onMicTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: response.isNotEmpty ? response : 'Voice assistant ready',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: _kBlueDark,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Icon(Icons.assistant_outlined, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              const Text('AidLink Voice Assistant',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isListening ? '🔴 Listening...'
                      : isWakeListening ? '👂 Say "Aid" anytime'
                      : '🎤 Tap mic to speak',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
              const Spacer(),
              Semantics(
                button: true, label: 'Close voice assistant',
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            if (response.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(response,
                    style: const TextStyle(
                        color: Color(0xffCBD5E1), fontSize: 12, height: 1.5)),
              ),
            const SizedBox(height: 10),
            if (spokenText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.person_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('You: $spokenText',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ]),
              ),
            Row(children: [
              Expanded(
                child: Text(
                  isListening ? 'Listening... speak now'
                      : 'Say "Aid" to activate, or tap the mic',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: isListening ? 'Stop listening' : 'Tap to speak',
                child: GestureDetector(
                  onTap: onMicTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: isListening ? Colors.red.shade500 : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isListening
                          ? [BoxShadow(color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 16, spreadRadius: 4)]
                          : [],
                    ),
                    child: Icon(isListening ? Icons.stop : Icons.mic,
                        color: isListening ? Colors.white : _kBlueDark, size: 26),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Resend verification ───────────────────────────────────────────────────────
Future<void> _resendVerification(AuthController auth) async {
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/api/users/resend-verification'),
      headers: {'x-auth-token': auth.token.value},
    );
    if (res.statusCode == 200) {
      Get.snackbar('Email Sent', 'Verification email resent. Check your inbox.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Could not resend email. Try again later.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  } catch (_) {
    Get.snackbar('Error', 'Network error. Try again later.',
        backgroundColor: Colors.red, colorText: Colors.white);
  }
}

// ── Alert Banner ──────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final Color borderColor;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AlertBanner({
    required this.borderColor, required this.icon,
    required this.title, required this.message,
    this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true, label: '$title. $message',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: borderColor,
                  fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(
                  fontSize: 12, color: Color(0xff374151))),
            ],
          )),
          if (actionLabel != null && onAction != null)
            Semantics(button: true, label: actionLabel,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(actionLabel!, style: TextStyle(
                      color: borderColor, fontWeight: FontWeight.bold,
                      fontSize: 13)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Incomplete Profile View ───────────────────────────────────────────────────
class _IncompleteProfileView extends StatelessWidget {
  final AuthController auth;
  final Color cardColor, textColor, subColor;
  const _IncompleteProfileView({required this.auth, required this.cardColor,
      required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Obx(() {
        if (auth.emailVerified.value) return const SizedBox.shrink();
        return _AlertBanner(
          borderColor: const Color(0xffD97706),
          icon: Icons.mark_email_unread_outlined,
          title: 'Email not verified',
          message: 'Please verify your email address to unlock all features.',
          actionLabel: 'Resend',
          onAction: () => _resendVerification(auth),
        );
      }),
      const SizedBox(height: 24),
      Center(child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _kBlue.withValues(alpha: 0.12),
              blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: const Icon(Icons.person_add_outlined, size: 52, color: _kBlue),
      )),
      const SizedBox(height: 20),
      Text('Welcome to AidLink!', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
              color: textColor)),
      const SizedBox(height: 6),
      Text('Profile Incomplete', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: subColor)),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(children: [
          Text('Complete your profile so AidLink can match you to the right '
              'government disability programs in Kenya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: subColor, height: 1.5)),
          const SizedBox(height: 16),
          _stepHint(Icons.person_outline,      '1', 'Tell us who is applying',      textColor),
          _stepHint(Icons.accessible_outlined, '2', 'Your disability information',  textColor),
          _stepHint(Icons.location_on_outlined,'3', 'Personal & location details',  textColor),
          _stepHint(Icons.payments_outlined,   '4', 'Financial & employment info',  textColor),
        ]),
      ),
      const SizedBox(height: 24),
      Focus(child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
              boxShadow: focused ? [BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.9),
                  spreadRadius: 3, blurRadius: 0)] : []),
          child: Semantics(button: true, label: 'Complete My Profile',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Complete My Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => Get.to(() => const CompleteProfilePage()),
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        );
      })),
    ]);
  }

  Widget _stepHint(IconData icon, String step, String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Center(child: Text(step, style: const TextStyle(
              color: _kBlue, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 16, color: const Color(0xff6b7280)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: textColor)),
      ]),
    );
  }
}

// ── Full Dashboard Body ───────────────────────────────────────────────────────
class _DashboardBody extends StatelessWidget {
  final AuthController auth;
  final Color cardColor, textColor, subColor;
  const _DashboardBody({required this.auth, required this.cardColor,
      required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    final matchOutput   = MatchingEngine.match(auth);
    final matches       = [matchOutput.topMatch, ...matchOutput.suggestions];
    final strongMatches = matches.where((m) => m.fullyEligible).toList();
    final topScore      = matches.isNotEmpty ? matches.first.matchScore : 0;

    return ListView(padding: EdgeInsets.zero, children: [

      Obx(() {
        if (!auth.isPwdCardRejected) return const SizedBox.shrink();
        return _AlertBanner(
          borderColor: const Color(0xffdc2626),
          icon: Icons.credit_card_off_outlined,
          title: 'NCPWD Card Rejected',
          message: auth.pwdCardRejectionReason.value.isNotEmpty
              ? auth.pwdCardRejectionReason.value
              : 'Your NCPWD card could not be verified. Re-upload a valid one.',
          actionLabel: 'Fix Now',
          onAction: () => Get.to(() => const CompleteProfilePage()),
        );
      }),

      Obx(() {
        if (!auth.isPwdCardPending) return const SizedBox.shrink();
        return _AlertBanner(
          borderColor: const Color(0xffD97706),
          icon: Icons.pending_outlined,
          title: 'NCPWD Card Pending Review',
          message: 'Your NCPWD card is awaiting verification by the AidLink team.',
        );
      }),

      Obx(() {
        if (auth.emailVerified.value) return const SizedBox.shrink();
        if (auth.isPwdCardRejected || auth.isPwdCardPending) return const SizedBox.shrink();
        return _AlertBanner(
          borderColor: const Color(0xffD97706),
          icon: Icons.mark_email_unread_outlined,
          title: 'Email not verified',
          message: 'Please verify your email to unlock all features.',
          actionLabel: 'Resend',
          onAction: () => _resendVerification(auth),
        );
      }),

      Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: _kBlueDark, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.waving_hand, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${auth.fullName.split(' ').first}!',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(auth.getUserSummary(),
                    style: const TextStyle(
                        color: Color(0xffCBD5E1), fontSize: 12)),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _heroStat('${matches.length}', 'Programs\nFound',
                Icons.search, Colors.white),
            const SizedBox(width: 8),
            _heroStat('${strongMatches.length}', 'Fully\nEligible',
                Icons.check_circle_outline, Colors.greenAccent),
            const SizedBox(width: 8),
            _heroStat('$topScore%', 'Top\nMatch', Icons.star_outline, Colors.amber),
          ]),
          const SizedBox(height: 14),
          Focus(child: Builder(builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  boxShadow: focused ? [BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.9),
                      spreadRadius: 3, blurRadius: 0)] : []),
              child: Semantics(button: true, label: 'View all my matched programs',
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                      foregroundColor: _kBlueDark,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0),
                  icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                  label: const Text('View All My Matched Programs',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => Get.to(() => const ProgramResultsPage()),
                ),
              ),
            );
          })),
        ]),
      ),

      const SizedBox(height: 16),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quick Actions', style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Row(children: [
            _actionCard(icon: Icons.assignment_outlined, label: 'My Programs',
                sublabel: 'Saved & Applications', color: const Color(0xff7c3aed),
                cardColor: cardColor, onTap: () => Get.to(() => const SavedProgramsPage())),
            const SizedBox(width: 10),
            _actionCard(icon: Icons.edit_note_outlined, label: 'Update Profile',
                sublabel: 'Edit your details', color: const Color(0xff0d9488),
                cardColor: cardColor, onTap: () => Get.to(() => const CompleteProfilePage())),
            const SizedBox(width: 10),
            _actionCard(icon: Icons.person_outlined, label: 'View Profile',
                sublabel: 'Your information', color: _kBlue,
                cardColor: cardColor, onTap: () => Get.to(() => const MemoPage())),
          ]),
        ]),
      ),

      const SizedBox(height: 16),

      if (matches.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Your Top Matches', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.bold, color: textColor)),
            TextButton(
              onPressed: () => Get.to(() => const ProgramResultsPage()),
              child: Text('See all ${matches.length} →',
                  style: const TextStyle(color: _kBlue, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        ...matches.take(3).map((m) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MatchPreviewCard(result: m, cardColor: cardColor, textColor: textColor),
        )),
      ],

      const SizedBox(height: 16),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xff0d9488).withValues(alpha: 0.25))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xff0d9488).withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lightbulb_outline,
                  color: Color(0xff0d9488), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Did you know?', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12,
                    color: Color(0xff0d9488))),
                const SizedBox(height: 3),
                Text(
                  'Having an NCPWD Card significantly increases your eligibility. '
                  'Register at any NCPWD County Office.',
                  style: TextStyle(fontSize: 12, color: subColor, height: 1.4)),
              ],
            )),
          ]),
        ),
      ),

      const SizedBox(height: 28),
    ]);
  }

  Widget _heroStat(String value, String label, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18,
            fontWeight: FontWeight.bold)),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffCBD5E1), fontSize: 9)),
      ]),
    ));
  }

  Widget _actionCard({required IconData icon, required String label,
      required String sublabel, required Color color,
      required Color cardColor, required VoidCallback onTap}) {
    return Expanded(child: Semantics(button: true, label: label,
      child: Focus(child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return GestureDetector(onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: focused
                    ? Border.all(color: Colors.amber, width: 3)
                    : Border.all(color: color.withValues(alpha: 0.18)),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07),
                    blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold,
                      fontSize: 11)),
              Text(sublabel, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xff6b7280), fontSize: 9)),
            ]),
          ),
        );
      })),
    ));
  }
}

// ── Match Preview Card ────────────────────────────────────────────────────────
class _MatchPreviewCard extends StatelessWidget {
  final MatchResult result;
  final Color cardColor, textColor;
  const _MatchPreviewCard({required this.result, required this.cardColor,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = result.matchScore >= 80
        ? const Color(0xff16a34a)
        : result.matchScore >= 60 ? const Color(0xff0d9488) : const Color(0xffd97706);
    final String matchLabel = result.fullyEligible ? 'Strong Match'
        : result.matchScore >= 60 ? 'Partial Match' : 'Low Match';
    final IconData matchIcon =
        result.fullyEligible ? Icons.check_circle : Icons.info_outline;

    return Semantics(
      label: '${result.program.name}. ${result.program.organization}.'
          ' $matchLabel. ${result.matchScore} percent match.',
      child: Focus(child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: focused
                  ? Border.all(color: Colors.amber, width: 3)
                  : Border.all(color: result.fullyEligible
                      ? const Color(0xff16a34a).withValues(alpha: 0.3)
                      : const Color(0xffd97706).withValues(alpha: 0.25)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6, offset: const Offset(0, 2))]),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1), shape: BoxShape.circle,
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${result.matchScore}%', style: TextStyle(color: scoreColor,
                    fontSize: 11, fontWeight: FontWeight.bold)),
                Text(result.matchScore >= 80 ? 'High' : 'Mid',
                    style: TextStyle(color: scoreColor, fontSize: 8)),
              ]),
            ),
            title: Text(result.program.name, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: textColor)),
            subtitle: Text(result.program.organization,
                style: const TextStyle(fontSize: 11, color: Color(0xff4b5563))),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(matchIcon, size: 14, color: scoreColor),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(matchLabel, style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.bold, color: scoreColor)),
              ),
            ]),
            onTap: () => Get.to(() => const ProgramResultsPage()),
          ),
        );
      })),
    );
  }
}