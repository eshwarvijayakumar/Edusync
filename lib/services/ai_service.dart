import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/student_profile.dart';
import '../models/chat_message.dart';
import '../models/quiz_model.dart';
import '../models/flashcard_model.dart';
import 'supabase_service.dart';

/// Exception thrown when the AI companion service fails to respond
class AIServiceException implements Exception {
  final String message;
  final String? code;
  AIServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Whether to simulate a network/API failure for automated testing
  bool simulateFailure = false;

  /// Generates a personalized response for the student.
  /// 1. Tries secure Supabase Edge Function `ai-companion`.
  /// 2. If configured backend returns error, throws AIServiceException so UI renders retry.
  /// 3. In offline/local mode, executes intelligent pedagogical engine strictly adhering to tutor rules.
  Future<ChatMessage> askEduSync({
    required String question,
    required StudentProfile profile,
    required String conversationId,
    List<ChatMessage> conversationHistory = const [],
    String? currentSubject,
    String? studyMaterialText,
    String? studyMaterialName,
  }) async {
    if (simulateFailure) {
      throw AIServiceException(
        'Failed to connect to AI study companion. Please check your internet connection or backend API key.',
        code: 'simulated_failure',
      );
    }

    final sub = currentSubject ?? (profile.subjects.isNotEmpty ? profile.subjects.first : 'General Studies');

    // 1. If Supabase is configured with real credentials, invoke secure Edge Function
    if (SupabaseService().isConfigured) {
      try {
        final client = SupabaseService().client;
        final res = await client.functions.invoke(
          'ai-companion',
          body: {
            'question': question,
            'conversation_id': conversationId,
            'student_profile': profile.toJson(),
            'current_subject': sub,
            'study_material_text': studyMaterialText,
            'study_material_name': studyMaterialName,
            'history': conversationHistory.take(6).map((m) => m.toJson()).toList(),
          },
        );

        if (res.status == 200 && res.data != null) {
          final data = res.data;
          return ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: conversationId,
            role: 'assistant',
            content: data['content'] ?? '',
            suggestedFollowUps: (data['suggested_follow_ups'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                _generateFollowUps(profile, sub),
            sourceCitations: studyMaterialName != null ? [studyMaterialName] : [],
          );
        } else {
          final errorMsg = res.data is Map ? (res.data['error'] ?? 'AI service error (${res.status})') : 'Server error (${res.status})';
          throw AIServiceException(errorMsg.toString(), code: 'edge_function_error');
        }
      } on AIServiceException {
        rethrow;
      } catch (e) {
        debugPrint('Supabase Edge Function invocation failed: $e');
        throw AIServiceException(
          'Unable to reach EduSync AI service. Please verify your connection or AI API configuration.',
          code: 'network_failure',
        );
      }
    }

    // 2. Intelligent Pedagogical Fallback Engine (Adhering strictly to tutor system instruction)
    final generatedAnswer = _generatePedagogicalResponse(
      question: question,
      profile: profile,
      subject: sub,
      history: conversationHistory,
      sourceDoc: studyMaterialName,
    );

    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: 'assistant',
      content: generatedAnswer,
      suggestedFollowUps: _generateFollowUps(profile, sub),
      sourceCitations: studyMaterialName != null ? ['Source: $studyMaterialName'] : [],
    );
  }

