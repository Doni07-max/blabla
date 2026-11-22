# Week 12 practice: build the "New likes" background notification yourself

Goal: you can write the WorkManager + local notification demo from memory in class.
Do the steps in order. Each step ends with a **checkpoint**: don't move on until it passes.
Solutions are folded under "Show solution". Try first, then compare.

Time: about 2 hours the first time, 30–40 minutes on the second run (the second run is your rehearsal).

---

## 0. What is already in the project (don't redo)

| Piece | Where | Status |
|---|---|---|
| `workmanager`, `flutter_local_notifications` packages | `pubspec.yaml` | ✅ done |
| Desugaring + `compileSdk = 37` | `android/app/build.gradle.kts` | ✅ done |
| `shareAcrossIsolates: true` | `lib/core/db/app_database.dart` | ✅ done |
| `AppNotifications` (init / permission / show) | `lib/core/background/notifications.dart` | ✅ done, **read it once** |

## What you will write (the missing classes)

| # | File | What it contains |
|---|---|---|
| 1 | `lib/core/background/workers.dart` | `BackgroundTasks` (names), `callbackDispatcher()`, `_runLikesDigest()` |
| 2 | same file | `LikesDigestScheduler` (start / stop / isRunning / runOnce) |
| 3 | `lib/main.dart` | `async main()` that calls `AppNotifications.init()` and `Workmanager().initialize(...)` |
| 4 | `lib/screens/content/likes_digest_sheet.dart` | `LikesDigestSheet` bottom sheet (switch + "Test it now") |
| 5 | `lib/screens/tabs/profile_tab.dart` | 🔔 `IconButton` in the AppBar that opens the sheet |

The mental model to say out loud in class:

```
UI (main isolate)                       Android WorkManager                 Background isolate
───────────────────                     ───────────────────                 ──────────────────
LikesDigestScheduler.start()  ──────▶   stores the job, waits   ──────▶    callbackDispatcher()
  registerPeriodicTask(...)             (15 min, constraints)               └ executeTask(task, data)
                                                                              ├ new AppDatabase()
                                                                              ├ update likes
                                                                              └ AppNotifications.show...
UI drift watch() stream  ◀──────────── shareAcrossIsolates ◀───────────────  db write
```

---

## Step 0 — Read `notifications.dart` (10 min)

Answer these for yourself (students will ask):
- Why is everything `static`, and why is there an `_initialized` flag? → `init()` gets called from two isolates and from several places; it must be safe to call twice.
- What is a **channel**? → Android 8+ groups notifications into channels the user can mute in Settings. The id `'likes_digest'` must stay stable.
- Why `id: 1` in `show`? → the same id **replaces** the old notification instead of stacking them.
- Why `requestPermission()`? → Android 13+ (API 33) needs the `POST_NOTIFICATIONS` runtime permission. The plugin already adds it to the manifest, but you still have to *ask* at runtime.

If you want to practice writing this file too, delete it and rewrite it from the code below.

