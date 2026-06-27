-- Equity positions backing the income strategy (assigned shares + covered-call
-- underlyings). Powers the Assigned Holdings section on the Trades & P/L page:
-- breakeven and live P/L are computed from cost basis, current price, and the
-- option premium realized on the underlying.

create table if not exists equity_holdings (
  id uuid primary key default gen_random_uuid(),
  connected_account_id uuid not null references connected_accounts (id) on delete cascade,
  ticker text not null,
  shares numeric(14, 4) not null default 0,
  cost_basis_per_share numeric(14, 4) not null default 0,
  current_price numeric(14, 4) not null default 0,
  synced_at timestamptz not null default now()
);

create index if not exists equity_holdings_account_idx on equity_holdings (connected_account_id);

alter table equity_holdings enable row level security;

-- Sync writes via the service role (bypasses RLS); users only read/remove their own.
create policy "equity_holdings_select_own" on equity_holdings
  for select using (
    exists (
      select 1 from connected_accounts ca
      where ca.id = equity_holdings.connected_account_id and ca.user_id = auth.uid()
    )
  );

create policy "equity_holdings_delete_own" on equity_holdings
  for delete using (
    exists (
      select 1 from connected_accounts ca
      where ca.id = equity_holdings.connected_account_id and ca.user_id = auth.uid()
    )
  );