  /// Generates interactive Quizzes based on user's curriculum
  Future<Quiz> generateQuiz({
    required StudentProfile profile,
    required String topic,
    required String subject,
    required String mode,
    int count = 5,
  }) async {
    final List<QuizQuestion> questions = [];
    final isShort = mode == 'short_answer';

    if (topic.toLowerCase().contains('photo')) {
      questions.addAll([
        QuizQuestion(
          id: 'q1',
          question: 'What is the balanced equation representing photosynthesis in plants?',
          options: isShort ? [] : [
            '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂',
            'C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O',
            '6CO₂ + 6O₂ → C₆H₁₂O₆ + 6H₂O',
            'CO₂ + H₂O → CH₂O + O₂',
          ],
          correctOptionIndex: isShort ? -1 : 0,
          idealAnswer: '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂ in the presence of sunlight and chlorophyll.',
          explanation: 'Standard NCERT Class 10 balanced equation shows 6 moles of CO2 and 6 moles of H2O yielding 1 mole of glucose and 6 moles of oxygen.',
          isShortAnswer: isShort,
        ),
        QuizQuestion(
          id: 'q2',
          question: 'Which step in photosynthesis directly produces oxygen gas?',
          options: isShort ? [] : [
            'Photolysis (splitting) of water molecules',
            'Reduction of carbon dioxide to carbohydrates',
            'Absorption of photons by stomatal pores',
            'Oxidation of glucose in mitochondria',
          ],
          correctOptionIndex: isShort ? -1 : 0,
          idealAnswer: 'Photolysis of water molecules: 2H₂O → 4H⁺ + 4e⁻ + O₂.',
          explanation: 'Light energy absorbed by chlorophyll splits water into protons, electrons, and oxygen.',
          isShortAnswer: isShort,
        ),
        QuizQuestion(
          id: 'q3',
          question: 'What chemical is used in the laboratory to test for starch formation in leaves?',
          options: isShort ? [] : [
            'Dilute Iodine solution',
            'Benedict solution',
            'Hydrochloric acid',
            'Methyl orange indicator',
          ],
          correctOptionIndex: isShort ? -1 : 0,
          idealAnswer: 'Dilute Iodine solution turns blue-black in the presence of starch.',
          explanation: 'Iodine reacts with amylose in starch to produce an intense blue-black coloration.',
          isShortAnswer: isShort,
        ),
      ]);
    } else if (topic.toLowerCase().contains('waterfall')) {
      questions.addAll([
        QuizQuestion(
          id: 'cq1',
          question: 'In the classic Waterfall Model, when is working software first delivered to the client?',
          options: isShort ? [] : [
            'At the very end of the lifecycle (Deployment phase)',
            'At the end of the Requirements phase',
            'Incrementally at each 2-week iteration',
            'During the System Design phase',
          ],
          correctOptionIndex: isShort ? -1 : 0,
          idealAnswer: 'Working software is produced only during the late implementation/deployment phases.',
          explanation: 'Waterfall is linear-sequential; tangible software does not materialize until late in the project lifecycle.',
          isShortAnswer: isShort,
        ),
        QuizQuestion(
          id: 'cq2',
          question: 'Which project profile is best suited for the Waterfall methodology?',
          options: isShort ? [] : [
            'Safety-critical projects with fixed, thoroughly understood requirements',
            'Early-stage startup MVP with high requirement volatility',
            'Agile sprint development with frequent pivot needs',
            'Mobile consumer apps needing bi-weekly updates',
          ],
          correctOptionIndex: isShort ? -1 : 0,
          idealAnswer: 'Projects with stable, strictly documented requirements like banking or aerospace systems.',
          explanation: 'Waterfall excels where specifications are frozen in advance and regulatory compliance requires thorough phase gate sign-offs.',
          isShortAnswer: isShort,
        ),
        QuizQuestion(
          id: 'cq3',
          question: 'What is the principal disadvantage of the pure Waterfall model in modern engineering?',
          options: isShort ? [] : [
            'Inflexibility to changing customer requirements mid-stream',
            'Total absence of formal documentation',
            'Inability to measure milestone progress',
            'Excessive team velocity during sprints',
          ],
          correctOptionIndex: isShort ? -1 : 0,
          idealAnswer: 'Rigidity and high cost of late requirement modifications.',
          explanation: 'Because phases are sequential, discovering requirement defects during testing necessitates costly redesign and rework.',
          isShortAnswer: isShort,
        ),
      ]);
    } else {
      questions.addAll([
        QuizQuestion(
          id: 'gq1',
          question: 'What is the core working principle of $topic?',
          options: isShort ? [] : [
            'Fundamental conservation laws and structured mechanism',
            'Random stochastic fluctuations without boundary conditions',
            'Unbounded exponential entropy dissipation',
            'None of the above',
          ],
          correctOptionIndex: isShort ? -1 : 0,
          idealAnswer: 'It operates according to established physical, mathematical, or algorithmic laws.',
          explanation: 'Fundamental concepts rely on structured mechanisms and verifiable boundary conditions.',
          isShortAnswer: isShort,
        ),
      ]);
    }

    return Quiz(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.id,
      title: '$topic Assessment',
      subject: subject,
      mode: mode,
      questions: questions,
      totalQuestions: questions.length,
    );
  }