<details><summary>Full file <code>lib/core/background/notifications.dart</code> (already in the project)</summary>

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications (shown by the phone itself; no server, unlike FCM push).
///
/// The background task runs in a separate isolate, so [init] must be called
/// there as well as in `main()`. Plugin instances are not shared between isolates.
class AppNotifications {
  AppNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Android shows this channel in Settings → Apps → android_dev → Notifications.
  static const _likesChannel = AndroidNotificationDetails(
    'likes_digest',
    'Likes digest',
    channelDescription: 'Periodic summary of new likes on your posts',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// Android 13+ needs the POST_NOTIFICATIONS runtime permission.
  /// Returns true when notifications are allowed.
  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  static Future<void> showLikesDigest({required String title, required String body}) async {
    await init();
    await _plugin.show(
      id: 1, // same id → a new digest replaces the previous one
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _likesChannel),
    );
  }
}
```

> ⚠️ In `flutter_local_notifications` v20+, `initialize(settings: ...)` and `show(id: ..., title: ...)` use **named** parameters.
> Older tutorials write `show(1, 'title', 'body', details)`, which no longer compiles.
</details>

<details><summary>Project setup that is already done (so you can explain it or redo it in a fresh project)</summary>

```bash
flutter pub add workmanager flutter_local_notifications
```

`android/app/build.gradle.kts`: the changed parts:
```kotlin
android {
    compileSdk = 37 // flutter_local_notifications needs 37+

    compileOptions {
        // Required by flutter_local_notifications (java.time APIs on older Android).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    // ...
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

`lib/core/db/app_database.dart`: the constructor:
```dart
  // shareAcrossIsolates: the UI and the workmanager background isolate use one
  // connection, so writes made by a background task also update the UI's watch() streams.
  AppDatabase()
      : super(driftDatabase(
          name: 'social_app',
          native: const DriftNativeOptions(shareAcrossIsolates: true),
        ));
```

No manual `AndroidManifest.xml` change is needed: the plugin adds `POST_NOTIFICATIONS` itself.
</details>

---

## Step 1 — Task names + `callbackDispatcher` (25 min)

Create `lib/core/background/workers.dart`.

**1a. Names.** Make a class `BackgroundTasks` with three `static const String`s:
- `likesDigest`: the **task name** (which code to run)
- `likesDigestPeriodic`: the **unique name** of the repeating job
- `likesDigestOnce`: the **unique name** of the 10-second test job

> ⚠️ Pay attention: *task name* ≠ *unique name*. Two jobs (periodic + one-off) run the **same** task.
> Unique names are what you cancel/replace by. Mixing them up is the #1 bug.

**1b. Entry point.** Write a **top-level** function `callbackDispatcher()`:
- annotate it with `@pragma('vm:entry-point')`
- inside, call `Workmanager().executeTask((task, inputData) async { ... })`
- `switch (task)` → on `BackgroundTasks.likesDigest` call `_runLikesDigest()`
- return `true` on success, `false` in `catch`

> ⚠️ Pay attention:
> - It **must** be top-level (or static), not a method or closure. Android starts it with no app running.
> - Without `@pragma('vm:entry-point')`, release builds tree-shake it away and the task silently never runs.
> - Returning `false` = "retry later with backoff". Throwing without catching also counts as a failure.
> - Use `debugPrint('[workmanager] ...')` so you can find logs in `flutter logs` / Logcat.

**1c. The work.** Write `Future<void> _runLikesDigest()`:
1. `final db = AppDatabase();` ← new instance, **no Riverpod here**
2. select `cachedPosts` where `authorId.equals('me')`
3. if empty → `AppNotifications.showLikesDigest(title: 'No new likes yet', body: ...)` and return
4. otherwise in `db.batch(...)` add `Random().nextInt(4)` likes to each post, sum them up
5. show `'You got $total new likes ❤️'`
6. `await db.close()` inside `finally`

> ⚠️ Pay attention:
> - Background isolate = no widgets, no `ref`, no `ProviderScope`, no `BuildContext`. Create what you need.
> - Always close the DB in `finally`.
> - `AppNotifications.showLikesDigest` calls `init()` itself. That's why `init()` is idempotent.
> - You need `import 'package:drift/drift.dart';` for `Value(...)` and `.equals`.

✅ **Checkpoint 1:** `flutter analyze` shows no errors in `workers.dart`.

<details><summary>Show solution (step 1)</summary>

```dart
import 'dart:math';

import 'package:android_dev/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications.dart';

abstract final class BackgroundTasks {
  static const likesDigest = 'likesDigest';
  static const likesDigestPeriodic = 'likes-digest-periodic';
  static const likesDigestOnce = 'likes-digest-once';
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[workmanager] running $task with $inputData');
    try {
      switch (task) {
        case BackgroundTasks.likesDigest:
          await _runLikesDigest();
      }
      return true;
    } catch (error, stack) {
      debugPrint('[workmanager] $task failed: $error\n$stack');
      return false;
    }
  });
}

Future<void> _runLikesDigest() async {
  final db = AppDatabase();
  try {
    final myPosts = await (db.select(db.cachedPosts)
          ..where((post) => post.authorId.equals('me')))
        .get();

    if (myPosts.isEmpty) {
      await AppNotifications.showLikesDigest(
        title: 'No new likes yet',
        body: 'Share your first post so people can like it!',
      );
      return;
    }

    final random = Random();
    var totalNewLikes = 0;
    await db.batch((batch) {
      for (final post in myPosts) {
        final newLikes = random.nextInt(4);
        if (newLikes == 0) continue;
        totalNewLikes += newLikes;
        batch.update(
          db.cachedPosts,
          CachedPostsCompanion(likes: Value(post.likes + newLikes)),
          where: (row) => row.id.equals(post.id),
        );
      }
    });

    await AppNotifications.showLikesDigest(
      title: totalNewLikes == 0 ? 'Quiet time' : 'You got $totalNewLikes new likes ❤️',
      body: totalNewLikes == 0
          ? 'No new likes since the last check.'
          : 'People liked your posts while you were away.',
    );
  } finally {
    await db.close();
  }
}
```
</details>

---

## Step 2 — `LikesDigestScheduler` (15 min)

Same file. A class with four static methods, all one-liners on `Workmanager()`:

| Method | Workmanager call | Key arguments |
|---|---|---|
| `start()` | `registerPeriodicTask(uniqueName, taskName, ...)` | `frequency: Duration(minutes: 15)`, `existingWorkPolicy: ExistingPeriodicWorkPolicy.update` |
| `stop()` | `cancelByUniqueName(...)` | the **periodic** unique name |
| `isRunning()` | `isScheduledByUniqueName(...)` | returns `Future<bool>` |
| `runOnce()` | `registerOneOffTask(...)` | `initialDelay: Duration(seconds: 10)`, `existingWorkPolicy: ExistingWorkPolicy.replace` |

> ⚠️ Pay attention:
> - **Argument order:** `(uniqueName, taskName)`. Unique name comes first.
> - **15 min is the minimum.** Anything lower is silently raised to 15. Android picks the exact moment (Doze, battery), so it is *never* on the dot. That's why `runOnce` exists for the live demo.
> - Policy `keep` would ignore your changes if the job already exists (e.g., you change the frequency). `update` applies them.
> - Optional extra for Class 24: add `constraints: Constraints(networkType: NetworkType.connected)` and show it waiting in airplane mode.

✅ **Checkpoint 2:** `flutter analyze` is clean.

<details><summary>Full file <code>lib/core/background/workers.dart</code> (steps 1 + 2 together)</summary>

```dart
import 'dart:math';

import 'package:android_dev/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications.dart';

/// Task names (what the worker does) and unique names (which scheduled job).
/// Same idea as a Worker class plus a unique work name in Android WorkManager.
abstract final class BackgroundTasks {
  static const likesDigest = 'likesDigest';
  static const likesDigestPeriodic = 'likes-digest-periodic';
  static const likesDigestOnce = 'likes-digest-once';
}

/// Entry point that Android calls when a task is due.
///
/// It runs in a separate isolate: no widgets, no ProviderScope, no Riverpod.
/// Anything the task needs (the database, notifications) must be created here.
/// The pragma stops the compiler from tree-shaking this top-level function away.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[workmanager] running $task with $inputData');
    try {
      switch (task) {
        case BackgroundTasks.likesDigest:
          await _runLikesDigest();
      }
      return true; // success
    } catch (error, stack) {
      debugPrint('[workmanager] $task failed: $error\n$stack');
      return false; // WorkManager retries it with backoff
    }
  });
}

/// Simulates other users liking your posts, saves the likes to drift,
/// then shows one summary notification.
Future<void> _runLikesDigest() async {
  final db = AppDatabase();
  try {
    final myPosts = await (db.select(db.cachedPosts)
          ..where((post) => post.authorId.equals('me')))
        .get();

    if (myPosts.isEmpty) {
      await AppNotifications.showLikesDigest(
        title: 'No new likes yet',
        body: 'Share your first post so people can like it!',
      );
      return;
    }

    final random = Random();
    var totalNewLikes = 0;
    await db.batch((batch) {
      for (final post in myPosts) {
        final newLikes = random.nextInt(4); // 0–3 "fake" likes per post
        if (newLikes == 0) continue;
        totalNewLikes += newLikes;
        batch.update(
          db.cachedPosts,
          CachedPostsCompanion(likes: Value(post.likes + newLikes)),
          where: (row) => row.id.equals(post.id),
        );
      }
    });

    await AppNotifications.showLikesDigest(
      title: totalNewLikes == 0 ? 'Quiet time' : 'You got $totalNewLikes new likes ❤️',
      body: totalNewLikes == 0
          ? 'No new likes since the last check.'
          : 'People liked your posts while you were away.',
    );
  } finally {
    await db.close();
  }
}

/// Called by the UI (main isolate) to schedule and cancel work.
abstract final class LikesDigestScheduler {
  /// Repeats roughly every 15 minutes, Android's minimum for periodic work.
  /// Android decides the exact moment (Doze, battery saver), so it is never on the dot.
  static Future<void> start() => Workmanager().registerPeriodicTask(
        BackgroundTasks.likesDigestPeriodic,
        BackgroundTasks.likesDigest,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );

  static Future<void> stop() =>
      Workmanager().cancelByUniqueName(BackgroundTasks.likesDigestPeriodic);

  static Future<bool> isRunning() =>
      Workmanager().isScheduledByUniqueName(BackgroundTasks.likesDigestPeriodic);

  /// For class demos: the same task as a one-off, run after [delay],
  /// so nobody waits 15 minutes. Close the app after tapping it.
  static Future<void> runOnce({Duration delay = const Duration(seconds: 10)}) =>
      Workmanager().registerOneOffTask(
        BackgroundTasks.likesDigestOnce,
        BackgroundTasks.likesDigest,
        initialDelay: delay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
}
```
</details>

<details><summary>Show solution (step 2)</summary>

```dart
abstract final class LikesDigestScheduler {
  static Future<void> start() => Workmanager().registerPeriodicTask(
        BackgroundTasks.likesDigestPeriodic,
        BackgroundTasks.likesDigest,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

  static Future<void> stop() =>
      Workmanager().cancelByUniqueName(BackgroundTasks.likesDigestPeriodic);

  static Future<bool> isRunning() =>
      Workmanager().isScheduledByUniqueName(BackgroundTasks.likesDigestPeriodic);

  static Future<void> runOnce({Duration delay = const Duration(seconds: 10)}) =>
      Workmanager().registerOneOffTask(
        BackgroundTasks.likesDigestOnce,
        BackgroundTasks.likesDigest,
        initialDelay: delay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
}
```
</details>

---

## Step 3 — `main.dart` (5 min)

Change `void main() => runApp(...)` to an `async` main that:
1. calls `WidgetsFlutterBinding.ensureInitialized();` **first**
2. `await AppNotifications.init();`
3. `await Workmanager().initialize(callbackDispatcher);` ← pass the function, **don't call it** (no `()`)
4. `runApp(const ProviderScope(child: MainApp()));`

> ⚠️ Pay attention:
> - Forgetting `ensureInitialized()` → crash: plugins are used before the engine is ready.
> - `initialize(callbackDispatcher())` with `()` is a classic mistake: it runs the dispatcher on the UI isolate.
> - `isInDebugMode` is **deprecated** in this version (0.10.x). Don't copy it from old tutorials.

✅ **Checkpoint 3:** `flutter run` starts the app normally, with no red screen.

<details><summary>Show solution (step 3): full file <code>lib/main.dart</code></summary>

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'core/background/notifications.dart';
import 'core/background/workers.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppNotifications.init();
  await Workmanager().initialize(callbackDispatcher);
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      );
}
```
</details>

---

## Step 4 — `LikesDigestSheet` (25 min)

Create `lib/screens/content/likes_digest_sheet.dart`. A **StatefulWidget** (no Riverpod needed).

Requirements:
- `static Future<void> show(BuildContext context)` → `showModalBottomSheet(..., showDragHandle: true)`
- state field `bool? _enabled`, where `null` means "still asking WorkManager"
- `initState` → `LikesDigestScheduler.isRunning().then(...)` → `setState` (check `mounted`!)
- `_ensurePermission()` → `AppNotifications.requestPermission()`; if denied, show a SnackBar
- `SwitchListTile` "New likes digest" → on → permission, then `start()`; off → `stop()`
  - `onChanged: _enabled == null ? null : _toggle` (disabled while loading)
- `ListTile` "Test it now" → permission, then `runOnce()`, close the sheet, SnackBar "Close the app, the notification arrives in ~10 s"
- wrap content in `SafeArea` + `Column(mainAxisSize: MainAxisSize.min)`

> ⚠️ Pay attention:
> - Ask for the permission **when the user turns the feature on**, not at app start. That's the Android guideline, and it's a good teaching point.
> - Check `mounted` after every `await` before `setState`, `Navigator` or `ScaffoldMessenger`.
> - The project imports `package:material_ui/material_ui.dart`, not `flutter/material.dart`. Stay consistent.
> - The switch reads the real state from WorkManager, so it stays correct after an app restart. Show that in class.

✅ **Checkpoint 4:** analyze is clean.

<details><summary>Show solution (step 4): full file <code>lib/screens/content/likes_digest_sheet.dart</code></summary>

```dart
import 'package:android_dev/core/background/notifications.dart';
import 'package:android_dev/core/background/workers.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom sheet for turning the periodic "new likes" notification on and off.
class LikesDigestSheet extends StatefulWidget {
  const LikesDigestSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const LikesDigestSheet(),
      );

  @override
  State<LikesDigestSheet> createState() => _LikesDigestSheetState();
}

