import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';
import '../utils/theme.dart';

class TeamGalleryAdmin extends StatefulWidget {
  const TeamGalleryAdmin({super.key});

  @override
  State<TeamGalleryAdmin> createState() => _TeamGalleryAdminState();
}

class _TeamGalleryAdminState extends State<TeamGalleryAdmin> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final files = await _picker.pickMultiImage(imageQuality: 88);
    if (files.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    var successCount = 0;
    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final url = await StorageService.uploadTeamGalleryImage(
          imageBytes: bytes,
          fileName: file.name,
        );
        if (url.isEmpty) continue;
        await FirebaseFirestore.instance.collection('team_gallery').add({
          'imageUrl': url,
          'title': 'NEXTR 구매 팀',
          'caption': 'NEXTR와 함께한 팀의 실제 착용 사진입니다.',
          'createdAt': FieldValue.serverTimestamp(),
          'sortOrder': DateTime.now().millisecondsSinceEpoch,
          'isVisible': true,
        });
        successCount++;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount장 등록되었습니다.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 등록 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팀 사진 삭제'),
        content: const Text('이 구매 팀 사진을 갤러리에서 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    final url = doc.data()?['imageUrl']?.toString() ?? '';
    await doc.reference.delete();
    if (url.isNotEmpty) await StorageService.deleteFile(url);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('구매 팀 사진 갤러리',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined,
                          size: 17),
                  label: const Text('사진 등록'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('실제 구매 팀의 착용 사진을 등록하면 OUR TEAMS 화면에 공개됩니다.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('team_gallery')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final docs = [...snapshot.data!.docs]..sort((a, b) =>
                    (b.data()['sortOrder'] as num? ?? 0)
                        .compareTo(a.data()['sortOrder'] as num? ?? 0));
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('등록된 구매 팀 사진이 없습니다.'),
                  );
                }
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: docs.map((doc) {
                    final data = doc.data();
                    final url = data['imageUrl']?.toString() ?? '';
                    return SizedBox(
                      width: 130,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url,
                                width: 130, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              onPressed: () => _delete(doc),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
