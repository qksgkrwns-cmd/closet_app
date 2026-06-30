-- Add outerwear slot support for daily looks.
-- Safe to run multiple times.

ALTER TABLE public.daily_looks
ADD COLUMN IF NOT EXISTS outer_item_id bigint;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'daily_looks_outer_item_id_fkey'
  ) THEN
    ALTER TABLE public.daily_looks
    ADD CONSTRAINT daily_looks_outer_item_id_fkey
    FOREIGN KEY (outer_item_id)
    REFERENCES public.clothes(id)
    ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_daily_looks_outer_item_id
ON public.daily_looks(outer_item_id);
