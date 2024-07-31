import 'package:flutter/material.dart';
import 'package:payment_reminder/src/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:payment_reminder/providers/auth_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthScreen extends StatelessWidget {
  final NotificationService notificationService;

  AuthScreen({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: Size(750, 1334),
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MyHeader(
                image: "assets/icons/login.svg",
                textTop: "Welcome to",
                textBottom: "Swavalambi Savings",
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 20.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0.0, 10.0),
                            blurRadius: 15.0,
                          ),
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0.0, -10.0),
                            blurRadius: 10.0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pinkAccent,
                                  Colors.orangeAccent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8.0),
                                topRight: Radius.circular(8.0),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            alignment: Alignment.center,
                            child: TabBar(
                              unselectedLabelColor: Colors.white70,
                              labelColor: Colors.white,
                              indicator: UnderlineTabIndicator(
                                borderSide:
                                    BorderSide(color: Colors.white, width: 4),
                                insets: EdgeInsets.symmetric(horizontal: 40),
                              ),
                              tabs: [
                                Tab(text: 'Login'),
                                Tab(text: 'Register'),
                              ],
                            ),
                          ),
                          Container(
                            height: 400,
                            child: TabBarView(
                              children: [
                                LoginWidget(),
                                RegisterWidget(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

abstract class BaseAuthWidget extends StatefulWidget {
  final bool isLogin;

  BaseAuthWidget({required this.isLogin});

  @override
  _BaseAuthWidgetState createState() => _BaseAuthWidgetState();
}

class _BaseAuthWidgetState extends State<BaseAuthWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(); // Added name controller
  bool _isLoading = false;
  bool passwordInvisible = true;

  void _toggleLoading(bool value) {
    setState(() => _isLoading = value);
  }

  bool _validateInputs() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      return false;
    }
    if (!widget.isLogin && _nameController.text.isEmpty) {
      // Validate name field
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your name')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!widget.isLogin) // Add name field only for registration
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person, color: Colors.pinkAccent),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email, color: Colors.pinkAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.pinkAccent),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: passwordInvisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock, color: Colors.pinkAccent),
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordInvisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      passwordInvisible = !passwordInvisible;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.pinkAccent),
                ),
              ),
            ),
            SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    onPressed: () async {
                      if (_validateInputs()) {
                        _toggleLoading(true);
                        try {
                          if (widget.isLogin) {
                            await authProvider.signInWithEmailPassword(
                                _emailController.text,
                                _passwordController.text);
                            print("Login successful");
                          } else {
                            await authProvider.signUpWithEmailPassword(
                                _emailController.text,
                                _passwordController.text,
                                _nameController
                                    .text); // Include name in registration
                            print("Registration successful");
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '${widget.isLogin ? 'Login' : 'Registration'} Failed: ${e.toString()}')));
                        } finally {
                          _toggleLoading(false);
                        }
                      }
                    },
                    child: Text(
                      widget.isLogin ? 'Login' : 'Register',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class LoginWidget extends BaseAuthWidget {
  LoginWidget() : super(isLogin: true);
}

class RegisterWidget extends BaseAuthWidget {
  RegisterWidget() : super(isLogin: false);
}

class MyHeader extends StatelessWidget {
  final String image;
  final String textTop;
  final String textBottom;

  MyHeader(
      {required this.image, required this.textTop, required this.textBottom});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: MyClipper(),
      child: Container(
        padding: EdgeInsets.only(left: 40, top: 50, right: 20),
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.pinkAccent,
              Colors.orangeAccent,
            ],
          ),
          image: DecorationImage(
            image: AssetImage(image),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 20,
                    child: Text(
                      "$textTop \n$textBottom",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
