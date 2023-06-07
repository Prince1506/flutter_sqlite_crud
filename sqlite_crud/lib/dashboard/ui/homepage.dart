import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqlite_crud/constants/app_constants.dart';
import 'package:sqlite_crud/constants/sq_lite_constants.dart';
import 'package:sqlite_crud/constants/sq_lite_crud_constants.dart';
import 'package:sqlite_crud/db/helper/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All data
  List<Map<String, dynamic>> listItems = [];
  final formKey = GlobalKey<FormState>();

  bool _isLoading = true;

  // This function is used to fetch all data from the database
  void _refreshData() async {
    final items = await DatabaseHelper.getItems();
    setState(() {
      listItems = items;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    if (!isPlatformWeb()) {
      _refreshData(); // Loading the data when the app starts
    } else {
      _isLoading = false;
    }
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void showMyForm(int? id) async {
    // id == null -> create new item
    // id != null -> update an existing item
    if (id != null) {
      if (isPlatformWeb()) {
        final existingData = listItems
            .firstWhere((element) => element[SqLiteConstants.TABLE_ID] == id);
        _titleController.text = existingData[SqLiteConstants.TABLE_TITLE];
        _descriptionController.text =
            existingData[SqLiteConstants.TABLE_DESCRIPTION];
      } else {
        final existingData = listItems
            .firstWhere((element) => element[SqLiteConstants.TABLE_ID] == id);
        _titleController.text = existingData[SqLiteConstants.TABLE_TITLE];
        _descriptionController.text =
            existingData[SqLiteConstants.TABLE_DESCRIPTION];
      }
    } else {
      _titleController.text = "";
      _descriptionController.text = "";
    }

    showCreateMenu(id);
  }

  void showCreateMenu(int? id) {
    showModalBottomSheet(
        context: context,
        elevation: 5,
        isDismissible: false,
        isScrollControlled: true,
        builder: (_) => Container(
            padding: EdgeInsets.only(
              top: 15,
              left: 15,
              right: 15,
              // prevent the soft keyboard from covering the text fields
              bottom: MediaQuery.of(context).viewInsets.bottom + 120,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    controller: _titleController,
                    validator: formValidator,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    validator: formValidator,
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        hintText: AppConstants.DESCRIPTION_HINT),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Exit")),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            if (isPlatformWeb()) {
                              await addItemToListLocally();
                            } else {
                              if (id != null) {
                                await updateItemInDb(id);
                              } else {
                                await addItemToDb();
                              }
                            }

                            // Clear the text fields
                            setState(() {
                              _titleController.text = '';
                              _descriptionController.text = '';
                            });

                            // Close the bottom sheet
                            Navigator.pop(context);
                          }
                          // Save new data
                        },
                        child: Text(id == null
                            ? SQLiteCrudConstants.buttonCreateNew
                            : SQLiteCrudConstants.buttonUpdate),
                      ),
                    ],
                  )
                ],
              ),
            )));
  }

  bool isPlatformWeb() {
    return defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.fuchsia;
  }

  String? formValidator(String? value) {
    if (value!.isEmpty) return 'Field is Required';
    return null;
  }

  // Insert a new data to the database
  Future<void> addItemToListLocally() async {
    var titleText = _titleController.text;
    var descriptiveText = _descriptionController.text;
    Map<String, dynamic> item = {
      SqLiteConstants.TABLE_TITLE: titleText,
      SqLiteConstants.TABLE_DESCRIPTION: descriptiveText
    };
    listItems.add(item);
  }

// Insert a new data to the database
  Future<void> addItemToDb() async {
    await DatabaseHelper.createItem(
        _titleController.text, _descriptionController.text);
    _refreshData();
  }

  // Update an existing data
  Future<void> updateItemInDb(int id) async {
    await DatabaseHelper.updateItem(
        id, _titleController.text, _descriptionController.text);
    _refreshData();
  }

  // Delete an item
  void deleteItemFromDb(int id) async {
    await DatabaseHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Successfully deleted!'), backgroundColor: Colors.green));
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.APP_NAME),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : listItems.isEmpty
              ? const Center(child: Text(AppConstants.DB_ERROR))
              : ListView.builder(
                  itemCount: listItems.length,
                  itemBuilder: (context, index) => Card(
                    color: index % 2 == 0 ? Colors.green : Colors.green[200],
                    margin: const EdgeInsets.all(15),
                    child: ListTile(
                        title:
                            Text(listItems[index][SqLiteConstants.TABLE_TITLE]),
                        subtitle: Text(listItems[index]
                            [SqLiteConstants.TABLE_DESCRIPTION]),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              isPlatformWeb()
                                  ? Container()
                                  : IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => showMyForm(
                                          listItems[index]
                                              [SqLiteConstants.TABLE_ID]),
                                    ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => isPlatformWeb()
                                    ? deleteItemFromList(index)
                                    : deleteItemFromDb(listItems[index]
                                        [SqLiteConstants.TABLE_ID]),
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showMyForm(null),
      ),
    );
  }

  deleteItemFromList(int itemIndex) {
    if (listItems.length > itemIndex) {
      setState(() {
        listItems.removeAt(itemIndex);
      });
    }
  }
}
