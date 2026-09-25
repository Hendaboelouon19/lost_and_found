import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';
import 'package:errasoft/themes/app_theme.dart';

class ItemDetailsScreen extends StatelessWidget {
  final LostFoundReport item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    final type = item.type.label;
    final category = item.category;
    final location = item.location;
    final time = item.time;
    final description = item.description;
    final match = item.matchProbability ?? 0.0;

    final isLost = item.type.isLost;

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLost ? AppTheme.nightBordeaux : AppTheme.coolHorizon,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: AppTheme.ivoryMist.withValues(alpha: .8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      color: AppTheme.ivoryMist,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (item.photoData != null || item.photoUrl != null) ...[
              _ReportImage(item: item),
              const SizedBox(height: 20),
            ],
            _InfoRow(label: 'Category', value: category),
            _InfoRow(label: 'Location', value: location),
            _InfoRow(label: 'Time', value: time),
            const SizedBox(height: 18),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Possible match: ${match.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: item.userId == FirebaseAuth.instance.currentUser?.uid
                    ? null
                    : () => _sendContactRequest(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Contact possible match'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendContactRequest(BuildContext context) async {
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null || item.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to contact the person who posted this.')),
      );
      return;
    }

    try {
      final request = await FirebaseFirestore.instance
          .collection('contactRequests')
          .add({
            'fromUserId': sender.uid,
            'toUserId': item.userId,
            'reportId': item.id,
            'message': 'I may have information about your ${item.title}.',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': item.userId,
        'type': 'contact_request',
        'contactRequestId': request.id,
        'reportId': item.id,
        'title': 'Someone wants to connect',
        'body': 'A community member may have information about your item.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact request sent')),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to send request')),
        );
      }
    }
  }
}

class _ReportImage extends StatelessWidget {
  const _ReportImage({required this.item});

  final LostFoundReport item;

  @override
  Widget build(BuildContext context) {
    if (item.photoData == null &&
        item.photoUrl == null &&
        item.category.toLowerCase().contains('bag')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/products/bag.png',
          width: double.infinity,
          height: 220,
          fit: BoxFit.contain,
        ),
      );
    }
    if (item.photoData != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            base64Decode(item.photoData!),
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        item.photoUrl!,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          height: 80,
          child: Center(child: Text('Image unavailable')),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
