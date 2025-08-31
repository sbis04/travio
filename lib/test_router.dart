import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Simple test to verify GoRouter is working
void testRouting(BuildContext context) {
  print('🔗 Testing GoRouter functionality...');

  // Test navigation to about page
  print('🔗 Attempting to navigate to /about');
  context.go('/about');

  // Test navigation to contact page
  Future.delayed(const Duration(seconds: 2), () {
    print('🔗 Attempting to navigate to /contact');
    context.go('/contact');
  });

  // Test navigation back to home
  Future.delayed(const Duration(seconds: 4), () {
    print('🔗 Attempting to navigate to /');
    context.go('/');
  });
}
