-- ====================================================================
-- EduSync Reference Curriculum Topics & Prompt Seed Data
-- ====================================================================

-- 1. Insert Known Curriculum Topics for AI Tutor Grounding
INSERT INTO public.curriculum_topics (
    board_or_university,
    grade_or_degree,
    department_or_stream,
    subject,
    chapter_or_unit,
    topic_name,
    key_concepts
) VALUES
-- CBSE Grade 10 Science: Life Processes - Photosynthesis
(
    'CBSE',
    'Grade 10',
    'Science',
    'Science',
    'Chapter 6: Life Processes',
    'Photosynthesis',
    'Autotrophic nutrition process. Balanced Chemical Equation: 6CO2 + 6H2O -> C6H12O6 + 6O2 (in presence of Sunlight and Chlorophyll). Key sequential steps: (1) Absorption of light energy by chlorophyll, (2) Conversion of light energy to chemical energy and splitting of water molecules into hydrogen and oxygen (photolysis), (3) Reduction of carbon dioxide to carbohydrates. Role of stomata, guard cells, chloroplasts, and starch test using iodine solution.'
),

-- Tamil Nadu State Board Grade 10 Science: Plant Physiology - Photosynthesis & Plastids
(
    'Tamil Nadu State Board',
    'Grade 10',
    'Science',
    'Science',
    'Unit 12: Plant Anatomy and Plant Physiology',
    'Photosynthesis and Plastids',
    'Samacheer Kalvi syllabus. Photosynthesis mechanism: Overall equation 6CO2 + 12H2O -> C6H12O6 + 6H2O + 6O2. Chloroplast anatomy: double membrane, stroma, thylakoids, grana. Two phases: (1) Light-dependent reaction (Hill Reaction) taking place in thylakoid membrane/grana producing ATP and NADPH2, (2) Light-independent reaction (Dark Reaction / Calvin Cycle) occurring in stroma fixing CO2 into carbohydrates using ATP and NADPH2. Factors: light intensity, CO2 concentration, temperature, water.'
),

-- B.Tech Computer Science: Software Engineering - Waterfall Model
(
    'Anna University / VTU / Indian Engineering Universities',
    'B.Tech',
    'Computer Science & Engg (CSE)',
    'Software Engineering',
    'Unit 1: Software Process Models',
    'Waterfall Model',
    'Classical linear sequential software development life cycle (SDLC) model proposed by Winston Royce (1970). Six sequential phases: (1) Requirements Analysis and Specification (SRS document creation), (2) System and Software Design (architectural, high-level, and low-level design), (3) Implementation and Unit Testing (source coding and unit verification), (4) Integration and System Testing (verifying interrelated modules and functional requirements), (5) Deployment / Installation (release to client production environment), (6) Maintenance (corrective, adaptive, and perfective maintenance). Advantages: Simple, disciplined, clear documentation milestones, suitable for stable requirements. Limitations: Rigid, no working software until late lifecycle, high risk of late-stage defect discovery, unsuitable for dynamic or agile projects. Real-world applications: High-integrity safety-critical systems, defense contracts, banking ATM firmware, railway interlocking software.'
)
ON CONFLICT DO NOTHING;
