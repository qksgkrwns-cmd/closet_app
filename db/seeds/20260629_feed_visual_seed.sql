-- Visual feed seed for manual QA in Supabase SQL editor.
-- This script uses existing rows from profiles, so no auth/users insert is required.
-- Run after migrations, including 20260629_create_user_follows.sql.

DO $$
DECLARE
  u1 uuid;
  u2 uuid;
  u3 uuid;
  l1 bigint;
  l2 bigint;
  l3 bigint;
  l4 bigint;
BEGIN
  SELECT id INTO u1 FROM public.profiles ORDER BY created_at ASC LIMIT 1;
  SELECT id INTO u2 FROM public.profiles WHERE id <> u1 ORDER BY created_at ASC LIMIT 1;
  SELECT id INTO u3 FROM public.profiles WHERE id NOT IN (u1, u2) ORDER BY created_at ASC LIMIT 1;

  IF u1 IS NULL OR u2 IS NULL THEN
    RAISE NOTICE 'Need at least 2 profiles to seed feed data. Current profiles are insufficient.';
    RETURN;
  END IF;

  -- Clean previously inserted seed data.
  DELETE FROM public.daily_look_reactions
  WHERE daily_look_id IN (
    SELECT id FROM public.daily_looks WHERE content LIKE '[SEED-FEED] %'
  );

  DELETE FROM public.daily_look_bookmarks
  WHERE daily_look_id IN (
    SELECT id FROM public.daily_looks WHERE content LIKE '[SEED-FEED] %'
  );

  DELETE FROM public.daily_looks
  WHERE content LIKE '[SEED-FEED] %';

  -- Ensure genders/styles for reliable feed filtering checks.
  UPDATE public.profiles
  SET gender = '남성',
      body_type = COALESCE(NULLIF(body_type, ''), '보통'),
      height = COALESCE(height, 175),
      weight = COALESCE(weight, 70),
      style_preferences = COALESCE(style_preferences, ARRAY['미니멀', '스트릿'])
  WHERE id = u1;

  UPDATE public.profiles
  SET gender = '남성',
      body_type = COALESCE(NULLIF(body_type, ''), '보통'),
      height = COALESCE(height, 173),
      weight = COALESCE(weight, 68),
      style_preferences = COALESCE(style_preferences, ARRAY['스트릿', '캐주얼'])
  WHERE id = u2;

  IF u3 IS NOT NULL THEN
    UPDATE public.profiles
    SET gender = '여성',
        body_type = COALESCE(NULLIF(body_type, ''), '슬림'),
        height = COALESCE(height, 165),
        weight = COALESCE(weight, 53),
        style_preferences = COALESCE(style_preferences, ARRAY['페미닌', '캐주얼'])
    WHERE id = u3;
  END IF;

  -- Insert feed posts with visible sample images and hashtags.
  INSERT INTO public.daily_looks (
    user_id, wear_date, content, hashtags, is_public, image_url, created_at
  ) VALUES (
    u1,
    CURRENT_DATE,
    '[SEED-FEED] 미니멀 블랙 코트 데일리룩',
    ARRAY['#겨울', '#상의', '#검정', '#미니멀'],
    true,
    'https://picsum.photos/seed/closet-seed-1/900/1200',
    now() - interval '2 hour'
  ) RETURNING id INTO l1;

  INSERT INTO public.daily_looks (
    user_id, wear_date, content, hashtags, is_public, image_url, created_at
  ) VALUES (
    u2,
    CURRENT_DATE - interval '1 day',
    '[SEED-FEED] 스트릿 오렌지 포인트 룩',
    ARRAY['#가을', '#상의', '#하의', '#주황', '#스트릿'],
    true,
    'https://picsum.photos/seed/closet-seed-2/900/1200',
    now() - interval '5 hour'
  ) RETURNING id INTO l2;

  INSERT INTO public.daily_looks (
    user_id, wear_date, content, hashtags, is_public, image_url, created_at
  ) VALUES (
    u1,
    CURRENT_DATE - interval '2 day',
    '[SEED-FEED] 캐주얼 데님 룩',
    ARRAY['#봄', '#하의', '#파랑', '#캐주얼'],
    true,
    'https://picsum.photos/seed/closet-seed-3/900/1200',
    now() - interval '1 day'
  ) RETURNING id INTO l3;

  IF u3 IS NOT NULL THEN
    INSERT INTO public.daily_looks (
      user_id, wear_date, content, hashtags, is_public, image_url, created_at
    ) VALUES (
      u3,
      CURRENT_DATE - interval '1 day',
      '[SEED-FEED] 여성 유저 테스트용 룩',
      ARRAY['#여름', '#원피스', '#화이트'],
      true,
      'https://picsum.photos/seed/closet-seed-4/900/1200',
      now() - interval '3 hour'
    ) RETURNING id INTO l4;
  END IF;

  -- Reactions and bookmarks to verify popular sort.
  INSERT INTO public.daily_look_reactions (daily_look_id, user_id, reaction_type)
  VALUES
    (l1, u2, 'like'),
    (l2, u1, 'like')
  ON CONFLICT DO NOTHING;

  IF u3 IS NOT NULL THEN
    INSERT INTO public.daily_look_reactions (daily_look_id, user_id, reaction_type)
    VALUES
      (l1, u3, 'like'),
      (l2, u3, 'like'),
      (l4, u1, 'like')
    ON CONFLICT DO NOTHING;
  END IF;

  INSERT INTO public.daily_look_bookmarks (daily_look_id, user_id)
  VALUES
    (l1, u2),
    (l2, u1)
  ON CONFLICT DO NOTHING;

  IF u3 IS NOT NULL THEN
    INSERT INTO public.daily_look_bookmarks (daily_look_id, user_id)
    VALUES
      (l1, u3),
      (l2, u3)
    ON CONFLICT DO NOTHING;
  END IF;

  -- Following relation for "팔로잉" filter checks.
  INSERT INTO public.user_follows (user_id, following_id)
  VALUES
    (u1, u2),
    (u2, u1)
  ON CONFLICT (user_id, following_id) DO NOTHING;

  IF u3 IS NOT NULL THEN
    INSERT INTO public.user_follows (user_id, following_id)
    VALUES (u1, u3)
    ON CONFLICT (user_id, following_id) DO NOTHING;
  END IF;

  RAISE NOTICE 'Feed seed inserted. users: %, %, % | looks: %, %, %, %', u1, u2, u3, l1, l2, l3, l4;
END $$;
