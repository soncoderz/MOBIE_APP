import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/toast_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  
  // Server validation errors for each field
  Map<String, String?> _serverErrors = {};

  final List<Map<String, String>> _genderOptions = [
    {'value': 'male', 'label': 'Nam'},
    {'value': 'female', 'label': 'Nữ'},
    {'value': 'other', 'label': 'Khác'},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      initialEntryMode: DatePickerEntryMode.input,
      fieldLabelText: 'Ngày/Tháng/Năm',
      fieldHintText: 'dd/mm/yyyy',
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _handleRegister() async {
    // Clear ALL previous server errors at start of each attempt
    setState(() {
      _serverErrors = {};
    });
    
    // Wait for setState to complete before validating
    await Future.delayed(Duration.zero);
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      AppToast.info('Vui lòng đồng ý với điều khoản sử dụng');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    
    // Format dateOfBirth as ISO string if selected
    String? dateOfBirthStr;
    if (_selectedDateOfBirth != null) {
      dateOfBirthStr = _selectedDateOfBirth!.toIso8601String();
    }
    
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      gender: _selectedGender,
      dateOfBirth: dateOfBirthStr,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Registration successful - navigate to login
      AppToast.success('Đăng ký thành công! Bạn có thể đăng nhập ngay.');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context); // Go back to login screen
        }
      });
    } else {
      // Check if there's a field-specific error
      final errorField = authProvider.errorField;
      final errorMessage = authProvider.errorMessage;
      
      if (errorField != null && errorMessage != null) {
        // Set server error for specific field and revalidate form
        setState(() {
          _serverErrors[errorField] = errorMessage;
        });
        _formKey.currentState!.validate();
      } else {
        // Show generic error toast
        AppToast.error(errorMessage ?? 'Đăng ký thất bại');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Điền thông tin để đăng ký',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Full name field
                CustomTextField(
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên đầy đủ',
                  controller: _fullNameController,
                  validator: Validators.validateFullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 20),

                // Email field
                CustomTextField(
                  label: 'Email',
                  hint: 'Nhập email của bạn',
                  controller: _emailController,
                  validator: (value) {
                    // Check server error first
                    if (_serverErrors['email'] != null) {
                      return _serverErrors['email'];
                    }
                    return Validators.validateEmail(value);
                  },
                  onChanged: (_) {
                    // Clear server error when user types
                    if (_serverErrors['email'] != null) {
                      setState(() {
                        _serverErrors.remove('email');
                      });
                    }
                  },
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 20),

                // Phone field (optional)
                CustomTextField(
                  label: 'Số điện thoại (Tùy chọn)',
                  hint: 'Nhập số điện thoại',
                  controller: _phoneController,
                  validator: (value) {
                    // Check server error first
                    if (_serverErrors['phoneNumber'] != null) {
                      return _serverErrors['phoneNumber'];
                    }
                    return Validators.validatePhone(value);
                  },
                  onChanged: (_) {
                    // Clear server error when user types
                    if (_serverErrors['phoneNumber'] != null) {
                      setState(() {
                        _serverErrors.remove('phoneNumber');
                      });
                    }
                  },
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 20),

                // Gender dropdown
                // Gender dropdown (required)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giới tính *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _serverErrors['gender'] != null 
                              ? Colors.red 
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.wc_outlined),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        hint: const Text('Chọn giới tính'),
                        validator: (value) {
                          if (_serverErrors['gender'] != null) {
                            return _serverErrors['gender'];
                          }
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn giới tính';
                          }
                          return null;
                        },
                        items: _genderOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option['value'],
                            child: Text(option['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                            _serverErrors.remove('gender');
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date of Birth picker (required)
                FormField<DateTime>(
                  validator: (value) {
                    if (_serverErrors['dateOfBirth'] != null) {
                      return _serverErrors['dateOfBirth'];
                    }
                    if (_selectedDateOfBirth == null) {
                      return 'Vui lòng chọn ngày sinh';
                    }
                    return null;
                  },
                  builder: (FormFieldState<DateTime> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày sinh *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            await _selectDateOfBirth();
                            state.didChange(_selectedDateOfBirth);
                            // Clear server error when user selects date
                            if (_serverErrors['dateOfBirth'] != null) {
                              setState(() {
                                _serverErrors.remove('dateOfBirth');
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: state.hasError ? Colors.red : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDateOfBirth != null
                                      ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                                      : 'Chọn ngày sinh',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDateOfBirth != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              state.errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Address field (optional)
                CustomTextField(
                  label: 'Địa chỉ (Tùy chọn)',
                  hint: 'Nhập địa chỉ của bạn',
                  controller: _addressController,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  keyboardType: TextInputType.streetAddress,
                ),
                const SizedBox(height: 20),

                // Password field
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 20),

                // Confirm password field
                CustomTextField(
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu',
                  controller: _confirmPasswordController,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 20),

                // Terms and conditions checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: const Text(
                          'Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Register button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Đăng Ký',
                      onPressed: _handleRegister,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
