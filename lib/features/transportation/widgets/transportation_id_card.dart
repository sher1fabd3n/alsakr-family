import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../core/constants/app_branding.dart';
import '../../parent/state/parent_child_context.dart';
import '../models/transportation_models.dart';



/// كارنيه طالب: ذهبي للنقل الخاص (هوية مدرسة الصقر)، أزرق للحافلة — البيانات بالأسود.
class TransportationIdCard extends StatelessWidget {
  const TransportationIdCard({
    super.key,
    required this.card,
    this.studentId,
    this.onPhotoTap,
  });

  final TransportationCardData card;
  final int? studentId;
  final VoidCallback? onPhotoTap;

  /// درجة «OPEN NOW» من هوية مدرسة الصقر
  static const _goldDark = Color(0xFFC68400);
  static const _gold = Color(0xFFFFB000);
  static const _goldLight = Color(0xFFFFC933);

  static const _blueDark = Color(0xFF0D47A1);

  static const _blue = Color(0xFF1565C0);

  static const _blueLight = Color(0xFF1976D2);

  static const _muted = Color(0xFF5C6B7A);

  static const _valueBlack = Color(0xFF111111);



  bool get _isSchoolBus => card.isSchoolBus;



  Color get _themeDark => _isSchoolBus ? _blueDark : _goldDark;

  Color get _theme => _isSchoolBus ? _blue : _gold;

  Color get _themeLight => _isSchoolBus ? _blueLight : _goldLight;

  Color get _photoBg => _isSchoolBus ? const Color(0xFFEEF4FC) : const Color(0xFFFFF8E7);



  String? _resolvePhotoUrl(String? url) {

    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http')) return url;

    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');

    return '$base${url.startsWith('/') ? '' : '/'}$url';

  }



  @override

