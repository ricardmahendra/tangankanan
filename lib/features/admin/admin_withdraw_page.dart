import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/withdrawal_model.dart';
import '../admin/admin_repository.dart';

class AdminWithdrawPage extends StatefulWidget {
  const AdminWithdrawPage({super.key});

  @override
  State<AdminWithdrawPage> createState() => _AdminWithdrawPageState();
}

class _AdminWithdrawPageState extends State<AdminWithdrawPage> {
  final _adminRepo = AdminRepository();
  List<WithdrawalModel> _pendingWithdrawals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingWithdrawals();
  }

  Future<void> _loadPendingWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final withdrawals = await _adminRepo.getPendingWithdrawals();
      setState(() => _pendingWithdrawals = withdrawals);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveWithdrawal(String withdrawalId) async {
    try {
      await _adminRepo.approveWithdrawal(withdrawalId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penarikan disetujui')),
        );
      }
      _loadPendingWithdrawals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectWithdrawal(String withdrawalId, String reason) async {
    try {
      await _adminRepo.rejectWithdrawal(withdrawalId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penarikan ditolak')),
        );
      }
      _loadPendingWithdrawals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String withdrawalId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Penarikan'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan penolakan',
            hintText: 'Masukkan alasan penolakan',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _rejectWithdrawal(withdrawalId, reasonController.text);
              Navigator.pop(context);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Penarikan Dana'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingWithdrawals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text('Tidak ada penarikan yang tertunda'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingWithdrawals.length,
                  itemBuilder: (context, index) {
                    final withdrawal = _pendingWithdrawals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header dengan nama mitra
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        withdrawal.mitraName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${withdrawal.id}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    withdrawal.status,
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Details
                            _DetailRow(
                              'Jumlah',
                              _formatCurrency(withdrawal.amount),
                            ),
                            _DetailRow('Bank', withdrawal.bankName),
                            _DetailRow(
                              'No. Rekening',
                              withdrawal.bankAccount,
                            ),
                            _DetailRow(
                              'Tanggal Permintaan',
                              withdrawal.requestedAt
                                  .toString()
                                  .split(' ')[0],
                            ),
                            if (withdrawal.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Catatan:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        withdrawal.note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showRejectDialog(
                                      withdrawal.id,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    child: const Text(
                                      'Tolak',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _approveWithdrawal(withdrawal.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Setujui'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPendingWithdrawals,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.isEmpty ? '-' : value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
