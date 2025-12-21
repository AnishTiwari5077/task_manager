// server.js
import express from 'express';
import cors from 'cors';
import { createClient } from '@supabase/supabase-js';
import Joi from 'joi';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

app.use(cors());
app.use(express.json());

// Classification keywords
const KEYWORDS = {
  scheduling: ['meeting', 'schedule', 'call', 'appointment', 'deadline'],
  finance: ['payment', 'invoice', 'bill', 'budget', 'cost', 'expense'],
  technical: ['bug', 'fix', 'error', 'install', 'repair', 'maintain'],
  safety: ['safety', 'hazard', 'inspection', 'compliance', 'ppe']
};

const PRIORITY_KEYWORDS = {
  high: ['urgent', 'asap', 'immediately', 'today', 'critical', 'emergency'],
  medium: ['soon', 'this week', 'important']
};

const SUGGESTED_ACTIONS = {
  scheduling: ['Block calendar', 'Send invite', 'Prepare agenda', 'Set reminder'],
  finance: ['Check budget', 'Get approval', 'Generate invoice', 'Update records'],
  technical: ['Diagnose issue', 'Check resources', 'Assign technician', 'Document fix'],
  safety: ['Conduct inspection', 'File report', 'Notify supervisor', 'Update checklist'],
  general: ['Review task', 'Assign owner', 'Set deadline', 'Update status']
};

// Auto-classification function
function classifyTask(title, description) {
  const text = `${title} ${description || ''}`.toLowerCase();
  
  // Determine category
  let category = 'general';
  for (const [cat, keywords] of Object.entries(KEYWORDS)) {
    if (keywords.some(keyword => text.includes(keyword))) {
      category = cat;
      break;
    }
  }
  
  // Determine priority
  let priority = 'low';
  for (const [pri, keywords] of Object.entries(PRIORITY_KEYWORDS)) {
    if (keywords.some(keyword => text.includes(keyword))) {
      priority = pri;
      break;
    }
  }
  
  // Extract entities
  const entities = extractEntities(text);
  
  // Get suggested actions
  const suggestedActions = SUGGESTED_ACTIONS[category] || SUGGESTED_ACTIONS.general;
  
  return {
    category,
    priority,
    extracted_entities: entities,
    suggested_actions: suggestedActions
  };
}

function extractEntities(text) {
  const entities = {
    dates: [],
    people: [],
    locations: [],
    actions: []
  };
  
  // Extract dates (simple patterns)
  const datePatterns = [
    /today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday/gi,
    /\d{1,2}\/\d{1,2}\/\d{2,4}/g,
    /\d{1,2}-\d{1,2}-\d{2,4}/g
  ];
  datePatterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) entities.dates.push(...matches);
  });
  
  // Extract people (after "with", "by", "assign to")
  const peoplePattern = /(?:with|by|assign to)\s+([a-z]+(?:\s+[a-z]+)?)/gi;
  let match;
  while ((match = peoplePattern.exec(text)) !== null) {
    entities.people.push(match[1]);
  }
  
  // Extract action verbs
  const actionVerbs = ['schedule', 'call', 'meet', 'send', 'review', 'fix', 'install', 'pay', 'check'];
  actionVerbs.forEach(verb => {
    if (text.includes(verb)) entities.actions.push(verb);
  });
  
  return entities;
}

// Validation schemas
const taskSchema = Joi.object({
  title: Joi.string().required().min(3).max(200),
  description: Joi.string().allow('', null),
  category: Joi.string().valid('scheduling', 'finance', 'technical', 'safety', 'general'),
  priority: Joi.string().valid('high', 'medium', 'low'),
  status: Joi.string().valid('pending', 'in_progress', 'completed').default('pending'),
  assigned_to: Joi.string().allow('', null),
  due_date: Joi.date().iso().allow(null)
});

const updateTaskSchema = Joi.object({
  title: Joi.string().min(3).max(200),
  description: Joi.string().allow('', null),
  category: Joi.string().valid('scheduling', 'finance', 'technical', 'safety', 'general'),
  priority: Joi.string().valid('high', 'medium', 'low'),
  status: Joi.string().valid('pending', 'in_progress', 'completed'),
  assigned_to: Joi.string().allow('', null),
  due_date: Joi.date().iso().allow(null)
}).min(1);

