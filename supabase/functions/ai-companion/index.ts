// ====================================================================
// Supabase Edge Function: ai-companion
// Secure server-side AI endpoint for EduSync
// Evaluates student profile, matches curriculum topics, and calls real LLM.
// NEVER exposes AI_API_KEY or SUPABASE_SERVICE_ROLE_KEY to the client.
// ====================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const {
      question,
      conversation_id,
      student_profile: clientProfile,
      current_subject,
      study_material_text,
      study_material_name,
      history = [],
    } = await req.json();

    if (!question || typeof question !== "string" || !question.trim()) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid question parameter" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Read Server Environment Variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    const aiProvider = (Deno.env.get("AI_PROVIDER") || "gemini").toLowerCase();
    const aiApiKey = Deno.env.get("AI_API_KEY") || "";
    const aiModel = Deno.env.get("AI_MODEL") || (aiProvider === "openai" ? "gpt-4o-mini" : "gemini-1.5-flash");

    // Fail early if AI API key is not configured
    if (!aiApiKey) {
      return new Response(
        JSON.stringify({
          error: "AI service temporarily unavailable. AI_API_KEY is not configured on the server. Please configure backend secrets.",
          code: "missing_api_key",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Initialize Supabase Admin Client
    let supabase: any = null;
    let authenticatedUser: any = null;
    let storedProfile: any = null;

    if (supabaseUrl && supabaseServiceKey) {
      supabase = createClient(supabaseUrl, supabaseServiceKey, {
        auth: { persistSession: false },
      });

      // Verify logged-in student via JWT Authorization header
      const authHeader = req.headers.get("Authorization");
      if (authHeader) {
        const token = authHeader.replace("Bearer ", "");
        const { data: { user }, error: userError } = await supabase.auth.getUser(token);
        if (!userError && user) {
          authenticatedUser = user;
          // Load stored student profile from database
          const { data: profileData } = await supabase
            .from("student_profiles")
            .select("*")
            .eq("id", user.id)
            .single();
          storedProfile = profileData;
        }
      }
    }

    // Merge database profile with client provided profile
    const profile = storedProfile || clientProfile || {};
    const isSchool = profile.is_school_student ?? profile.isSchoolStudent ?? true;
    const grade = profile.grade || "Grade 10";
    const board = profile.board || "CBSE";
    const state = profile.state || "Tamil Nadu";
    const medium = profile.medium || "English";
    const subjects = Array.isArray(profile.subjects) ? profile.subjects.join(", ") : "Science, Mathematics";
    const goal = profile.main_goal || profile.mainGoal || "Understand concepts";
    const degree = profile.degree || "B.Tech";
    const department = profile.department || "Computer Science & Engg (CSE)";
    const semester = profile.year_or_sem || profile.yearOrSem || "Semester 3";
    const collegeName = profile.college_name || profile.collegeName || "";

    // 3. Search and Retrieve Relevant Curriculum Topics from Database
    let curriculumContext = "";
    if (supabase) {
      try {
        const { data: topics } = await supabase
          .from("curriculum_topics")
          .select("*");

        if (topics && topics.length > 0) {
          const qLower = question.toLowerCase();
          // Find matching curriculum topic
          const matched = topics.find((t: any) => {
            const topicLower = (t.topic_name || "").toLowerCase();
            const conceptsLower = (t.key_concepts || "").toLowerCase();
            return (
              qLower.includes(topicLower) ||
              topicLower.split(" ").some((word: string) => word.length > 3 && qLower.includes(word)) ||
              conceptsLower.split(",").some((c: string) => c.trim().length > 3 && qLower.includes(c.trim().toLowerCase()))
            );
          });

          if (matched) {
            curriculumContext = `\nOFFICIAL CURRICULUM TOPIC MATCH [${matched.board_or_university} - ${matched.grade_or_degree} - ${matched.subject} - ${matched.chapter_or_unit} - ${matched.topic_name}]:\nKey Concepts: ${matched.key_concepts}\n`;
          }
        }
      } catch (err) {
        console.warn("Could not query curriculum_topics:", err);
      }
    }

    // 4. Construct Tutor System Instruction
    const profileContext = isSchool
      ? `School: ${grade}, ${board}, ${state}, ${medium}, subjects: [${subjects}], goal: ${goal}`
      : `College: ${degree}, ${department}, ${semester}, subjects: [${subjects}], goal: ${goal}, college: ${collegeName || "Not specified"}`;

    const systemPrompt = `You are EduSync, a helpful and patient AI study tutor for Indian students.
Always adapt your answers to the student's profile:
- ${profileContext}

Rules:
1. Explain clearly for this specific level. Avoid unnecessary jargon for younger students; provide technical depth for college students.
2. If relevant, refer to the curriculum of CBSE, Tamil Nadu State Board, or Indian university standards as appropriate. If no exact syllabus match exists, answer correctly for the student's educational stage without claiming syllabus alignment.
3. If study material or curriculum topic is provided, use it directly.
4. Structure your response:
   - Direct explanation
   - Key points or steps
   - Simple example (use Indian context when helpful)
   - Quick summary or formula if applicable
5. Be encouraging and concise.
6. Support multiple Indian languages when requested.
7. When the student asks follow-up questions, remember the conversation history.${curriculumContext}`;

    // 5. Build Conversation History Context
    const conversationHistory: Array<{ role: string; content: string }> = [];
    if (Array.isArray(history) && history.length > 0) {
      for (const msg of history.slice(-6)) {
        if (msg.role && msg.content) {
          conversationHistory.push({
            role: msg.role === "assistant" ? "assistant" : "user",
            content: String(msg.content),
          });
        }
      }
    }

    let userPromptWithMaterial = question;
    if (study_material_text && study_material_name) {
      userPromptWithMaterial = `STUDY MATERIAL (${study_material_name}):\n"""\n${study_material_text.substring(0, 3000)}\n"""\n\nSTUDENT QUESTION:\n${question}`;
    }

    // 6. Call LLM API (Google Gemini or OpenAI)
    let aiContent = "";

    if (aiProvider === "gemini") {
      const contents = [];
      for (const m of conversationHistory) {
        contents.push({
          role: m.role === "assistant" ? "model" : "user",
          parts: [{ text: m.content }],
        });
      }
      contents.push({
        role: "user",
        parts: [{ text: userPromptWithMaterial }],
      });

      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${aiModel}:generateContent?key=${aiApiKey}`;
      const resp = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: systemPrompt }],
          },
          contents,
          generationConfig: {
            temperature: 0.4,
            maxOutputTokens: 1500,
          },
        }),
      });

      if (!resp.ok) {
        const errText = await resp.text();
        throw new Error(`Gemini API error (${resp.status}): ${errText}`);
      }

      const resJson = await resp.json();
      aiContent = resJson.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!aiContent) {
        throw new Error("Empty response received from Gemini model.");
      }
    } else {
      // OpenAI or Groq compatible API
      const messages = [
        { role: "system", content: systemPrompt },
        ...conversationHistory.map((m) => ({
          role: m.role === "assistant" ? "assistant" : "user",
          content: m.content,
        })),
        { role: "user", content: userPromptWithMaterial },
      ];

      const apiUrl = aiProvider === "groq"
        ? "https://api.groq.com/openai/v1/chat/completions"
        : "https://api.openai.com/v1/chat/completions";

      const resp = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${aiApiKey}`,
        },
        body: JSON.stringify({
          model: aiModel,
          messages,
          temperature: 0.4,
        }),
      });

      if (!resp.ok) {
        const errText = await resp.text();
        throw new Error(`OpenAI API error (${resp.status}): ${errText}`);
      }

      const resJson = await resp.json();
      aiContent = resJson.choices?.[0]?.message?.content;
      if (!aiContent) {
        throw new Error("Empty response received from LLM model.");
      }
    }

    // 7. Generate Dynamic Contextual Follow-up Chips
    const followUps = isSchool
      ? [
          "Explain Simpler",
          "Give an Example",
          "Create Quiz",
          "Make Flashcards",
          `Translate into ${medium}`,
        ]
      : [
          "Explain Simpler",
          "Give an Example",
          "Create Quiz",
          "Make Flashcards",
          "Show Code / Implementation",
        ];

    // 8. Save Question and AI Answer in Student's Private Chat History
    if (supabase && authenticatedUser && conversation_id) {
      try {
        await supabase.from("messages").insert([
          {
            conversation_id: conversation_id,
            role: "user",
            content: question,
          },
          {
            conversation_id: conversation_id,
            role: "assistant",
            content: aiContent,
            suggested_follow_ups: followUps,
            source_citations: study_material_name ? [study_material_name] : [],
          },
        ]);
      } catch (saveErr) {
        console.warn("Could not save to chat history:", saveErr);
      }
    }

    return new Response(
      JSON.stringify({
        content: aiContent,
        suggested_follow_ups: followUps,
        source_name: study_material_name,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error: any) {
    console.error("AI companion error:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Failed to process question. Please try again.",
        code: "backend_error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
