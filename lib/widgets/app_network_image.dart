import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final IconData fallbackIcon;
  final Alignment alignment;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showBorder = false,
    this.fallbackIcon = Icons.image_not_supported,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: radius,
        border: showBorder
            ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: fit,
              alignment: alignment,
              gaplessPlayback: true,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, _, __) {
                return Center(child: Icon(fallbackIcon, color: Colors.grey.shade500));
              },
            )
          : Center(child: Icon(fallbackIcon, color: Colors.grey.shade500)),
    );
  }
}
