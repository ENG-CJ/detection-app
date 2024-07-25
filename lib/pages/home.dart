import 'dart:convert';

import 'package:cool_alert/cool_alert.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:online_food_order_app/const/colors.dart';
import 'package:online_food_order_app/const/url.dart';
import 'package:online_food_order_app/modals/Transactions.dart';
import 'package:online_food_order_app/modals/foods.dart';
import 'package:online_food_order_app/pages/Login/login_page.dart';
import 'package:online_food_order_app/pages/cText.dart';
import 'package:online_food_order_app/pages/favorites.dart';
import 'package:online_food_order_app/pages/fire_detected.dart';
import 'package:online_food_order_app/pages/my_cart.dart';
import 'package:online_food_order_app/pages/product_lists.dart';
import 'package:online_food_order_app/pages/profile.dart';
import 'package:online_food_order_app/pages/report.dart';
import 'package:online_food_order_app/pages/your_orders.dart';
import 'package:online_food_order_app/storage/local_storage.dart';
import 'package:online_food_order_app/util/button.dart';
import 'package:online_food_order_app/util/food_card.dart';
import 'package:online_food_order_app/util/info_content.dart';
import 'package:snackbar/snackbar.dart';

import '../modals/cateogries.dart';
import '../modals/user.dart';
import 'Menu/nenu.details.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var dio = Dio();

  var isLoading = true;
  var loadingData = true;
  var hasError = true;
  var error = '';
  var userEmail = "";
  var userid = "";

  var loadCategories = true;
  List<Foods> foods = [];
  List<Categories> categories = [];
  var box = Hive.box("cart");
  var favBox = Hive.box("fav");

  void addToCart(Map<String, dynamic> data) {
    try {
      box.add(data);
    } catch (e) {
      print(e);
    }
  }

  void addToFav(Map<String, dynamic> data) {
    try {
      favBox.add(data);
    } catch (e) {
      print(e);
    }
  }

  var username = '';
  int id = 0;
  Future<bool> hasData(name) async {
    var isExist = false;

    try {
      var data = box.keys.map((e) {
        var user = box.get(e);
        return user;
      }).toList();

      var exists = data.where((element) => element['foodName'] == name);
      if (exists.length > 0)
        setState(() {
          isExist = true;
        });
      else
        setState(() {
          isExist = false;
        });
      print("run1");
    } catch (e) {
      setState(() {
        isExist = false;
      });
      print("run2");
    }
    return isExist;
  }

  bool hasFavData(name) {
    var isExist = false;
    try {
      var data = favBox.keys.map((e) {
        var favs = favBox.get(e);
        return favs;
      }).toList();

      var exists = data.where((element) => element['foodName'] == name);
      if (exists.length > 0)
        setState(() {
          isExist = true;
        });
      else
        setState(() {
          isExist = false;
        });
      print("run1");
    } catch (e) {
      setState(() {
        isExist = false;
      });
      print("run2");
    }
    return isExist;
  }

  bool hasFav(name) {
    var isExist = false;
    try {
      var data = favBox.keys.map((e) {
        var favs = favBox.get(e);
        return favs;
      }).toList();

      var exists = data.where((element) => element['foodName'] == name);
      if (exists.length > 0)
        isExist = true;
      else
        isExist = false;
    } catch (e) {
      isExist = false;
    }
    return isExist;
  }

  var amount = "0.0";
  var isDetected = false;
  var messageFire = "";
  Future<void> GetSumAmount() async {
    setState(() {
      loadingData = true;
    });
    try {
      await Future.delayed(Duration(seconds: 2));
      print(userEmail);

      var data = {"action": "SumAmount", "email": userEmail, "id": userid};
      Response response = await dio.post(URL,
          data: jsonEncode(data),
          options: Options(headers: {"Content-Type": "application/json"}));

      var responseData = response.data;

      if (jsonDecode(responseData)['status']) {
        if (jsonDecode(responseData)['data'].length > 0) {
          amount = formatAmount(
              jsonDecode(responseData)['data']['amount'].toString());
        }
        hasError = false;
      } else {
        hasError = true;
        error = responseData['message'];
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

  Future<void> FetchFireDetection() async {
    setState(() {
      loadingData = true;
    });
    try {
      await Future.delayed(Duration(seconds: 2));

      var data = {
        "action": "FlameTodayDetected",
        "date": DateTime.now().toString()
      };
      Response response = await dio.post(URL,
          data: jsonEncode(data),
          options: Options(headers: {"Content-Type": "application/json"}));
      var responseData = response.data;
      isDetected = jsonDecode(responseData)['status'];
      messageFire = jsonDecode(responseData)['message'];
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

  List<TransactionController> transactions = [];
  Future<void> GetRecentTransactions() async {
    setState(() {
      loadingData = true;
    });
    try {
      await Future.delayed(Duration(seconds: 2));

      var data = {
        "action": "GetRecentTransactions",
        "email": userEmail,
        "id": userid
      };
      Response response = await dio.post(URL,
          data: jsonEncode(data),
          options: Options(headers: {"Content-Type": "application/json"}));

      var responseData = response.data;
      print("kkk" + responseData);
      if (jsonDecode(responseData)['status']) {
        if (jsonDecode(responseData)['data'].length > 0) {
          print("inside list");
          (jsonDecode(responseData)['data'] as List).map((e) {
            print(e);
            transactions.add(TransactionController(
                amount: formatAmount(e['amount'].toString()),
                date: e['date'].toString()));
          }).toList();
        }
        hasError = false;
      } else {
        hasError = true;
        error = responseData['message'];
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

  Future<void> getAllCategories() async {
    try {
      Response response = await dio.get("$URL/categories");

      if (response.data['data'].length > 0) {
        categories = (response.data['data'] as List)
            .map((e) => Categories.fromJson(e))
            .toList();
      }
      print("data is $categories");
      loadCategories = false;
      setState(() {});
    } catch (e) {
      print(" error $e ");
      loadCategories = false;
      setState(() {});
    }
  }

  bool currentUserHasData = false;
  User? user;

  @override
  void initState() {
    super.initState();

    FetchFireDetection().then((value) => {});
    GetSumAmount().then((value) {});
    GetRecentTransactions().then((value) {});
    LocalStorage().getCurrentUser().then((value) {
      if (value != null) {
        username = value;
      }
    });
    LocalStorage().GetUserKey("id").then((value) {
      if (value != null) {
        userid = value.toString();
      }
    });
    LocalStorage().GetUserKey("email").then((value) {
      if (value != null) {
        userEmail = value.toString();
      }
    });
  }

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

  Widget _buildCtegoryView(List<Categories> cat) {
    if (cat.length > 0)
      return Padding(
        padding: const EdgeInsets.only(left: 14, right: 10, top: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                // width: 200,
                height: 50,
                child: ListView.separated(
                  itemBuilder: (_, index) {
                    return CButton(
                      onClick: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductList(
                                    category: categories[index].name,
                                  ))),
                      color: colors['primary']!.withAlpha(30),
                      widget: Center(
                          child: Text(
                        categories[index].name,
                        style: TextStyle(
                            color: colors['primary'],
                            fontFamily: "Poppins Medium"),
                      )),
                      width: 160,
                      height: 36,
                      radius: 6,
                    );
                  },
                  separatorBuilder: (_, i) => SizedBox(
                    width: 10,
                  ),
                  itemCount: categories.length,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                ),
              ),
            ],
          ),
        ),
      );
    return Text("No Cateogries Data Found");
  }

  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['body-color'],
      body: index == 0
          ? loadingData
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : hasError
                  ? InfoContent(
                      description: error,
                      btnText: "Reload",
                      click: () {
                        GetSumAmount();
                        GetRecentTransactions();
                      },
                    )
                  : ModalProgressHUD(
                      inAsyncCall: loadingData,
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 14, right: 10, top: 18),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onLongPress: () {
                                          CoolAlert.show(
                                              context: context,
                                              type: CoolAlertType.confirm,
                                              title: "Confirm To Exit?",
                                              confirmBtnText: "Exit",
                                              cancelBtnText: "Return",
                                              onConfirmBtnTap: () {
                                                LocalStorage()
                                                    .clearLocalData()
                                                    .then((value) {
                                                  Navigator.pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (_) =>
                                                              LoginPage()),
                                                      (route) => false);
                                                });
                                              });
                                        },
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => Profile(
                                                        onLoad: () {
                                                          LocalStorage()
                                                              .getCurrentUser()
                                                              .then((value) {
                                                            setState(() {
                                                              if (value != null)
                                                                username =
                                                                    value;
                                                            });
                                                          });
                                                        },
                                                      )));
                                        },
                                        child: CircleAvatar(
                                          radius: 25,
                                          backgroundImage:
                                              AssetImage("asset/avatar.png"),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        username.split(" ")[0],
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontFamily: "Poppins Bold"),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 14, right: 10, top: 18),
                              child: Container(
                                width: double.maxFinite,
                                height: 100,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFFdfdcdc).withOpacity(1),
                                        offset: Offset(0, 0),
                                        blurRadius: 26,
                                        spreadRadius: 3,
                                      ),
                                    ]),
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            cText(
                                                text: "Amount",
                                                textStyle: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: "Poppins Bold",
                                                )),
                                            cText(
                                              text:
                                                  "Amount Spending Since Joined",
                                            ),
                                          ],
                                        ),
                                        cText(
                                            text: "+ ${amount}",
                                            textStyle: TextStyle(
                                              fontSize: 30,
                                              color: Colors.green,
                                              fontFamily: "Poppins Bold",
                                            ))
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(
                                    left: 14, right: 10, top: 18),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Recent Transactions",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: "Poppins Medium"),
                                    ),
                                    InkWell(
                                        // onTap: () => GetRecentTransactions(),
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => Report(
                                                    Onclireport:
                                                        GetRecentTransactions(),
                                                    onAmount: GetSumAmount()))),
                                        child:
                                            FaIcon(FontAwesomeIcons.circleInfo))
                                  ],
                                )),
                            Divider(),
                            Expanded(
                                child: ListView.builder(
                                    itemCount: transactions.length,
                                    itemBuilder: (_, i) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 15, right: 10, top: 9),
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(0xFFdfdcdc)
                                                      .withOpacity(1),
                                                  offset: Offset(0, 0),
                                                  blurRadius: 26,
                                                  spreadRadius: 3,
                                                ),
                                              ]),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  cText(
                                                      text: "Amount",
                                                      textStyle: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "Poppins Bold",
                                                      )),
                                                  cText(
                                                    text:
                                                        "+ \$${transactions[i].amount}",
                                                    textStyle: TextStyle(
                                                        fontSize: 21,
                                                        fontFamily:
                                                            "Poppins Bold",
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 80, 135, 82)),
                                                  )
                                                ],
                                              ),
                                              Divider(),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  cText(
                                                      text: "Date",
                                                      textStyle: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "Poppins Bold",
                                                      )),
                                                  cText(
                                                      text:
                                                          "${transactions[i].date}",
                                                      textStyle: TextStyle(
                                                        fontSize: 16,
                                                        fontFamily:
                                                            "Poppins SemiBold",
                                                      ))
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }))
                          ],
                        ),
                      ),
                    )
          : FireDetected(
              click: () => FetchFireDetection(),
              btnText: "Refetch",
              description: messageFire,
              isFire: isDetected,
            ),
      bottomNavigationBar: CurvedNavigationBar(
        onTap: (newIndex) {
          setState(() {
            index = newIndex;
          });
        },
        index: index,
        color: colors['primary'] as Color,
        backgroundColor: Colors.white,
        buttonBackgroundColor: colors['primary']!.withOpacity(0.74),
        items: [
          Icon(
            Icons.home,
            color: Colors.white,
          ),
          Icon(
            FontAwesomeIcons.fireFlameCurved,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
