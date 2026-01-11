import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'navigation_service.dart';

/// Deep Link Service - Handles incoming deep links for payment callbacks
/// 
/// This service listens for deep links with scheme 'hospitalapp://'
/// and routes them to appropriate screens, particularly for MoMo payment callbacks.
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // Callback for payment result
  Function(String orderId, String resultCode, String? message)? onPaymentResult;
  String? _lastPaymentResultKey;
  DateTime? _lastPaymentResultAt;
  static const Duration _paymentResultDedupeWindow = Duration(minutes: 5);

  /// Initialize the deep link service
  Future<void> init() async {
    _appLinks = AppLinks();

    // Handle initial link if app was opened from a deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 Initial deep link: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for incoming deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Received deep link: $uri');
        _handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('Processing deep link: $uri');
    debugPrint('Scheme: ${uri.scheme}');
    debugPrint('Host: ${uri.host}');
    debugPrint('Path: ${uri.path}');
    debugPrint('Query params: ${uri.queryParameters}');

    // Handle MoMo payment callback
    // Expected format: hospitalapp://payment/result?orderId=xxx&resultCode=0&message=xxx
    if (uri.scheme == 'hospitalapp') {
      if (uri.host == 'payment' || uri.path.contains('payment')) {
        final orderId = uri.queryParameters['orderId'] ?? '';
        final resultCode = uri.queryParameters['resultCode'] ?? '';
        final message = uri.queryParameters['message'];

        debugPrint('🎉 MoMo payment callback received!');
        debugPrint('Order ID: $orderId');
        debugPrint('Result Code: $resultCode');
        debugPrint('Message: $message');

        if (_isDuplicatePaymentResult(orderId, resultCode, message)) {
          debugPrint('Payment result already handled, skipping dialog.');
          return;
        }

        // Trigger callback if registered
        if (onPaymentResult != null) {
          onPaymentResult!(orderId, resultCode, message);
          return;
        }

        // Also try to navigate to show result
        _showPaymentResult(orderId, resultCode, message);
      }
    }
  }

  /// Show payment result dialog
  void _showPaymentResult(String orderId, String resultCode, String? message) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    final isSuccess = resultCode == '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại',
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSuccess)
              const Text('Thanh toán MoMo của bạn đã được xử lý thành công.')
            else
              Text('Mã lỗi: $resultCode\n${message ?? 'Vui lòng thử lại.'}'),
            const SizedBox(height: 8),
            Text(
              'Mã đơn: $orderId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Pop back to appointment detail or billing screen
              Navigator.of(context).popUntil((route) {
                return route.isFirst || 
                       route.settings.name == '/appointment-detail' ||
                       route.settings.name == '/appointments';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.blue,
            ),
            child: Text(
              isSuccess ? 'Hoàn tất' : 'Đóng',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Register payment result callback
  void registerPaymentCallback(
    Function(String orderId, String resultCode, String? message) callback,
  ) {
    onPaymentResult = callback;
  }

  void markPaymentHandled(String orderId, String resultCode, {String? message}) {
    final key = _buildPaymentResultKey(orderId, resultCode, message);
    _lastPaymentResultKey = key;
    _lastPaymentResultAt = DateTime.now();
  }

  /// Unregister payment result callback
  void unregisterPaymentCallback() {
    onPaymentResult = null;
  }

  bool _isDuplicatePaymentResult(
    String orderId,
    String resultCode,
    String? message,
  ) {
    final key = _buildPaymentResultKey(orderId, resultCode, message);
    final now = DateTime.now();
    if (_lastPaymentResultKey == key &&
        _lastPaymentResultAt != null &&
        now.difference(_lastPaymentResultAt!) <= _paymentResultDedupeWindow) {
      return true;
    }
    _lastPaymentResultKey = key;
    _lastPaymentResultAt = now;
    return false;
  }

  String _buildPaymentResultKey(
    String orderId,
    String resultCode,
    String? message,
  ) {
    if (orderId.isNotEmpty) {
      return '$orderId:$resultCode';
    }
    final messageKey = (message ?? '').trim();
    return '${resultCode}:${messageKey.isNotEmpty ? messageKey : 'no-order'}';
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    onPaymentResult = null;
  }
}
