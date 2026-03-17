import { corsHeaders } from '../_shared/cors.ts'

interface PlannableItem {
  id: string
  title: string
  duration_minutes: number
  energy_level: 'high' | 'medium' | 'low'
}

interface EnergyPattern {
  peak_hours: number[]
  low_hours: number[]
}

interface ScheduleBlock {
  item_id: string
  title: string
  start_minute: number
  duration_minutes: number
  energy_level: string
}

function hourToTimeString(hour: number): string {
  const suffix = hour >= 12 ? 'PM' : 'AM'
  const displayHour = hour > 12 ? hour - 12 : hour === 0 ? 12 : hour
  return `${displayHour}${suffix}`
}

function buildSystemPrompt(
  energyPattern: EnergyPattern,
  constraints?: string
): string {
  const peakStr = energyPattern.peak_hours
    .map((h) => hourToTimeString(h))
    .join(', ')
  const lowStr = energyPattern.low_hours
    .map((h) => hourToTimeString(h))
    .join(', ')

  let prompt = `You are an AI daily schedule optimizer. Create an optimal daily schedule based on the user's energy pattern and task requirements.

Rules:
- Schedule all items between 6 AM (360 minutes from midnight) and 10 PM (1320 minutes from midnight)
- The user's PEAK energy hours are: ${peakStr}. Schedule HIGH energy items during these hours.
- The user's LOW energy hours are: ${lowStr}. Schedule LOW energy items during these hours.
- MEDIUM energy items can be scheduled at any time.
- Leave 15-30 minute gaps between tasks for transitions.
- No overlapping blocks.
- All times must be expressed as minutes from midnight (e.g., 9 AM = 540, 2 PM = 840).
- Snap all start times to 15-minute intervals.

Respond with valid JSON in this exact format:
{ "blocks": [{ "item_id": "uuid", "title": "task title", "start_minute": 540, "duration_minutes": 60, "energy_level": "high" }] }`

  if (constraints) {
    prompt += `\n\nAdditional constraints from the user: ${constraints}`
  }

  return prompt
}

function buildUserPrompt(items: PlannableItem[]): string {
  const itemList = items
    .map(
      (item) =>
        `- ID: ${item.id}, Title: "${item.title}", Duration: ${item.duration_minutes} min, Energy: ${item.energy_level}`
    )
    .join('\n')

  return `Schedule these items for today:\n${itemList}`
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { items, energyPattern, constraints } = await req.json()

    const apiKey = Deno.env.get('GROQ_API_KEY')
    if (!apiKey) {
      throw new Error('GROQ_API_KEY is not set in Edge Function secrets')
    }

    const systemPrompt = buildSystemPrompt(energyPattern, constraints)
    const userPrompt = buildUserPrompt(items)

    const response = await fetch(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'llama-3.3-70b-versatile',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.3,
          max_completion_tokens: 2048,
          response_format: { type: 'json_object' },
        }),
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(
        `Groq API error (${response.status}): ${errorText}`
      )
    }

    const completion = await response.json()
    const content = completion.choices[0].message.content
    const schedule = JSON.parse(content)

    return new Response(JSON.stringify(schedule), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
