import '../services/supabase_service.dart';

class CommunityRepository {
  ({dynamic client, dynamic user}) _session() {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('No active Supabase session');
    }
    return (client: client, user: user);
  }

  String get currentUserId => _session().user.id as String;

  Future<List<Map<String, dynamic>>> loadPosts() async {
    final session = _session();
    final rows = await session.client
        .from('community_posts')
        .select('id, user_id, body, created_at, updated_at')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addPost(String body) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 2000) {
      throw const FormatException('Post must contain 1 to 2000 characters');
    }
    final session = _session();
    await session.client.from('community_posts').insert({
      'user_id': session.user.id,
      'body': text,
    });
  }

  Future<void> updatePost(String id, String body) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 2000) {
      throw const FormatException('Post must contain 1 to 2000 characters');
    }
    final session = _session();
    await session.client
        .from('community_posts')
        .update({'body': text})
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  Future<void> deletePost(String id) async {
    final session = _session();
    await session.client
        .from('community_posts')
        .delete()
        .eq('id', id)
        .eq('user_id', session.user.id);
  }
}
