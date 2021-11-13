import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quiver/async.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(MaterialApp(
    title: 'Countdown',
    home: MainWindow(),
    theme: ThemeData(fontFamily: 'IBM Plex Mono'),
  ));
}

class MainWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: Color(0xFF373052),
              appBar: AppBar(
                elevation: 0.0,
                backgroundColor: Color(0xFF373052),
                title: TabBar(
                  indicatorColor: Colors.transparent,
                  tabs: [
                    Tab(icon: Icon(Icons.timelapse, size: 34.0)),
                    Tab(icon: Icon(Icons.format_list_numbered, size: 34.0)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [TimeText(), LeaderboardWindow()],
              ),
            )));
  }
}

class LeaderboardWindow extends StatefulWidget {
  @override
  _LeaderboardWindow createState() => _LeaderboardWindow();
}

class _LeaderboardWindow extends State<LeaderboardWindow> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Leaderboard.readBoard(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length > 0) {
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.only(left: 10, top: 5, right: 10),
                    child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        child: Container(
                            padding: EdgeInsets.all(15),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "${(index + 1).toString()}.",
                                  style: TextStyle(
                                      fontFamily: "Roboto", fontSize: 24),
                                ),
                                Text(
                                  snapshot.data[index]['name'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Text(
                                  "Čas: ${snapshot.data[index]['time'].toString()}",
                                  style: TextStyle(
                                      fontFamily: "Roboto", fontSize: 16),
                                ),
                                GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.close),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        Leaderboard.removeTime(
                                            snapshot.data[index]['id']);
                                      });
                                    })
                              ],
                            ))),
                  );
                });
          } else {
            return Container(
                alignment: AlignmentDirectional.center,
                child: Text(
                  "Lestvica je prazna!",
                  style: TextStyle(fontSize: 28, color: Colors.white),
                ));
          }
        } else if (snapshot.hasError) {
          return Container(
              alignment: AlignmentDirectional.center,
              child: Text("${snapshot.error}",
                  style: TextStyle(color: Colors.red)));
        } else {
          return Container(
            alignment: AlignmentDirectional.center,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          );
        }
      },
    );
  }
}

class TimeText extends StatefulWidget {
  @override
  _TimeText createState() => _TimeText();
}

class _TimeText extends State<TimeText> {
  int current = 0, start = 1;
  String btnText;
  var btnColor, stream, countdown;
  bool btnState;

  String dropdownValue = 'DEC';

  final textController = TextEditingController();

  _TimeText() {
    changeBtn(true, "Začni!", Colors.green[400]);
  }

  @override
  void dispose() {
    if (stream != null) {
      stream.cancel();
    }
    super.dispose();
  }

  String convertTo(int dec, int sis) {
    if (dec == 0) {
      return "0";
    }

    String out = "";
    int ost;
    while (dec > 0) {
      ost = dec % sis;
      if (ost > 9) {
        ost += 55;
        out = String.fromCharCode(ost) + out;
      } else {
        out = ost.toString() + out;
      }
      dec = dec ~/ sis;
    }

    return out;
  }

  int convertFrom(String num, int sis) {
    if (num == "0") {
      return 0;
    }

    int out = 0;

    int counter = num.length - 1;
    for (int i in num.codeUnits) {
      if (i >= 65 && i <= 90) {
        i -= 55;
      } else {
        i -= 48;
      }
      out += i * pow(sis, counter);
      counter--;
    }

    return out;
  }

  void startTimer() {
    if (textController.text != null) {
      var num;
      switch (dropdownValue) {
        case "DEC":
          num = int.parse(textController.text);
          break;
        case "BIN":
          num = convertFrom(textController.text, 2);
          break;
        case "OCT":
          num = convertFrom(textController.text, 8);
          break;
        case "HEX":
          num = convertFrom(textController.text, 16);
          break;
      }
      current = start = num;
      textController.clear();

      countdown = new CountdownTimer(
        new Duration(seconds: start),
        new Duration(seconds: 1),
      );

      stream = countdown.listen(null); // Subscribe to timer stream
      stream.onData((duration) {
        setState(() {
          current = start - duration.elapsed.inSeconds;
        });
      });

      stream.onDone(() {
        stream.cancel();
        changeBtn(true, "Začni!", Colors.green[400]);
      });

      setState(() {});
    }
  }

  void changeBtn(bool state, String text, var color) {
    btnState = state;
    btnText = text;
    btnColor = color;
  }

