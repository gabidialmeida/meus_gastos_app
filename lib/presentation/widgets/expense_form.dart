import 'package:flutter/material.dart';
import 'package:gastos_app/data/datasources/google_sheets_service.dart';
import 'package:gastos_app/data/models/expense_model.dart';
import 'package:intl/intl.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _expense = Expense(
    date: DateTime.now(),
    description: '',
    value: 0,
    category: 'Outros',
    subcategory: '',
    paymentAccount: 'Dinheiro',
  );

  final List<String> _categories = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Lazer',
    'Saúde',
    'Educação',
    'Outros'
  ];

  final Map<String, List<String>> _subcategories = {
    'Alimentação': ['Supermercado', 'Restaurante', 'Lanches', 'Delivery'],
    'Transporte': ['Combustível', 'Ônibus', 'Metrô', 'Táxi', 'Uber'],
    'Moradia': ['Aluguel', 'Condomínio', 'Conta de Luz', 'Água', 'Internet'],
    'Lazer': ['Cinema', 'Parque', 'Viagem', 'Hobby'],
    'Saúde': ['Plano de Saúde', 'Médico', 'Remédios', 'Academia'],
    'Educação': ['Curso', 'Livro', 'Material Escolar'],
    'Outros': ['Presente', 'Doação', 'Outros']
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Campo de Data
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_expense.date)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expense.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _expense.date = date);
                }
              },
            ),
            
            // Campo de Descrição
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descrição',
                icon: Icon(Icons.description),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Informe uma descrição' : null,
              onSaved: (value) => _expense.description = value!,
            ),
            
            // Campo de Valor
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                icon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value!.isEmpty ? 'Informe um valor' : null,
              onSaved: (value) => _expense.value = double.parse(value!),
            ),
            
            // Campo de Categoria
            DropdownButtonFormField<String>(
              value: _expense.category,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                icon: Icon(Icons.category),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _expense.category = value!;
                  _expense.subcategory = _subcategories[value]!.first;
                });
              },
            ),
            
            // Campo de Subcategoria
            DropdownButtonFormField<String>(
              value: _expense.subcategory.isEmpty
                  ? _subcategories[_expense.category]!.first
                  : _expense.subcategory,
              decoration: const InputDecoration(
                labelText: 'Subcategoria',
                icon: Icon(Icons.list),
              ),
              items: _subcategories[_expense.category]!.map((String subcategory) {
                return DropdownMenuItem<String>(
                  value: subcategory,
                  child: Text(subcategory),
                );
              }).toList(),
              onChanged: (value) => _expense.subcategory = value!,
            ),
            
            // Campo de Conta de Pagamento
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Conta de Pagamento',
                icon: Icon(Icons.account_balance_wallet),
              ),
              initialValue: _expense.paymentAccount,
              validator: (value) =>
                  value!.isEmpty ? 'Informe a conta de pagamento' : null,
              onSaved: (value) => _expense.paymentAccount = value!,
            ),
            
            const SizedBox(height: 20),
            
            // Botão de Salvar
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Salvar Gasto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        await GoogleSheetsService().addExpense(_expense);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto salvo com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar gasto: $e')),
        );
      }
    }
  }
}