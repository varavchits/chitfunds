import 'package:chitfunds/screens/createbranch.dart';
import 'package:chitfunds/screens/customerreceipt.dart';
import 'package:chitfunds/wigets/customappbar.dart';
import 'package:chitfunds/wigets/customdrawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class receiptListPage extends StatefulWidget {
  const receiptListPage({Key? key}) : super(key: key);

  @override
  _BranchListPageState createState() => _BranchListPageState();
}

class _BranchListPageState extends State<receiptListPage> {
  late Future<List<Map<String, dynamic>>> _branchListFuture;
  List<Map<String, dynamic>> _allBranches = [];
  List<Map<String, dynamic>> _filteredBranches = [];
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> branchNames = [];

  @override
  void initState() {
    super.initState();
    _branchListFuture = fetchBranches();
    _searchController.addListener(() {
      _filterBranches(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchBranches() async {
    const String _baseUrl = 'https://chits.tutytech.in/receipt.php';

    try {
      // Debug: Print the request URL and parameters
      print('Request URL: $_baseUrl');
      print('Request Body: type=select');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'type': 'select'},
      );

      // Debug: Print the response
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as List<dynamic>;

        // Handle missing keys safely
        return responseData.map((branch) {
          return {
            'id': branch['id'] ?? '',
            'customername': branch['customername'] ?? 'Unknown Branch',
            'mobileno': branch['mobileno']?.toString() ?? '0',
            'loanamount': branch['loanamount'] ?? 'N/A',
            'receivedamount': branch['receivedamount'] ?? 'N/A',
            'depositamount': branch['depositamount'] ?? 'N/A',
            'paymenttype': branch['paymenttype'] ?? 'N/A',
            'chequeno': branch['chequeno'] ?? 'N/A',
            'chequedate': branch['chequedate'] ?? 'N/A',
            'bankname': branch['bankname'] ?? 'N/A',
            'remarks': branch['remarks'] ?? 'N/A',
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch branches');
      }
    } catch (e) {
      // Debug: Print the error
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }

  void _filterBranches(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBranches = _allBranches;
      } else {
        _filteredBranches = _allBranches
            .where((branch) => branch['customername']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> deleteBranch(String branchId) async {
    const String _baseUrl = 'https://chits.tutytech.in/branch.php';
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'type': 'delete', 'branchid': branchId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete branch');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> _deleteBranch(String branchId) async {
    try {
      await deleteBranch(branchId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch deleted successfully')),
      );
      _refreshBranchList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting branch: $e')),
      );
    }
  }

  void _refreshBranchList() {
    setState(() {
      _branchListFuture = fetchBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Receipt List',
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: CustomDrawer(branchNames: branchNames),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2), // Shadow position
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Receipts',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Receipt(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Button background color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Add Receipts',
                      style: TextStyle(
                          fontSize: 16.0, color: Colors.white), // Text styling
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              // Fetched data container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2), // Shadow position
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _branchListFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No branches found'));
                    }

                    _allBranches = snapshot.data!;
                    _filteredBranches = _searchController.text.isEmpty
                        ? _allBranches
                        : _filteredBranches;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors
                                .grey[200]!, // Light background for headers
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                'Customer Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(
                                      0xFF4A90E2), // Blue color to match gradient theme
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Mobile No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Loan Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Received Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Deposit Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Payment Type',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cheque No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cheque Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Bank Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Remarks',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          ],
                          rows: _filteredBranches.map((branch) {
                            return DataRow(
                              cells: [
                                DataCell(Text(branch['customername'] ?? 'N/A')),
                                DataCell(Text(branch['mobileno'] ?? '0')),
                                DataCell(Text(branch['loanamount'] ?? 'N/A')),
                                DataCell(
                                    Text(branch['receivedamount'] ?? 'N/A')),
                                DataCell(
                                    Text(branch['depositamount'] ?? 'N/A')),
                                DataCell(Text(branch['paymenttype'] ?? 'N/A')),
                                DataCell(Text(branch['chequeno'] ?? 'N/A')),
                                DataCell(Text(branch['chequedate'] ?? 'N/A')),
                                DataCell(Text(branch['bankname'] ?? 'N/A')),
                                DataCell(Text(branch['remarks'] ?? 'N/A')),
                                DataCell(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Edit feature not implemented'),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteBranch(branch['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: const Color.fromARGB(218, 209, 209, 204),
            padding: const EdgeInsets.all(10.0),
            child: const Text(
              'POWERED BY TUTYTECH',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}