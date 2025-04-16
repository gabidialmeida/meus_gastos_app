import 'dart:async';
import 'dart:developer';

import 'package:gastos_app/data/models/expense_model.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';

class NotificationExpenseTracker {
  static StreamSubscription<ServiceNotificationEvent>? _subscription;
  static final List<String> _bankPackages = [
    'com.itau',
    'com.bradesco',
    'com.bancointer',
    'com.nubank',
    'com.santander',
    // Adicione outros pacotes de bancos que você usa
  ];

  static Future<bool> initialize() async {
    try {
      // Verificar permissão
      final hasPermission = await NotificationListenerService.isPermissionGranted();
      
      if (!hasPermission) {
        log("Permissão não concedida");
        return false;
      }

      // Iniciar o listener
      _subscription = NotificationListenerService.notificationsStream.listen(_handleNotification);
      
      log("Serviço de notificação inicializado com sucesso");
      return true;
    } catch (e) {
      log("Erro ao inicializar serviço: $e");
      return false;
    }
  }

  static void _handleNotification(ServiceNotificationEvent event) {
    if (_isBankNotification(event)) {
      final expense = _parseExpenseFromNotification(event);
      if (expense != null) {
        log("Novo gasto detectado: ${expense.description} - R\$${expense.value}");
        // Aqui você chamaria: GoogleSheetsService().addExpense(expense, 'SEU_SPREADSHEET_ID');
      }
    }
  }

  static bool _isBankNotification(ServiceNotificationEvent event) {
    return _bankPackages.contains(event.packageName);
  }

  static Expense? _parseExpenseFromNotification(ServiceNotificationEvent event) {
    try {
      final fullText = '${event.title} ${event.content}';
      
      // Expressão regular para valores monetários (R$ 1.234,56)
      final valueRegex = RegExp(r'R\$\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})|\d+,\d{2})');
      final match = valueRegex.firstMatch(fullText);
      
      if (match == null) return null;
      
      final valueStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      final value = double.parse(valueStr);
      
      // Determina se é um débito (gasto) ou crédito
      final isDebit = fullText.toLowerCase().contains('pagamento') || 
                     fullText.toLowerCase().contains('débito') ||
                     fullText.toLowerCase().contains('compra');
      
      return Expense(
        date: DateTime.now(),
        description: event.title ?? "Transação bancária",
        value: isDebit ? value : -value, // Negativo para créditos
        category: 'Bancário',
        subcategory: 'Notificação automática',
        paymentAccount: _identifyBank(event.packageName),
      );
    } catch (e) {
      log('Erro ao processar notificação: $e');
      return null;
    }
  }

  static String _identifyBank(String? packageName) {
    const banks = {
      'com.itau': 'Itaú',
      'com.bradesco': 'Bradesco',
      'com.bancointer': 'Banco Inter',
      'com.nubank': 'Nubank',
      'com.santander': 'Santander',
    };
    return packageName != null ? banks[packageName] ?? 'Banco desconhecido' : 'Não identificado';
  }

  static void dispose() {
    _subscription?.cancel();
  }
}