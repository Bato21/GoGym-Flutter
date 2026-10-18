-- Catálogo de ejercicios (RepDB, traducido al español). Es igual para todos los
-- usuarios: cualquiera con sesión lo lee y nadie lo edita desde la app.
-- id es el slug estable ("barbell-bench-press") que guardan rutinas y sesiones
-- en su jsonb como catalogoId. imagen e imagen_final son nombres de archivo; la
-- URL se arma en la app contra jsDelivr.
-- Los datos se cargan con supabase/seed/ejercicios.sql.

create table public.ejercicios (
  id text primary key,
  nombre text not null,
  descripcion text not null default '',
  grupo text not null check (grupo in (
    'Pecho', 'Espalda', 'Hombro', 'Bíceps', 'Tríceps',
    'Pierna', 'Core', 'Antebrazo', 'Cuerpo completo'
  )),
  categoria text not null,
  nivel text not null check (nivel in ('Principiante', 'Intermedio', 'Avanzado')),
  equipo text not null,
  peso_corporal boolean not null default false,
  musculos text[] not null default '{}',
  musculos_secundarios text[] not null default '{}',
  met numeric(4, 1) not null check (met > 0),
  imagen text,
  imagen_final text,
  instrucciones text[] not null default '{}',
  consejos text[] not null default '{}'
);

comment on table public.ejercicios is 'Catálogo de ejercicios (RepDB). Solo lectura para la app.';

revoke all on table public.ejercicios from anon, authenticated;
grant select on table public.ejercicios to authenticated;

alter table public.ejercicios enable row level security;

create policy "ejercicios: leer con sesión" on public.ejercicios
  for select to authenticated using (true);
