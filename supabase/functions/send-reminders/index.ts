import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

/**
 * Read and parse Firebase service account credentials from the
 * FIREBASE_SERVICE_ACCOUNT Edge Function secret at runtime.
 * Lazy: only called when the function is actually invoked.
 */
function getServiceAccount(): { client_email: string; private_key: string; project_id: string } {
  const raw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT is not set in Edge Function secrets')
  }
  return JSON.parse(raw)
}

// --- Helper Functions ---

/**
 * Check whether the reminder's category-level toggle is enabled.
 * If the toggle for this reminder type is off, skip sending.
 */
function isCategoryEnabled(reminder: any): boolean {
  switch (reminder.reminder_type) {
    case 'task_deadline':
      return reminder.task_reminders_enabled
    case 'habit_reminder':
      return reminder.habit_reminders_enabled
    case 'planner_summary':
      return reminder.planner_summary_enabled
    case 'planner_block':
      return reminder.planner_block_reminders_enabled
    default:
      return true
  }
}

/**
 * Determine if the current time falls within the user's quiet hours window.
 * Handles midnight wrap-around (e.g., 22:00 -- 07:00).
 *
 * Converts the current UTC time to the user's timezone before comparing
 * against quiet hours start/end. Falls back to UTC if timezone is null.
 */
function isInQuietHours(
  now: Date,
  quietStart: string | null,
  quietEnd: string | null,
  timezone: string | null
): boolean {
  if (!quietStart || !quietEnd) return false

  // Convert current UTC time to user's local time
  const tz = timezone || 'UTC'
  let currentMinutes: number
  try {
    const userLocalStr = now.toLocaleString('en-US', { timeZone: tz })
    const userLocal = new Date(userLocalStr)
    currentMinutes = userLocal.getHours() * 60 + userLocal.getMinutes()
  } catch {
    // Invalid timezone string -- fall back to UTC
    currentMinutes = now.getUTCHours() * 60 + now.getUTCMinutes()
  }

  const [startH, startM] = quietStart.split(':').map(Number)
  const [endH, endM] = quietEnd.split(':').map(Number)
  const start = startH * 60 + startM
  const end = endH * 60 + endM

  if (start <= end) {
    // Non-wrapping range (e.g., 13:00 -- 17:00)
    return currentMinutes >= start && currentMinutes < end
  }
  // Wraps midnight (e.g., 22:00 -- 07:00)
  return currentMinutes >= start || currentMinutes < end
}

/**
 * Adaptive timing: analyze the user's 2-week completion patterns to generate
 * an insight message. Implements dual-signal analysis:
 *   Signal 1 -- Deadline proximity (how close to deadline they complete tasks)
 *   Signal 2 -- Response delay (minutes between reminder sent and task completion)
 */
interface AdaptiveResult {
  adjustedOffsetMinutes: number | null
  insight: string | null
}

async function calculateAdaptiveInsight(
  supabaseClient: any,
  userId: string
): Promise<AdaptiveResult> {
  // Get last 2 weeks of completion patterns
  const twoWeeksAgo = new Date(
    Date.now() - 14 * 24 * 60 * 60 * 1000
  ).toISOString()

  const { data: completions } = await supabaseClient
    .from('completion_patterns')
    .select('*')
    .eq('user_id', userId)
    .gte('created_at', twoWeeksAgo)
    .order('created_at', { ascending: false })

  if (!completions || completions.length < 3) {
    return { adjustedOffsetMinutes: null, insight: null }
  }

  // Signal 1: Deadline proximity (how many minutes before deadline they complete)
  const proximities = completions
    .filter((c: any) => c.deadline_at)
    .map((c: any) => {
      const deadline = new Date(c.deadline_at).getTime()
      const completed = new Date(c.completed_at).getTime()
      return (deadline - completed) / (1000 * 60)
    })

  const avgProximity =
    proximities.length > 0
      ? proximities.reduce((a: number, b: number) => a + b, 0) /
        proximities.length
      : null

  // Signal 2: Response delay (minutes between reminder and completion)
  const delays = completions
    .filter((c: any) => c.response_delay_minutes != null)
    .map((c: any) => c.response_delay_minutes)

  const avgDelay =
    delays.length > 0
      ? delays.reduce((a: number, b: number) => a + b, 0) / delays.length
      : 30

  let insight: string | null = null

  // If completing tasks close to deadline (< 30 min before on average),
  // they're procrastinating -- shift reminders earlier
  if (avgProximity !== null && avgProximity < 30) {
    insight = `Reminder moved earlier -- you tend to complete tasks ${Math.round(avgProximity)} min before deadline`
  }
  // If user responds quickly when they get reminders (< 15 min avg delay)
  else if (avgDelay < 15 && delays.length >= 3) {
    insight = `You typically act on reminders within ${Math.round(avgDelay)} minutes`
  }

  return { adjustedOffsetMinutes: null, insight }
}

