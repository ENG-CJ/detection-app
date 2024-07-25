import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:online_food_order_app/modals/Transactions.dart';
import 'package:online_food_order_app/pages/cText.dart';
import 'package:online_food_order_app/pages/home.dart';
import 'package:online_food_order_app/storage/local_storage.dart';
import 'package:online_food_order_app/util/button.dart';
// import 'package:online_food_order_app/storage/local_storage.dart';
import 'package:online_food_order_app/util/info_content.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../const/colors.dart';
import '../const/url.dart';
import '../modals/my_orders.dart';
import 'package:date_picker_plus/date_picker_plus.dart';

class Report extends StatefulWidget {
  final Future<void>? Onclireport;
  final Future<void>? onAmount;
  const Report({super.key, this.Onclireport, this.onAmount});

  @override
  State<Report> createState() => _Report();
}

class _Report extends State<Report> {
  String formatAmount(String amount) {
    if (double.parse(amount) >= 1000000000) {
      return '${(double.parse(amount) / 1000000000).toStringAsFixed(2)}B';
    } else if (double.parse(amount) >= 1000000) {
      return '${(double.parse(amount) / 1000000).toStringAsFixed(2)}M';
    } else if (double.parse(amount) >= 1000) {
      return '${(double.parse(amount) / 1000).toStringAsFixed(1)}K';
    } else {
      return double.parse(amount).toStringAsFixed(2);
    }
  }

  bool hasError = false;
  bool isLoadingData = true;
  bool authenticating = false;
  String errorDescr = "";
  List<MyOrders> myOrders = [];
  var dio = Dio();
  Future<void> loadMyOrders(id) async {
    try {
      await Future.delayed(Duration(seconds: 3));
      Response response = await dio.get("$URL/orders/specificOrder/$id");
      if (response.data['status']) {
        print("yes");
        myOrders = (response.data['data'] as List)
            .map((e) => MyOrders.fromJson(e))
            .toList();
        hasError = false;
        isLoadingData = false;
      } else {
        print("no");
        hasError = true;
        isLoadingData = false;
        errorDescr = response.data['description'];
      }

      setState(() {});
    } catch (e) {
      print("no2");
      hasError = true;
      isLoadingData = false;
      errorDescr = e.toString();
      setState(() {});
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    LocalStorage().GetUserKey("id").then((value) {
      userid = value;
    });
    LocalStorage().GetUserKey("email").then((value) {
      userEmail = value;
    });
    GetRecentTransactions().then((value) {});
  }

  Widget builContentBody(List<TransactionController> transactions) {
    if (loadingData) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (hasError)
      return InfoContent(
        description: errorDescr,
        btnText: "Reload",
        click: () {
          GetRecentTransactions();
        },
      );
    if (transactions.length > 0)
      return ListView.separated(
          itemBuilder: (_, index) {
            return buildListOrderCard(transactions[index]);
          },
          separatorBuilder: (_, i) => SizedBox(
                height: 8,
              ),
          itemCount: transactions.length);
    return InfoContent(
      description: "Currently, There are no Reports shown.",
      btnText: "Back",
      click: () {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => Home()), (route) => false);
      },
    );
  }

  void checkNavigationStack(BuildContext context) {
    bool isNotEmpty = Navigator.of(context).canPop();

    if (isNotEmpty) {
      Navigator.pop(context);
    } else {
      return;
    }
  }

  bool loadingData = false;
  var userEmail = "";
  var userid = "";
  var error = "";
  var startDateTime = DateTime(1990, 1, 1);
  var endDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  List<TransactionController> transactions = [];
  Future<void> GetRecentTransactions() async {
    setState(() {
      loadingData = true;
    });
    transactions = [];
    try {
      await Future.delayed(Duration(seconds: 2));

      var data = {
        "action": "GetAllTransactions",
        "email": userEmail,
        "id": userid,
        "start": startDateTime.toString(),
        "end": endDate.toString()
      };
      Response response = await dio.post(URL,
          data: jsonEncode(data),
          options: Options(headers: {"Content-Type": "application/json"}));

      var responseData = response.data;
      print("response is " + responseData);
      if (jsonDecode(responseData)['status']) {
        if (jsonDecode(responseData)['data'].length > 0) {
          (jsonDecode(responseData)['data'] as List).map((e) {
            print(e['amount']);
            transactions.add(TransactionController(
                amount: formatAmount(e['amount'].toString()),
                date: e['date'].toString()));
          }).toList();
        }
        hasError = false;
      } else {
        hasError = true;
        errorDescr = jsonDecode(responseData)['message'];
      }

      loadingData = false;
      setState(() {});
    } catch (e) {
      print(" error $e ");
      loadingData = false;
      hasError = true;
      error = e.toString();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['body-color'],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  InkWell(
                      onTap: () {
                        checkNavigationStack(context);
                      },
                      child: FaIcon(FontAwesomeIcons.arrowLeft)),
                  SizedBox(
                    width: 18,
                  ),
                  Text(
                    "My Reports",
                    style: TextStyle(fontSize: 18, fontFamily: "Poppins Bold"),
                  )
                ],
              ),
            ),
            // SfDateRangePicker(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: CButton(
                    onClick: () async {
                      final range = await showRangePickerDialog(
                          context: context,
                          width: 300,
                          height: 300,
                          slidersColor: Colors.lightBlue,
                          highlightColor: colors['primary'],
                          slidersSize: 20,
                          splashColor: Colors.lightBlueAccent,
                          splashRadius: 40,
                          centerLeadingDate: true,
                          maxDate: DateTime(2030, 1, 1),
                          minDate: DateTime(2024, 1, 1));
                      setState(() {
                        if (range != null) {
                          startDateTime = range.start;
                          endDate = range.end;
                          GetRecentTransactions();
                        }
                      });
                    },
                    widget: Center(
                      child: cText(
                        text: "Generate Report",
                        textStyle: TextStyle(color: Colors.white),
                      ),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date",
                    style: TextStyle(fontSize: 18, fontFamily: "Poppins Bold"),
                  ),
                  Text(
                    "Amount Spending",
                    style: TextStyle(fontSize: 18, fontFamily: "Poppins Bold"),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(child: builContentBody(transactions))
          ],
        ),
      ),
    );
  }

  Widget buildListOrderCard(TransactionController transactionController) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFf0e6e6).withOpacity(1),
                  offset: Offset(2, 4),
                  blurRadius: 11,
                  spreadRadius: 5,
                ),
              ],
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomRight: Radius.circular(14))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transactionController.date.toString(),
                    style: TextStyle(fontSize: 16, fontFamily: "Poppins Bold"),
                  ),
                  // Text(
                  //   order.category,
                  //   style: TextStyle(fontSize: 15, fontFamily: "Poppins Light"),
                  // ),
                ],
              ),
              Text(
                "+ \$" + transactionController.amount.toString(),
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontFamily: "Poppins Bold"),
              )
            ],
          )),
    );
  }
}
