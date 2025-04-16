import 'dart:async';
import 'dart:developer';
import 'package:notifications/notifications.dart';
import 'package:gastos_app/data/datasources/google_sheets_service.dart';
import 'package:gastos_app/data/models/expense_model.dart';

class NotificationHandler {
  static StreamSubscription<NotificationEvent>? _subscription;
  static Notifications? _notifications;
  static bool _serviceRunning = false;

  static final List<String> _bankPackages = [
    'br.com.intermedium',
    'com.nu.production',
  ];

  static Future<bool> initialize() async {
    try {
      if (_serviceRunning) return true;
      _startNotificationListener();
      _serviceRunning = true;
      log("Serviço de notificação inicializado com sucesso");
      return true;
    } catch (e) {
      log("Erro ao inicializar serviço de notificação: $e");
      _serviceRunning = false;
      return false;
    }
  }

  static void _startNotificationListener() {
    _notifications = Notifications();
    _subscription = _notifications!.notificationStream!.listen(
      _handleNotification,
      onError: (error) {
        log("Erro no stream de notificações: $error");
        _restartListener();
      },
      cancelOnError: false,
    );
  }

  static void _restartListener() async {
    log("Reiniciando listener de notificações...");
    await Future.delayed(const Duration(seconds: 2));
    _startNotificationListener();
  }

  static void _handleNotification(NotificationEvent event) {
    try {
      log("Notificação recebida - Pacote: ${event.packageName}");

      if (!_isBankNotification(event)) return;

      log("Conteúdo da notificação: $event");

      final expense = _parseExpenseFromNotification(event);
      if (expense != null) {
        log(
          "Transação detectada: ${expense.description} - R\$${expense.value}",
        );
        _saveExpense(expense);
      }
    } catch (e) {
      log("Erro ao processar notificação: $e");
    }
  }

  static Future<void> _saveExpense(Expense expense) async {
    try {
      await GoogleSheetsService().addExpense(expense);
      log("Transação salva com sucesso");
    } catch (e) {
      log("Erro ao salvar transação: $e");
    }
  }

  static bool _isBankNotification(NotificationEvent event) {
    final isBank = _bankPackages.contains(event.packageName);
    if (isBank) log("Notificação bancária detectada: ${event.packageName}");
    return isBank;
  }

  static Expense? _parseExpenseFromNotification(NotificationEvent event) {
    try {
      final title = event.title?.toLowerCase() ?? '';
      final message = event.message?.toLowerCase() ?? '';
      final fullText = '$title $message';

      final valueRegex = RegExp(r'r\$ ?(\d{1,3}(?:\.\d{3})*,\d{2})');
      final match = valueRegex.firstMatch(fullText);
      if (match == null) {
        log("Nenhum valor encontrado na notificação");
        return null;
      }

      final valueStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      final value = double.tryParse(valueStr);
      if (value == null) return null;

      final description = _extractDescription(event);

      return Expense(
        date: DateTime.now(),
        description: description,
        value: value,
        category: 'Bancário',
        subcategory: 'Notificação automática',
        paymentAccount: _identifyBank(event.packageName),
      );
    } catch (e) {
      log('Erro ao processar notificação: $e');
      return null;
    }
  }

  static String _extractDescription(NotificationEvent event) {
    final package = event.packageName;
    final message = event.message?.toLowerCase() ?? '';

    if (package == 'com.nu.production') {
      // Nubank
      final lojaRegex = RegExp(
        r'aprovada em ([\w\s&-]+)',
        caseSensitive: false,
      );
      final match = lojaRegex.firstMatch(message);
      if (match != null) return match.group(1)!.trim();
    }

    if (package == 'br.com.intermedium') {
      // Banco Inter
      final lojaRegex = RegExp(
        r'comprar r\$.*? em ([\w\s&-]+)',
        caseSensitive: false,
      );
      final match = lojaRegex.firstMatch(message);
      if (match != null) return match.group(1)!.trim();
    }

    // fallback
    return event.title ?? 'Transação';
  }

  static String _identifyBank(String? packageName) {
    const banks = {
      'br.com.intermedium': 'Banco Inter',
      'com.nu.production': 'Nubank',
    };
    return packageName != null
        ? banks[packageName] ?? 'Banco desconhecido'
        : 'Não identificado';
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _serviceRunning = false;
    log("Serviço de notificação encerrado");
  }
}
