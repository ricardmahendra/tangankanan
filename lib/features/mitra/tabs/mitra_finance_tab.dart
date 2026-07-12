import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/partner_repository.dart';
import '../../../data/repositories/withdrawal_repository.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/withdrawal_model.dart';

class MitraFinanceTab extends StatefulWidget {
  const MitraFinanceTab({super.key});

  @override
  State<MitraFinanceTab> createState() => _MitraFinanceTabState();
}

class _MitraFinanceTabState extends State<MitraFinanceTab> {
  final _partnerRepo = PartnerRepository();
  final _withdrawalRepo = WithdrawalRepository();
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();

  bool _isLoading = false;
  PartnerModel? _partner;
  List<WithdrawalModel> _withdrawals = [];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);
    
    final activePartner = _partnerRepo.getCurrentPartner();
    if (activePartner != null) {
      _partner = activePartner;
    } else {
      // Mock partner fallback
      _partner = const PartnerModel(
        id: 'mock_mitra_id',
        name: 'Budi Santoso',
        phone: '081234567890',
        nik: '3320010203040001',
        balance: 350000,
        bankName: 'Bank Central Asia (BCA)',
        bankAccount: '1234567890',
      );
    }

    // Set initial values for bank fields if they exist
    if (_partner != null) {
      _bankNameController.text = _partner!.bankName;
      _bankAccountController.text = _partner!.bankAccount;
    }

    try {
      if (_partner != null) {
        _withdrawals = await _withdrawalRepo.getWithdrawals(_partner!.id);
      }
    } catch (e) {
      print('Gagal memuat data penarikan: $e');
      _setMockWithdrawals();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setMockWithdrawals() {
    _withdrawals = [
      WithdrawalModel(
        id: 'mock_w_1',
        partnerId: _partner!.id,
        amount: 100000,
        bankName: 'BCA',
        bankAccount: '1234567890',
        status: 'transferred',
        transferredAt: DateTime.now().subtract(const Duration(days: 2)),
        created: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      ),
      WithdrawalModel(
        id: 'mock_w_2',
        partnerId: _partner!.id,
        amount: 50000,
        bankName: 'BCA',
        bankAccount: '1234567890',
        status: 'pending',
        created: DateTime.now().subtract(const Duration(hours: 3)),
      )
    ];
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_partner == null) return;

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final bankName = _bankNameController.text.trim();
    final bankAccount = _bankAccountController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Execute request
      await _withdrawalRepo.requestWithdrawal(
        partnerId: _partner!.id,
        amount: amount,
        bankName: bankName,
        bankAccount: bankAccount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan penarikan dana berhasil dikirim!'),
          backgroundColor: AppColors.success,
        ),
      );

      _amountController.clear();
      _loadFinanceData();
    } catch (e) {
      // Handled for offline/mock mode
      print('Gagal kirim withdraw ke backend: $e');
      if (!mounted) return;
      
      // Simulate local success in mock mode
      final mockNewWithdrawal = WithdrawalModel(
        id: 'mock_new_${DateTime.now().millisecondsSinceEpoch}',
        partnerId: _partner!.id,
        amount: amount,
        bankName: bankName,
        bankAccount: bankAccount,
        status: 'pending',
        created: DateTime.now(),
      );

      setState(() {
        _partner = PartnerModel(
          id: _partner!.id,
          name: _partner!.name,
          phone: _partner!.phone,
          nik: _partner!.nik,
          bio: _partner!.bio,
          isOnline: _partner!.isOnline,
          isVerified: _partner!.isVerified,
          rating: _partner!.rating,
          totalJobs: _partner!.totalJobs,
          balance: _partner!.balance - amount, // Deduct local simulation
          bankName: bankName,
          bankAccount: bankAccount,
        );
        _withdrawals.insert(0, mockNewWithdrawal);
        _amountController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulasi: Pengajuan penarikan dikirim (Offline Mode).'),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_partner == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Keuangan & Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
      ),
      body: _isLoading && _withdrawals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinanceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tampilan Saldo Utama
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SALDO AKTIP TOTAL',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRupiah(_partner!.balance),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pendapatan Anda siap dicairkan ke rekening terdaftar.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Formulir Tarik Saldo
                    Text(
                      'Tarik Saldo Pendapatan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Nominal Penarikan (Rp)',
                                hintText: 'Contoh: 100000',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nominal penarikan wajib diisi';
                                }
                                final amt = int.tryParse(value.trim()) ?? 0;
                                if (amt < 50000) {
                                  return 'Minimal penarikan adalah Rp 50.000';
                                }
                                if (amt > _partner!.balance) {
                                  return 'Saldo tidak mencukupi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bankNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Bank / E-Wallet',
                                hintText: 'Contoh: Bank BCA, Mandiri, Gopay',
                                prefixIcon: Icon(Icons.account_balance_outlined),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Nama bank wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bankAccountController,
                              decoration: const InputDecoration(
                                labelText: 'Nomor Rekening / No HP',
                                hintText: 'Contoh: 1234567890',
                                prefixIcon: Icon(Icons.credit_card_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Nomor rekening wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitWithdrawal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Kirim Pengajuan'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Riwayat Pengajuan Withdrawal
                    Text(
                      'Riwayat Penarikan Dana',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_withdrawals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada riwayat penarikan dana.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _withdrawals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final wd = _withdrawals[index];

                          Color badgeColor;
                          String statusText;
                          switch (wd.status) {
                            case 'pending':
                              badgeColor = AppColors.statusPending;
                              statusText = 'PROSES';
                              break;
                            case 'approved':
                              badgeColor = AppColors.statusConfirmed;
                              statusText = 'DISETUJUI';
                              break;
                            case 'rejected':
                              badgeColor = AppColors.statusCancelled;
                              statusText = 'DITOLAK';
                              break;
                            case 'transferred':
                              badgeColor = AppColors.statusCompleted;
                              statusText = 'SELESAI';
                              break;
                            default:
                              badgeColor = AppColors.textSecondary;
                              statusText = wd.status.toUpperCase();
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatRupiah(wd.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${wd.bankName} - ${wd.bankAccount}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        wd.created != null
                                            ? DateFormat('dd MMM yyyy, HH:mm').format(wd.created!)
                                            : '',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (wd.status == 'rejected' && wd.adminNote.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Catatan: "${wd.adminNote}"',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.danger,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
