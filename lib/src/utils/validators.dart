class Validators {
  static bool isValidEmail(String email) {
    // Add your email validation logic here
    return email.contains('@');
  }

  static bool isValidPassword(String password) {
    // Add your password validation logic here
    return password.length >= 6;
  }
}
