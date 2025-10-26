import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config({ path: '../.env' });

const supabase = createClient(
  process.env.VITE_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function main() {
  const { data: existingUser } = await supabase
    .from('users')
    .select('id')
    .eq('email', 'demo@example.com')
    .maybeSingle();

  let userId: string;

  if (existingUser) {
    userId = existingUser.id;
    console.log('User already exists, using existing user');
  } else {
    const { data: user, error: userError } = await supabase
      .from('users')
      .insert({
        email: 'demo@example.com',
        name: 'Demo',
        password_hash: '$2a$10$u1M9xGgJ9Nv5dR9wCwA08uvqzv5rB6d.2Lr0qE5n5r8Z0cUD1b6jK'
      })
      .select()
      .single();

    if (userError) {
      console.error('Error creating user:', userError);
      return;
    }
    userId = user!.id;
    console.log('Created user:', user);
  }

  const { data: ws, error: wsError } = await supabase
    .from('workspaces')
    .insert({ name: 'Demo Space', slug: 'demo-space' })
    .select()
    .single();

  if (wsError) {
    console.error('Error creating workspace:', wsError);
    return;
  }

  await supabase
    .from('memberships')
    .insert({ user_id: userId, workspace_id: ws.id, role: 'OWNER' });

  const { data: proj, error: projError } = await supabase
    .from('projects')
    .insert({ name: 'Demo Project', key: 'DEMO', workspace_id: ws.id })
    .select()
    .single();

  if (projError) {
    console.error('Error creating project:', projError);
    return;
  }

  await supabase
    .from('project_members')
    .insert({ user_id: userId, project_id: proj.id, role: 'MANAGER' });

  const { data: todo } = await supabase
    .from('columns')
    .insert({ name: 'To Do', order: 1, project_id: proj.id })
    .select()
    .single();

  const { data: doing } = await supabase
    .from('columns')
    .insert({ name: 'Doing', order: 2, project_id: proj.id })
    .select()
    .single();

  const { data: done } = await supabase
    .from('columns')
    .insert({ name: 'Done', order: 3, project_id: proj.id })
    .select()
    .single();

  await supabase
    .from('tasks')
    .insert({ title: 'Welcome task', description: 'Drag me!', column_id: todo!.id });

  console.log('Seeded successfully! Project ID:', proj.id);
  console.log('Login with: demo@example.com / demo1234');
}

main();
