-- Trigger function to handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, username)
  values (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'username'
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to execute the function on new user creation
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
