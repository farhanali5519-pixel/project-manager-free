import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.upsert({
    where: { email: 'demo@example.com' },
    update: {},
    create: { email: 'demo@example.com', name: 'Demo', passwordHash: '$2a$10$u1M9xGgJ9Nv5dR9wCwA08uvqzv5rB6d.2Lr0qE5n5r8Z0cUD1b6jK' } // password: demo1234
  });
  const ws = await prisma.workspace.create({ data: { name: 'Demo Space', slug: 'demo-space',
    memberships: { create: { userId: user.id, role: 'OWNER' } } } });
  const proj = await prisma.project.create({ data: { name: 'Demo Project', key: 'DEMO', workspaceId: ws.id,
    members: { create: { userId: user.id, role: 'MANAGER' } } } });
  const todo = await prisma.column.create({ data: { name: 'To Do', order: 1, projectId: proj.id } });
  const doing = await prisma.column.create({ data: { name: 'Doing', order: 2, projectId: proj.id } });
  const done = await prisma.column.create({ data: { name: 'Done', order: 3, projectId: proj.id } });
  await prisma.task.create({ data: { title: 'Welcome task', description: 'Drag me!', columnId: todo.id } });
  console.log('Seeded. Project ID:', proj.id);
}
main().finally(() => prisma.$disconnect());
