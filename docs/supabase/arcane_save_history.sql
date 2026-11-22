-- Arcane Surge : historique des sauvegardes (20 dernières versions par joueur).
-- À exécuter une fois dans Supabase > SQL Editor (projet academie-cmd-powershell).
create table if not exists public.arcane_save_history (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  data jsonb not null,
  saved_at timestamptz not null default now()
);
create index if not exists arcane_save_history_user_idx on public.arcane_save_history (user_id, saved_at desc);
alter table public.arcane_save_history enable row level security;
revoke all on public.arcane_save_history from anon, authenticated;
grant select on public.arcane_save_history to authenticated;
drop policy if exists "Arcane : lire son historique" on public.arcane_save_history;
create policy "Arcane : lire son historique" on public.arcane_save_history
  for select to authenticated using ((select auth.uid()) = user_id);

create or replace function public.arcane_save_keep_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.data is distinct from new.data then
    insert into public.arcane_save_history (user_id, data) values (old.user_id, old.data);
    delete from public.arcane_save_history h
     where h.user_id = old.user_id
       and h.id not in (
         select h2.id from public.arcane_save_history h2
          where h2.user_id = old.user_id
          order by h2.saved_at desc, h2.id desc
          limit 20);
  end if;
  return new;
end;
$$;
revoke all on function public.arcane_save_keep_history() from public, anon, authenticated;

drop trigger if exists arcane_saves_history on public.arcane_saves;
create trigger arcane_saves_history
  before update on public.arcane_saves
  for each row execute function public.arcane_save_keep_history();
