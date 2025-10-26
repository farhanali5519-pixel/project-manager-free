/*
  # Create Project Management System Schema

  ## Overview
  This migration creates a complete project management system with workspaces, projects, tasks, and team collaboration features.

  ## 1. New Tables
  
  ### `users`
  - `id` (uuid, primary key) - Unique user identifier
  - `email` (text, unique) - User email address
  - `password_hash` (text) - Hashed password for authentication
  - `name` (text) - User's full name
  - `image` (text, nullable) - Profile image URL
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### `workspaces`
  - `id` (uuid, primary key) - Unique workspace identifier
  - `name` (text) - Workspace name
  - `slug` (text, unique) - URL-friendly workspace identifier
  - `created_at` (timestamptz) - Creation timestamp
  
  ### `memberships`
  - `id` (uuid, primary key) - Unique membership identifier
  - `role` (role_enum) - User role in workspace (OWNER, ADMIN, MEMBER, VIEWER)
  - `user_id` (uuid) - Reference to user
  - `workspace_id` (uuid) - Reference to workspace
  - `created_at` (timestamptz) - Membership creation timestamp
  - Unique constraint on (user_id, workspace_id)
  
  ### `projects`
  - `id` (uuid, primary key) - Unique project identifier
  - `name` (text) - Project name
  - `key` (text, unique) - Project key (e.g., "PROJ")
  - `workspace_id` (uuid) - Reference to workspace
  - `created_at` (timestamptz) - Creation timestamp
  
  ### `project_members`
  - `id` (uuid, primary key) - Unique project membership identifier
  - `role` (project_role_enum) - User role in project (MANAGER, CONTRIBUTOR, VIEWER)
  - `project_id` (uuid) - Reference to project
  - `user_id` (uuid) - Reference to user
  - `created_at` (timestamptz) - Membership creation timestamp
  - Unique constraint on (project_id, user_id)
  
  ### `columns`
  - `id` (uuid, primary key) - Unique column identifier
  - `name` (text) - Column name (e.g., "To Do", "In Progress")
  - `order` (integer) - Display order
  - `project_id` (uuid) - Reference to project
  - `created_at` (timestamptz) - Creation timestamp
  
  ### `tasks`
  - `id` (uuid, primary key) - Unique task identifier
  - `title` (text) - Task title
  - `description` (text, nullable) - Task description
  - `assignee_id` (uuid, nullable) - Reference to assigned user
  - `column_id` (uuid) - Reference to column
  - `priority` (priority_enum) - Task priority (LOW, MEDIUM, HIGH, URGENT)
  - `due_date` (timestamptz, nullable) - Due date
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### `comments`
  - `id` (uuid, primary key) - Unique comment identifier
  - `text` (text) - Comment text
  - `task_id` (uuid) - Reference to task
  - `user_id` (uuid) - Reference to user who created comment
  - `created_at` (timestamptz) - Creation timestamp

  ## 2. Security
  - RLS enabled on all tables
  - Policies for authenticated users to manage their own data
  - Workspace-based access control
  - Project-based access control

  ## 3. Important Notes
  - All tables use UUID primary keys
  - Timestamps are automatically managed
  - Cascading deletes are configured for related data
  - Enums are used for role and priority types
*/

-- Create enums
CREATE TYPE role_enum AS ENUM ('OWNER', 'ADMIN', 'MEMBER', 'VIEWER');
CREATE TYPE project_role_enum AS ENUM ('MANAGER', 'CONTRIBUTOR', 'VIEWER');
CREATE TYPE priority_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  name text NOT NULL,
  image text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create workspaces table
CREATE TABLE IF NOT EXISTS workspaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create memberships table
CREATE TABLE IF NOT EXISTS memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role role_enum NOT NULL,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, workspace_id)
);

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  key text UNIQUE NOT NULL,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Create project_members table
CREATE TABLE IF NOT EXISTS project_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role project_role_enum NOT NULL,
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(project_id, user_id)
);

-- Create columns table
CREATE TABLE IF NOT EXISTS columns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  "order" integer NOT NULL,
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  assignee_id uuid REFERENCES users(id) ON DELETE SET NULL,
  column_id uuid NOT NULL REFERENCES columns(id) ON DELETE CASCADE,
  priority priority_enum NOT NULL DEFAULT 'MEDIUM',
  due_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  text text NOT NULL,
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_memberships_user_id ON memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_workspace_id ON memberships(workspace_id);
CREATE INDEX IF NOT EXISTS idx_projects_workspace_id ON projects(workspace_id);
CREATE INDEX IF NOT EXISTS idx_project_members_project_id ON project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user_id ON project_members(user_id);
CREATE INDEX IF NOT EXISTS idx_columns_project_id ON columns(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_column_id ON tasks(column_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id ON tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_comments_task_id ON comments(task_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- RLS Policies for workspaces table
CREATE POLICY "Workspace members can view workspace"
  ON workspaces FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM memberships
      WHERE memberships.workspace_id = workspaces.id
      AND memberships.user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace owners can update workspace"
  ON workspaces FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM memberships
      WHERE memberships.workspace_id = workspaces.id
      AND memberships.user_id = auth.uid()
      AND memberships.role = 'OWNER'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM memberships
      WHERE memberships.workspace_id = workspaces.id
      AND memberships.user_id = auth.uid()
      AND memberships.role = 'OWNER'
    )
  );

CREATE POLICY "Authenticated users can create workspaces"
  ON workspaces FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for memberships table
CREATE POLICY "Members can view workspace memberships"
  ON memberships FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.workspace_id = memberships.workspace_id
      AND m.user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace admins can manage memberships"
  ON memberships FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.workspace_id = memberships.workspace_id
      AND m.user_id = auth.uid()
      AND m.role IN ('OWNER', 'ADMIN')
    )
  );

