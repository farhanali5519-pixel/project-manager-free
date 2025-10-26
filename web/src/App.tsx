import React, { useEffect, useState } from 'react';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';

const API = import.meta.env.VITE_API_URL || 'http://localhost:4000';

function Login({ onDone }: { onDone: () => void }) {
  const [email, setEmail] = useState('demo@example.com');
  const [password, setPassword] = useState('demo1234');
  const [loading, setLoading] = useState(false);
  const login = async () => {
    setLoading(true);
    const res = await fetch(API + '/auth/login', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({ email, password })});
    if (!res.ok) { alert('Login failed'); setLoading(false); return; }
    const data = await res.json();
    localStorage.setItem('token', data.token);
    onDone();
  };
  return (<div style={{maxWidth:420, margin:'80px auto', fontFamily:'sans-serif'}}>
    <h2>Login</h2>
    <input placeholder="email" value={email} onChange={e=>setEmail(e.target.value)} style={{width:'100%', padding:8}}/>
    <input placeholder="password" type="password" value={password} onChange={e=>setPassword(e.target.value)} style={{width:'100%', padding:8, marginTop:8}}/>
    <button onClick={login} disabled={loading} style={{marginTop:12, padding:'8px 12px'}}>Login</button>
    <p style={{opacity:0.7}}>Use seeded demo account.</p>
  </div>);
}

type Task = { id:string; title:string; description?:string; columnId:string };
type Column = { id:string; name:string; order:number; tasks: Task[] };
type Board = { columns: Column[] };

function BoardView({ projectId }:{projectId:string}) {
  const [board, setBoard] = useState<Board | null>(null);
  const token = localStorage.getItem('token') || '';
  const headers = { 'Content-Type':'application/json', 'Authorization': 'Bearer '+token };

  const load = async () => {
    const res = await fetch(API + `/projects/${projectId}/board`, { headers });
    const data = await res.json();
    setBoard(data);
  };
  useEffect(()=>{ load(); }, []);

  const onDragEnd = async (result: DropResult) => {
    if (!result.destination || !board) return;
    const source = result.source;
    const dest = result.destination;
    const cols = [...board.columns];
    const fromCol = cols.find(c => c.id === source.droppableId)!;
    const toCol = cols.find(c => c.id === dest.droppableId)!;
    const [moved] = fromCol.tasks.splice(source.index, 1);
    toCol.tasks.splice(dest.index, 0, moved);
    moved.columnId = toCol.id;
    setBoard({ columns: cols });
    // persist
    await fetch(API + `/tasks/${moved.id}`, { method:'PATCH', headers, body: JSON.stringify({ columnId: toCol.id })});
  };

  if (!board) return <p style={{padding:20}}>Loading board…</p>;

  return (
    <div style={{ display:'flex', gap:16, padding:16, fontFamily:'sans-serif' }}>
      <DragDropContext onDragEnd={onDragEnd}>
        {board.columns.map(col => (
          <Droppable droppableId={col.id} key={col.id}>
            {(provided) => (
              <div ref={provided.innerRef} {...provided.droppableProps}
                style={{ background:'#f5f5f5', padding:12, width:280, borderRadius:8 }}>
                <h3>{col.name}</h3>
                {col.tasks.map((t, idx) => (
                  <Draggable draggableId={t.id} index={idx} key={t.id}>
                    {(prov) => (
                      <div ref={prov.innerRef} {...prov.draggableProps} {...prov.dragHandleProps}
                        style={{ background:'#fff', padding:10, margin:'8px 0', borderRadius:6, boxShadow:'0 1px 3px rgba(0,0,0,.1)', ...prov.draggableProps.style }}>
                        <strong>{t.title}</strong>
                        {t.description && <p style={{margin:0, opacity:.7}}>{t.description}</p>}
                      </div>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
              </div>
            )}
          </Droppable>
        ))}
      </DragDropContext>
    </div>
  );
}

export default function App(){
  const [authed, setAuthed] = useState(!!localStorage.getItem('token'));
  const [projectId, setProjectId] = useState<string | null>(null);

  useEffect(()=>{
    // read projectId from localStorage (seed script prints it; user can paste)
    const saved = localStorage.getItem('projectId');
    if (saved) setProjectId(saved);
  },[]);

  if (!authed) return <Login onDone={()=>setAuthed(true)} />;

  return (
    <div style={{fontFamily:'sans-serif'}}>
      <header style={{display:'flex', gap:12, alignItems:'center', padding:12, borderBottom:'1px solid #eee'}}>
        <h2 style={{margin:0}}>Project Manager</h2>
        <input placeholder="Project ID" value={projectId||''} onChange={e=>setProjectId(e.target.value)} style={{padding:6}} />
        <button onClick={()=> projectId && localStorage.setItem('projectId', projectId)}>
          Save Project
        </button>
      </header>
      {projectId ? <BoardView projectId={projectId} /> : <p style={{padding:16}}>Seed run karke console me aaya Project ID yahan paste karein.</p>}
    </div>
  );
}
