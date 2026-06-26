-- Add required gender field for profile-based feed filtering.
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS gender text;

-- Backfill existing rows to a known value so the app can prompt users to update.
UPDATE public.profiles
SET gender = '미설정'
WHERE gender IS NULL OR trim(gender) = '';

-- Enforce allowed values for consistency.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_gender_allowed_values'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_gender_allowed_values
      CHECK (gender IN ('남성', '여성', '미설정'));
  END IF;
END $$;

-- Make gender non-nullable after backfill.
ALTER TABLE public.profiles
ALTER COLUMN gender SET NOT NULL;

ALTER TABLE public.profiles
ALTER COLUMN gender SET DEFAULT '미설정';