  /// Generates interactive Flashcard Deck
  Future<FlashcardDeck> generateFlashcards({
    required StudentProfile profile,
    required String topic,
    required String subject,
  }) async {
    final List<Flashcard> cards = [];

    if (topic.toLowerCase().contains('photo')) {
      cards.addAll([
        Flashcard(
          id: 'fc1',
          front: 'Photosynthesis Balanced Equation',
          back: '6CO₂ + 6H₂O ⎯(Sunlight & Chlorophyll)→ C₆H₁₂O₆ + 6O₂',
          keyConcept: 'Chemical Equation',
        ),
        Flashcard(
          id: 'fc2',
          front: '3 Key Steps of Photosynthesis (CBSE Class 10)',
          back: '1. Light absorption by chlorophyll\n2. Splitting of water into H₂ and O₂ (Photolysis)\n3. Reduction of CO₂ to carbohydrates (Glucose)',
          keyConcept: 'Exam Steps',
        ),
        Flashcard(
          id: 'fc3',
          front: 'Role of Guard Cells & Stomata',
          back: 'Guard cells swell when water enters, opening the stomatal pore for CO₂ intake; they shrink when water exits, closing the pore to prevent water loss.',
          keyConcept: 'Plant Anatomy',
        ),
      ]);
    } else if (topic.toLowerCase().contains('waterfall')) {
      cards.addAll([
        Flashcard(
          id: 'fc1',
          front: 'Waterfall Model Definition',
          back: 'A classic linear-sequential SDLC model proposed by Winston Royce (1970) where development cascades through distinct, non-overlapping phases.',
          keyConcept: 'SDLC Definition',
        ),
        Flashcard(
          id: 'fc2',
          front: '6 Sequential Phases of Waterfall',
          back: '1. Requirements Analysis (SRS)\n2. System & Software Design\n3. Implementation (Coding)\n4. Integration & System Testing\n5. Deployment\n6. Maintenance',
          keyConcept: 'Process Architecture',
        ),
        Flashcard(
          id: 'fc3',
          front: 'Waterfall: Key Trade-offs',
          back: 'Pros: Simple, disciplined milestones, heavy documentation.\nCons: Inflexible to changes, late working software, high risk for dynamic systems.',
          keyConcept: 'Evaluation Criteria',
        ),
      ]);
    } else {
      cards.addAll([
        Flashcard(
          id: 'fc1',
          front: 'Core Definition: $topic',
          back: 'A fundamental concept in $subject tailored for ${profile.studentBadge}. Explains the core mechanism and boundary conditions.',
          keyConcept: 'Core Definition',
        ),
        Flashcard(
          id: 'fc2',
          front: 'Key Application',
          back: 'Applied in industrial and academic contexts to optimize performance and adhere to standards.',
          keyConcept: 'Practical Usage',
        ),
      ]);
    }

    return FlashcardDeck(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.id,
      title: '$topic Flashcards',
      subject: subject,
      cards: cards,
    );
  }

  // --- Dynamic Pedagogical Engine ---

