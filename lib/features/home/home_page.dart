import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/pocketbase/pb.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/category_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _categoryRepo = CategoryRepository();
  final _authRepo = AuthRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<CategoryModel> _categories = [];
  UserModel? _currentUser;

  late AnimationController _bannerAnimController;
  late Animation<double> _bannerAnimation;
  late StreamSubscription _authSubscription;

  @override
  void initState() {
    super.initState();
    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerAnimController,
      curve: Curves.easeOut,
    );
    
    // Dengarkan perubahan state auth (misal: saat foto profil diupdate)
    _authSubscription = pb.authStore.onChange.listen((event) {
      if (mounted) {
        setState(() {
          _currentUser = _authRepo.getCurrentUser();
        });
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _bannerAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _currentUser = _authRepo.getCurrentUser();

    try {
      final categories = await _categoryRepo.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
        _bannerAnimController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _categories = [
            const CategoryModel(id: 'mock_1', name: 'Home Cleaning', isActive: true, order: 1),
            const CategoryModel(id: 'mock_2', name: 'Laundry', isActive: true, order: 2),
            const CategoryModel(id: 'mock_3', name: 'Caregiver', isActive: true, order: 3),
            const CategoryModel(id: 'mock_4', name: 'Household Helper', isActive: true, order: 4),
            const CategoryModel(id: 'mock_5', name: 'Outdoor Maintenance', isActive: true, order: 5),
            const CategoryModel(id: 'mock_6', name: 'Service AC', isActive: true, order: 6),
          ];
        });
        _bannerAnimController.forward();
      }
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cleaning')) return Icons.cleaning_services_rounded;
    if (lower.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (lower.contains('caregiver')) return Icons.favorite_rounded;
    if (lower.contains('household') || lower.contains('helper')) return Icons.handyman_rounded;
    if (lower.contains('outdoor') || lower.contains('grass')) return Icons.grass_rounded;
    if (lower.contains('maintenance')) return Icons.build_rounded;
    return Icons.home_repair_service_rounded;
  }

  Color _getCategoryColor(int index) {
    const colors = [
      Color(0xFF1A5FA8), // primary
      Color(0xFF2E75B6), // primary mid
      Color(0xFF9B59B6), // purple
      Color(0xFF1ABC9C), // teal
      Color(0xFF27AE60), // green
      Color(0xFFE67E22), // orange
    ];
    return colors[index % colors.length];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchBar(),
                  _buildPromoBanner(),
                  _buildCategorySection(),
                  _buildWhyTanganKananSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final name = _currentUser?.name ?? 'Pengguna';
    final firstName = name.split(' ').first;

    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      snap: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E7FCB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, 👋',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(
                              Icons.location_on_rounded,
                              color: Colors.white60,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Jepara, Jawa Tengah',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Notification Bell
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          context.push('/notifications');
                        },
                        icon: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF39C12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      // Beralih ke tab profil (index 3) bisa dilakukan via go_router 
                      // atau dikelola oleh MainPage. Untuk saat ini kita push ke /profile
                      context.push('/profile');
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: _currentUser?.avatar.isNotEmpty == true 
                          ? NetworkImage(_currentUser!.avatar) 
                          : null,
                      child: _currentUser?.avatar.isEmpty ?? true
                          ? Text(
                              firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          showSearch(
            context: context,
            delegate: _CategorySearchDelegate(_categories),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: const [
              Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
              SizedBox(width: 12),
              Text(
                'Cari layanan rumah tangga...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: FadeTransition(
        opacity: _bannerAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(_bannerAnimation),
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Promo otomatis diaplikasikan di halaman checkout!'),
                  duration: Duration(seconds: 3),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5FA8), Color(0xFF2980B9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🎉  Promo Spesial',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Gratis Biaya Layanan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const Text(
                        'untuk 50 pesanan pertama!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pesan sekarang & hemat 12% biaya platform.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Decorative icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 36,
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

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Layanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_categories.length} kategori',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Apa yang bisa kami bantu hari ini?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? _buildCategoryShimmer()
              : _hasError && _categories.isEmpty
                  ? _buildErrorState()
                  : _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final color = _getCategoryColor(index);
        final icon = _getCategoryIcon(category.name);

        return _CategoryCard(
          category: category,
          color: color,
          icon: icon,
          index: index,
          onTap: () => context.push('/order/${category.id}', extra: category),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 52,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tidak dapat memuat kategori',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Periksa koneksi internet Anda',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyTanganKananSection() {
    final features = [
      _FeatureItem(
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF2ECC71),
        title: 'Mitra Terverifikasi',
        subtitle: 'Semua mitra telah melewati verifikasi KTP dan pelatihan SOP',
      ),
      _FeatureItem(
        icon: Icons.price_check_rounded,
        color: const Color(0xFF3498DB),
        title: 'Tarif Transparan',
        subtitle: 'Harga sudah ditampilkan sejak awal, tidak ada biaya tersembunyi',
      ),
      _FeatureItem(
        icon: Icons.timer_rounded,
        color: const Color(0xFF9B59B6),
        title: 'Tepat Waktu',
        subtitle: 'Mitra wajib tiba dalam toleransi ±15 menit dari jadwal',
      ),
      _FeatureItem(
        icon: Icons.star_rounded,
        color: const Color(0xFFF39C12),
        title: 'Berbasis Rating',
        subtitle: 'Rating dan ulasan nyata dari pengguna untuk setiap mitra',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.thumb_up_alt_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mengapa TanganKanan?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...features.asMap().entries.map(
            (entry) => _FeatureCard(
              feature: entry.value,
              index: entry.key,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────
// Widget: Category Card dengan animasi
// ────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final Color color;
  final IconData icon;
  final int index;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.color,
    required this.icon,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.index * 80),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Short display name for the card (max 2 words)
  String _shortName(String name) {
    final parts = name.split(' ');
    if (parts.length <= 2) return name;
    return '${parts[0]}\n${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon circle
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _shortName(widget.category.name),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────
// Data class + Widget: Feature Card
// ────────────────────────────────────────
class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _FeatureCard extends StatefulWidget {
  final _FeatureItem feature;
  final int index;
  const _FeatureCard({required this.feature, required this.index});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    Future.delayed(Duration(milliseconds: 200 + widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.feature.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.feature.icon,
                  color: widget.feature.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feature.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.feature.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────
// Search Delegate untuk Kategori Layanan
// ────────────────────────────────────────
class _CategorySearchDelegate extends SearchDelegate<String?> {
  final List<CategoryModel> categories;

  _CategorySearchDelegate(this.categories);

  @override
  String get searchFieldLabel => 'Cari layanan...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final results = categories.where((c) {
      return c.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('Layanan tidak ditemukan'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final category = results[index];
        return ListTile(
          leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.primary),
          title: Text(category.name),
          onTap: () {
            close(context, null);
            context.push('/order/${category.id}', extra: category);
          },
        );
      },
    );
  }
}
