# Free Project Management App (Starter)

## Quick Start

### 0) Requirements
- Docker (for Postgres) OR local Postgres
- Node.js 18+ and pnpm or npm

### 1) Run Database
```bash
docker compose up -d
```

### 2) Install & Prepare API
```bash
cd api
npm install
npm run prisma:push
npm run seed
npm run dev
```
API defaults to http://localhost:4000

> Seed prints a Project ID in terminal. Copy that.

### 3) Run Web (React + Vite)
```bash
cd ../web
npm install
cp .env.example .env
npm run dev
```
Open the URL Vite shows (often http://localhost:5173).
Login with **demo@example.com / demo1234**. Paste the Project ID you copied to load the Kanban board (drag & drop enabled).

## Notes
- Minimal features: login, workspaces/projects creation via API (or add your own UI), board view, task drag & drop with persistence.
- Extend API following the Prisma schema.
