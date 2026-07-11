// lib/App/views/videocall/screen/CallScreen.dart
//
// Live 1:1 video call screen. Joins the Agora channel using the
// channel/token/uid returned by AstrologerService.startSession(), and
// ends the session via AstrologerService.endSession() when the user hangs up.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:astro_tale/core/constants/agora_constants.dart';
import 'package:astro_tale/services/api_services/astrologer_service.dart';

class CallScreen extends StatefulWidget {
  final AgoraSession session;

  const CallScreen({super.key, required this.session});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final AstrologerService _service = AstrologerService();

  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _micMuted = false;
  bool _cameraOff = false;
  bool _ending = false;
  String? _error;

  Timer? _callTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _initAgora() async {
    try {
      // Camera/mic permissions — Android/iOS only. On web the browser
      // shows its own native permission prompt when the SDK requests the
      // media stream, so permission_handler has nothing to do there.
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final statuses = await [
          Permission.microphone,
          Permission.camera,
        ].request();
        final denied = statuses.values.any((s) => !s.isGranted);
        if (denied) {
          setState(() {
            _error = 'Camera and microphone permissions are required for a video call.';
          });
          return;
        }
      }

      if (AgoraConstants.appId.isEmpty ||
          AgoraConstants.appId == 'PUT_YOUR_AGORA_APP_ID_HERE') {
        setState(() {
          _error = 'Agora App ID is not configured. See agora_constants.dart.';
        });
        return;
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: AgoraConstants.appId));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (mounted) setState(() => _localUserJoined = true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (mounted) setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (mounted) setState(() => _remoteUid = null);
          },
          onError: (err, msg) {
            if (mounted) {
              setState(() => _error = 'Connection error: $msg');
            }
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();

      await _engine!.joinChannel(
        token: widget.session.agoraToken,
        channelId: widget.session.agoraChannel,
        uid: widget.session.agoraUid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start video call: $e');
    }
  }

  Future<void> _toggleMic() async {
    setState(() => _micMuted = !_micMuted);
    await _engine?.muteLocalAudioStream(_micMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() => _cameraOff = !_cameraOff);
    await _engine?.muteLocalVideoStream(_cameraOff);
  }

  Future<void> _endCall() async {
    if (_ending) return;
    setState(() => _ending = true);
    try {
      await _service.endSession(widget.session.bookingId);
    } catch (_) {
      // Best-effort — the user still leaves the call locally even if the
      // backend call fails, so they're never stuck on a dead screen.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  String get _formattedDuration {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050B1E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _remoteUid != null && _engine != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine!,
                        canvas: VideoCanvas(uid: _remoteUid!),
                        connection:
                            RtcConnection(channelId: widget.session.agoraChannel),
                      ),
                    )
                  : _waitingState(),
            ),

            // Local preview — small corner tile
            if (_localUserJoined && _engine != null && !_cameraOff)
              Positioned(
                top: 16,
                right: 16,
                width: 110,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),

            Positioned(top: 16, left: 16, child: _topInfo()),

            if (_error != null)
              Positioned(top: 80, left: 16, right: 16, child: _errorBanner()),

            Positioned(left: 0, right: 0, bottom: 24, child: _controls()),
          ],
        ),
      ),
    );
  }

  Widget _waitingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'Waiting for ${widget.session.astrologerName} to join...',
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _topInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.session.astrologerName,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formattedDuration,
            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _error!,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlButton(
          icon: _micMuted ? LucideIcons.mic_off : LucideIcons.mic,
          onTap: _toggleMic,
          active: _micMuted,
        ),
        const SizedBox(width: 20),
        _controlButton(
          icon: LucideIcons.phone_off,
          onTap: _endCall,
          background: Colors.redAccent,
          large: true,
        ),
        const SizedBox(width: 20),
        _controlButton(
          icon: _cameraOff ? LucideIcons.video_off : LucideIcons.video,
          onTap: _toggleCamera,
          active: _cameraOff,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    bool large = false,
    Color? background,
  }) {
    final size = large ? 64.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? (active ? Colors.white24 : Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: large ? 28 : 22),
      ),
    );
  }
}