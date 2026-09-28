alter table public.fotos_pneus
  add column if not exists agio boolean default false,
  add column if not exists aluguel boolean default false;

alter table public.fotos_pneus
  drop constraint if exists fotos_pneus_single_deal_type;

alter table public.fotos_pneus
  add constraint fotos_pneus_single_deal_type
  check (not (coalesce(agio, false) and coalesce(aluguel, false)));