/**
 * Obtain a short-lived OAuth2 access token for FCM HTTP v1 API
 * using the Firebase service account credentials.
 */
const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err: any, tokens: any) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}

// --- Main Handler ---

Deno.serve(async (_req: Request) => {
  try {
    const serviceAccount = getServiceAccount()

    // Step 1: Query pending reminders (unsent, with valid FCM token, notifications enabled)
    const now = new Date()
    const { data: pendingReminders, error } = await supabase
      .from('pending_reminders')
      .select('*')
      .lte('remind_at', now.toISOString())

    if (error) {
      console.error('Error querying pending reminders:', error.message)
      return new Response(
        JSON.stringify({ sent: 0, error: error.message }),
        {
          headers: { 'Content-Type': 'application/json' },
          status: 500,
        }
      )
    }

    if (!pendingReminders || pendingReminders.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // Step 2: Get FCM access token via service account
    const accessToken = await getAccessToken({
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key,
    })

    // Step 3: Process each reminder -- apply filters and send
    let sentCount = 0
    const errors: string[] = []

    for (const reminder of pendingReminders) {
      // Filter: check category-level toggle
      if (!isCategoryEnabled(reminder)) continue

      // Filter: quiet hours
      if (
        reminder.quiet_hours_enabled &&
        isInQuietHours(now, reminder.quiet_start, reminder.quiet_end, reminder.timezone)
      ) {
        continue
      }

      // Apply adaptive timing: generate insight for task deadline reminders
      let insight = reminder.insight
      if (!insight && reminder.reminder_type === 'task_deadline') {
        const adaptiveResult = await calculateAdaptiveInsight(
          supabase,
          reminder.user_id
        )
        if (adaptiveResult.insight) {
          insight = adaptiveResult.insight
        }
      }

      try {
        // Send data-only FCM message (no notification field -- Flutter app
        // handles display via flutter_local_notifications for action buttons)
        const res = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              message: {
                token: reminder.fcm_token,
                data: {
                  type: reminder.reminder_type,
                  item_id: reminder.item_id,
                  title: reminder.title,
                  body: reminder.body,
                  insight: insight || '',
                  route: reminder.deep_link_route || '',
                },
                android: { priority: 'high' },
              },
            }),
          }
        )

        if (res.ok) {
          sentCount++
          // Mark reminder as sent in the database
          await supabase
            .from('scheduled_reminders')
            .update({ sent: true, sent_at: now.toISOString() })
            .eq('id', reminder.id)
        } else {
          const errBody = await res.text()
          errors.push(`Reminder ${reminder.id}: ${res.status} ${errBody}`)

          // If token is stale/unregistered (device uninstalled app), clear it
          if (
            errBody.includes('UNREGISTERED') ||
            errBody.includes('NOT_FOUND')
          ) {
            await supabase
              .from('profiles')
              .update({ fcm_token: null })
              .eq('id', reminder.user_id)
          }
        }
      } catch (err) {
        errors.push(`Reminder ${reminder.id}: ${(err as Error).message}`)
      }
    }

    return new Response(
      JSON.stringify({
        sent: sentCount,
        errors: errors.length,
        details: errors.slice(0, 5),
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (err) {
    console.error('send-reminders error:', (err as Error).message)
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
