import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Database',
      home: const OrnekDatabase(),
    );
  }
}

class OrnekDatabase extends StatefulWidget {
  const OrnekDatabase({super.key});

  @override
  State<OrnekDatabase> createState() => _OrnekDatabaseState();
}

class _OrnekDatabaseState extends State<OrnekDatabase> {
  final TextEditingController controller = TextEditingController();
  int? selectedID;
  String ekle = "Yeni bir model ekleyin";
  String duzenle = "Seçili modeli düzenleyin";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 120,
        title: TextField(
          controller: controller,
          decoration: InputDecoration(
            label: Text(selectedID == null ? ekle : duzenle),
            hintText: ekle,
            border: OutlineInputBorder(),
          ),
        ),
      ),
      body: Center(
        child: FutureBuilder<List<MyModel>>(
          future: DatabaseHelper.instance.getDatasFromSQL(),
          builder: (context, AsyncSnapshot<List<MyModel>> snapshot) {
            if (!snapshot.hasData) {
              return Center(child: Text("Loading..."));
            }
            return snapshot.data!.isEmpty
                ? Center(child: Text("Liste Boş"))
                : ListView(
                    children: snapshot.data!.map((myModel) {
                      return Center(
                        child: Card(
                          color: selectedID == myModel.id ? Colors.black : Colors.white,
                          elevation: 5,
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                if (selectedID == myModel.id) {
                                  selectedID = null;
                                  controller.clear();
                                } else {
                                  selectedID = myModel.id;
                                  controller.text = myModel.name;
                                }
                              });
                            },
                            leading: Text(
                              myModel.id.toString(),
                              style: TextStyle(color: selectedID == myModel.id ? Colors.white : Colors.black),
                            ),
                            title: Text(
                              myModel.name,
                              style: TextStyle(color: selectedID == myModel.id ? Colors.white : Colors.black),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: selectedID == myModel.id ? Colors.white : Colors.black),
                              onPressed: () async {
                                String cevap = await DatabaseHelper.instance.delete(myModel.id!);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cevap)));
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String cevap = "";
          if (selectedID != null) {
            cevap = await DatabaseHelper.instance.update(MyModel(id: selectedID, name: controller.text));
          } else {
            cevap = await DatabaseHelper.instance.add(MyModel(name: controller.text));
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cevap)));
          // selectedID != null
          //     ? await DatabaseHelper.instance.update(MyModel(id: selectedID, name: controller.text))
          //     : await DatabaseHelper.instance.add(MyModel(name: controller.text));
          setState(() {
            controller.clear();
            selectedID = null;
          });
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}

class MyModel {
  final int? id;
  final String name;

  MyModel({this.id, required this.name});

  factory MyModel.fromMap(Map<String, dynamic> map) => MyModel(id: map["id"], name: map["name"]);

  Map<String, dynamic> toMap() => {"id": id, "name": name};
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  final String databaseName = "myDB";
  final String name = "name";

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentDirectory = await getApplicationCacheDirectory();
    String path = join(documentDirectory.path, "$databaseName.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE $databaseName(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, $name TEXT)");
  }

  Future<List<MyModel>> getDatasFromSQL() async {
    Database db = await instance.database;
    var myModels = await db.query(databaseName);
    List<MyModel> myModelList = myModels.isNotEmpty ? myModels.map((e) => MyModel.fromMap(e)).toList() : [];
    return myModelList;
  }

  Future<String> add(MyModel myModel) async {
    Database db = await instance.database;
    await db.insert(databaseName, myModel.toMap());
    return "Eklendi";
  }

  Future<String> update(MyModel myModel) async {
    Database db = await instance.database;
    await db.update(databaseName, myModel.toMap(), where: "id = ?", whereArgs: [myModel.id]);
    return "Güncellendi";
  }

  Future<String> delete(int id) async {
    Database db = await instance.database;
    await db.delete(databaseName, where: "id = ?", whereArgs: [id]);
    return "Silindi";
  }
}
