-- Drop the index associated with the plan column
DROP INDEX IF EXISTS public.idx_brokers_plan;

-- Drop the plan column from the brokers table
ALTER TABLE public.brokers DROP COLUMN IF EXISTS plan;