// POST /api/tasks - Create a new task
app.post('/api/tasks', async (req, res) => {
  try {
    const { error, value } = taskSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    // Auto-classify if not provided
    const classification = classifyTask(value.title, value.description);
    
    const taskData = {
      title: value.title,
      description: value.description || null,
      category: value.category || classification.category,
      priority: value.priority || classification.priority,
      status: value.status || 'pending',
      assigned_to: value.assigned_to || null,
      due_date: value.due_date || null,
      extracted_entities: classification.extracted_entities,
      suggested_actions: classification.suggested_actions,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    const { data, error: dbError } = await supabase
      .from('tasks')
      .insert([taskData])
      .select()
      .single();
    
    if (dbError) throw dbError;
    
    // Log task creation in history
    await supabase.from('task_history').insert([{
      task_id: data.id,
      action: 'created',
      new_value: taskData,
      changed_by: value.assigned_to || 'system',
      changed_at: new Date().toISOString()
    }]);
    
    res.status(201).json({ success: true, data, classification });
  } catch (err) {
    console.error('Error creating task:', err);
    res.status(500).json({ error: 'Failed to create task' });
  }
});

// GET /api/tasks - List all tasks with filters
app.get('/api/tasks', async (req, res) => {
  try {
    const { status, category, priority, limit = 50, offset = 0, search } = req.query;
    
    let query = supabase.from('tasks').select('*', { count: 'exact' });
    
    if (status) query = query.eq('status', status);
    if (category) query = query.eq('category', category);
    if (priority) query = query.eq('priority', priority);
    if (search) query = query.ilike('title', `%${search}%`);
    
    query = query
      .order('created_at', { ascending: false })
      .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);
    
    const { data, error, count } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      data,
      pagination: {
        total: count,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (err) {
    console.error('Error fetching tasks:', err);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// GET /api/tasks/:id - Get task details with history
app.get('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: task, error: taskError } = await supabase
      .from('tasks')
      .select('*')
      .eq('id', id)
      .single();
    
    if (taskError) {
      if (taskError.code === 'PGRST116') {
        return res.status(404).json({ error: 'Task not found' });
      }
      throw taskError;
    }
    
    const { data: history, error: historyError } = await supabase
      .from('task_history')
      .select('*')
      .eq('task_id', id)
      .order('changed_at', { ascending: false });
    
    if (historyError) throw historyError;
    
    res.json({ success: true, data: { ...task, history } });
  } catch (err) {
    console.error('Error fetching task:', err);
    res.status(500).json({ error: 'Failed to fetch task' });
  }
});

// PATCH /api/tasks/:id - Update task
app.patch('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = updateTaskSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    // Get old task data
    const { data: oldTask, error: fetchError } = await supabase
      .from('tasks')
      .select('*')
      .eq('id', id)
      .single();
    
    if (fetchError) {
      if (fetchError.code === 'PGRST116') {
        return res.status(404).json({ error: 'Task not found' });
      }
      throw fetchError;
    }
    
    const updateData = { ...value, updated_at: new Date().toISOString() };
    
    const { data, error: updateError } = await supabase
      .from('tasks')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (updateError) throw updateError;
    
    // Log update in history
    const action = value.status && value.status !== oldTask.status 
      ? 'status_changed' 
      : 'updated';
    
    await supabase.from('task_history').insert([{
      task_id: id,
      action,
      old_value: oldTask,
      new_value: updateData,
      changed_by: value.assigned_to || oldTask.assigned_to || 'system',
      changed_at: new Date().toISOString()
    }]);
    
    res.json({ success: true, data });
  } catch (err) {
    console.error('Error updating task:', err);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

// DELETE /api/tasks/:id - Delete task
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { error } = await supabase
      .from('tasks')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    
    res.json({ success: true, message: 'Task deleted successfully' });
  } catch (err) {
    console.error('Error deleting task:', err);
    res.status(500).json({ error: 'Failed to delete task' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export { classifyTask, extractEntities };