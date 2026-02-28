import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/screens/clothing_detail_screen.dart';

class SustainabilityScreen extends StatefulWidget {
  const SustainabilityScreen({super.key});

  @override
  State<SustainabilityScreen> createState() => _SustainabilityScreenState();
}

class _SustainabilityScreenState extends State<SustainabilityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _clothingStream;

  @override
  void initState() {
    super.initState();
    _clothingStream = _firestore.collection('clothing').snapshots();
  }

  // Robust image fetching helper
  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          ),
        );
      } else if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',').last;
        try {
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
          );
        } catch (e) {
          return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image));
        }
      } else {
        try {
          return Image.memory(
            base64Decode(imageUrl),
            fit: BoxFit.cover,
          );
        } catch (e) {
          return Container(color: Colors.grey[200], child: const Icon(Icons.image));
        }
      }
    }
    return Container(color: Colors.grey[200], child: const Icon(Icons.checkroom));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern grey/white/green aesthetic
      appBar: AppBar(
        title: const Text(
          'Sustainability Tracker', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _clothingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final allDocs = snapshot.data?.docs ?? [];
          if (allDocs.isEmpty) {
            return const Center(
              child: Text(
                'No tracking data available.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Process logic
          final now = DateTime.now();
          List<Map<String, dynamic>> neglectedItems = [];
          List<Map<String, dynamic>> bestInvestments = [];
          
          double totalWardrobeValue = 0.0;
          int activeItemsCount = 0;

          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] as String?;
            final wearCount = (data['wear_count'] as num?)?.toInt() ?? 0;
            final lastWornTimestamp = data['last_worn'] as Timestamp?;
            final sustainabilityInfo = data['sustainability_info'] as Map<String, dynamic>? ?? {};
            
            final brand = sustainabilityInfo['brand']?.toString() ?? 'Unknown Brand';
            final currency = sustainabilityInfo['currency']?.toString() ?? '\$';
            final price = (sustainabilityInfo['price'] as num?)?.toDouble() ?? 0.0;
            final purchaseDateStr = sustainabilityInfo['purchase_date'] as String?;

            // CPW Calculation
            double cpw = price;
            if (wearCount > 0) {
              cpw = price / wearCount;
            }

            // Days Since Last Worn Logic
            int daysSinceLastWorn = 365;
            if (lastWornTimestamp != null) {
              final lastWornDate = lastWornTimestamp.toDate();
              daysSinceLastWorn = now.difference(lastWornDate).inDays;
            } else if (purchaseDateStr != null && purchaseDateStr.isNotEmpty) {
              try {
                final purchaseDate = DateTime.parse(purchaseDateStr);
                daysSinceLastWorn = now.difference(purchaseDate).inDays;
              } catch (e) {
                // Ignore parse errors, fallback to 365
              }
            }

            final itemData = Map<String, dynamic>.from(data);
            itemData['id'] = doc.id;
            itemData['ui_brand'] = brand;
            itemData['ui_currency'] = currency;
            itemData['ui_wearCount'] = wearCount;
            itemData['cpw'] = cpw;
            itemData['daysSinceLastWorn'] = daysSinceLastWorn;

            totalWardrobeValue += price;
            if (wearCount > 0 && daysSinceLastWorn <= 180) {
              activeItemsCount++;
            }

            if (daysSinceLastWorn > 180) {
              neglectedItems.add(itemData);
            }

            if (wearCount > 0) {
              bestInvestments.add(itemData);
            }
          }

          final neglectedCount = neglectedItems.length;
          final totalItemsCount = allDocs.length;
          final utilizationPercentage = totalItemsCount > 0 
              ? (activeItemsCount / totalItemsCount) * 100 
              : 0.0;

          // Sort neglected items by days since last worn descending (most neglected first)
          neglectedItems.sort((a, b) => (b['daysSinceLastWorn'] as int).compareTo(a['daysSinceLastWorn'] as int));

          // Sort best investments by CPW ascending (lowest cost per wear first)
          bestInvestments.sort((a, b) => (a['cpw'] as double).compareTo(b['cpw'] as double));
          // Top 5 items
          final topInvestments = bestInvestments.take(5).toList();
          
          // Worst investments by CPW descending (highest cost per wear first)
          final worstInvestments = List<Map<String, dynamic>>.from(bestInvestments)
            ..sort((a, b) => (b['cpw'] as double).compareTo(a['cpw'] as double));
          final topWorstInvestments = worstInvestments.take(5).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card (Doar Statistici Generale)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.eco, size: 48, color: Colors.green),
                        const SizedBox(height: 12),
                        const Text(
                          'Wardrobe Health',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24), // Spațiu mai mare în loc de Divider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Total Value',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${totalWardrobeValue.toStringAsFixed(0)} RON', 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Utilization',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      utilizationPercentage.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold, 
                                        color: utilizationPercentage > 50 ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      '%',
                                      style: TextStyle(
                                        fontSize: 14, 
                                        fontWeight: FontWeight.bold, 
                                        color: utilizationPercentage > 50 ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: totalItemsCount > 0 ? (activeItemsCount / totalItemsCount) : 0,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            color: utilizationPercentage > 50 ? Colors.green : Colors.orange,
                          ),
                        ),
                        // Un mic mesaj de încurajare dacă totul e perfect
                        if (neglectedCount == 0 && totalItemsCount > 0) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Your wardrobe is well utilized! Great job.',
                            style: TextStyle(fontSize: 14, color: Colors.green[700], fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section 1: Consider Donating or Selling
                  if (neglectedItems.isNotEmpty) ...[
                    const Text(
                      'Consider Donating or Selling',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    // AICI AM MUTAT TEXTUL:
                    Text(
                      'You have $neglectedCount neglected items taking up space.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: neglectedItems.length,
                        itemBuilder: (context, index) {
                          final item = neglectedItems[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClothingDetailScreen(itemData: item),
                                ),
                              );
                            },
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: _buildImageWidget(item['imageUrl']),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['ui_brand'],
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Not worn in ${item['daysSinceLastWorn']} days',
                                            style: TextStyle(
                                              fontSize: 10, 
                                              color: Colors.red[800], 
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Section 2: Best Investments
                  if (topInvestments.isNotEmpty) ...[
                    const Text(
                      'Best Investments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: topInvestments.length,
                      itemBuilder: (context, index) {
                        final item = topInvestments[index];
                        final cpwFormatted = '${item['ui_currency']}${(item['cpw'] as double).toStringAsFixed(2)}';
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClothingDetailScreen(itemData: item),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: _buildImageWidget(item['imageUrl']),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['ui_brand'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['ui_wearCount']} total wears',
                                        style: TextStyle(
                                          color: Colors.grey[600], 
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      cpwFormatted,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'CPW',
                                      style: TextStyle(
                                        color: Colors.green[800], 
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 32),

                  // Section 3: Worst Investments
                  if (topWorstInvestments.isNotEmpty) ...[
                    const Text(
                      'Worst Investments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topWorstInvestments.length,
                      itemBuilder: (context, index) {
                        final item = topWorstInvestments[index];
                        final cpwFormatted = '${item['ui_currency']}${(item['cpw'] as double).toStringAsFixed(2)}';
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClothingDetailScreen(itemData: item),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: _buildImageWidget(item['imageUrl']),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['ui_brand'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['ui_wearCount']} total wears',
                                        style: TextStyle(
                                          color: Colors.grey[600], 
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      cpwFormatted,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'CPW',
                                      style: TextStyle(
                                        color: Colors.red[800], 
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}