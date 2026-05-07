import "package:astro_tale/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? userAvatar;
  final String? botAvatar;
  final List<String> keywords;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.userAvatar,
    this.botAvatar,
    this.keywords = const <String>[],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final useLightUserBubble = isUser && isDark;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final textColor = isUser
        ? (useLightUserBubble ? const Color(0xFF0F172A) : Colors.white)
        : (isDark
              ? Colors.white.withValues(alpha: 0.92)
              : const Color(0xFF0F172A));
    final userGradient = const LinearGradient(
      colors: <Color>[Color(0xFF2B6CB0), Color(0xFF1E3A8A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    TextSpan buildSpan() {
      if (keywords.isEmpty) {
        return TextSpan(
          text: text,
          style: GoogleFonts.dmSans(
            color: textColor,
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        );
      }

      final spans = <TextSpan>[];
      String remaining = text;

      while (remaining.isNotEmpty) {
        int index = remaining.length;
        String? matchedKeyword;

        for (final keyword in keywords) {
          final current = remaining.toLowerCase().indexOf(
            keyword.toLowerCase(),
          );
          if (current >= 0 && current < index) {
            index = current;
            matchedKeyword = remaining.substring(
              current,
              current + keyword.length,
            );
          }
        }

        if (index > 0) {
          spans.add(
            TextSpan(
              text: remaining.substring(0, index),
              style: GoogleFonts.dmSans(
                color: textColor,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        if (matchedKeyword != null) {
          spans.add(
            TextSpan(
              text: matchedKeyword,
              style: GoogleFonts.dmSans(
                color: isUser
                    ? const Color(0xFFFCD34D)
                    : AppColors.lightPrimary,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
          remaining = remaining.substring(index + matchedKeyword.length);
        } else {
          break;
        }
      }

      return TextSpan(children: spans);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          if (!isUser) ...<Widget>[
            _ChatAvatar(
              radius: 19,
              backgroundColor: isDark
                  ? const Color(0xFF24314E)
                  : const Color(0xFFEAF2FF),
              assetPath: botAvatar,
              fallbackAsset: "assets/images/mati.png",
              fallbackIcon: Icons.auto_awesome,
              iconColor: const Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: isUser
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                  : const EdgeInsets.fromLTRB(14, 12, 14, 16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? (useLightUserBubble ? null : userGradient)
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF2B2E4A).withValues(alpha: 0.92),
                                const Color(0xFF23264A).withValues(alpha: 0.98),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.98),
                                const Color(0xFFF3F7FF).withValues(alpha: 0.98),
                              ],
                      ),
                color: isUser
                    ? (useLightUserBubble ? Colors.white : null)
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 7),
                  bottomRight: Radius.circular(isUser ? 7 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? (useLightUserBubble
                            ? const Color(0xFFDCE4F5)
                            : Colors.transparent)
                      : (isDark ? Colors.white24 : const Color(0xFFD8E3F6)),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3B3F5C).withValues(alpha: 0.7)
                                : const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 15,
                                color: Color(0xFFDBC33F),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Mati Prediction",
                                style: GoogleFonts.dmSans(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : const Color(0xFF2B2E4A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.2,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.auto_graph_rounded,
                          size: 17,
                          color: isDark
                              ? const Color(0xFFDBC33F)
                              : const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  RichText(text: buildSpan()),
                ],
              ),
            ),
          ),
          if (isUser) ...<Widget>[
            const SizedBox(width: 8),
            _ChatAvatar(
              radius: 19,
              backgroundColor: isDark
                  ? Colors.white12
                  : const Color(0xFFEAF2FF),
              imageUrl: userAvatar,
              fallbackAsset: "assets/icons/profile.png",
              fallbackIcon: Icons.person,
              iconColor: const Color(0xFF2563EB),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.radius,
    required this.backgroundColor,
    required this.fallbackAsset,
    required this.fallbackIcon,
    required this.iconColor,
    this.imageUrl,
    this.assetPath,
  });

  final double radius;
  final Color backgroundColor;
  final String fallbackAsset;
  final IconData fallbackIcon;
  final Color iconColor;
  final String? imageUrl;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: SizedBox(width: size, height: size, child: _buildImage(size)),
      ),
    );
  }

  Widget _buildImage(double size) {
    final trimmedUrl = imageUrl?.trim() ?? "";
    if (trimmedUrl.isNotEmpty) {
      return Image.network(
        trimmedUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAssetFallback(size),
      );
    }

    final trimmedAsset = assetPath?.trim() ?? "";
    if (trimmedAsset.isNotEmpty) {
      return Image.asset(
        trimmedAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAssetFallback(size),
      );
    }

    return _buildAssetFallback(size);
  }

  Widget _buildAssetFallback(double size) {
    final asset = fallbackAsset.trim();
    if (asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIconFallback(),
      );
    }
    return _buildIconFallback();
  }

  Widget _buildIconFallback() {
    return Center(
      child: Icon(fallbackIcon, size: radius, color: iconColor),
    );
  }
}
