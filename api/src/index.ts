import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

const app = express();
const prisma = new PrismaClient();
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

// --- Auth ---
app.post('/auth/register', async (req, res) => {
  const { email, password, name } = req.body;
  if (!email || !password || !name) return res.status(400).json({ error: 'Missing fields' });
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return res.status(400).json({ error: 'Email in use' });
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({ data: { email, passwordHash, name } });
  res.json({ token: sign(user.id), user });
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) return res.status(400).json({ error: 'Invalid credentials' });
  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) return res.status(400).json({ error: 'Invalid credentials' });
  res.json({ token: sign(user.id), user });
});

app.get('/me', auth, async (req: any, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  res.json({ user });
});

// --- Workspace ---
app.post('/workspaces', auth, async (req: any, res) => {
  const { name, slug } = req.body;
  const ws = await prisma.workspace.create({
    data: { name, slug, memberships: { create: { userId: req.userId, role: 'OWNER' } } }
  });
  res.json(ws);
});

// --- Project ---
app.post('/projects', auth, async (req: any, res) => {
  const { workspaceId, name, key } = req.body;
  const project = await prisma.project.create({
    data: { name, key, workspaceId, members: { create: { userId: req.userId, role: 'MANAGER' } } }
  });
  res.json(project);
});

app.get('/projects/:id/board', auth, async (req: any, res) => {
  const projectId = req.params.id;
  const cols = await prisma.column.findMany({
    where: { projectId },
    orderBy: { order: 'asc' },
    include: { tasks: { orderBy: { createdAt: 'asc' } } }
  });
  res.json({ columns: cols });
});

// --- Columns ---
app.post('/columns', auth, async (req: any, res) => {
  const { projectId, name, order } = req.body;
  const col = await prisma.column.create({ data: { name, order, projectId } });
  res.json(col);
});

// --- Tasks ---
app.post('/tasks', auth, async (req: any, res) => {
  const { columnId, title, description } = req.body;
  const task = await prisma.task.create({ data: { columnId, title, description } });
  res.json(task);
});

app.patch('/tasks/:id', auth, async (req: any, res) => {
  const { columnId, title, description } = req.body;
  const updated = await prisma.task.update({ where: { id: req.params.id }, data: { columnId, title, description } });
  res.json(updated);
});

app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));