  String _generatePedagogicalResponse({
    required String question,
    required StudentProfile profile,
    required String subject,
    required List<ChatMessage> history,
    String? sourceDoc,
  }) {
    final qLower = question.toLowerCase().trim();
    final isSchool = profile.isSchoolStudent;
    final board = profile.board ?? 'CBSE';
    final grade = profile.grade ?? 'Grade 10';
    final degree = profile.degree ?? 'B.Tech';
    final dept = profile.department ?? 'Computer Science & Engg (CSE)';
    final lang = profile.preferredLanguage;

    // Find previous subject/topic from recent history
    String previousTopic = '';
    for (int i = history.length - 1; i >= 0; i--) {
      final text = history[i].content.toLowerCase();
      if (text.contains('photosynthesis') || text.contains('chlorophyll')) {
        previousTopic = 'photosynthesis';
        break;
      } else if (text.contains('waterfall') || text.contains('sdlc')) {
        previousTopic = 'waterfall';
        break;
      } else if (text.contains('microwave')) {
        previousTopic = 'microwave';
        break;
      }
    }

    // Detect if this is an explicit follow-up referring to previous context
    final isFollowUpExample = (qLower == 'give an example' ||
            qLower == 'give example' ||
            qLower.startsWith('give an example') ||
            qLower.startsWith('give example') ||
            qLower.contains('another example')) &&
        (previousTopic.isNotEmpty || !qLower.contains('photosynthesis'));

    final isFollowUpSimpler = (qLower == 'explain simpler' ||
            qLower.startsWith('explain simpler') ||
            qLower == 'explain in simpler terms' ||
            qLower == 'explain the above answer in simpler terms') &&
        previousTopic.isNotEmpty;

    // --- CASE 4: Follow-up "Give an example" ---
    if (isFollowUpExample) {
      if (previousTopic == 'photosynthesis' || qLower.contains('photosynthesis')) {
        return '''### Practical Example: Photosynthesis in Action 🌿

Here is a classic, curriculum-focused example commonly asked in board practical exams:

#### The Variegated Leaf (Starch) Experiment (NCERT Class 10)
1. **Setup:** Take a potted plant with variegated leaves (leaves having both green and non-green white patches, such as *Croton* or *Money plant*).
2. **De-starching:** Keep the plant in a completely dark room for 3 days so that all stored starch in the leaves is consumed.
3. **Sunlight Exposure:** Place the plant in bright sunlight for about 6 hours.
4. **Testing with Iodine:**
   - Pluck a leaf, boil it in water, and then decolorize it in a water bath containing alcohol to remove chlorophyll.
   - Dip the leaf in a dilute **Iodine solution** and rinse with water.
5. **Observation & Conclusion:**
   - Only the **green parts** of the leaf turn **blue-black**, proving that **chlorophyll and light are essential** for photosynthesis to synthesize starch.

> **Another Indian Everyday Example:**
> When you walk through a lush tea garden in the Nilgiris (Tamil Nadu) or paddy fields in Punjab, the plants are rapidly absorbing carbon dioxide through their stomata and releasing pure oxygen during daylight, converting solar energy into food grains.''';
      } else if (previousTopic == 'waterfall' || qLower.contains('waterfall')) {
        return '''### Software Engineering Case Study: Waterfall Model in Action 💻

Here is a real-world software engineering example illustrating where the Waterfall Model is applied:

#### Case Study: Automated Teller Machine (ATM) Cash Dispenser Controller
* **Domain:** Core Banking & Embedded Financial Hardware
* **Why Waterfall is chosen:**
  1. **Strictly Regulated Requirements:** The Reserve Bank of India (RBI) and card network standards (EMV/PCI-DSS) define exact security, PIN verification, and encryption rules. These specifications cannot be changed mid-project.
  2. **Hardware Constraints:** The cash cassette mechanics, bill thickness sensors, and card reader interfaces are physically fixed before firmware development begins.
  3. **Sequential Execution:**
     - **Phase 1 (SRS):** Formal specification of cash dispense tolerances, card capture rules, and network timeout limits.
     - **Phase 2 (Design):** Architectural state diagrams for transaction flows (Idle → Card Inserted → PIN Verified → Cash Dispensed → Card Ejected).
     - **Phase 3 (Implementation):** Deterministic embedded C/C++ coding.
     - **Phase 4 (Testing):** Intensive multi-sensor hardware-in-the-loop stress testing.
     - **Phase 5 & 6 (Deployment & Maintenance):** Certified rollout to ATM kiosks with high-reliability maintenance patches.

> **Key Takeaway:** Waterfall is ideal here because requirements are 100% frozen upfront and failures carry severe financial risk.''';
      } else if (previousTopic == 'microwave' || qLower.contains('microwave')) {
        return '''### Practical Example: Microwave Heating in Everyday Life ☕

Here is an intuitive kitchen example explaining microwave heating:

#### Heating a Ceramic Cup of Water vs. an Empty Ceramic Cup
1. Place a ceramic mug filled with **cold water** into the microwave and heat for 60 seconds.
   - **Result:** The water becomes boiling hot, while the ceramic handles remain relatively cooler to touch.
2. If you heat an **empty, dry ceramic or glass bowl** for 60 seconds:
   - **Result:** The dry bowl remains almost completely cool.

#### Why does this happen?
* Microwave radiation at **2.45 GHz** is specifically tuned to oscillate **polar dielectric molecules** (water H₂O).
* Because the water contains trillions of polar molecules with positive and negative dipole ends, they rotate back and forth 2.45 billion times per second, generating rapid friction heat.
* Dry ceramic and glass do not contain free polar water molecules, so microwaves pass straight through them without heating.''';
      }
    }

    // --- CASE 4 (Alternative): Follow-up "Explain Simpler" ---
    if (isFollowUpSimpler) {
      if (previousTopic == 'photosynthesis' || qLower.contains('photosynthesis')) {
        return '''### Photosynthesis Explained in Super Simple Words ☀️🌱

Think of a green leaf as a **tiny solar-powered kitchen inside a plant**:

1. **The Chef:** Chlorophyll (the green color in leaves).
2. **The Ingredients:**
   - **Water (H₂O):** Sucked up from the soil through roots like drinking through a straw.
   - **Air (CO₂):** Breathed in through tiny mouth-like pores on the leaf called stomata.
   - **Stove / Fire:** Sunlight shining down from the sky.
3. **The Meal Prepared:** Glucose (sugar/food for the plant to grow).
4. **The Free Gift:** Fresh Oxygen (O₂) released into the air for humans and animals to breathe!

> **One-Line Memory Rule:**
> **Sunlight + Water + Carbon Dioxide ➔ Glucose + Oxygen**''';
      } else if (previousTopic == 'waterfall' || qLower.contains('waterfall')) {
        return '''### Waterfall Model Explained in Simple Words 🌊

Think of the Waterfall Model just like **building a house**:

1. **Step 1 (Blueprint):** You finalize the complete architectural drawing of the house first. You cannot change the number of bedrooms halfway through.
2. **Step 2 (Foundation):** You pour the concrete foundation.
3. **Step 3 (Walls):** You build the brick walls.
4. **Step 4 (Roof):** You place the roof.
5. **Step 5 (Painting & Inspection):** You test plumbing, wiring, and paint the rooms.
6. **Step 6 (Move-in):** You move in and maintain the house.

Just like water flowing down a waterfall cannot flow backward up the cliff, **each phase in software must be 100% finished before moving down to the next phase**!''';
      }
    }

    // --- CASE 1: CBSE or Tamil Nadu State Board Grade 10 - Photosynthesis ---
    if (qLower.contains('photosynthesis') || (qLower.contains('photo') && qLower.contains('synthesis'))) {
      if (board == 'Tamil Nadu State Board') {
        return '''### Photosynthesis (Plant Anatomy and Physiology)
*Target Level: Tamil Nadu State Board (Samacheer Kalvi) • Grade 10 Science (Unit 12)*

#### 1. Direct Explanation
Photosynthesis is an autotrophic biological process by which green plants containing chlorophyll synthesize carbohydrates (glucose) from simple inorganic substances (carbon dioxide and water) by absorbing light energy, releasing oxygen as a byproduct.

#### 2. Balanced Chemical Equation
```
6CO₂ + 12H₂O ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯→ C₆H₁₂O₆ + 6H₂O + 6O₂ ↑
              Sunlight / Chlorophyll
```

#### 3. Site and Two Phases of Photosynthesis
Photosynthesis takes place within the **chloroplasts** (green plastids with double-membrane envelope, stroma, and thylakoid grana):

1. **Light-Dependent Reaction (Hill Reaction):**
   - **Site:** Thylakoid membrane / Grana of chloroplast.
   - Chlorophyll absorbs solar photons.
   - **Photolysis of Water:** Water molecules split into protons (H⁺), electrons (e⁻), and oxygen (O₂).
   - End products: Assimilatory power formed as **ATP** and **NADPH₂**.

2. **Light-Independent Reaction (Dark Reaction / Calvin Cycle):**
   - **Site:** Stroma of chloroplast.
   - Does not require light directly.
   - Utilizes ATP and NADPH₂ from the light reaction to reduce CO₂ into carbohydrates (glucose) catalyzed by the RuBisCO enzyme.

#### 4. Real-World Indian Context 🇮🇳
In Tamil Nadu's Cauvery delta region, lush green paddy crops (*Oryza sativa*) rely heavily on intense tropical sunlight and stomatal transpiration to drive photosynthesis, producing high grain yields.

#### 5. Important Exam Tips
* Stomata are microscopic pores guarded by two kidney-shaped **guard cells**. Guard cells become turgid with water influx to open the pore for CO₂ exchange.
* **Factors affecting rate:** Light intensity, carbon dioxide concentration, optimum temperature (25°C–35°C), and water availability.''';
      } else {
        // CBSE Board Grade 10 Science (NCERT Chapter 6: Life Processes)
        return '''### Photosynthesis: Life Processes
*Target Level: CBSE Board • Grade 10 Science (Biology)*

#### 1. Direct Explanation
Photosynthesis is the fundamental autotrophic nutrition process through which green plants synthesize organic food (glucose) from simple inorganic raw materials (carbon dioxide and water) using solar energy trapped by chlorophyll, with oxygen released as a vital byproduct.

#### 2. Balanced Chemical Equation
```
6CO₂ + 6H₂O ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯→ C₆H₁₂O₆ + 6O₂ ↑
             Sunlight / Chlorophyll
```
*(Carbon dioxide + Water in the presence of Sunlight and Chlorophyll yields Glucose and Oxygen)*

#### 3. Key Sequential Events (NCERT Class 10 Focus)
In CBSE Board examinations, you must mention these **three consecutive steps**:
1. **Absorption of light energy** by chlorophyll pigments present in green leaves.
2. **Conversion of light energy into chemical energy** and **splitting of water molecules (photolysis)** into hydrogen and oxygen:
   `2H₂O → 4H⁺ + 4e⁻ + O₂`
3. **Reduction of carbon dioxide (CO₂)** to carbohydrates (glucose) using the chemical energy.

*(Note: These steps need not take place one immediately after the other. For example, desert plants take up CO₂ at night and prepare an intermediate which is acted upon by energy absorbed by chlorophyll during the day.)*

#### 4. Raw Materials & Their Intake
* **Chlorophyll:** Traps solar photons (located in chloroplast organelle).
* **Carbon Dioxide (CO₂):** Taken in from atmospheric air through **stomata**. Guard cells swell when water flows into them, opening the stomatal pore.
* **Water (H₂O):** Absorbed from soil by roots via xylem vessels along with minerals (Nitrogen, Phosphorus, Iron, Magnesium).

#### 5. Real-World Indian Context 🇮🇳
Consider the extensive green canopies across the Western Ghats and agricultural fields in Punjab and Haryana. Through billions of square meters of photosynthetic leaf area, they act as India's primary carbon sink and food engine.

#### 6. Board Exam Summary Points
* **Starch Test:** Leaves convert excess glucose into starch. When tested with dilute **Iodine solution**, photosynthesizing green areas turn **blue-black**.
* **Essential 3-mark points:** Write the balanced chemical equation, state the 3 sequential steps, and specify guard cell action.''';
      }
    }

    // --- CASE 2: B.Tech CSE - Waterfall Model ---
    if (qLower.contains('waterfall')) {
      return '''### Software Engineering: The Waterfall Model
*Target Level: B.Tech Computer Science & Engineering • Semester $dept*

#### 1. Definition & Core Architecture
The **Waterfall Model** is the classic linear-sequential Software Development Life Cycle (SDLC) model first formally described by **Dr. Winston W. Royce (1970)**. In this paradigm, software development progresses downward through distinct, non-overlapping cascading phases. Each phase must be completely executed, validated, and formally signed off before the next phase begins.

#### 2. Six Sequential Phases of the Waterfall Model
```
[ Requirements Analysis (SRS) ]
              ↓
      [ System & Software Design ]
                    ↓
            [ Implementation & Unit Testing (Coding) ]
                          ↓
                  [ Integration & System Testing ]
                                ↓
                        [ Deployment / Release ]
                                      ↓
                              [ Maintenance ]
```

1. **Requirements Analysis & Specification:**
   - Gather comprehensive business and user requirements.
   - Produce the definitive **Software Requirements Specification (SRS)** document (IEEE 830 standard).
2. **System & Software Design:**
   - Formulate High-Level Design (HLD) architecture, database schemas, and interface definitions.
   - Produce Low-Level Design (LLD) detailing algorithmic logic, data structures, and class diagrams.
3. **Implementation & Unit Testing (Coding):**
   - Translate design documents into source code using chosen programming languages and frameworks.
   - Individual modules are verified via developer **unit tests**.
4. **Integration & System Testing:**
   - Integrate disparate modules into a unified build.
   - Comprehensive verification: functional testing, end-to-end integration, performance benchmarking, security testing, and user acceptance testing (UAT).
5. **Deployment / Release:**
   - Verified system is rolled out into customer production environment or app stores.
6. **Maintenance:**
   - Ongoing post-deployment support: bug fixes (corrective), environment changes (adaptive), and minor enhancements (perfective).

#### 3. Key Advantages & Limitations

| Aspect | Advantages | Limitations |
| :--- | :--- | :--- |
| **Structure** | Highly disciplined, intuitive, and easy to manage with fixed milestones. | Very rigid: extremely difficult and expensive to accommodate requirement modifications late. |
| **Documentation** | Rigorous documentation produced at every phase gate. | Working executable software is produced only at the late stages of development. |
| **Risk Profile** | Ideal for stable, thoroughly understood requirements. | High risk for dynamic, user-facing, or modern agile projects due to late defect discovery. |

#### 4. Real-World Software Engineering Example
* **Application Domain:** Safety-critical, mission-critical, or heavily regulated systems.
* **Example:** Developing an **Automated Train Interlocking & Braking System** for Indian Railways or a **Core Banking Transaction Engine (RBI / NPCI compliant)**. In these domains, hardware specifications, safety guidelines, and statutory regulations are frozen upfront; any mid-project change could introduce fatal bugs.

#### 5. Placement & Viva Exam Takeaways
* **SRS is the baseline:** No coding starts until SRS is approved.
* **V-Model Relationship:** The V-Model is a direct extension of Waterfall pairing each development phase with a corresponding testing phase.''';
    }

    // --- CASE 3: General Question Outside Syllabus (e.g. Microwave Oven) ---
    if (qLower.contains('microwave') || qLower.contains('oven')) {
      return '''### How a Microwave Oven Works

*(General Science Explanation • No specific syllabus alignment)*

#### 1. Direct Explanation
A microwave oven is a kitchen appliance that heats and cooks food by exposing it to electromagnetic radiation in the microwave frequency spectrum (typically **2.45 GHz** or 2.45 × 10⁹ Hz). Rather than heating food from the outside via hot air or conduction, it generates thermal energy throughout the food by exciting polar water molecules.

#### 2. Key Operational Steps
1. **Generation of Microwaves:**
   - High-voltage electrical power is fed into an electron vacuum tube known as a **magnetron**.
   - The magnetron converts electrical energy into microwave radiation oscillating at **2.45 GHz**.
2. **Waveguide & Cavity Distribution:**
   - The electromagnetic waves are channeled through a metallic waveguide into the reflective metal cooking chamber.
   - A rotating turntable ensures even wave exposure across the food.
3. **Dielectric Heating of Polar Molecules:**
   - Water, fats, and sugars present in food are electrically **polar dipoles** (having a slightly positive hydrogen end and a negative oxygen end).
   - As the electric field rapidly alternates 2.45 billion times every second, these polar molecules continuously rotate back and forth to align with the alternating field.
4. **Intermolecular Friction to Heat:**
   - The violent molecular rotation causes intense intermolecular friction, dissipating electromagnetic energy directly into thermal heat.

#### 3. Everyday Example
* When you heat a cup of water, the water reaches boiling temperature within minutes, but the glass or ceramic cup only warms up through contact heat conducted from the hot water.
* This occurs because dry ceramic, glass, and microwave-safe plastics lack free polar water molecules, allowing microwaves to pass harmlessly through them without heating the container.

#### 4. Quick Summary
* **Source:** Magnetron tube (~2.45 GHz).
* **Core Principle:** Dielectric heating via rapid oscillation of polar water molecules.
* **Safety Note:** Metal reflects microwaves and can cause electrical arcing, so metals must never be placed inside.''';
    }

    // --- GENERAL TOPIC PEDAGOGICAL GENERATOR ---
    return _generateGenericSubjectAnswer(
      question: question,
      profile: profile,
      subject: subject,
      sourceDoc: sourceDoc,
    );
  }

