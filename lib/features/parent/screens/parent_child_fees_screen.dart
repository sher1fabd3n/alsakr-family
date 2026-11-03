import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/student_models.dart';
import '../services/parent_family_service.dart';
import '../state/parent_child_context.dart';
import '../widgets/child_switcher.dart';
import 'parent_upload_receipt_screen.dart';

class ParentChildFeesScreen extends StatefulWidget {
  const ParentChildFeesScreen({super.key});

  @override
  State<ParentChildFeesScreen> createState() => _ParentChildFeesScreenState();
}

class _ParentChildFeesScreenState extends State<ParentChildFeesScreen> {
  int? _studentId;
  Future<StudentFeesResponse>? _future;

  Future<void> _openUpload() async {
    if (_studentId == null) return;
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ParentUploadReceiptScreen(studentId: _studentId!)),
    );
    if (uploaded == true && mounted && _studentId != null) {
      setState(() {
        _future = context.read<ParentFamilyService>().getChildFees(_studentId!);
      });
    }
  }

  Future<void> _openReceipt(FeeReceipt receipt) async {
    if (_studentId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<ParentFamilyService>();
    try {
      final bytes = await service.downloadChildFeeReceipt(_studentId!, receipt.id);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: receipt.originalFileName.isEmpty ? 'receipt' : receipt.originalFileName,
              mimeType: 'application/octet-stream',
            ),
          ],
          text: receipt.category,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ParentChildContext>().activeStudentId;
    if (activeId != null && activeId != _studentId) {
      _studentId = activeId;
      _future = context.read<ParentFamilyService>().getChildFees(activeId);
    }

    final currency = NumberFormat('#,##0', 'ar');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (_studentId == null) return;
          setState(() {
            _future = context.read<ParentFamilyService>().getChildFees(_studentId!);
          });
          await _future;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'المصاريف',
                subtitle: context.watch<ParentChildContext>().activeChild?.name,
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ChildSwitcher(compact: true, height: 120),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: FutureBuilder<StudentFeesResponse>(
                future: _future,
                builder: (context, snapshot) {
                  if (_studentId == null) {
                    return const SliverFillRemaining(child: Center(child: Text('اختر ابناً أولاً')));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', ''))),
                    );
                  }

                  final fees = snapshot.data!;
                  final hasSync = fees.lastSyncedAt != null;
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (hasSync) ...[
                        FadeSlideIn(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.sync, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('ملخص المصاريف',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        )),
                                    const Spacer(),
                                    Text(_formatDate(fees.lastSyncedAt),
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const Divider(height: 20),
                                _FeeSyncRow(
                                    label: 'الرسوم الدراسية',
                                    required_: fees.tuitionRequired,
                                    paid: fees.tuitionPaid,
                                    discount: fees.tuitionDiscount,
                                    remaining: fees.tuitionRemaining),
                                _FeeSyncRow(
                                    label: 'الكتب',
                                    required_: fees.booksRequired,
                                    paid: fees.booksPaid,
                                    discount: fees.booksDiscount,
                                    remaining: fees.booksRemaining),
                                _FeeSyncRow(
                                    label: 'اليونيفورم',
                                    required_: fees.uniformRequired,
                                    paid: fees.uniformPaid,
                                    discount: fees.uniformDiscount,
                                    remaining: fees.uniformRemaining),
                                _FeeSyncRow(
                                    label: 'الباص',
                                    required_: fees.busRequired,
                                    paid: fees.busPaid,
                                    discount: fees.busDiscount,
                                    remaining: fees.busRemaining),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('المتأخرات الحالية',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: fees.currentArrears > 0 ? Colors.red : AppColors.textSecondary,
                                          )),
                                    ),
                                    Text(currency.format(fees.currentArrears),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: fees.currentArrears > 0 ? Colors.red : AppColors.textPrimary,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text('المتبقي الإجمالي',
                                          style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                    Text(currency.format(fees.totalRemaining),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: fees.totalRemaining > 0 ? Colors.orange : Colors.green,
                                          fontSize: 16,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (fees.excelPayments.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long, color: AppColors.secondary, size: 20),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('سجلات السداد من المدرسة',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    ),
                                    Text(currency.format(fees.excelPaymentsTotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.secondary,
                                        )),
                                  ],
                                ),
                                const Divider(height: 20),
                                ...fees.excelPayments.map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.paymentType.isNotEmpty ? p.paymentType : 'سداد',
                                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                                              if (p.paymentMethod.isNotEmpty)
                                                Text(p.paymentMethod,
                                                    style: const TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 12,
                                                    )),
                                              Text(_formatDate(p.importedAt),
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 11,
                                                  )),
                                            ],
                                          ),
                                        ),
                                        Text(currency.format(p.paidAmount),
                                            style: const TextStyle(fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (fees.message != null && fees.message!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(fees.message!, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                      if (fees.paymentAccounts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'حسابات التحويل'),
                        const SizedBox(height: 12),
                        ...fees.paymentAccounts.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.bankName, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(a.accountNumber,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        child: FilledButton.icon(
                          onPressed: _openUpload,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('رفع إيصال دفع'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(title: 'إيصالات الدفع'),
                      const SizedBox(height: 12),
                      if (fees.receipts.isEmpty)
                        const Text('لا توجد إيصالات بعد.', style: TextStyle(color: AppColors.textSecondary))
                      else
                        ...fees.receipts.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => _openReceipt(r),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text(
                                          r.fromSchool ? 'من المدرسة • ${r.status}' : r.status,
                                          style: const TextStyle(color: AppColors.textSecondary),
                                        ),
                                        if ((r.adminNotes ?? r.notes)?.trim().isNotEmpty == true)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              r.adminNotes?.trim().isNotEmpty == true ? r.adminNotes! : r.notes!,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(currency.format(r.amount),
                                      style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeSyncRow extends StatelessWidget {
  const _FeeSyncRow({
    required this.label,
    required this.required_,
    required this.paid,
    required this.discount,
    required this.remaining,
  });

  final String label;
  final double required_;
  final double paid;
  final double discount;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0', 'ar');
    final color = remaining > 0 ? Colors.orange : Colors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Text(currency.format(remaining),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 14,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildChip('المطلوب', required_, Colors.grey.shade600),
              const SizedBox(width: 6),
              _buildChip('المسدد', paid, Colors.green),
              const SizedBox(width: 6),
              _buildChip('الخصم', discount, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, double amount, Color color) {
    final currency = NumberFormat('#,##0', 'ar');
    if (amount <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: ${currency.format(amount)}',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '';
  return '${dt.day}/${dt.month}/${dt.year}';
}
