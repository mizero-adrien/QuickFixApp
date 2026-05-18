-- Enable RLS on reviews table if not already enabled
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for all users" ON public.reviews;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.reviews;
DROP POLICY IF EXISTS "Enable update for own reviews" ON public.reviews;

-- Policy: Allow all users to read reviews
CREATE POLICY "Enable read access for all users"
  ON public.reviews
  FOR SELECT
  USING (true);

-- Policy: Allow authenticated users to insert reviews
CREATE POLICY "Enable insert for authenticated users"
  ON public.reviews
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Policy: Allow users to update their own reviews
CREATE POLICY "Enable update for own reviews"
  ON public.reviews
  FOR UPDATE
  USING (auth.uid() = reviewer_id OR reviewer_id IS NULL)
  WITH CHECK (auth.uid() = reviewer_id OR reviewer_id IS NULL);

-- Grant permissions to authenticated role
GRANT SELECT, INSERT, UPDATE ON public.reviews TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE reviews_id_seq TO authenticated;
