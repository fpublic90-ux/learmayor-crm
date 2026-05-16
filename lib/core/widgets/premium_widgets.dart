import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'dart:ui';

/// A premium Bento-style card with hover effects for desktop
class BentoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool isKinetic;
  final double scale;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
    this.isKinetic = false,
    this.scale = 0.97,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: (widget.isKinetic && _isPressed) ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
            padding: widget.padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.color ?? Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 24),
              border: Border.all(
                color: _isHovered ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: _isHovered ? AppTheme.premiumShadow : AppTheme.softShadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A standard detail tile for profile information
class DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const DetailTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor ?? AppTheme.textMid, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A semantic badge for status display
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
      ),
    );
  }
}

/// A wrapper to ensure layout stays tight on large screens
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A premium skeleton loader using Shimmer
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A ghost version of a Bento Card for loading states
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const BentoCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          ShimmerLoading(width: 54, height: 54, borderRadius: 27),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 140, height: 16),
                SizedBox(height: 8),
                ShimmerLoading(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full list of skeleton cards for loading directories
class SkeletonList extends StatelessWidget {
  final int itemCount;
  const SkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonCard(),
      ),
    );
  }
}

/// A premium empty state display
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.primary.withOpacity(0.2)),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.blueGrey.withOpacity(0.6), height: 1.5),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel ?? 'Create New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A robust image widget with caching and shimmer placeholder
class PremiumImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isCircle;
  final double borderRadius;
  final BoxFit fit;

  const PremiumImage({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.isCircle = true,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Handle Web Blobs
    if (kIsWeb && imageUrl!.startsWith('blob:')) {
      return _buildImageWrapper(Image.network(imageUrl!, fit: fit));
    }

    // Handle Local Assets
    if (imageUrl!.startsWith('assets/')) {
      return _buildImageWrapper(Image.asset(imageUrl!, fit: fit));
    }

    // Handle Local Files (Mobile/Desktop)
    if (!kIsWeb && (imageUrl!.startsWith('/') || imageUrl!.contains(':\\') || imageUrl!.startsWith('file:'))) {
      try {
        final path = imageUrl!.startsWith('file:') ? imageUrl!.substring(5) : imageUrl!;
        final file = File(path);
        if (file.existsSync()) {
          return _buildImageWrapper(Image.file(file, fit: fit, errorBuilder: (c, e, s) => _buildPlaceholder()));
        }
      } catch (e) {
        debugPrint('Image load error: $e');
      }
      return _buildPlaceholder();
    }

    // Handle Network Images
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          image: DecorationImage(image: imageProvider, fit: fit),
        ),
      ),
      placeholder: (context, url) => ShimmerLoading(
        width: size,
        height: size,
        borderRadius: isCircle ? size / 2 : borderRadius,
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildImageWrapper(Widget child) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircle ? size : borderRadius),
        child: child,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.background,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Center(
        child: Icon(Icons.person_rounded, color: AppTheme.textLight.withOpacity(0.5), size: size * 0.45),
      ),
    );
  }
}

/// A     stylized confirmation dialog
class PremiumConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final IconData? icon;

  const PremiumConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor = AppTheme.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      title: Column(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor, size: 32),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textDark),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textMid, fontSize: 15, height: 1.5),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(cancelLabel, style: const TextStyle(color: AppTheme.textMid, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PremiumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? bottom;
  final VoidCallback? onBack;

  const PremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.bottom,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showBackButton)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.background,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: const TextStyle(color: AppTheme.textMid, fontSize: 14),
              ),
            ),
          ],
          if (bottom != null) ...[
            const SizedBox(height: 20),
            bottom!,
          ],
        ],
      ),
    );
  }
}


/// A robust, state-based loading overlay to replace buggy dialog-based spinners
class PremiumLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;

  const PremiumLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.4),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
/// A premium glassmorphic container
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color color;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.05,
    this.borderRadius = 24,
    this.color = Colors.white,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A high-fidelity glassmorphic AppBar alternative
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;

  const GlassAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: AppTheme.background.withOpacity(0.8),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 20, right: 20),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBack ?? () => Navigator.pop(context),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 18)),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textLight, letterSpacing: 0.5)),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

/// A high-fidelity kinetic button with loading and semantic support
class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final Color? color;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.primary;
    final isDisabled = onPressed == null || isLoading;

    return AnimatedScale(
      scale: isLoading ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: isDisabled ? null : () {
          HapticFeedback.lightImpact();
          onPressed!();
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : (isDisabled ? themeColor.withOpacity(0.5) : themeColor),
            borderRadius: BorderRadius.circular(16),
            border: isOutline ? Border.all(color: themeColor, width: 2) : null,
            boxShadow: (!isOutline && !isDisabled) ? [
              BoxShadow(
                color: themeColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ] : null,
          ),
          child: Center(
            child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(isOutline ? themeColor : Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: isOutline ? themeColor : Colors.white, size: 20),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isOutline ? themeColor : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
