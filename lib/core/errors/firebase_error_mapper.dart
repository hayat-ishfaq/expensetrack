import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

/// Wraps any error into an [AppException] suitable for the UI.
AppException toAppException(Object error) {
  if (error is AppException) return error;
  if (error is TimeoutException) return const NetworkException();
  if (error is FirebaseAuthException) {
    if (error.code == 'network-request-failed') {
      return const NetworkException();
    }
    return AuthException(FirebaseErrorMapper.messageFor(error));
  }
  if (error is FirebaseException) {
    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
      return const NetworkException();
    }
    if (error.code == 'permission-denied') {
      return const PermissionException();
    }
    if (error.code == 'not-found') {
      return const NotFoundException();
    }
    return UnknownException(FirebaseErrorMapper.messageFor(error));
  }
  return UnknownException(FirebaseErrorMapper.messageFor(error));
}

/// Converts Firebase and platform errors into friendly, informative messages.
abstract final class FirebaseErrorMapper {
  static const String offlineMessage =
      "You're offline. This action will be available when you're connected.";
  static const String genericMessage =
      'Something went wrong. Please try again.';

  static String messageFor(Object error) {
    if (error is AppException) return error.message;
    if (error is FirebaseAuthException) {
      final mapped = _mapAuth(error.code);
      if (mapped != genericMessage) return mapped;
      return error.message?.isNotEmpty == true
          ? error.message!
          : 'Authentication error (${error.code}).';
    }
    if (error is FirebaseException) {
      final mapped = _mapFirestore(error.code);
      if (mapped != genericMessage) return mapped;
      return error.message?.isNotEmpty == true
          ? error.message!
          : 'Database error (${error.code}).';
    }
    if (error is TimeoutException) {
      return 'The request timed out. Please check your internet connection and try again.';
    }
    if (error is Exception) {
      final str = error.toString().replaceFirst('Exception: ', '');
      return str.isNotEmpty ? str : genericMessage;
    }
    return genericMessage;
  }

  static String _mapAuth(String code) => switch (code) {
    'invalid-credential' || 'wrong-password' =>
      'Incorrect email or password.',
    'user-not-found' => 'No account found with this email address.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'Password is too weak. Use at least 6 characters.',
    'invalid-email' => 'Enter a valid email address.',
    'network-request-failed' => offlineMessage,
    'too-many-requests' =>
      'Too many attempts. Take a short break and try again.',
    'user-disabled' => 'This account has been disabled.',
    'operation-not-allowed' =>
      'Email/password sign-in is not enabled in Firebase Console yet.',
    'requires-recent-login' => 'Please sign in again to confirm it was you.',
    'expired-action-code' =>
      'This password reset link has expired. Please request a new one.',
    'invalid-action-code' =>
      'This password reset link is invalid or has already been used.',
    'user-token-expired' => 'Your session expired. Please sign in again.',
    _ => genericMessage,
  };

  static String _mapFirestore(String code) => switch (code) {
    'unavailable' || 'deadline-exceeded' => offlineMessage,
    'permission-denied' =>
      'Database permission denied. Please verify your access permissions.',
    'not-found' => 'This item no longer exists.',
    'already-exists' => 'That item already exists.',
    'resource-exhausted' =>
      'Too many requests right now. Please try again shortly.',
    'unauthenticated' => 'Your session expired. Please sign in again.',
    'cancelled' => 'The request was cancelled.',
    _ => genericMessage,
  };
}
