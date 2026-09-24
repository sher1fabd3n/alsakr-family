import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/parent/state/parent_child_context.dart';
import '../theme/app_colors.dart';

/// Cached student photo with optional Hero transition support.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.studentId,
    required this.name,
    this.photoUrl,
    this.radius = 28,
    this.enableHero = false,
    this.parallaxOffset = 0,
    this.onEditPhoto,
  });

  final int studentId;
  final String name;
  final String? photoUrl;
  final double radius;
  final bool enableHero;
  final double parallaxOffset;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final parentCtx = context.watch<ParentChildContext>();
    final preview = parentCtx.localPhotoPreview(studentId);
    final revision = parentCtx.photoRevision;
    final resolvedUrl = photoUrl ?? parentCtx.childById(studentId)?.profilePhotoUrl;

    final avatar = Transform.translate(
      offset: Offset(parallaxOffset, parallaxOffset * 0.15),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: ClipOval(
          child: _Photo(
            name: name,
            radius: radius,
            previewBytes: preview,
            photoUrl: resolvedUrl,
            cacheNonce: revision,
          ),
        ),
      ),
    );

    if (!enableHero && onEditPhoto == null) return avatar;

    Widget result = avatar;
    if (enableHero) {
      result = Hero(
        tag: 'child-photo-$studentId',
        child: Material(
          color: Colors.transparent,
          child: avatar,
        ),
      );
    }

    if (onEditPhoto == null) return result;

    final badgeSize = (radius * 0.72).clamp(18.0, 26.0);
    return GestureDetector(
      onTap: onEditPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          result,
          Positioned(
            left: -2,
            bottom: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: badgeSize * 0.55,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.name,
    required this.radius,
    required this.previewBytes,
    required this.photoUrl,
    required this.cacheNonce,
  });

  final String name;
  final double radius;
  final Uint8List? previewBytes;
  final String? photoUrl;
  final int cacheNonce;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(
        previewBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        cacheKey: '$photoUrl|$cacheNonce',
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        placeholder: (context, url) => _Initials(name: name, radius: radius),
        errorWidget: (context, url, error) => _Initials(name: name, radius: radius),
      );
    }

    return _Initials(name: name, radius: radius);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: TextStyle(
            fontSize: radius * 0.85,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