class _LikesDigestSheetState extends State<LikesDigestSheet> {
  bool? _enabled; // null while we ask WorkManager

  @override
  void initState() {
    super.initState();
    LikesDigestScheduler.isRunning().then((value) {
      if (mounted) setState(() => _enabled = value);
    });
  }

  Future<bool> _ensurePermission() async {
    final granted = await AppNotifications.requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allow notifications in Settings to get the digest.')),
      );
    }
    return granted;
  }

  Future<void> _toggle(bool value) async {
    if (value && !await _ensurePermission()) return;
    value ? await LikesDigestScheduler.start() : await LikesDigestScheduler.stop();
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _testNow() async {
    if (!await _ensurePermission()) return;
    await LikesDigestScheduler.runOnce();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scheduled. Close the app — the notification arrives in ~10 s.')),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.favorite_border),
                title: const Text('New likes digest'),
                subtitle: const Text('Background check about every 15 minutes'),
                value: _enabled ?? false,
                onChanged: _enabled == null ? null : _toggle,
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Test it now'),
                subtitle: const Text('Run the same task once, 10 seconds from now'),
                onTap: _testNow,
              ),
            ],
          ),
        ),
      );
}
```
</details>

---

## Step 5 — Profile button (5 min)

In `profile_tab.dart`, add to `AppBar.actions` **before** the edit button:

```dart
IconButton(
  tooltip: 'Notifications',
  icon: const Icon(Icons.notifications_outlined),
  onPressed: () => LikesDigestSheet.show(context),
),
```
plus the import of `likes_digest_sheet.dart`.

<details><summary>Show solution (step 5): full file <code>lib/screens/tabs/profile_tab.dart</code></summary>

Only two things change compared to the current file: the new **import** (line 4) and the new **🔔 IconButton** in `actions`.

```dart
import 'package:android_dev/screens/home_screen/state/feed_controller.dart';
import 'package:android_dev/screens/home_screen/services/local_data_service.dart';
import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/screens/content/likes_digest_sheet.dart'; // NEW
import 'package:drift/drift.dart' hide Column;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentProfileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(localDataServiceProvider).watchProfile('me'),
);

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final nickname = profile?.nickname ?? 'alimhan';
    final avatarUrl = profile?.avatarUrl;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // NEW: opens the background-notification settings
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => LikesDigestSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfile(context, ref, nickname, avatarUrl),
          ),
        ],
      ),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load profile: $error')),
        data: (allPosts) {
          final ownPosts =
              allPosts.where((post) => post.authorId == 'me').toList();
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                        ? null
                        : NetworkImage(avatarUrl),
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(nickname.isEmpty ? 'A' : nickname[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32))
                        : null,
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('${ownPosts.length} posts'),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child:
                    Text('Posts', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SliverGrid.builder(
              itemCount: ownPosts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) => Image.network(
                ownPosts[index].imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    String nickname,
    String? avatarUrl,
  ) async {
    final nameController = TextEditingController(text: nickname);
    final imageController = TextEditingController(text: avatarUrl ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: imageController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Profile picture URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final image = imageController.text.trim();
              await ref.read(localDataServiceProvider).saveProfile(
                    UserProfilesCompanion.insert(
                      id: 'me',
                      nickname: name,
                      avatarUrl: Value(image.isEmpty ? null : image),
                    ),
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    imageController.dispose();
  }
}
```
</details>

✅ **Checkpoint 5 (the real test, on an Android 13+ device/emulator):**
1. Create one post in the New Post tab (so the task has something to like).
2. Profile → 🔔 → **Test it now** → allow notifications.
3. Swipe the app away from recents → ~10 s → notification appears.
4. Open the app → the like count on your post went up (proves `shareAcrossIsolates` / the same DB).
5. Turn the switch on → restart the app → the switch is still on.
6. `adb shell dumpsys jobscheduler | grep android_dev` → you see the scheduled job.

---

## Troubleshooting (things that will go wrong)

| Symptom | Cause | Fix |
|---|---|---|
| Build: "requires compileSdk 37" | Flutter default is 36 | already set in `build.gradle.kts` |
| Build: "requires core library desugaring" | missing desugaring | already set; know *why* it's there |
| No notification, no error | permission denied, or channel muted in Settings | Settings → Apps → android_dev → Notifications |
| Task never runs | dispatcher not top-level / missing `@pragma` / app **force-stopped** | force-stop cancels all jobs; swipe-away doesn't |
| Periodic didn't fire after 15 min | normal: Doze/battery delays it | use `runOnce` in demos |
| UI doesn't update after task | DB not shared between isolates | `shareAcrossIsolates: true` |
| `MissingPluginException` in task | old plugin / hot restart weirdness | full stop + `flutter run` again |

Logs: `flutter logs`, or Logcat filtered by `workmanager`.

---

## Questions students will ask (prepare answers)

1. **"Is this push notification?"** No. These are *local* notifications: the phone creates them itself. Push comes from a server via Firebase Cloud Messaging (FCM). You'd use push for a real "someone liked your post" event. Here we fake the likes locally.
2. **"Why can't the task use Riverpod / my widgets?"** It runs in a separate isolate (separate memory), possibly while the app isn't open at all.
3. **"Why not just a `Timer`?"** A timer dies with the app. WorkManager survives app close and reboot, and respects battery.
4. **"How is this different from Kotlin WorkManager?"** It *is* WorkManager underneath. `Worker.doWork()` ≈ `executeTask`, `Result.success/retry` ≈ `true/false`, `PeriodicWorkRequest` ≈ `registerPeriodicTask` (see the table in `week-12.md`).
5. **"What about iOS?"** iOS uses BGTaskScheduler; periodic timing is entirely up to the OS. The course targets Android.

---

## Rehearsal checklist (day before class)

- [ ] `git stash` or delete your files and rebuild steps 1–5 **without** looking at solutions
- [ ] Device/emulator on Android 13+, with notifications for the app **reset** (so students see the permission prompt)
- [ ] At least one own post exists in the app
- [ ] `adb` works on your laptop (`adb devices`)
- [ ] You can draw the isolate diagram on the board in 1 minute