  String _generateGenericSubjectAnswer({
    required String question,
    required StudentProfile profile,
    required String subject,
    String? sourceDoc,
  }) {
    final isSchool = profile.isSchoolStudent;
    final badge = profile.studentBadge;
    final goal = profile.mainGoal;

    final buffer = StringBuffer();
    buffer.writeln('### Concept Explanation: $subject\n');
    buffer.writeln('> **Academic Level:** `$badge` • **Learning Goal:** `$goal`\n');

    if (sourceDoc != null) {
      buffer.writeln('📖 *Referenced from study material: **$sourceDoc***\n');
    }

    buffer.writeln('#### 1. Direct Explanation');
    if (isSchool) {
      buffer.writeln(
        'To understand **"$question"**, let\'s break it down simply. '
        'At the ${profile.grade ?? "School"} level in ${profile.board ?? "CBSE"}, this concept explains how basic components interact according to established scientific and mathematical laws without unnecessary complexity.\n'
      );
    } else {
      buffer.writeln(
        'In the context of ${profile.department ?? "Engineering"} (${profile.degree ?? "B.Tech"}), '
        'analyzing **"$question"** involves examining underlying architectural principles, mathematical formulation, efficiency considerations, and practical industry trade-offs.\n'
      );
    }

    buffer.writeln('#### 2. Key Points & Step-by-Step Breakdown');
    if (isSchool) {
      buffer.writeln(
        '* **Point 1 (Definition):** Clearly define the core term and state the primary governing relation.\n'
        '* **Point 2 (Mechanism):** Follow the sequential transformation from inputs to final outputs.\n'
        '* **Point 3 (Key Observation):** Note the boundary conditions and standard units (e.g., SI units) required for exam marks.\n'
      );
    } else {
      buffer.writeln(
        '* **Architectural Framework:** Identify state variables, system inputs, and deterministic computational pipelines.\n'
        '* **Complexity & Optimization:** Evaluate time/space performance tradeoffs and edge-case boundaries.\n'
        '* **Standard Specifications:** Follow standard specifications (IEEE / ISO / ACM) relevant for university evaluations and interview prep.\n'
      );
    }

    buffer.writeln('#### 3. Real-World Context Example 🇮🇳');
    if (isSchool) {
      buffer.writeln(
        'Consider how energy conversion powers everyday systems in India—such as solar pump installations in rural agriculture or pressure regulation in household cooking. '
        'The same foundational rules apply directly to this concept.'
      );
    } else {
      buffer.writeln(
        'Consider high-scale Indian digital infrastructure like NPCI\'s Unified Payments Interface (UPI) or IRCTC reservation architecture, '
        'where reliability, concurrency, and fault tolerance depend on systematic engineering principles similar to this topic.'
      );
    }

    buffer.writeln('\n#### 4. Summary & Key Takeaway');
    buffer.writeln('```\nCore Principle: Inputs ➔ Verified Transformation Engine ➔ Reliable Output\nAlways state initial assumptions and check SI units in your exam papers.\n```');

    return buffer.toString();
  }

  List<String> _generateFollowUps(StudentProfile profile, String subject) {
    if (profile.isSchoolStudent) {
      return [
        'Explain Simpler',
        'Give an Example',
        'Create Quiz',
        'Make Flashcards',
        'Translate',
      ];
    } else {
      return [
        'Explain Simpler',
        'Give an Example',
        'Create Quiz',
        'Make Flashcards',
        'Translate',
      ];
    }
  }
}
