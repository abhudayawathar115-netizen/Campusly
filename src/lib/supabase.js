import { createClient } from '@supabase/supabase-js'
const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY
export const supabase = url && key ? createClient(url, key) : null
export async function loadCampusData() {
  if (!supabase) return null
  const [announcements, assignments, schedule] = await Promise.all([
    supabase.from('announcements').select('*').order('created_at', { ascending: false }).limit(6),
    supabase.from('assignments').select('*').order('due_date', { ascending: true }).limit(6),
    supabase.from('schedule').select('*').order('start_time', { ascending: true }).limit(6),
  ])
  const error = announcements.error || assignments.error || schedule.error
  if (error) throw error
  return { announcements: announcements.data, assignments: assignments.data, schedule: schedule.data }
}
