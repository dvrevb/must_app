import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import './success.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './login.dart';
import 'package:must/custom_dialog.dart';
import 'package:must/service/auth.dart';

import 'api/notification_api.dart';
var uuid = const Uuid();
final FirebaseAuth _auth = FirebaseAuth.instance;
final Random random= Random();
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

class InputPage extends StatefulWidget{
  const InputPage({Key? key}) : super(key: key);

  @override
  _InputPageState createState()=> _InputPageState();
}

class _InputPageState extends State<InputPage>{
  double _destinationDay=1;

  AuthService _authService = AuthService();

  final _fs=  FirebaseFirestore.instance;


  TextEditingController nameController = TextEditingController();
  TextEditingController explanationController = TextEditingController();
  TextEditingController destinationDayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //CollectionReference todosRef= _fs.collection('todos');
    //CollectionReference todosRef= _fs.collection('testCollection');
    CollectionReference todosRef= _fs.collection('todos');
    CollectionReference usersRef= _fs.collection('Users');

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("MUST",
          style: GoogleFonts.pacifico(fontSize: 25,color:Colors.white),

        ),
        centerTitle: true,
        actions: <Widget>[
          // First button - decrement
          IconButton(
              icon: const Icon(Icons.logout_outlined), // The "-" icon
              onPressed:() {
                _showDialog(context);
              } // The `_decrementCounter` function
          ),

          // Second button - increment
        ],
      ),
      body:
      Form(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0,0,0,12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: MyContainer(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  [
                    const Text("Hedef Adı",style:TextStyle(
                        color:Colors.black54,fontSize: 20,fontWeight: FontWeight.bold
                    ),
                    ),
                    TextFormField(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      controller: nameController,
                    ),
                  ],
                )
                ),
              ),
              Expanded(
                flex: 2,
                child: MyContainer(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  [
                    const Text("Hedef Açıklaması",style:TextStyle(
                        color:Colors.black54,fontSize: 20,fontWeight: FontWeight.bold
                    ),
                    ),
                    TextFormField(
                      style: const TextStyle(
                          color:Colors.black54,fontSize: 20,fontWeight: FontWeight.bold
                      ),
                      controller: explanationController,
                    ),
                  ],
                )
                ),
              ),
              Expanded(
                flex: 2,
                child: MyContainer(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Hedef Gün",style:TextStyle(
                        color:Colors.black54,fontSize: 20,fontWeight: FontWeight.bold
                    ),
                    ),
                    Text(_destinationDay.round().toString(), style: const TextStyle(
                        color:Colors.lightBlue,fontSize: 25,fontWeight: FontWeight.bold
                    ),
                    ),
                    Slider(
                      thumbColor: Colors.orange,
                      max: 365,
                      min:1,
                      value: _destinationDay,
                      onChanged: (double value){
                        setState(() {
                          _destinationDay = value;

                        });
                      },
                    ),
                  ],
                )
                ),
              ),

              Expanded(
                flex: 1,

                child: TextButton(
                  onPressed: () async{
                    User? user =_auth.currentUser;
                    String userId = user!.uid;
                    var notificationId= getRandomString(28);

                    Map<String, dynamic> toDoData = {
                      'name': nameController.text,
                      'explanation': explanationController.text,
                      'deadline': DateTime.now().add(Duration(days:_destinationDay.toInt())),
                      'user' : userId,
                      'done':false,
                      'notification_id':notificationId
                    };
                    var id=uuid.v4();
                    await todosRef.doc((id)).set(toDoData);


                    await usersRef.doc(userId).update({'todo_list':FieldValue.arrayUnion([id])});

                    //set notification
                    NotificationApi.showScheduledNotification(
                      id: notificationId.hashCode,
                      title: nameController.text,
                      body: explanationController.text,
                      payload: '',
                      scheduledDate: DateTime.now().add(Duration(days:_destinationDay.toInt())),
                    );

                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder:(context)=> SuccessPage()));
                  },
                  child: const Text('Oluştur'),
                  style: ButtonStyle(elevation: MaterialStateProperty.all(2), shape: MaterialStateProperty.all(const CircleBorder()),
                    backgroundColor: MaterialStateProperty.all(Colors.orange), foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
  _showDialog(BuildContext context){

    BlurryDialog  alert = BlurryDialog("Are you sure you want to exit?",(){
      Navigator.of(context).pop();
      _authService.signOut();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder:(context)=> LoginPage()));
    });


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class MyContainer extends StatelessWidget {

  final Color colorUser;
  final Widget child;
  const MyContainer({this.colorUser=Colors.white,required this.child,Key? key}) : super(key: key) ;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)
        ,color: colorUser,
      ),
    );
  }
}
String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(random.nextInt(_chars.length))));