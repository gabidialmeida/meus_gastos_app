import 'package:flutter/services.dart';
import 'package:gastos_app/core/constants/app_strings.dart';
import 'package:gastos_app/data/models/expense_model.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetsService {
  static final _scopes = [SheetsApi.spreadsheetsScope];

  Future<SheetsApi> getSheetsApi() async {
    final credentialsJson= await rootBundle.loadString('assets/credentials.json');

    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    final authClient = await clientViaServiceAccount(credentials, _scopes);
    return SheetsApi(authClient);
  }

  Future<void> addExpense(Expense expense) async {
    final sheetsApi = await getSheetsApi();
    
    final valueRange = ValueRange.fromJson({
      'values': [
        [
          expense.date.toIso8601String(),
          expense.description,
          expense.value,
          expense.category,
          expense.subcategory,
          expense.paymentAccount,
        ]
      ],
    });
    
    await sheetsApi.spreadsheets.values.append(
      valueRange,
      spreadsheetId,
      'A1', // Ou a aba específica que você quiser
      valueInputOption: 'USER_ENTERED',
    );
  }
}