import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ClothApp());
}

class Cloth {
  String type;
  String brand;
  double retailPrice;
  double sellPrice;
  int quantity;

  Cloth(this.type, this.brand, this.retailPrice, this.sellPrice, this.quantity);

  Map<String, dynamic> toJson() => {
    'type': type,
    'brand': brand,
    'retailPrice': retailPrice,
    'sellPrice': sellPrice,
    'quantity': quantity,
  };

  factory Cloth.fromJson(Map<String, dynamic> json) {
    return Cloth(
      json['type'],
      json['brand'],
      json['retailPrice'],
      json['sellPrice'],
      json['quantity'],
    );
  }
}

class Sale {
  String customer;
  String date;
  String type;
  String brand;
  double retailPrice;
  double sellPrice;
  bool isClear;

  Sale(
    this.customer,
    this.date,
    this.type,
    this.brand,
    this.retailPrice,
    this.sellPrice,
    this.isClear,
  );

  Map<String, dynamic> toJson() => {
    'customer': customer,
    'date': date,
    'type': type,
    'brand': brand,
    'retailPrice': retailPrice,
    'sellPrice': sellPrice,
    'isClear': isClear,
  };

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      json['customer'],
      json['date'],
      json['type'],
      json['brand'],
      json['retailPrice'],
      json['sellPrice'],
      json['isClear'],
    );
  }
}

class ClothApp extends StatefulWidget {
  @override
  _ClothAppState createState() => _ClothAppState();
}

class _ClothAppState extends State<ClothApp> {
  List<Cloth> clothes = [];
  List<Sale> sales = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> clothesJson =
        clothes.map((c) => jsonEncode(c.toJson())).toList();
    List<String> salesJson = sales.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList("clothes", clothesJson);
    await prefs.setStringList("sales", salesJson);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? clothesJson = prefs.getStringList("clothes");
    List<String>? salesJson = prefs.getStringList("sales");
    if (clothesJson != null) {
      clothes = clothesJson.map((c) => Cloth.fromJson(jsonDecode(c))).toList();
    }
    if (salesJson != null) {
      sales = salesJson.map((s) => Sale.fromJson(jsonDecode(s))).toList();
    }
    setState(() {});
  }

  double getProfit() {
    return sales
        .where((s) => s.isClear)
        .fold(0, (sum, s) => sum + (s.sellPrice - s.retailPrice));
  }

  int getPendingCount() {
    return sales.where((s) => !s.isClear).length;
  }

  int getClearCount() {
    return sales.where((s) => s.isClear).length;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cloth Manager",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text("Cloth Manager")),
        drawer: Drawer(
          child: Builder(
            builder:
                (drawerContext) => ListView(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text(
                        "Menu",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    ListTile(
                      title: Text("Home"),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        Navigator.of(drawerContext, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder:
                                (_) => HomePage(
                                  getProfit(),
                                  getPendingCount(),
                                  getClearCount(),
                                ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: Text("Inventory"),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        Navigator.of(drawerContext, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    InventoryPage(clothes, saveData, setState),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: Text("Sales"),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        Navigator.of(drawerContext, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder:
                                (_) => SalesPage(
                                  clothes,
                                  sales,
                                  saveData,
                                  setState,
                                ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: Text("Pending"),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        Navigator.of(drawerContext, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder:
                                (_) => PendingPage(sales, saveData, setState),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: Text("Reports"),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        Navigator.of(drawerContext, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => ReportsPage(sales, getProfit()),
                          ),
                        );
                      },
                    ),
                  ],
                ),
          ),
        ),
        body: HomePage(getProfit(), getPendingCount(), getClearCount()),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final double profit;
  final int pending;
  final int clear;

  HomePage(this.profit, this.pending, this.clear);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Profit: Rs $profit"),
          Text("Pending Sales: $pending"),
          Text("Cleared Sales: $clear"),
        ],
      ),
    );
  }
}

class InventoryPage extends StatefulWidget {
  final List<Cloth> clothes;
  final Function saveData;
  final Function refresh;