  Widget build(BuildContext context) {

    const cardTitle = 'بطاقة طالب للعام الدراسي 2026-2027';

    var photoUrl = _resolvePhotoUrl(card.studentPhotoUrl);
    Uint8List? previewBytes;
    final id = studentId;
    if (id != null) {
      final parentCtx = context.watch<ParentChildContext>();
      previewBytes = parentCtx.localPhotoPreview(id);
      final liveUrl = parentCtx.childById(id)?.profilePhotoUrl;
      if (liveUrl != null && liveUrl.isNotEmpty) {
        photoUrl = _resolvePhotoUrl(liveUrl);
      }
    }

    const dash = '—';



    return Center(

      child: ConstrainedBox(

        constraints: const BoxConstraints(maxWidth: 340),

        child: AspectRatio(

          aspectRatio: 85.6 / 54,

          child: DecoratedBox(

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(8),

              border: Border.all(color: _theme, width: 1.5),

              boxShadow: [

                BoxShadow(

                  color: _themeDark.withValues(alpha: 0.15),

                  blurRadius: 20,

                  offset: const Offset(0, 6),

                ),

              ],

            ),

            child: ClipRRect(

              borderRadius: BorderRadius.circular(7),

              child: Column(

                children: [

                  _Header(

                    schoolName: card.schoolName,

                    cardTitle: cardTitle,

                    themeDark: _themeDark,

                    themeLight: _themeLight,

                  ),

                  Expanded(

                    child: Padding(

                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                      child: Row(

                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [

                          Expanded(

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [

                                _InfoLine(

                                  label: 'الاسم:',

                                  value: card.studentName,

                                  valueStyle: const TextStyle(

                                    fontWeight: FontWeight.w700,

                                    fontSize: 11,

                                    color: _valueBlack,

                                  ),

                                ),

                                _InfoLine(

                                  label: 'المرحلة:',

                                  value: card.stageDisplayAr.isNotEmpty

                                      ? card.stageDisplayAr

                                      : dash,

                                ),

                                _InfoLine(

                                  label: 'العنوان:',

                                  value: (card.address?.isNotEmpty ?? false)

                                      ? card.address!

                                      : dash,

                                ),

                                Row(

                                  children: [

                                    Expanded(

                                      child: _InfoLine(

                                        label: 'الأب:',

                                        value: (card.fatherPhone?.isNotEmpty ?? false)

                                            ? card.fatherPhone!

                                            : dash,

                                        compact: true,

                                      ),

                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(

                                      child: _InfoLine(

                                        label: 'الأم:',

                                        value: (card.motherPhone?.isNotEmpty ?? false)

                                            ? card.motherPhone!

                                            : dash,

                                        compact: true,

                                      ),

                                    ),

                                  ],

                                ),

                                _InfoLine(

                                  label: 'النقل:',

                                  value: card.transportLine.isNotEmpty

                                      ? card.transportLine

                                      : card.transportationTypeAr,

                                ),

                              ],

                            ),

                          ),

                          const SizedBox(width: 8),

                          _Photo(
                            photoUrl: photoUrl,
                            previewBytes: previewBytes,
                            name: card.studentName,
                            themeColor: _theme,
                            photoBg: _photoBg,
                            onTap: onPhotoTap,
                          ),

                        ],

                      ),

                    ),

                  ),

                  Container(

                    height: 3,

                    decoration: BoxDecoration(

                      gradient: LinearGradient(

                        colors: [_themeDark, _themeLight],

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }

}



class _Header extends StatelessWidget {

  const _Header({

    required this.schoolName,

    required this.cardTitle,

    required this.themeDark,

    required this.themeLight,

  });



  final String schoolName;

  final String cardTitle;

  final Color themeDark;

  final Color themeLight;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

      decoration: BoxDecoration(

        gradient: LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [themeDark, themeLight],

        ),

      ),

      child: Row(

        children: [

          ClipRRect(

            borderRadius: BorderRadius.circular(5),

            child: Image.asset(

              AppBranding.logoAsset,

              width: 28,

              height: 28,

              fit: BoxFit.contain,

            ),

          ),

          const SizedBox(width: 8),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  schoolName,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.w700,

                    fontSize: 9,

                    height: 1.2,

                  ),

                ),

                Text(

                  cardTitle,

                  style: TextStyle(

                    color: Colors.white.withValues(alpha: 0.88),

                    fontSize: 7.5,

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



class _Photo extends StatelessWidget {
  const _Photo({
    required this.photoUrl,
    required this.name,
    required this.themeColor,
    required this.photoBg,
    this.previewBytes,
    this.onTap,
  });

  final String? photoUrl;
  final Uint8List? previewBytes;
  final String name;
  final Color themeColor;
  final Color photoBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      child = Image.memory(previewBytes!, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: photoUrl!,
        cacheKey: photoUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => Icon(Icons.person, color: themeColor),
        errorWidget: (_, _, _) => Icon(Icons.person, color: themeColor),
      );
    } else {
      child = Icon(Icons.person, color: themeColor, size: 32);
    }

    final image = Container(
      width: 72,
      height: 88,
      decoration: BoxDecoration(
        border: Border.all(color: themeColor, width: 1.5),
        borderRadius: BorderRadius.circular(3),
        color: photoBg,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (onTap == null) return image;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          image,
          Positioned(
            left: 2,
            bottom: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}



class _InfoLine extends StatelessWidget {

  const _InfoLine({

    required this.label,

    required this.value,

    this.valueStyle,

    this.compact = false,

  });



  final String label;

  final String value;

  final TextStyle? valueStyle;

  final bool compact;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: EdgeInsets.only(bottom: compact ? 2 : 3),

      child: RichText(

        maxLines: 2,

        overflow: TextOverflow.ellipsis,

        text: TextSpan(

          style: TextStyle(fontSize: compact ? 8.5 : 9.5, height: 1.3),

          children: [

            TextSpan(

              text: '$label ',

              style: const TextStyle(

                color: TransportationIdCard._muted,

                fontWeight: FontWeight.w500,

              ),

            ),

            TextSpan(

              text: value,

              style: valueStyle ??

                  TextStyle(

                    fontWeight: FontWeight.w700,

                    color: TransportationIdCard._valueBlack,

                    fontSize: compact ? 8.5 : 9.5,

                  ),

            ),

          ],

        ),

      ),

    );

  }

}

