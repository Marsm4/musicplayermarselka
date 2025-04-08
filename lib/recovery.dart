import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marselkaplaer/database/auth.dart';

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    AuthService authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: Text("Восстановление пароля",
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () {
            Navigator.popAndPushNamed(context, '/auth');
          },
          icon: Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: emailController,
                  cursorColor: Colors.white,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: Colors.white),
                    suffixIcon: IconButton(
                      onPressed: () async {
                        if (emailController.text.isEmpty) {
                          print("Поле пустое");
                        } else {
                          await authService
                              .recoveryPassword(emailController.text);
                          emailController.clear();
                        }
                      },
                      icon: Icon(Icons.send, color: Colors.white),
                    ),
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Text(
                "Для восстановления доступа к своему аккаунту, пожалуйста, введите свою почту",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
