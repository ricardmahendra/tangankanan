import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/location/location_service.dart';
import '../../data/models/order_flow_data.dart';
import '../../data/models/partner_model.dart';
import '../../data/repositories/partner_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';

class PartnerSelectPage extends StatefulWidget {
  final OrderFlowData flowData;

  const PartnerSelectPage({
    super.key,
    required this.flowData,
  });

  @override
  State<PartnerSelectPage> createState() => _PartnerSelectPageState();
}

class _PartnerSelectPageState extends State<PartnerSelectPage> {
  final PartnerRepository _repo = PartnerRepository();
  final LocationService _locationService = LocationService();
  
  bool _isLoading = true;
  String _error = '';
  List<PartnerModel> _partners = [];
  Map<String, List<String>> _partnerSkills = {};
  PartnerModel? _selectedPartner;
  Position? _userPosition;
  Map<String, double> _distances = {};

  @override
  void initState() {
    super.initState();
    _loadPartners();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _userPosition = position;
          _calculateDistances();
        });
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  void _calculateDistances() {
    if (_userPosition == null) return;
    
    _distances = {};
    for (final partner in _partners) {
      if (partner.latitude != null && partner.longitude != null) {
        final distance = _locationService.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          partner.latitude!,
          partner.longitude!,
        );
        _distances[partner.id] = distance;
      }
    }
    
    // Sort partners by distance
    _partners.sort((a, b) {
      final distA = _distances[a.id] ?? double.infinity;
      final distB = _distances[b.id] ?? double.infinity;
      return distA.compareTo(distB);
    });
    
    if (mounted) {
      setState(() {});
    }
  }

  List<String> get _selectedSubcategoryIds => widget.flowData.selectedItems
      .map((item) => item.subcategory.id)
      .toList();

  Future<void> _loadPartners() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
<<<<<<< HEAD
      
      final subcategoryIds = widget.flowData.selectedItems.map((item) => item.subcategory.id).toList();
      final data = await _repo.getAvailablePartnersForSkills(subcategoryIds);
      
      // Fetch skills names map for the partners
      final partnerIds = data.map((p) => p.id).toList();
      final skillsMap = await _repo.getPartnerSkillNamesMap(partnerIds);

=======
      final data = await _repo.getAvailablePartners(
        subcategoryIds: _selectedSubcategoryIds,
      );
>>>>>>> c75ed048dd5667123ebf69bbb69570a529680da8
      setState(() {
        _partners = data;
        _partnerSkills = skillsMap;
        _isLoading = false;
      });
      // Calculate distances after partners are loaded
      _calculateDistances();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onProceed() {
    if (_selectedPartner == null) return;

    final updatedData = widget.flowData.copyWith(
      selectedPartner: _selectedPartner,
    );

    context.push('/order/confirm', extra: updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pilih Mitra'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: _selectedPartner != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPartners,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_partners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada mitra yang tersedia\nuntuk layanan yang Anda pilih.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mitra harus online, terverifikasi, dan memiliki\nsemua keahlian yang sesuai pesanan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _loadPartners,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _partners.length,
      itemBuilder: (context, index) {
        final partner = _partners[index];
        final isSelected = _selectedPartner?.id == partner.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPartner = partner;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: partner.avatar.isNotEmpty
                      ? NetworkImage(partner.avatar) // Would need full URL builder in prod
                      : null,
                  child: partner.avatar.isEmpty
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.warning, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            partner.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${partner.totalJobs} Pekerjaan',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
<<<<<<< HEAD
                      // Standard skills and custom skills display
                      Builder(
                        builder: (context) {
                          final standardSkills = _partnerSkills[partner.id] ?? [];
                          final customSkills = partner.customSkills;
                          final allSkills = [...standardSkills, ...customSkills];
                          
                          if (allSkills.isEmpty) return const SizedBox.shrink();
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                ...standardSkills.map((skill) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )),
                                ...customSkills.map((skill) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          );
                        },
                      ),
=======
                      const SizedBox(height: 4),
                      if (_distances.containsKey(partner.id))
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _locationService.formatDistance(_distances[partner.id]!),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
>>>>>>> c75ed048dd5667123ebf69bbb69570a529680da8
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
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
              'Pilih Mitra Ini',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
