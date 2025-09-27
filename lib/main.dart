
---

## 4. `lib/main.dart`
Here’s the **DOM simulator** with:  
- Tap-to-select entry price.  
- Place Buy/Sell Limit.  
- Auto SL/TP with colored markers.  
- Cancel All + Go Flat.  
- Trade log with P&L.  

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const DomSimulatorApp());
}

class DomSimulatorApp extends StatelessWidget {
  const DomSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOM Simulator',
      theme: ThemeData.dark(),
      home: const DomPage(),
    );
  }
}

class DomPage extends StatefulWidget {
  const DomPage({super.key});

  @override
  State<DomPage> createState() => _DomPageState();
}

class _DomPageState extends State<DomPage> {
  final int centerPrice = 100;
  final int priceLevels = 20;
  int? selectedPrice;
  List<Order> activeOrders = [];
  List<Trade> tradeLog = [];

  void placeOrder(bool isBuy) {
    if (selectedPrice == null) return;
    final order = Order(price: selectedPrice!, isBuy: isBuy);

    // Attach TP and SL
    order.takeProfit = isBuy ? order.price + 3 : order.price - 3;
    order.stopLoss = isBuy ? order.price - 2 : order.price + 2;

    setState(() {
      activeOrders.add(order);
    });
  }

  void cancelAll() {
    setState(() {
      activeOrders.clear();
    });
  }

  void goFlat() {
    // Close all trades at market (mid price)
    const midPrice = 100;
    setState(() {
      for (var order in activeOrders) {
        tradeLog.add(Trade(
          entryPrice: order.price,
          exitPrice: midPrice,
          isBuy: order.isBuy,
        ));
      }
      activeOrders.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prices = List.generate(priceLevels, (i) => centerPrice + i - priceLevels ~/ 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DOM Simulator'),
        actions: [
          IconButton(icon: const Icon(Icons.cancel), onPressed: cancelAll),
          IconButton(icon: const Icon(Icons.close), onPressed: goFlat),
        ],
      ),
      body: Row(
        children: [
          // Price Ladder
          Expanded(
            child: ListView.builder(
              itemCount: prices.length,
              itemBuilder: (context, index) {
                final price = prices[index];
                final isSelected = price == selectedPrice;

                final hasOrder = activeOrders.any((o) => o.price == price);
                final order = activeOrders.where((o) => o.price == price).toList();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPrice = price;
                    });
                  },
                  child: Container(
                    height: 40,
                    color: isSelected
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Show TP/SL markers
                        Row(
                          children: [
                            if (order.isNotEmpty)
                              for (var o in order) ...[
                                if (o.takeProfit == price)
                                  Container(width: 10, height: 20, color: Colors.green),
                                if (o.stopLoss == price)
                                  Container(width: 10, height: 20, color: Colors.red),
                              ]
                          ],
                        ),
                        Text('$price'),
                        if (hasOrder)
                          const Icon(Icons.circle, size: 12, color: Colors.orange),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Controls
          SizedBox(
            width: 120,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => placeOrder(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('BUY LIMIT'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => placeOrder(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('SELL LIMIT'),
                ),
              ],
            ),
          ),

          // Trade Log
          Expanded(
            child: ListView(
              children: tradeLog.map((t) {
                final pnl = t.isBuy ? t.exitPrice - t.entryPrice : t.entryPrice - t.exitPrice;
                return ListTile(
                  title: Text('${t.isBuy ? "Buy" : "Sell"} ${t.entryPrice} → ${t.exitPrice}'),
                  trailing: Text('PnL: $pnl'),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

class Order {
  final int price;
  final bool isBuy;
  int? takeProfit;
  int? stopLoss;

  Order({required this.price, required this.isBuy});
}

class Trade {
  final int entryPrice;
  final int exitPrice;
  final bool isBuy;

  Trade({required this.entryPrice, required this.exitPrice, required this.isBuy});
}

