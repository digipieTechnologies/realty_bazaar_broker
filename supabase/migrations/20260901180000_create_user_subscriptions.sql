-- Migration: Create user_subscriptions table
-- Purpose: Track active and historical subscriptions for brokers after a successful payment.

CREATE TABLE public.user_subscriptions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    broker_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    subscription_plan_id uuid NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    is_expired boolean NOT NULL DEFAULT false,
    total_days integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    plan_code text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    
    CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id),
    CONSTRAINT user_subscriptions_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers (id) ON DELETE CASCADE,
    CONSTRAINT user_subscriptions_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.user_payments (id) ON DELETE CASCADE,
    CONSTRAINT user_subscriptions_plan_id_fkey FOREIGN KEY (subscription_plan_id) REFERENCES public.subscription_plans (id) ON DELETE RESTRICT
);

-- Enable RLS
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Broker can read their own subscriptions
CREATE POLICY "Brokers can view own subscriptions" ON public.user_subscriptions
    FOR SELECT
    USING (auth.uid() = broker_id);

-- Create updated_at trigger
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Service role policies (assuming backend functions manage insertions after payment)
-- Only Service Role or secure backend functions should insert/update subscriptions.
