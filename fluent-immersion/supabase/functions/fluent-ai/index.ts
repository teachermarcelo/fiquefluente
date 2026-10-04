import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json"
};

function localScore(text: string) {
  const words = text.trim().split(/\s+/).filter(Boolean).length;
  const score = Math.round(Math.min(100, Math.max(35, 45 + Math.min(words, 120) * 0.35 + (/[.!?]/.test(text) ? 8 : 0) + (text.length > 250 ? 10 : 0))));
  return { score, grammar: Math.min(100, score + 2), vocabulary: Math.max(0, score - 3), coherence: score, feedback: words < 80 ? "Develop your ideas with more details, examples and connectors." : "Good start. Add more precise vocabulary and review verb tenses for a stronger answer.", provider: "local-free-fallback" };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const body = await req.json();
    const text = String(body.text || "").trim();
    const level = String(body.level || "A1");
    const language = String(body.language || "en");
    if (!text) return new Response(JSON.stringify({ error: "Text is required" }), { status: 400, headers: cors });

    const key = Deno.env.get("GEMINI_API_KEY");
    if (!key) return new Response(JSON.stringify(localScore(text)), { headers: cors });

    const prompt = `You are an expert CEFR language teacher. Evaluate this ${language === "es" ? "Spanish" : "English"} writing at level ${level}.
Return ONLY JSON with: score, grammar, vocabulary, coherence, task_achievement, corrections (array of strings), feedback.
Text:
${text}`;

    const response = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + encodeURIComponent(key), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
    });
    if (!response.ok) return new Response(JSON.stringify(localScore(text)), { headers: cors });
    const data = await response.json();
    const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";
    const clean = raw.replace(/^\s*```json\s*/i, "").replace(/\s*```\s*$/i, "").trim();
    let result;
    try { result = JSON.parse(clean); } catch { result = localScore(text); }
    return new Response(JSON.stringify({ ...result, provider: "gemini" }), { headers: cors });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e?.message || e) }), { status: 500, headers: cors });
  }
});