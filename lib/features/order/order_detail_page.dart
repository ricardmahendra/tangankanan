import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/order_flow_data.dart';
import '../../data/models/address_model.dart';
import '../../data/repositories/address_repository.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderFlowData flowData;

  const OrderDetailPage({
    super.key,
    required this.flowData,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final AddressRepository _addressRepo = AddressRepository();
  
  DateTime? _scheduledAt;
  List<AddressModel> _savedAddresses = [];
  AddressModel? _selectedAddress;
  bool _isLoadingAddresses = true;
  bool _useCustomAddress = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    // Pre-fill if we came back to this page
    if (widget.flowData.address.isNotEmpty) {
      _addressController.text = widget.flowData.address;
      _useCustomAddress = true;
    }
    if (widget.flowData.notes.isNotEmpty) {
      _notesController.text = widget.flowData.notes;
    }
    _scheduledAt = widget.flowData.scheduledAt;
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final userId = pb.authStore.record?.id ?? '';
      if (userId.isNotEmpty) {
        final addresses = await _addressRepo.getAddresses(userId);
        final defaultAddress = await _addressRepo.getDefaultAddress(userId);
        
        if (mounted) {
          setState(() {
            _savedAddresses = addresses;
            _selectedAddress = defaultAddress;
            _isLoadingAddresses = false;
            
            // Auto-select default address if available and no custom address is set
            if (defaultAddress != null && widget.flowData.address.isEmpty) {
              _addressController.text = defaultAddress.address;
              _useCustomAddress = false;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingAddresses = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAddresses = false);
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _onProceed() {
    if (_formKey.currentState!.validate() && _scheduledAt != null) {
      final updatedData = widget.flowData.copyWith(
        address: _addressController.text,
        recipientName: _selectedAddress?.recipientName ?? '',
        recipientPhone: _selectedAddress?.recipientPhone ?? '',
        addressId: _selectedAddress?.id,
        notes: _notesController.text,
        scheduledAt: _scheduledAt,
      );

      context.push('/order/${widget.flowData.category.id}/partners', extra: updatedData);
    } else if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jadwal layanan terlebih dahulu'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(currencyFormat),
              const SizedBox(height: 24),
              const Text(
                'Alamat Pengiriman',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // Saved Addresses Section
              if (!_isLoadingAddresses && _savedAddresses.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Radio button for saved addresses
                      ...List.generate(_savedAddresses.length, (index) {
                        final address = _savedAddresses[index];
                        final isSelected = _selectedAddress?.id == address.id && !_useCustomAddress;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAddress = address;
                              _useCustomAddress = false;
                              _addressController.text = address.address;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: index < _savedAddresses.length - 1
                                  ? const Border(bottom: BorderSide(color: AppColors.border))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Radio<AddressModel>(
                                  value: address,
                                  groupValue: _useCustomAddress ? null : _selectedAddress,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedAddress = value;
                                        _useCustomAddress = false;
                                        _addressController.text = value.address;
                                      });
                                    }
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            address.label,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (address.isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Utama',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address.recipientName,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        address.recipientPhone,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address.address,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      // Custom Address Option
                      InkWell(
                        onTap: () {
                          setState(() {
                            _useCustomAddress = true;
                            _selectedAddress = null;
                            _addressController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _useCustomAddress,
                                onChanged: (value) {
                                  if (value == true) {
                                    setState(() {
                                      _useCustomAddress = true;
                                      _selectedAddress = null;
                                      _addressController.clear();
                                    });
                                  }
                                },
                                activeColor: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Gunakan Alamat Baru',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Custom Address Input
              if (_useCustomAddress || _savedAddresses.isEmpty)
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Jl. Diponegoro No. 12, Jepara',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Alamat tidak boleh kosong' : null,
                ),
              
              if (_savedAddresses.isEmpty && !_isLoadingAddresses)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () => context.push('/profile/addresses'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Alamat Tersimpan'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Jadwal Layanan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _scheduledAt == null
                              ? 'Pilih tanggal & waktu'
                              : DateFormat('dd MMM yyyy, HH:mm').format(_scheduledAt!),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: _scheduledAt == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Catatan (Opsional)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Catatan tambahan untuk mitra...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lanjut Pilih Mitra',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.flowData.category.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: 24),
          ...widget.flowData.selectedItems.map((sel) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${sel.subcategory.name} (x${sel.quantity})',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      ),
                    ),
                    Text(
                      format.format(sel.subtotal),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Estimasi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                format.format(widget.flowData.totalPrice),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
