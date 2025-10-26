import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config({ path: '../.env' });

const app = express();
const supabase = createClient(
  process.env.VITE_SUPABASE_URL!,
  process.env.VITE_SUPABASE_SUPABASE_ANON_KEY!
);

app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';
const PORT = process.env.PORT ? Number(process.env.PORT) : 4000;

function sign(userId: string) {
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: '7d' });
}

function auth(req: any, res: any, next: any) {
  const token = (req.headers.authorization || '').replace('Bearer ', '');
  try {
    const payload: any = jwt.verify(token, JWT_SECRET);
    req.userId = payload.sub;
    next();
  } catch {
    return res.status(401).json({ error: 'Unauthenticated' });
  }
}

app.post('/auth/register', async (req, res) => {
  const { email, password, name } = req.body;
  if (!email || !password || !name) return res.status(400).json({ error: 'Missing fields' });

  const { data: existing } = await supabase
    .from('users')
    .select('id')
    .eq('email', email)
    .maybeSingle();

  if (existing) return res.status(400).json({ error: 'Email in use' });

  const passwordHash = await bcrypt.hash(password, 10);
  const { data: user, error } = await supabase
    .from('users')
    .insert({ email, password_hash: passwordHash, name })
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  res.json({ token: sign(user.id), user });
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;

  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('email', email)
    .maybeSingle();

  if (!user) return res.status(400).json({ error: 'Invalid credentials' });

  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) return res.status(400).json({ error: 'Invalid credentials' });

  res.json({ token: sign(user.id), user });
});

app.get('/me', auth, async (req: any, res) => {
  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('id', req.userId)
    .single();

  res.json({ user });
});

app.post('/workspaces', auth, async (req: any, res) => {
  const { name, slug } = req.body;

  const { data: ws, error: wsError } = await supabase
    .from('workspaces')
    .insert({ name, slug })
    .select()
    .single();

  if (wsError) return res.status(500).json({ error: wsError.message });

  await supabase
    .from('memberships')
    .insert({ user_id: req.userId, workspace_id: ws.id, role: 'OWNER' });

  res.json(ws);
});

app.post('/projects', auth, async (req: any, res) => {
  const { workspaceId, name, key } = req.body;

  const { data: project, error: projError } = await supabase
    .from('projects')
    .insert({ name, key, workspace_id: workspaceId })
    .select()
    .single();

  if (projError) return res.status(500).json({ error: projError.message });

  await supabase
    .from('project_members')
    .insert({ user_id: req.userId, project_id: project.id, role: 'MANAGER' });

  res.json(project);
});

app.get('/projects/:id/board', auth, async (req: any, res) => {
  const projectId = req.params.id;

  const { data: cols } = await supabase
    .from('columns')
    .select('*, tasks(*)')
    .eq('project_id', projectId)
    .order('order', { ascending: true });

  res.json({ columns: cols || [] });
});

app.post('/columns', auth, async (req: any, res) => {
  const { projectId, name, order } = req.body;

  const { data: col, error } = await supabase
    .from('columns')
    .insert({ name, order, project_id: projectId })
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  res.json(col);
});

app.post('/tasks', auth, async (req: any, res) => {
  const { columnId, title, description } = req.body;

  const { data: task, error } = await supabase
    .from('tasks')
    .insert({ column_id: columnId, title, description })
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  res.json(task);
});

app.patch('/tasks/:id', auth, async (req: any, res) => {
  const { columnId, title, description } = req.body;
  const updateData: any = {};

  if (columnId !== undefined) updateData.column_id = columnId;
  if (title !== undefined) updateData.title = title;
  if (description !== undefined) updateData.description = description;

  const { data: updated, error } = await supabase
    .from('tasks')
    .update(updateData)
    .eq('id', req.params.id)
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  res.json(updated);
});

app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));