CREATE POLICY "Workspace admins can update memberships"
  ON memberships FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.workspace_id = memberships.workspace_id
      AND m.user_id = auth.uid()
      AND m.role IN ('OWNER', 'ADMIN')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.workspace_id = memberships.workspace_id
      AND m.user_id = auth.uid()
      AND m.role IN ('OWNER', 'ADMIN')
    )
  );

CREATE POLICY "Workspace admins can delete memberships"
  ON memberships FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.workspace_id = memberships.workspace_id
      AND m.user_id = auth.uid()
      AND m.role IN ('OWNER', 'ADMIN')
    )
  );

-- RLS Policies for projects table
CREATE POLICY "Workspace members can view projects"
  ON projects FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM memberships
      WHERE memberships.workspace_id = projects.workspace_id
      AND memberships.user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can create projects"
  ON projects FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM memberships
      WHERE memberships.workspace_id = projects.workspace_id
      AND memberships.user_id = auth.uid()
      AND memberships.role IN ('OWNER', 'ADMIN', 'MEMBER')
    )
  );

CREATE POLICY "Workspace admins can update projects"
  ON projects FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM memberships
      WHERE memberships.workspace_id = projects.workspace_id
      AND memberships.user_id = auth.uid()
      AND memberships.role IN ('OWNER', 'ADMIN')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM memberships
      WHERE memberships.workspace_id = projects.workspace_id
      AND memberships.user_id = auth.uid()
      AND memberships.role IN ('OWNER', 'ADMIN')
    )
  );

-- RLS Policies for project_members table
CREATE POLICY "Project members can view project membership"
  ON project_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
    )
  );

CREATE POLICY "Project managers can manage project members"
  ON project_members FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'MANAGER'
    )
  );

CREATE POLICY "Project managers can update project members"
  ON project_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'MANAGER'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'MANAGER'
    )
  );

CREATE POLICY "Project managers can delete project members"
  ON project_members FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'MANAGER'
    )
  );

-- RLS Policies for columns table
CREATE POLICY "Project members can view columns"
  ON columns FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = columns.project_id
      AND pm.user_id = auth.uid()
    )
  );

CREATE POLICY "Project managers can manage columns"
  ON columns FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = columns.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('MANAGER', 'CONTRIBUTOR')
    )
  );

CREATE POLICY "Project managers can update columns"
  ON columns FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = columns.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('MANAGER', 'CONTRIBUTOR')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = columns.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('MANAGER', 'CONTRIBUTOR')
    )
  );

CREATE POLICY "Project managers can delete columns"
  ON columns FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = columns.project_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'MANAGER'
    )
  );

-- RLS Policies for tasks table
CREATE POLICY "Project members can view tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM columns c
      JOIN project_members pm ON pm.project_id = c.project_id
      WHERE c.id = tasks.column_id
      AND pm.user_id = auth.uid()
    )
  );

CREATE POLICY "Project contributors can create tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM columns c
      JOIN project_members pm ON pm.project_id = c.project_id
      WHERE c.id = tasks.column_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('MANAGER', 'CONTRIBUTOR')
    )
  );

CREATE POLICY "Project contributors can update tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM columns c
      JOIN project_members pm ON pm.project_id = c.project_id
      WHERE c.id = tasks.column_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('MANAGER', 'CONTRIBUTOR')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM columns c
      JOIN project_members pm ON pm.project_id = c.project_id
      WHERE c.id = tasks.column_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('MANAGER', 'CONTRIBUTOR')
    )
  );

CREATE POLICY "Project managers can delete tasks"
  ON tasks FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM columns c
      JOIN project_members pm ON pm.project_id = c.project_id
      WHERE c.id = tasks.column_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'MANAGER'
    )
  );

-- RLS Policies for comments table
CREATE POLICY "Project members can view comments"
  ON comments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks t
      JOIN columns c ON c.id = t.column_id
      JOIN project_members pm ON pm.project_id = c.project_id
      WHERE t.id = comments.task_id
      AND pm.user_id = auth.uid()
    )
  );

CREATE POLICY "Project members can create comments"
  ON comments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks t
      JOIN columns c ON c.id = t.column_id
      JOIN project_members pm ON pm.project_id = c.project_id
      WHERE t.id = comments.task_id
      AND pm.user_id = auth.uid()
    )
    AND user_id = auth.uid()
  );

CREATE POLICY "Users can update own comments"
  ON comments FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own comments"
  ON comments FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();