  void showRes() {
    int res = start - current;

    String konc = "";
    switch (res) {
      case 1:
        konc += "o";
        break;
      case 2:
        konc += "i";
        break;
      case 3:
      case 4:
        konc += "e";
        break;
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Dosežen rezultat",
              style: TextStyle(fontFamily: "Roboto"),
            ),
            content: StatefulBuilder(builder: (context, setState) {
              return IntrinsicHeight(
                  child: Column(
                children: <Widget>[
                  Text(
                    "Deaktivacija je trajala $res sekund$konc.",
                    style: TextStyle(fontFamily: "Roboto"),
                  ),
                  TextField(
                      controller: textController,
                      keyboardType: TextInputType.text,
                      style: TextStyle(fontFamily: "Roboto"),
                      decoration: InputDecoration(
                        labelText: 'Vzdevek',
                      ))
                ],
              ));
            }),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "Objavi",
                  style: TextStyle(fontFamily: "Roboto"),
                ),
                onPressed: () {
                  Leaderboard.addTime(textController.text, res);
                  textController.clear();
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void showInput() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  "Vnesite preostali čas",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                  ),
                ),
                content: Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                        controller: textController,
                        keyboardType: TextInputType.text,
                        style: TextStyle(fontFamily: "Roboto"),
                        decoration: InputDecoration(
                          labelText: 'Sekunde',
                        ),
                        onSubmitted: (val) {
                          Navigator.of(context).pop();
                          startTimer();
                          changeBtn(false, "Ustavi", Colors.red[400]);
                        },
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20, left: 10),
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        onChanged: (String newValue) {
                          setState(() {
                            changeBtn(btnState, newValue, btnColor);
                            dropdownValue = newValue;
                          });
                        },
                        items: <String>['DEC', 'BIN', 'OCT', 'HEX']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(
                                    fontSize: 20, fontFamily: "Roboto")),
                          );
                        }).toList(),
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text(
                      "Začni",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      startTimer();
                      changeBtn(false, "Ustavi", Colors.red[400]);
                    },
                  )
                ],
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(
        child: Center(
            child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("DEC: " + current.toString(),
                    style: TextStyle(
                        fontSize: 34.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text("BIN: " + convertTo(current, 2),
                    style: TextStyle(
                        fontSize: 34.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text("OCT: " + convertTo(current, 8),
                    style: TextStyle(
                        fontSize: 34.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text("HEX: " + convertTo(current, 16),
                    style: TextStyle(
                        fontSize: 34.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            Transform.rotate(
              angle: 5 * pi / 4,
              child: Container(
                height: 300,
                width: 300,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  value: 0.75,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF322A40)),
                ),
              ),
            ),
            Transform.rotate(
              angle: 5 * pi / 4,
              child: Container(
                height: 300,
                width: 300,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  value: (1 - current / start) * 0.75,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF857CF0)),
                ),
              ),
            )
          ],
        )),
      ),
      Container(
        padding: EdgeInsets.only(top: 5.0, left: 5.0, right: 5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
          child: Container(
            height: 100.0,
            color: Colors.white,
            padding: EdgeInsets.only(
                top: 20.0, left: 10.0, right: 10.0, bottom: 10.0),
            child: Column(
              children: <Widget>[
                Container(
                  child: ButtonTheme(
                    minWidth: double.infinity,
                    height: 60.0,
                    child: FlatButton(
                      onPressed: () {
                        setState(() {
                          if (btnState) {
                            showInput();
                          } else {
                            stream.cancel();
                            countdown.cancel();
                            showRes();
                            changeBtn(true, "Začni!", Colors.green[400]);
                          }
                        });
                      },
                      child: Text(
                        btnText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.0)),
                      color: btnColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    ]);
  }
}

class Leaderboard {
  static createDatabase() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = path.join(databasesPath, 'leaderboard.db');

    var database =
        await openDatabase(dbPath, version: 1, onCreate: createTable);
    return database;
  }

  static createTable(Database database, int version) async {
    await database.execute("CREATE TABLE Time ("
        "id INTEGER PRIMARY KEY,"
        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "name TEXT,"
        "time INTEGER"
        ")");
  }

  static addTime(String name, int time) async {
    var db = await createDatabase();
    await db.transaction((txn) async {
      var result = await txn.rawInsert(
        "INSERT INTO Time (name, time) VALUES ('$name', $time)",
      );
      return result;
    });
  }

  static removeTime(int id) async {
    var db = await createDatabase();
    var result = await db.rawQuery("DELETE FROM Time WHERE id=$id");
    return result;
  }

  static Future<List> readBoard() async {
    var db = await createDatabase();
    var result = await db.rawQuery('SELECT * FROM Time ORDER BY time ASC');
    return result.toList();
  }
}
