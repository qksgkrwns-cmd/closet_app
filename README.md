# closet_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Magic Link Login Setup

If email login link does not open the app, configure Supabase redirect URLs.

1. Open Supabase Dashboard -> Authentication -> URL Configuration.
2. Add this redirect URL:
	- `io.supabase.closetapp://login-callback/`
3. Save settings and request a new login email.

The app is configured for this callback in:

- iOS URL scheme: `ios/Runner/Info.plist`
- Android deep link intent filter: `android/app/src/main/AndroidManifest.xml`
- Login request redirect: `lib/pages/login_page.dart`

## Feed Features Summary

The feed now includes the following features:

- Same-gender filtering (required profile gender)
- Similar body filter toggle
- Similar style filter toggle
- Following-only filter toggle
- Bookmarked-only filter toggle
- Sorting: popular (likes + bookmarks) / latest
- Uploader name tap -> user closet page
- Hashtag-based visual filters (season/color/category chips)
- Bottom fixed stats bar for each post (likes/bookmarks/combined)

## Feature Test Checklist

Manual checks for each feed feature:

1. Gender filter
	- Set profile gender to 남성.
	- Confirm feed excludes 여성-only uploader posts.
2. Similar body filter
	- Toggle 체형 button ON.
	- Confirm only body-similar posts remain.
3. Similar style filter
	- Toggle 스타일 button ON.
	- Confirm posts from users with overlapping style preferences remain.
4. Following filter
	- Toggle 팔로잉 button ON.
	- Confirm only followed users (and own posts) remain.
5. Bookmarked filter
	- Toggle 북마크 button ON.
	- Confirm only bookmarked posts remain.
6. Sort option
	- Switch between 인기순 and 최신순.
	- Confirm list order changes accordingly.
7. Uploader profile navigation
	- Tap uploader name/avatar area.
	- Confirm user closet page opens.
8. Tag filter tab
	- Open 필터 tab and select 시즌/색상/카테고리 chips.
	- Confirm feed list is narrowed down.
9. Bottom stats bar
	- Confirm each card shows likes/bookmarks/combined score.

## Test Data (Visual)

Use the SQL files below in Supabase SQL Editor:

1. Run migration:
	- `db/migrations/20260629_create_user_follows.sql`
2. Seed visual feed data:
	- `db/seeds/20260629_feed_visual_seed.sql`

Seed behavior:

- Reuses existing `profiles` users (no auth user creation required)
- Inserts multiple public feed posts with visible image URLs
- Inserts likes/bookmarks so 인기순 changes are visible
- Inserts follow relations for 팔로잉 filter tests
- Safe to rerun (old `[SEED-FEED]` rows are cleaned first)