  InventoryPage(this.clothes, this.saveData, this.refresh);

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final typeController = TextEditingController();
  final brandController = TextEditingController();
  final retailController = TextEditingController();
  final sellController = TextEditingController();
  final qtyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inventory")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Add New Cloth",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: typeController,
                      decoration: InputDecoration(
                        labelText: "Type",
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: brandController,
                      decoration: InputDecoration(
                        labelText: "Brand",
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: retailController,
                      decoration: InputDecoration(
                        labelText: "Retail Price",
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: sellController,
                      decoration: InputDecoration(
                        labelText: "Sell Price",
                        prefixIcon: Icon(Icons.money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: qtyController,
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        prefixIcon: Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text("Add Cloth"),
                        onPressed: () {
                          widget.clothes.add(
                            Cloth(
                              typeController.text,
                              brandController.text,
                              double.parse(retailController.text),
                              double.parse(sellController.text),
                              int.parse(qtyController.text),
                            ),
                          );
                          widget.saveData();
                          widget.refresh(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              "Inventory",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Brand')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Retail Price')),
                    DataColumn(label: Text('Sell Price')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Delete')),
                  ],
                  rows: List.generate(widget.clothes.length, (i) {
                    var c = widget.clothes[i];
                    return DataRow(
                      cells: [
                        DataCell(Text(c.brand)),
                        DataCell(Text(c.type)),
                        DataCell(
                          Text('Rs ${c.retailPrice.toStringAsFixed(2)}'),
                        ),
                        DataCell(Text('Rs ${c.sellPrice.toStringAsFixed(2)}')),
                        DataCell(Text(c.quantity.toString())),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () {
                              setState(() {
                                widget.clothes.removeAt(i);
                              });
                              widget.saveData();
                              widget.refresh(() {});
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesPage extends StatefulWidget {
  final List<Cloth> clothes;
  final List<Sale> sales;
  final Function saveData;
  final Function refresh;

  SalesPage(this.clothes, this.sales, this.saveData, this.refresh);

  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final customerController = TextEditingController();
  final salePriceController = TextEditingController();
  String? selectedBrand;
  String? selectedType;
  bool isClear = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sales")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Add New Sale",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: customerController,
                      decoration: InputDecoration(
                        labelText: "Customer",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Select Brand",
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      value: selectedBrand,
                      onChanged: (val) {
                        setState(() => selectedBrand = val);
                      },
                      items:
                          widget.clothes
                              .map(
                                (c) => DropdownMenuItem(
                                  child: Text("${c.brand} (${c.type})"),
                                  value: c.brand,
                                ),
                              )
                              .toList(),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: salePriceController,
                      decoration: InputDecoration(
                        labelText: "Sale Price (Negotiated)",
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text("Payment Clear"),
                      value: isClear,
                      onChanged: (val) => setState(() => isClear = val!),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add_shopping_cart),
                        label: Text("Add Sale"),
                        onPressed: () {
                          var cloth = widget.clothes.firstWhere(
                            (c) => c.brand == selectedBrand,
                          );
                          double salePrice =
                              double.tryParse(salePriceController.text) ??
                              cloth.sellPrice;
                          widget.sales.add(
                            Sale(
                              customerController.text,
                              DateTime.now().toString(),
                              cloth.type,
                              cloth.brand,
                              cloth.retailPrice,
                              salePrice,
                              isClear,
                            ),
                          );
                          cloth.quantity -= 1;
                          widget.saveData();
                          widget.refresh(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              "Sales List",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Brand')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Retail Price')),
                    DataColumn(label: Text('Sale Price')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows:
                      widget.sales
                          .map(
                            (s) => DataRow(
                              cells: [
                                DataCell(Text(s.customer)),
                                DataCell(Text(s.brand)),
                                DataCell(Text(s.type)),
                                DataCell(
                                  Text(
                                    'Rs ${s.retailPrice.toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Text('Rs ${s.sellPrice.toStringAsFixed(2)}'),
                                ),
                                DataCell(Text(s.date.split(' ').first)),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      s.isClear ? 'Clear' : 'Pending',
                                    ),
                                    backgroundColor:
                                        s.isClear
                                            ? Colors.green[100]
                                            : Colors.orange[100],
                                    labelStyle: TextStyle(
                                      color:
                                          s.isClear
                                              ? Colors.green[900]
                                              : Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingPage extends StatelessWidget {
  final List<Sale> sales;
  final Function saveData;
  final Function refresh;

  PendingPage(this.sales, this.saveData, this.refresh);

  @override
  Widget build(BuildContext context) {
    var pending = sales.where((s) => !s.isClear).toList();
    return Scaffold(
      appBar: AppBar(title: Text("Pending Payments")),
      body: ListView.builder(
        itemCount: pending.length,
        itemBuilder: (ctx, i) {
          var s = pending[i];
          return ListTile(
            title: Text("${s.customer} - ${s.brand}"),
            subtitle: Text("Rs ${s.sellPrice}"),
            trailing: ElevatedButton(
              child: Text("Mark Clear"),
              onPressed: () {
                s.isClear = true;
                saveData();
                refresh(() {});
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  final List<Sale> sales;
  final double profit;

  ReportsPage(this.sales, this.profit);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reports")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              color: Colors.blue[50],
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Profit:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Rs ${profit.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              "All Sales",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Brand')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Retail Price')),
                    DataColumn(label: Text('Sale Price')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows:
                      sales
                          .map(
                            (s) => DataRow(
                              cells: [
                                DataCell(Text(s.customer)),
                                DataCell(Text(s.brand)),
                                DataCell(Text(s.type)),
                                DataCell(
                                  Text(
                                    'Rs ${s.retailPrice.toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Text('Rs ${s.sellPrice.toStringAsFixed(2)}'),
                                ),
                                DataCell(Text(s.date.split(' ').first)),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      s.isClear ? 'Clear' : 'Pending',
                                    ),
                                    backgroundColor:
                                        s.isClear
                                            ? Colors.green[100]
                                            : Colors.orange[100],
                                    labelStyle: TextStyle(
                                      color:
                                          s.isClear
                                              ? Colors.green[900]
                                              : Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
