import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/queue_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();

  String _selectedDoctor = kDoctorsList.first;
  PaperStatus _paperStatus = PaperStatus.ready;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<QueueProvider>(context, listen: false);

    setState(() => _isSubmitting = true);

    final response = await provider.addStudent(
      name: _nameController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      doctor: _selectedDoctor,
      paperStatus: _paperStatus,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (response.success) {
      _nameController.clear();
      _nationalIdController.clear();
      setState(() {
        _paperStatus = PaperStatus.ready;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('تم تسجيل الطالب بنجاح في نظام الطابور!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.how_to_reg_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسجيل طالب جديد',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'إضافة الطالب إلى طابور الانتظار وتحديد حالة الأوراق',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // 1. Student Name Input
                    const Text(
                      'اسم الطالب الرباعي *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'أدخل اسم الطالب...',
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم الطالب';
                        }
                        if (value.trim().length < 3) {
                          return 'الاسم قصير جداً';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'الرقم القومي *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nationalIdController,
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                      decoration: InputDecoration(
                        hintText: 'أدخل الرقم القومي المكون من 14 رقمًا',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        final nationalId = value?.trim() ?? '';
                        if (nationalId.isEmpty) return 'يرجى إدخال الرقم القومي';
                        if (!RegExp(r'^\d{14}$').hasMatch(nationalId)) {
                          return 'الرقم القومي يجب أن يتكون من 14 رقمًا';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // 2. Doctor Selector Dropdown
                    const Text(
                      'الدكتور / المشرف الأكاديمي *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDoctor,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.badge_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: kDoctorsList.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc,
                          child: Text(
                            doc,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDoctor = val);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // 3. Paper Status Selector (Radio / Toggle)
                    const Text(
                      'حالة أوراق الطالب *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          RadioListTile<PaperStatus>(
                            title: Row(
                              children: const [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('أوراق مكتملة وجاهزة (READY)'),
                              ],
                            ),
                            subtitle: const Text('سيتم إضافة الطالب مباشرة إلى قائمة الانتظار (WAITING)'),
                            value: PaperStatus.ready,
                            groupValue: _paperStatus,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              if (val != null) setState(() => _paperStatus = val);
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<PaperStatus>(
                            title: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Text('أوراق ناقصة / معلقة (PENDING)'),
                              ],
                            ),
                            subtitle: const Text('سيتم تعليق الطابور حتى استكمال الأوراق (PENDING_PAPERS)'),
                            value: PaperStatus.pending,
                            groupValue: _paperStatus,
                            activeColor: Colors.amber.shade800,
                            onChanged: (val) {
                              if (val != null) setState(() => _paperStatus = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitRegistration,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting ? 'جاري التسجيل...' : 'تسجيل الطالب الآن',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
