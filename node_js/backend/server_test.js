// server.test.js
import { describe, test, expect } from '@jest/globals';
import { classifyTask, extractEntities } from './server.js';

describe('Task Classification', () => {
  test('should classify scheduling task with high priority', () => {
    const result = classifyTask(
      'Schedule urgent meeting with team today',
      'Need to discuss budget allocation'
    );
    
    expect(result.category).toBe('scheduling');
    expect(result.priority).toBe('high');
    expect(result.suggested_actions).toContain('Block calendar');
    expect(result.suggested_actions).toContain('Send invite');
  });
  
  test('should classify finance task with medium priority', () => {
    const result = classifyTask(
      'Process invoice payment',
      'Important payment due this week for vendor supplies'
    );
    
    expect(result.category).toBe('finance');
    expect(result.priority).toBe('medium');
    expect(result.suggested_actions).toContain('Check budget');
    expect(result.suggested_actions).toContain('Get approval');
  });
  
  test('should classify technical task with low priority', () => {
    const result = classifyTask(
      'Fix minor bug in reporting module',
      'Low priority maintenance task'
    );
    
    expect(result.category).toBe('technical');
    expect(result.priority).toBe('low');
    expect(result.suggested_actions).toContain('Diagnose issue');
    expect(result.suggested_actions).toContain('Document fix');
  });
  
  test('should classify safety task correctly', () => {
    const result = classifyTask(
      'Conduct safety inspection',
      'Monthly compliance check required'
    );
    
    expect(result.category).toBe('safety');
    expect(result.suggested_actions).toContain('Conduct inspection');
    expect(result.suggested_actions).toContain('File report');
  });
  
  test('should default to general category for unmatched keywords', () => {
    const result = classifyTask(
      'General administrative task',
      'Review documents and provide feedback'
    );
    
    expect(result.category).toBe('general');
    expect(result.priority).toBe('low');
  });
});

describe('Entity Extraction', () => {
  test('should extract dates from text', () => {
    const entities = extractEntities('schedule meeting today about 12/25/2024 deliverables');
    
    expect(entities.dates.length).toBeGreaterThan(0);
    expect(entities.dates).toContain('today');
  });
  
  test('should extract people names after keywords', () => {
    const entities = extractEntities('meeting with john smith to discuss project');
    
    expect(entities.people.length).toBeGreaterThan(0);
  });
  
  test('should extract action verbs', () => {
    const entities = extractEntities('schedule call and send invoice for review');
    
    expect(entities.actions).toContain('schedule');
    expect(entities.actions).toContain('call');
    expect(entities.actions).toContain('send');
    expect(entities.actions).toContain('review');
  });
});