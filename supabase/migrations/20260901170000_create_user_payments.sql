-- Create Enums for Payments
CREATE TYPE public.payment_purpose_type AS ENUM ('buy_subscription');
CREATE TYPE public.payment_status_type AS ENUM ('pending', 'completed', 'failed', 'cancelled');

-- Create user_payments table
CREATE TABLE public.user_payments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    broker_id uuid NOT NULL,
    subscription_plan_id uuid NULL,
    amount numeric NOT NULL,
    purpose public.payment_purpose_type NOT NULL DEFAULT 'buy_subscription'::payment_purpose_type,
    status public.payment_status_type NOT NULL DEFAULT 'pending'::payment_status_type,
    payment_provider public.payment_provider_type NOT NULL DEFAULT 'razorpay'::payment_provider_type,
    payment_id text NULL,
    metadata jsonb NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    
    CONSTRAINT user_payments_pkey PRIMARY KEY (id),
    CONSTRAINT user_payments_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers (id) ON DELETE CASCADE,
    CONSTRAINT user_payments_subscription_plan_id_fkey FOREIGN KEY (subscription_plan_id) REFERENCES public.subscription_plans (id) ON DELETE SET NULL
) TABLESPACE pg_default;

-- Create Indexes
CREATE INDEX IF NOT EXISTS idx_user_payments_broker_id ON public.user_payments USING btree (broker_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_user_payments_status ON public.user_payments USING btree (status) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_user_payments_created_at ON public.user_payments USING btree (created_at) TABLESPACE pg_default;

-- Setup updated_at trigger
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.user_payments
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Brokers can view their own payments"
ON public.user_payments FOR SELECT
TO authenticated
USING (broker_id = (auth.uid()));

CREATE POLICY "Brokers can insert their own payments"
ON public.user_payments FOR INSERT
TO authenticated
WITH CHECK (broker_id = (auth.uid()));
