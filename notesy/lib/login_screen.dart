import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, AuthResult, GoogleAuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:notesy/loginanimations.dart';
import 'package:notesy/loginconstants.dart';

/// Login screen.
class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  final _loginForm = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String _errorMessage;
  bool _useEmailSignIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 200,
            child: Stack(
              children: <Widget>[
                Positioned(
                    child: FadeAnimation(
                  1,
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage("assets/loginbackground.png"),
                      ),
                    ),
                  ),
                ))
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FadeAnimation(
                  1,
                  Text(
                    "Hello there, \nwelcome to Notesy!",
                    style: TextStyle(
                      fontSize: 30,
                      color: Color(0xff21254A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                FadeAnimation(
                  1,
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.transparent,
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 12.0),
                        Container(
                          alignment: Alignment.centerLeft,
                          decoration: kBoxDecorationStyle,
                          height: 60.0,
                          child: TextField(
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: Color(0xff21254A),
                              fontFamily: 'OpenSans',
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(top: 14.0),
                              prefixIcon: Icon(
                                Icons.email,
                                color: Color(0xff21254A),
                              ),
                              hintText: 'Enter your Email',
                              hintStyle: kHintTextStyle,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.0),
                        Container(
                          alignment: Alignment.centerLeft,
                          decoration: kBoxDecorationStyle,
                          height: 60.0,
                          child: TextField(
                            obscureText: true,
                            style: TextStyle(
                              color: Color(0xff21254A),
                              fontFamily: 'OpenSans',
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(top: 14.0),
                              prefixIcon: Icon(
                                Icons.vpn_key,
                                color: Color(0xff21254A),
                              ),
                              hintText: 'Enter your Password',
                              hintStyle: kHintTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Center(
                  child: FadeAnimation(
                    1,
                    Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                FadeAnimation(
                  1,
                  Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 60),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Color.fromRGBO(105, 62, 212, 1),
                    ),
                    child: Center(
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                FadeAnimation(
                  1,
                  // Wrap entire Center widget with a GestureDetector then add onTap function. _signInWithGoogle,
                  GestureDetector(
                    onTap: _signInWithGoogle,
                    child: Center(
                      child: Text(
                        "Sign in With Google",
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _signInWithGoogle() async {
    _setLoggingIn();
    String errMsg;

    try {
      final googleUser = await _googleSignIn.signIn();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.getCredential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e, s) {
      debugPrint('google signIn failed: $e. $s');
      errMsg = 'Login failed, please try again later.';
    } finally {
      _setLoggingIn(false, errMsg);
    }
  }

  void _signInWithEmail() async {
    if (_loginForm.currentState?.validate() != true) return;

    FocusScope.of(context).unfocus();
    String errMsg;
    try {
      _setLoggingIn();
      final result =
          await _doEmailSignIn(_emailController.text, _passwordController.text);
      debugPrint('Login result: $result');
    } on PlatformException catch (e) {
      errMsg = e.message;
    } catch (e, s) {
      debugPrint('login failed: $e. $s');
      errMsg = 'Login failed, please try again later.';
    } finally {
      _setLoggingIn(false, errMsg);
    }
  }

  Future<AuthResult> _doEmailSignIn(String email, String password,
          {bool signUp = false}) =>
      (signUp
              ? _auth.createUserWithEmailAndPassword(
                  email: email, password: password)
              : _auth.signInWithEmailAndPassword(
                  email: email, password: password))
          .catchError((e) {
        if (e is PlatformException && e.code == 'ERROR_USER_NOT_FOUND') {
          return _doEmailSignIn(email, password, signUp: true);
        } else {
          throw e;
        }
      });

  void _setLoggingIn([bool loggingIn = true, String errMsg]) {
    if (mounted) {
      setState(() {
        _loggingIn = loggingIn;
        _errorMessage = errMsg;
      });
    }
  }
}
