import 'package:android_dev/core/auth/auth_service.dart';
import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/screens/home_screen/services/local_data_service.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AuthService auth;
  late LocalDataService data;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = AuthService(db);
    data = LocalDataService(db);
  });

  tearDown(() => db.close());

  test('upgrades a v1 database to the new schema', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE cached_posts (id TEXT PRIMARY KEY, author_id TEXT, '
          'author_name TEXT, image_url TEXT, caption TEXT, likes INTEGER, is_liked INTEGER)');
      raw.execute('CREATE TABLE user_profiles (id TEXT PRIMARY KEY, nickname TEXT, avatar_url TEXT)');
      raw.execute("INSERT INTO cached_posts VALUES ('post-1','me','alimhan','u','c',0,0)");
      raw.execute('PRAGMA user_version = 1');
    }));
    final user = await AuthService(old)
        .register(username: 'alice', displayName: 'Alice', password: 'secret1');
    final tables = await old
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row.read<String>('name'))
        .get();
    expect(tables, isNot(contains('cached_posts')));
    expect(tables, containsAll(['users', 'posts', 'post_likes', 'comments', 'sessions']));
    expect(await LocalDataService(old).watchFeed(user.id).first, isEmpty);
    await old.close();
  });

  group('auth', () {
    test('register signs in, logout signs out, login signs back in', () async {
      final user = await auth.register(username: ' Alice ', displayName: 'Alice', password: 'secret1');
      expect(user.username, 'alice');
      expect(user.passwordHash, isNot(contains('secret1')));
      expect((await auth.watchCurrentUser().first)?.id, user.id);

      await auth.logout();
      expect(await auth.watchCurrentUser().first, isNull);

      final again = await auth.login(username: 'ALICE', password: 'secret1');
      expect(again.id, user.id);
      expect((await auth.watchCurrentUser().first)?.id, user.id);
    });

    test('rejects a taken username, wrong password and unknown user', () async {
      await auth.register(username: 'bob', displayName: '', password: 'secret1');
      await expectLater(
        auth.register(username: 'BOB', displayName: '', password: 'other12'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(auth.login(username: 'bob', password: 'wrong!!'), throwsA(isA<AuthException>()));
      await expectLater(auth.login(username: 'nobody', password: 'secret1'), throwsA(isA<AuthException>()));
    });

    test('validates username and password', () async {
      await expectLater(auth.register(username: 'a', displayName: '', password: 'secret1'),
          throwsA(isA<AuthException>()));
      await expectLater(auth.register(username: 'valid_name', displayName: '', password: '123'),
          throwsA(isA<AuthException>()));
    });

    test('only one account is signed in at a time', () async {
      await auth.register(username: 'first', displayName: '', password: 'secret1');
      final second = await auth.register(username: 'second', displayName: '', password: 'secret1');
      expect((await auth.watchCurrentUser().first)?.id, second.id);
      expect(await db.select(db.sessions).get(), hasLength(1));
    });
  });

  group('posts, likes and comments', () {
    test('likes and comments are per user and counted in the feed', () async {
      final alice = await auth.register(username: 'alice', displayName: 'Alice', password: 'secret1');
      final bob = await auth.register(username: 'bob', displayName: 'Bob', password: 'secret1');
      final postId = await data.createPost(authorId: alice.id, imageUrl: 'https://x/1.jpg', caption: 'hi');

      await data.toggleLike(postId: postId, userId: alice.id);
      await data.toggleLike(postId: postId, userId: bob.id);
      await data.addComment(postId: postId, authorId: bob.id, body: 'nice');

      final asAlice = (await data.watchFeed(alice.id).first).single;
      expect(asAlice.authorName, 'Alice');
      expect(asAlice.likeCount, 2);
      expect(asAlice.commentCount, 1);
      expect(asAlice.isLiked, isTrue);

      await data.toggleLike(postId: postId, userId: bob.id); // unlike
      final asBob = (await data.watchFeed(bob.id).first).single;
      expect(asBob.likeCount, 1);
      expect(asBob.isLiked, isFalse);

      final comments = await data.watchComments(postId).first;
      expect(comments.single.authorName, 'Bob');
      expect(comments.single.body, 'nice');
    });

    test('feed stream updates when a like is added', () async {
      final alice = await auth.register(username: 'alice', displayName: 'Alice', password: 'secret1');
      final postId = await data.createPost(authorId: alice.id, imageUrl: 'https://x/1.jpg', caption: '');
      final counts = data.watchFeed(alice.id).map((posts) => posts.single.likeCount);
      final expectation = expectLater(counts, emitsInOrder([0, 1]));
      await Future<void>.delayed(Duration.zero);
      await data.toggleLike(postId: postId, userId: alice.id);
      await expectation;
    });

    test('only the author can delete; deleting removes likes and comments', () async {
      final alice = await auth.register(username: 'alice', displayName: 'Alice', password: 'secret1');
      final bob = await auth.register(username: 'bob', displayName: 'Bob', password: 'secret1');
      final postId = await data.createPost(authorId: alice.id, imageUrl: 'https://x/1.jpg', caption: '');
      await data.toggleLike(postId: postId, userId: bob.id);
      await data.addComment(postId: postId, authorId: bob.id, body: 'hey');

      await data.deletePost(postId: postId, userId: bob.id);
      expect(await data.watchFeed(bob.id).first, hasLength(1));

      await data.deletePost(postId: postId, userId: alice.id);
      expect(await data.watchFeed(alice.id).first, isEmpty);
      expect(await db.select(db.postLikes).get(), isEmpty);
      expect(await db.select(db.comments).get(), isEmpty);
    });
  });
}
