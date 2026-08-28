import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/place_model.dart';
import '../../services/place_service.dart';
import '../../widgets/premium_widgets.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  final _nameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _distCtrl = TextEditingController(text: '2.5');
  final _latCtrl = TextEditingController(text: '17.68');
  final _lngCtrl = TextEditingController(text: '83.20');
  final _ratingCtrl = TextEditingController(text: '4.5');
  final _descCtrl = TextEditingController();
  
  String _selectedType = 'Hidden gem';
  bool _isHiddenGem = true;
  bool _isSubmitting = false;

  // Manage Places list
  List<PlaceModel> _places = [];
  bool _isLoadingPlaces = true;

  final List<String> _categories = [
    'Hidden gem',
    'Cultural',
    'Scenic',
    'Dining',
    'Historic',
    'Adventure'
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadPlaces();
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1) {
        _loadPlaces();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _distCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _ratingCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoadingPlaces = true);
    try {
      final list = await PlaceService.instance.getPlaces();
      if (mounted) {
        setState(() {
          _places = list;
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load places: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final place = PlaceModel(
      placeId: '', // Firebase generates it automatically
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      tag: _tagCtrl.text.trim().isEmpty ? (_isHiddenGem ? 'Gem' : 'Popular') : _tagCtrl.text.trim(),
      distKm: double.tryParse(_distCtrl.text) ?? 2.5,
      lat: double.tryParse(_latCtrl.text) ?? 0.0,
      lng: double.tryParse(_lngCtrl.text) ?? 0.0,
      rating: double.tryParse(_ratingCtrl.text) ?? 4.5,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isHiddenGem: _isHiddenGem,
    );

    try {
      await PlaceService.instance.addPlace(place);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place successfully added! 🎉')),
        );
        _clearForm();
        _tabCtrl.animateTo(1); // Swaps to manage list tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding place: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _tagCtrl.clear();
    _descCtrl.clear();
    _isHiddenGem = true;
    _selectedType = 'Hidden gem';
    _distCtrl.text = '2.5';
    _latCtrl.text = '17.68';
    _lngCtrl.text = '83.20';
    _ratingCtrl.text = '4.5';
  }

  Future<void> _deletePlace(String id) async {
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete offline seed data.')),
      );
      return;
    }

    try {
      await PlaceService.instance.deletePlace(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place deleted successfully.')),
      );
      _loadPlaces();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting place: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.add_location_alt_rounded), text: 'Add Place'),
            Tab(icon: Icon(Icons.edit_location_rounded), text: 'Manage Places'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildAddTab(),
          _buildManageTab(),
        ],
      ),
    );
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Place', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 18),
              
              _buildLabel('Place Name'),
              _buildTextFormField(_nameCtrl, 'e.g. Lotus Pond Viewpoint', (val) => val == null || val.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Type / Category'),
                        _buildDropdown(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Custom Tag'),
                        _buildTextFormField(_tagCtrl, 'e.g. Gem, Popular', null),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Distance (Km)'),
                        _buildTextFormField(_distCtrl, '2.5', (val) => double.tryParse(val ?? '') == null ? 'Invalid value' : null, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Rating (0 - 5.0)'),
                        _buildTextFormField(_ratingCtrl, '4.5', (val) => double.tryParse(val ?? '') == null ? 'Invalid value' : null, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Latitude'),
                        _buildTextFormField(_latCtrl, '17.68', (val) => double.tryParse(val ?? '') == null ? 'Invalid value' : null, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Longitude'),
                        _buildTextFormField(_lngCtrl, '83.20', (val) => double.tryParse(val ?? '') == null ? 'Invalid value' : null, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildLabel('Description'),
              _buildTextFormField(_descCtrl, 'Enter details about this spot...', null, maxLines: 3),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Is it a Hidden Gem?', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  Switch(
                    value: _isHiddenGem,
                    activeThumbColor: AppColors.accent,
                    onChanged: (val) => setState(() => _isHiddenGem = val),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 8,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SUBMIT PLACE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageTab() {
    if (_isLoadingPlaces) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_places.isEmpty) {
      return const Center(
        child: Text('No places registered yet.', style: TextStyle(color: Colors.white70, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        final isSeed = place.placeId.startsWith('p'); // Seed ids start with 'p' like 'p001'
        
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${place.type} · Tag: ${place.tag}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Rating: ${place.rating} ★ · ${place.distKm} km', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                onPressed: isSeed ? null : () => _confirmDelete(place.placeId, place.name),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String hint,
    String? Function(String?)? validator, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          dropdownColor: const Color(0xFF132237),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedType = val ?? _selectedType),
        ),
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132237),
        title: const Text('Delete Place', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$name"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePlace(id);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
