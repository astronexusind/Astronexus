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
    final maxWidth = MediaQuery.of(context).size.width * 0.74;

    // ── User bubble colours ──────────────────────────────────────────
    // White bg + dark text in both light and dark modes
    final userBg = Colors.white;
    final userBorder = const Color(0xFFDDE3EF);
    final userText = const Color(0xFF0F172A);  // near-black

    // ── Bot bubble colours ───────────────────────────────────────────
    // Dark  : slightly elevated surface on dark bg
    // Light : pure white card
    final botBg = isDark ? const Color(0xFF1E1538) : Colors.white;
    final botBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);
    final botText = isDark ? Colors.white : const Color(0xFF0F172A);

    TextSpan buildSpan() {
      final textColor = isUser ? userText : botText;
      if (keywords.isEmpty) {
        return TextSpan(
          text: text,
          style: GoogleFonts.dmSans(
            color: textColor,
            fontSize: 14.5,
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
          final current = remaining.toLowerCase().indexOf(keyword.toLowerCase());
          if (current >= 0 && current < index) {
            index = current;
            matchedKeyword = remaining.substring(current, current + keyword.length);
          }
        }

        if (index > 0) {
          spans.add(TextSpan(
            text: remaining.substring(0, index),
            style: GoogleFonts.dmSans(
              color: textColor,
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ));
        }

        if (matchedKeyword != null) {
          spans.add(TextSpan(
            text: matchedKeyword,
            style: GoogleFonts.dmSans(
              color: isDark ? const Color(0xFFFBBF24) : AppColors.lightPrimary,
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ));
          remaining = remaining.substring(index + matchedKeyword.length);
        } else {
          break;
        }
      }

      return TextSpan(children: spans);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isUser) ...<Widget>[
            _ChatAvatar(
              radius: 18,
              backgroundColor: isDark
                  ? const Color(0xFF2E2057)
                  : const Color(0xFFEEF2FF),
              assetPath: botAvatar,
              fallbackAsset: "assets/images/mati.png",
              fallbackIcon: Icons.auto_awesome,
              iconColor: const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: isUser
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 13)
                  : const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: isUser ? userBg : botBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser ? userBorder : botBorder,
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    // Oracle badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Mati",
                          style: GoogleFonts.dmSans(
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF7C3AED),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            letterSpacing: 0.2,
                          ),
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
              radius: 18,
              backgroundColor: isDark
                  ? const Color(0xFF2E2057)
                  : const Color(0xFFEEF2FF),
              imageUrl: userAvatar,
              fallbackAsset: "assets/icons/profile.png",
              fallbackIcon: Icons.person,
              iconColor: const Color(0xFF7C3AED),
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
    return Center(child: Icon(fallbackIcon, size: radius, color: iconColor));
  }
}
