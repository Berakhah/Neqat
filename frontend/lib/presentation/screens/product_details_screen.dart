// import 'package:flutter/material.dart';
// import 'package:frontend/presentation/screens/scanner_screen.dart';

// class ProductDetailsPage extends StatefulWidget {
//   final String productName;
//   final String price;
//   final String description;
//   final String category;
//   final String brand;
//   final String rating;
//   final String barcode;

//   const ProductDetailsPage({
//     super.key,
//     required this.productName,
//     required this.price,
//     required this.description,
//     required this.category,
//     required this.brand,
//     required this.rating,
//     required this.barcode,
//   });

//   @override
//   State<ProductDetailsPage> createState() => _ProductDetailsPageState();
// }

// class _ProductDetailsPageState extends State<ProductDetailsPage> {
//   final List<String> _reviews = [
//     "Great product, highly recommend!",
//     "Good value for the price.",
//     "Could be better, but decent overall.",
//   ];
//   final TextEditingController _reviewController = TextEditingController();

//   void _addReview() {
//     if (_reviewController.text.trim().isNotEmpty) {
//       setState(() {
//         _reviews.add(_reviewController.text.trim());
//         _reviewController.clear();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.grey[200],
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           titleTextStyle: TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//           iconTheme: IconThemeData(color: Colors.black),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//         ),
//       ),
//       home: Scaffold(
//         body: Stack(
//           children: [
//             Column(
//               children: [
//                 Expanded(
//                   child: Container(
//                     color: Colors.grey[200],
//                     padding: const EdgeInsets.all(16.0),
//                     child: SingleChildScrollView(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 80),
//                           Text(
//                             widget.productName,
//                             style: const TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.price,
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.blue,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Barcode',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.barcode,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.black54,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Category',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.category,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.black54,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Brand',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.brand,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.black54,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Rating',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Text(
//                                 widget.rating,
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.black54,
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               const Icon(
//                                 Icons.star,
//                                 color: Colors.amber,
//                                 size: 20,
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Description',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.description,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.black54,
//                             ),
//                           ),
//                           const SizedBox(
//                             height: 150,
//                           ), // Space for bottom content
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 color: Colors.white,
//                 child: SafeArea(
//                   child: Container(
//                     color: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16.0,
//                       vertical: 4.0,
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         IconButton(
//                           icon: const Icon(
//                             Icons.arrow_back,
//                             color: Colors.black,
//                           ),
//                           onPressed: () => Navigator.of(context).pop(),
//                         ),
//                         const Text(
//                           'Product Details',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(width: 48),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             // DraggableScrollableSheet behind the bottom section
//             DraggableScrollableSheet(
//               initialChildSize:
//                   0.15, // Increased to show only Reviews and count
//               minChildSize: 0.15, // Minimum size when collapsed
//               maxChildSize: 1.0, // Full screen height when expanded
//               builder: (context, scrollController) {
//                 return Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(20),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 10,
//                         offset: Offset(0, -2),
//                       ),
//                     ],
//                   ),
//                   child: SingleChildScrollView(
//                     controller: scrollController,
//                     child: Column(
//                       children: [
//                         // Handle bar and Reviews label with count
//                         Column(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const SizedBox(
//                                     width: 48,
//                                   ), // Spacer for alignment
//                                   Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       const Text(
//                                         'Reviews',
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 2,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.blue,
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           '${_reviews.length}',
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(
//                                     width: 48,
//                                   ), // Spacer for alignment
//                                 ],
//                               ),
//                             ),
//                             Divider(
//                               color: Colors.grey[600],
//                               thickness: 2,
//                               height: 0,
//                             ), // Divider added here
//                           ],
//                         ),
//                         // Review list (hidden initially)
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: _reviews.length,
//                           itemBuilder: (context, index) {
//                             return ListTile(
//                               title: Text(
//                                 _reviews[index],
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         // Input for new review (hidden initially)
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: TextField(
//                                   controller: _reviewController,
//                                   decoration: const InputDecoration(
//                                     hintText: 'Write your review...',
//                                     border: OutlineInputBorder(),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.send,
//                                   color: Colors.blue,
//                                 ),
//                                 onPressed: _addReview,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             // Bottom section with Scan Another Product button (in front)
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 color: Colors.white.withOpacity(
//                   0.9,
//                 ), // Slightly transparent to show Reviews behind
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushAndRemoveUntil(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const ScannerPage(),
//                           ),
//                           (route) =>
//                               route.isFirst ||
//                               route.settings.name == '/scanner',
//                         );
//                       },
//                       child: const Text(
//                         'Scan Another Product',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:frontend/features/review/domain/entities/product.dart';
import 'package:frontend/presentation/screens/scanner_screen.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product? product; // Make product nullable

  const ProductDetailsPage({super.key, this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final List<Map<String, String>> _reviews = [
    {
      'name': 'John Doe',
      'comment': 'Great product, highly recommend!',
      'avatar': '',
    },
    {
      'name': 'Jane Smith',
      'comment': 'Good value for the price.',
      'avatar': '',
    },
    {
      'name': 'Alex Brown',
      'comment': 'Could be better, but decent overall.',
      'avatar': '',
    },
  ];
  final TextEditingController _reviewController = TextEditingController();

  void _addReview() {
    if (_reviewController.text.trim().isNotEmpty) {
      setState(() {
        _reviews.add({
          'name': 'Guest User',
          'comment': _reviewController.text.trim(),
          'avatar': '',
        });
        _reviewController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If product is null, show an error message
    if (widget.product == null) {
      return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[200],
        ),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error: Product Not Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerPage(),
                        ),
                        (route) => route.isFirst || route.settings.name == '/scanner',
                      );
                    },
                    child: const Text('Scan Another Product'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If product is not null, proceed with the normal UI
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.product!.imageFrontUrl != null) ...[
                            const SizedBox(height: 86),
                            const Text(
                              'Product Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Center(
                              child: Image.network(
                                widget.product!.imageFrontUrl!,
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 30),
                          const Text(
                            'Product Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            widget.product!.productName ?? 'No Product Name',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product!.categories ?? 'No category available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Brand',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product!.brands ?? 'No brand available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Text(
                              //   widget.product!.rating?.toString() ?? 'Not rated',
                              //   style: const TextStyle(
                              //     fontSize: 16,
                              //     color: Colors.black54,
                              //   ),
                              // ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product!.brands ?? 'No description available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.15,
              maxChildSize: 1.0,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(width: 48),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Reviews',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_reviews.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            Divider(
                              color: Colors.grey[600],
                              thickness: 2,
                              height: 0,
                            ),
                          ],
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(review['avatar']!.isEmpty ? review['name']![0] : ''),
                              ),
                              title: Text(
                                review['name']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                review['comment']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _reviewController,
                                  decoration: const InputDecoration(
                                    hintText: 'Write your review...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.blue,
                                ),
                                onPressed: _addReview,
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScannerPage(),
                          ),
                          (route) => route.isFirst || route.settings.name == '/scanner',
                        );
                      },
                      child: const Text(
                        'Scan Another Product',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}