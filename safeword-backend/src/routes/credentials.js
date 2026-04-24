const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const { authenticateUser } = require('../middleware/auth');

// Create a service-role client for server-side operations (bypasses RLS).
// The backend enforces security by scoping all queries to req.userId.
function getSupabase() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );
}

// All routes require authentication
router.use(authenticateUser);

// ─── CREATE Credential ────────────────────────────────────────────────────────
router.post('/', async (req, res) => {
  const { title, username, password, more_info, iv, salt, category } = req.body;

  if (!title || !password || !iv || !salt) {
    return res.status(400).json({
      error: 'Missing required fields: title, password, iv, salt',
    });
  }

  if (typeof title !== 'string' || title.length > 255) {
    return res.status(400).json({ error: 'Invalid title length' });
  }

  try {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('credentials')
      .insert({
        user_id: req.userId,
        title: title.trim(),
        username: username?.trim() || null,
        password, // already AES-256-CBC encrypted on client
        more_info: more_info?.trim() || null,
        category: category?.trim() || null,
        iv,
        salt,
      })
      .select()
      .single();

    if (error) {
      console.error('DB insert error:', error.message);
      return res.status(500).json({ error: 'Failed to save credential' });
    }

    res.status(201).json(data);
  } catch (err) {
    console.error('Create credential error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── READ ALL Credentials ─────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const { search } = req.query;

  try {
    const supabase = getSupabase();
    let query = supabase
      .from('credentials')
      .select('id, user_id, title, username, password, more_info, category, iv, salt, created_at, updated_at')
      .eq('user_id', req.userId)
      .order('updated_at', { ascending: false });

    if (search && search.trim()) {
      const term = search.trim();
      query = query.or(
        `title.ilike.%${term}%,username.ilike.%${term}%`
      );
    }

    const { data, error } = await query;

    if (error) {
      console.error('DB fetch error:', error.message);
      return res.status(500).json({ error: 'Failed to fetch credentials' });
    }

    res.json(data || []);
  } catch (err) {
    console.error('List credentials error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── READ ONE Credential ──────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  const { id } = req.params;

  // Basic UUID validation
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(id)) {
    return res.status(400).json({ error: 'Invalid credential ID' });
  }

  try {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('credentials')
      .select('*')
      .eq('id', id)
      .eq('user_id', req.userId)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Credential not found' });
    }

    res.json(data);
  } catch (err) {
    console.error('Get credential error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── UPDATE Credential ────────────────────────────────────────────────────────
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { title, username, password, more_info, iv, category } = req.body;

  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(id)) {
    return res.status(400).json({ error: 'Invalid credential ID' });
  }

  if (!title || !password || !iv) {
    return res.status(400).json({
      error: 'Missing required fields: title, password, iv',
    });
  }

  try {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('credentials')
      .update({
        title: title.trim(),
        username: username?.trim() || null,
        password,
        more_info: more_info?.trim() || null,
        category: category?.trim() || null,
        iv,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .eq('user_id', req.userId)
      .select()
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Credential not found or unauthorized' });
    }

    res.json(data);
  } catch (err) {
    console.error('Update credential error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── DELETE Credential ────────────────────────────────────────────────────────
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(id)) {
    return res.status(400).json({ error: 'Invalid credential ID' });
  }

  try {
    const supabase = getSupabase();
    const { error } = await supabase
      .from('credentials')
      .delete()
      .eq('id', id)
      .eq('user_id', req.userId);

    if (error) {
      return res.status(500).json({ error: 'Failed to delete credential' });
    }

    res.status(204).send();
  } catch (err) {
    console.error('Delete credential error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
