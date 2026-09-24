import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/section_header.dart';
import '../../models/student_models.dart';
import '../../services/student_services.dart';
import '../auth/login_screen.dart';
import '../parent/parent_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<StudentFeesResponse> _feesFuture;

  @override
  void initState() {
    super.initState();
    _feesFuture = context.read<StudentService>().getFees();
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    context.read<AppState>().clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthService>().currentStudent;

    if (student == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _feesFuture = context.read<StudentService>().getFees();
          });
          await _feesFuture;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'الملف الشخصي',
                subtitle: student.name,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeSlideIn(
                    child: AppCard(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.surfaceMuted,
                            backgroundImage: student.profilePhotoUrl != null
                                ? NetworkImage(student.profilePhotoUrl!)
                                : null,
                            child: student.profilePhotoUrl == null
                                ? Text(
                                    student.name[0],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            student.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'الصف ${student.grade}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'البيانات الأساسية'),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: AppCard(
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.badge_outlined,
                            label: 'رقم الجلوس',
                            value: '${student.rollNo}',
                          ),
                          const Divider(height: 24),
                          _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'البريد الإلكتروني',
                            value: student.emailAddress,
                          ),
                          const Divider(height: 24),
                          _InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'الهاتف',
                            value: '${student.phoneNumber}',
                          ),
                          if (student.stage != null && student.stage!.isNotEmpty) ...[
                            const Divider(height: 24),
                            _InfoTile(
                              icon: Icons.stairs_outlined,
                              label: 'المرحلة',
                              value: student.stage!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'المصاريف'),
                  const SizedBox(height: 12),
                  FutureBuilder<StudentFeesResponse>(
                    future: _feesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AppCard(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final fees = snapshot.data;
                      if (fees == null) {
                        return const AppCard(child: Text('تعذر تحميل المصاريف'));
                      }
                      return FadeSlideIn(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fees.academicYearName != null)
                                Text(
                                  'العام الدراسي: ${fees.academicYearName}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              const SizedBox(height: 12),
                              _InfoTile(
                                icon: Icons.payments_outlined,
                                label: 'إجمالي المصاريف',
                                value: fees.tuitionAndBooksTotal.toStringAsFixed(2),
                              ),
                              if (fees.totalRemaining > 0) ...[
                                const SizedBox(height: 8),
                                _InfoTile(
                                  icon: Icons.pending_actions,
                                  label: 'المتبقي',
                                  value: fees.totalRemaining.toStringAsFixed(2),
                                ),
                              ],
                              if (fees.currentArrears > 0) ...[
                                const SizedBox(height: 8),
                                _InfoTile(
                                  icon: Icons.warning_amber_rounded,
                                  label: 'المتأخرات',
                                  value: fees.currentArrears.toStringAsFixed(2),
                                ),
                              ],
                              if (fees.message != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  fees.message!,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: AppCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ParentDashboardScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.family_restroom_rounded, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'لوحة ولي الأمر',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('تسجيل الخروج'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
