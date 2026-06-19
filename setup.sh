# Create project directory and all files
mkdir -p caresync-wellness/public
cd caresync-wellness

# Create package.json
cat > package.json << 'EOF'
{
  "name": "caresync-wellness-hub",
  "version": "1.0.0",
  "description": "Multi-lingual wellness portal with AI chatbot, 3D anatomy, and holistic health tools",
  "main": "server.js",
  "type": "module",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js"
  },
  "dependencies": {
    "@google/genai": "^0.1.1",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2"
  }
}
EOF

# Create .env example
cat > .env.example << 'EOF'
# Get your API key from https://aistudio.google.com/
GEMINI_API_KEY=your_gemini_api_key_here
PORT=3000
EOF

# Create server.js (backend)
cat > server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { GoogleGenAI } from '@google/genai';

dotenv.config();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize Gemini AI client if API key is provided
let aiClient = null;
try {
  if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY !== 'your_gemini_api_key_here') {
    aiClient = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
    console.log('✅ Gemini AI client initialized successfully');
  } else {
    console.log('⚠️ No valid Gemini API key found. Using rule-based chatbot fallback.');
  }
} catch (error) {
  console.log('⚠️ Failed to initialize Gemini AI client. Using rule-based fallback.');
}

// Language support configuration
const SUPPORTED_LANGUAGES = {
  en: 'English',
  am: 'Amharic (አማርኛ)',
  om: 'Afaan Oromoo'
};

// Rule-based response system for demo/fallback mode
const getRuleBasedResponse = (userMessage, language) => {
  const lowerMsg = userMessage.toLowerCase();
  
  // Greeting detection
  if (lowerMsg.match(/hello|hi|hey|selam|ሰላም|asham|akkam/i)) {
    const responses = {
      en: "Hello! I'm your wellness assistant. How are you feeling today?",
      am: "ሰላም! እኔ የእርስዎ የጤና እንክብካቤ ረዳት ነኝ። ዛሬ እንዴት ይሰማዎታል?",
      om: "Asham! Ani gargaaraa fayyaa keessan. Har'a akkamitti hubattuu?"
    };
    return { message: responses[language] || responses.en, chips: ["Tell me more", "I need help", "Just browsing"] };
  }
  
  // Symptom duration question
  if (lowerMsg.match(/duration|how long|ምን ያህል ጊዜ|yeroo hammam/i)) {
    const responses = {
      en: "Thank you for sharing. Has this discomfort affected your daily activities or sleep?",
      am: "አመሰግናለሁ። ይህ ምቾት ማጣት በዕለት ተዕለት እንቅስቃሴዎ ወይም በእንቅልፍዎ ላይ ተጽዕኖ አሳድሯል?",
      om: "Galatoomi. Miiraan kun sochii guyyaa ykn hirriba keessan irratti dhiibbaa qabaateeraa?"
    };
    return { 
      message: responses[language] || responses.en,
      chips: ["Yes, significantly", "Somewhat", "No impact"]
    };
  }
  
  // Impact response
  if (lowerMsg.match(/significantly|somewhat|no impact|yes|አዎ|ee/i)) {
    const responses = {
      en: "I understand. Based on what you've shared, I recommend speaking with a mental health professional. Would you like me to help you book an appointment?",
      am: "ገባኝ። በገለጹት መሰረት ከአእምሮ ጤና ባለሙያ ጋር እንድትነጋገሩ ሀሳብ አቀርባለሁ። ቀጠሮ ለማስያዝ እርዳታ ይፈልጋሉ?",
      om: "Nan hubadhe. Waan ibsitan irratti hundaa'uunsa, ogeessa fayyaa sammuu wajjin haasa'uu isin gorsa. Beellama qopheessuuf gargaaruu barbaadduu?"
    };
    return {
      message: responses[language] || responses.en,
      chips: ["Book appointment", "Tell me more", "Not now"]
    };
  }
  
  // Default responses
  const defaultResponses = {
    en: "I'm here to help with your wellness journey. Can you tell me more about how you're feeling?",
    am: "በጤና ጉዞዎ ላይ ለመርዳት እዚህ አለሁ። ስለሚሰማዎት ስሜት በዝርዝር ሊገልጹልኝ ይችላሉ?",
    om: "Achumanii fayyaa keessan irratti isin gargaaruf as jira. Waan miiramtani ilaalchisee waan dabalataa natti himuu dandeessuu?"
  };
  return {
    message: defaultResponses[language] || defaultResponses.en,
    chips: ["Physical symptoms", "Mental health", "Sleep issues", "Stress management"]
  };
};

// Generate AI response using Gemini SDK v0.1.1
const generateGeminiResponse = async (userMessage, language) => {
  if (!aiClient) {
    return getRuleBasedResponse(userMessage, language);
  }
  
  try {
    const systemInstruction = `You are a compassionate medical intake assistant for a wellness platform called CareSync.
Your role is to provide empathetic, professional responses to users seeking mental and physical health support.
Respond in ${language === 'am' ? 'Amharic (አማርኛ)' : language === 'om' ? 'Afaan Oromoo' : 'English'}.
Keep responses concise (1-2 sentences) and always suggest 2-4 quick reply options (chips) that guide the conversation forward.
Be warm but professional. Never give medical diagnoses, but offer general wellness advice and encourage professional consultation.`;

    // Fixed API parameters for structured JSON outputs matching the @google/genai format
    const response = await aiClient.models.generateContent({
      model: 'gemini-2.0-flash-lite',
      contents: userMessage,
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            message: { type: "STRING" },
            chips: {
              type: "ARRAY",
              items: { type: "STRING" }
            }
          },
          required: ["message", "chips"]
        },
        temperature: 0.7
      }
    });

    return JSON.parse(response.text);
  } catch (error) {
    console.error("Gemini API error:", error);
    return getRuleBasedResponse(userMessage, language);
  }
};

// API Endpoint: AI Chat
app.post('/api/chat', async (req, res) => {
  try {
    const { message, language = 'en', context = {} } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    if (context.isInitial && context.symptom && context.zone) {
      const initialMessages = {
        en: `I see you're experiencing ${context.symptom} in the ${context.zone} area. I'm here to help. How long has this been going on?`,
        am: `${context.zone} አካባቢ ${context.symptom} እንደሚሰማዎት ተረድቻለሁ። ለመርዳት እዚህ አለሁ። ይህ ስሜት ለምን ያህል ጊዜ ሲቆይ ኖሯል?`,
        om: `Ani naannoo ${context.zone} keessatti ${context.symptom} akka qabaattan hubadheera. Gargaaruf as jira. Kun yeroo hammam tureera?`
      };
      return res.json({
        message: initialMessages[language] || initialMessages.en,
        chips: ["Less than 24 hours", "A few days", "More than a week", "Chronic/On and off"]
      });
    }
    
    const aiResponse = await generateGeminiResponse(message, language);
    res.json(aiResponse);
    
  } catch (error) {
    console.error('Chat API error:', error);
    const fallback = getRuleBasedResponse(req.body.message || "Help", req.body.language || 'en');
    res.json(fallback);
  }
});

// API Endpoint: Simulated Payment
app.post('/api/pay', (req, res) => {
  const { provider, amount } = req.body;
  setTimeout(() => {
    res.json({
      status: "SUCCESS",
      transactionId: "TXN-" + Math.random().toString(36).substring(2, 9).toUpperCase(),
      timestamp: new Date().toISOString(),
      message: `Payment of ${amount || 0} processed via ${provider}`
    });
  }, 800);
});

// API Endpoint: Simulated Ride Booking
app.post('/api/book-ride', (req, res) => {
  setTimeout(() => {
    res.json({
      logisticsStatus: "DISPATCHED",
      driverName: "Tariku Alemu",
      plateNumber: "ET-2-A" + Math.floor(Math.random() * 9000 + 1000),
      etaMinutes: Math.floor(Math.random() * 12 + 4),
      driverPhone: "+2519" + Math.floor(Math.random() * 10000000 + 1000000)
    });
  }, 1000);
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', geminiAvailable: aiClient !== null });
});

// Serve index.html for all other routes (SPA support)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`✨ CareSync Wellness Hub running on http://localhost:${PORT}`);
  console.log(`📱 Multi-language support: ${Object.values(SUPPORTED_LANGUAGES).join(', ')}`);
  console.log(`🤖 AI Mode: ${aiClient ? 'Gemini AI' : 'Rule-based fallback'}`);
});
EOF

# Create public/index.html (main application)
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <title>CareSync - Integrated Wellness Hub</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Noto+Sans+Ethiopic:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="style.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
</head>
<body>

    <div id="sos-anchor" class="sos-container">
        <button id="sos-btn" class="sos-btn">🚨 IMMEDIATE HELP / አስቸኳይ እርዳታ / GARGAARSA DIDIMMA</button>
    </div>

    <header class="global-header">
        <div class="logo" onclick="showPage('home')">🌿 CareSync</div>
        <div class="header-controls">
            <nav class="desktop-nav">
                <button onclick="showPage('home')" data-key="navHome">Home</button>
                <button onclick="showPage('traditional')" data-key="navTrad">Traditional Medicine</button>
                <button onclick="showPage('state-anatomy')" data-key="navAnatomy">Symptom Mapper</button>
                <button onclick="showPage('quiz')" data-key="navQuiz">Mind Quiz</button> <button onclick="showPage('subscriptions')" data-key="navSubs">Premium</button>
                <button id="auth-nav-btn" class="auth-btn" onclick="showPage('auth')" data-key="navAuth">Sign In</button>
            </nav>
            <div class="language-selector">
                <button class="lang-btn" data-lang="en" onclick="switchLanguage('en')">EN</button>
                <button class="lang-btn" data-lang="am" onclick="switchLanguage('am')">አማ</button>
                <button class="lang-btn" data-lang="om" onclick="switchLanguage('om')">OM</button>
            </div>
            <button id="lite-mode-toggle" class="lite-toggle">📉 Data Saver: OFF</button>
        </div>
    </header>

    <main id="app-container">
        <section id="state-splash" class="view-state active">
            <div class="card text-center">
                <div class="logo-large">🌿 CareSync</div>
                <h2 data-key="splashTitle">Select Your Language</h2>
                <p class="subtitle" data-key="splashSubtitle">Welcome to your wellness journey</p>
                <div class="btn-group-vertical">
                    <button class="btn btn-primary" onclick="selectLanguage('en')">🇬🇧 English</button>
                    <button class="btn btn-primary" onclick="selectLanguage('am')">🇪🇹 አማርኛ (Amharic)</button>
                    <button class="btn btn-primary" onclick="selectLanguage('om')">🇪🇹 Afaan Oromoo</button>
                </div>
            </div>
        </section>

        <section id="state-auth" class="view-state">
            <div class="card">
                <h2 id="auth-title">Verify Phone Number</h2>
                <p id="auth-subtitle" class="subtitle">We'll send a verification code to your mobile number.</p>
                <div id="phone-input-group">
                    <div class="input-wrapper">
                        <span class="input-prefix">+251</span>
                        <input type="tel" id="phone-number" placeholder="911234567" maxlength="9">
                    </div>
                    <button class="btn btn-accent w-100 mt-3" onclick="sendOTP()" data-key="sendCodeBtn">Send Verification Code</button>
                </div>
                <div id="otp-input-group" class="hidden">
                    <input type="text" id="otp-code" placeholder="••••••" maxlength="6" class="text-center letter-spacing-lg">
                    <button class="btn btn-success w-100 mt-3" onclick="verifyOTP()" data-key="verifyBtn">Verify & Continue</button>
                </div>
                <div id="auth-error" class="error-message hidden mt-3"></div>
            </div>
        </section>

        <section id="state-kyc" class="view-state">
            <div class="card">
                <h2 data-key="kycTitle">Personalize Your Account</h2>
                <p data-key="kycSubtitle" class="subtitle">Help us match you with the right care providers.</p>
                <div class="form-group">
                    <label data-key="lblName">Full Name</label>
                    <input type="text" id="full-name" placeholder="Enter your full name">
                </div>
                <div class="form-group mt-3">
                    <label data-key="lblFayda">Fayda National ID (Optional)</label>
                    <input type="text" id="fayda-id" placeholder="ET-XXXX-XXXX-XXXX">
                </div>
                <div class="form-group mt-3">
                    <label data-key="lblInsurance">Insurance Provider (Optional)</label>
                    <select id="insurance-provider">
                        <option value="none" data-key="noInsurance">No Private Insurance (Community Care)</option>
                        <option value="nyala">Nyala Insurance</option>
                        <option value="awash">Awash Insurance</option>
                        <option value="africa">Africa Insurance</option>
                    </select>
                </div>
                <div class="btn-group-horizontal mt-4">
                    <button class="btn btn-secondary" onclick="skipKYC()" data-key="skipBtn">Skip for Now</button>
                    <button class="btn btn-success" onclick="saveKYC()" data-key="saveBtn">Save Profile</button>
                </div>
            </div>
        </section>

        <section id="state-anatomy" class="view-state">
            <div class="anatomy-layout">
                <div class="canvas-container">
                    <div id="three-canvas-target"></div>
                    <div id="lite-fallback-map" class="hidden">
                        <div class="flat-body-grid">
                            <button data-part="Head" class="body-part-btn">🧠 Head / ራስ / Mataa</button>
                            <button data-part="Chest" class="body-part-btn">❤️ Chest / ደረት / Qoma</button>
                            <button data-part="Stomach" class="body-part-btn">🍽️ Stomach / ሆድ / Garraa</button>
                            <button data-part="Limbs" class="body-part-btn">💪 Limbs / እጆችና እግሮች / Namaa fi Miilla</button>
                        </div>
                    </div>
                </div>
                <div class="anatomy-sidebar">
                    <h3 data-key="anatomyHeading">Symptom Mapping</h3>
                    <p data-key="anatomyLead">Click on the 3D model or use the list below to select your area of concern.</p>
                    <div id="selection-panel" class="fade-in hidden">
                        <div class="alert-info">
                            <span data-key="selectedZoneLabel">Selected Zone:</span> <strong id="selected-zone-display">-</strong>
                        </div>
                        <p class="mt-3" data-key="symptomPrompt">What type of discomfort are you experiencing?</p>
                        <div id="symptom-chips" class="chip-container"></div>
                        <button class="btn btn-accent w-100 mt-4" onclick="confirmSymptomMap()" data-key="lockBtn">Lock Symptoms & Start AI Intake</button>
                    </div>
                </div>
            </div>
        </section>

        <section id="state-ai-intake" class="view-state">
            <div class="chat-layout">
                <div class="chat-header">
                    <div class="bot-avatar">🤖</div>
                    <div>
                        <h4 data-key="aiChatTitle">CareSync Clinical AI</h4>
                        <span class="status-indicator" data-key="aiStatus">Connected | Multi-Lingual Assistant</span>
                    </div>
                </div>
                <div id="chat-stream" class="chat-body">
                    <div class="message bot" data-key="welcomeMsg">Welcome! I'm your wellness assistant. Let's talk about how you're feeling.</div>
                </div>
                <div class="chat-footer">
                    <div id="ai-quick-chips" class="chip-container mb-2"></div>
                    <div class="chat-input-wrapper">
                        <input type="text" id="user-message-input" placeholder="Type your message here..." onkeypress="handleChatKeypress(event)">
                        <button class="btn btn-accent" onclick="submitUserMessage()" data-key="sendBtn">Send →</button>
                    </div>
                </div>
            </div>
        </section>

        <section id="state-dashboard" class="view-state">
            <div class="dashboard-grid">
                <div class="card-dashboard">
                    <h3 data-key="careTeamTitle">👤 Your Care Team</h3>
                    <div class="therapist-card mt-3">
                        <div class="avatar-placeholder">🩺</div>
                        <div>
                            <h4 id="therapist-name">Dr. Martha Yonas</h4>
                            <p class="text-muted" data-key="psychiatristTitle">Consultant Psychiatrist</p>
                            <span class="badge-match" data-key="aiMatched">✓ AI-Matched to your symptoms</span>
                        </div>
                    </div>
                    <div class="alert-success mt-3">
                        <strong data-key="intakeComplete">✓ Intake completed</strong><br>
                        <small data-key="caseTransmitted">Your case has been securely transmitted</small>
                    </div>
                </div>

                <div class="card-dashboard">
                    <h3 data-key="appointmentTitle">📅 Appointment & Logistics</h3>
                    <div class="booking-status-box mt-2">
                        <div class="status-row">
                            <span data-key="appointmentLabel">📅 Appointment:</span>
                            <strong id="appointment-time">Today, 3:30 PM</strong>
                        </div>
                        <div class="status-row mt-2">
                            <span data-key="transportLabel">🚗 Transport:</span>
                            <strong id="ride-status" data-key="pendingPayment">Pending Payment</strong>
                        </div>
                        <div class="status-row mt-2">
                            <span data-key="locationLabel">📍 Location:</span>
                            <strong id="location-text">CareSync Wellness Center</strong>
                        </div>
                    </div>
                    
                    <h4 class="mt-4" data-key="paymentTitle">💳 Complete Payment</h4>
                    <div class="payment-grid mt-2">
                        <button class="btn btn-payment" onclick="processPayment('telebirr')">📱 Telebirr</button>
                        <button class="btn btn-payment" onclick="processPayment('cbe')">🏦 CBE Birr</button>
                        <button class="btn btn-payment" onclick="processPayment('banking')">💳 Mobile Banking</button>
                    </div>
                    <div id="payment-overlay-status" class="mt-3 font-sm"></div>
                    
                    <button class="btn btn-secondary w-100 mt-3" onclick="bookRide()" data-key="bookRideBtn">🚕 Book Ride to Appointment</button>
                </div>
            </div>
            <div class="dashboard-footer mt-4">
                <button class="btn btn-primary" onclick="resetToSplash()" data-key="startOver">← Start Over</button>
            </div>
        </section>

        <section id="traditional" class="view-state">
            <h2 data-key="tradPageTitle">🌿 Traditional Medicine Finder</h2>
            <p class="subtitle" data-key="tradPageDesc">Select a recorded condition profile to pull verified traditional remedies and instructional links.</p>
            <div class="form-group">
                <label data-key="tradFormLabel">Select Your Disease or Symptom Profile:</label>
                <select id="symptomSelect">
                    <option value="" data-key="optDefault">-- Click to choose an option --</option>
                    <option value="digestive" data-key="optDigestive">Indigestion & Severe Bloating</option>
                    <option value="sleep" data-key="optSleep">Insomnia & Persistent Restlessness</option>
                    <option value="fatigue" data-key="optFatigue">Chronic Low Energy & Fatigue</option>
                </select>
            </div>
            <button class="btn btn-primary" onclick="findTraditionalRemedy()" data-key="tradSubmitBtn">Generate Remedy Data</button>
            <div id="traditionalResult" class="remedy-result hidden">
                <h4 id="remedyTitle"></h4>
                <p id="remedyDesc"></p>
                <p><strong data-key="eduResourceText">Educational Resource:</strong> <a id="remedyLink" href="#" target="_blank" data-key="remedyLinkText">Watch external video guides and tutorials here →</a></p>
            </div>
        </section>

        <section id="quiz" class="view-state">
            <h2 data-key="quizPageTitle">🧠 Mental Health Check-In Quiz</h2>
            <p class="subtitle" data-key="quizPageDesc">Complete these 5 critical questions accurately regarding your behaviors over the last 14 days.</p>
            <form id="mindQuizForm">
                <div class="quiz-question">
                    <label data-key="lblQ1">1. Experiencing little interest or pleasure in doing normal routine hobbies?</label>
                    <div class="radio-group">
                        <label><input type="radio" name="q1" value="0"> <span data-key="optNotAtAll">Not at all</span></label>
                        <label><input type="radio" name="q1" value="1"> <span data-key="optSeveralDays">Several days</span></label>
                        <label><input type="radio" name="q1" value="2"> <span data-key="optMostDays">Most days</span></label>
                    </div>
                </div>
                <div class="quiz-question">
                    <label data-key="lblQ2">2. Feeling down, depressed, flat, or noticeably hopeless?</label>
                    <div class="radio-group">
                        <label><input type="radio" name="q2" value="0"> <span data-key="optNotAtAll">Not at all</span></label>
                        <label><input type="radio" name="q2" value="1"> <span data-key="optSeveralDays">Several days</span></label>
                        <label><input type="radio" name="q2" value="2"> <span data-key="optMostDays">Most days</span></label>
                    </div>
                </div>
                <div class="quiz-question">
                    <label data-key="lblQ3">3. Experiencing trouble staying asleep, falling asleep, or oversleeping?</label>
                    <div class="radio-group">
                        <label><input type="radio" name="q3" value="0"> <span data-key="optNotAtAll">Not at all</span></label>
                        <label><input type="radio" name="q3" value="1"> <span data-key="optSeveralDays">Several days</span></label>
                        <label><input type="radio" name="q3" value="2"> <span data-key="optMostDays">Most days</span></label>
                    </div>
                </div>
                <div class="quiz-question">
                    <label data-key="lblQ4">4. Experiencing general lethargy, low physical drive, or running low on energy?</label>
                    <div class="radio-group">
                        <label><input type="radio" name="q4" value="0"> <span data-key="optNotAtAll">Not at all</span></label>
                        <label><input type="radio" name="q4" value="1"> <span data-key="optSeveralDays">Several days</span></label>
                        <label><input type="radio" name="q4" value="2"> <span data-key="optMostDays">Most days</span></label>
                    </div>
                </div>
                <div class="quiz-question">
                    <label data-key="lblQ5">5. Trouble focusing or concentrating on reading, text, or screens?</label>
                    <div class="radio-group">
                        <label><input type="radio" name="q5" value="0"> <span data-key="optNotAtAll">Not at all</span></label>
                        <label><input type="radio" name="q5" value="1"> <span data-key="optSeveralDays">Several days</span></label>
                        <label><input type="radio" name="q5" value="2"> <span data-key="optMostDays">Most days</span></label>
                    </div>
                </div>
                <button type="button" class="btn btn-primary" onclick="evaluateQuiz()" data-key="quizSubmitBtn">Submit Mind Evaluation</button>
            </form>
            <div id="quizHealthyResult" class="result-card hidden">
                <h3 style="color: #27ae60" data-key="healthyResultTitle">Your baseline scores look healthy!</h3>
                <p data-key="healthyResultDesc">Continue maintaining a robust routine, consistent sleep metrics, and regular mental breaks.</p>
            </div>
            <div id="quizDirectoryResult" class="result-card hidden">
                <h3 style="color: #d35400" data-key="careRoutingTitle">Professional Care Routing Required</h3>
                <p data-key="careRoutingDesc">Your score suggests you may be going through a tough time. Please pick an authorized professional from our panel below to proceed to booking:</p>
                <div class="doctor-card">
                    <div><h4>Dr. Sarah Jenkins, MD</h4><p><small data-key="doc1Specialty">Board Certified Clinical Psychiatrist</small></p></div>
                    <div><span class="price">$120</span><button class="btn btn-sm" onclick="goToFinance('Dr. Sarah Jenkins', 120)" data-key="selectPayBtn">Select & Pay</button></div>
                </div>
                <div class="doctor-card">
                    <div><h4>Dr. Aaron Patel, PsyD</h4><p><small data-key="doc2Specialty">Anxiety & Stress Management Specialist</small></p></div>
                    <div><span class="price">$95</span><button class="btn btn-sm" onclick="goToFinance('Dr. Aaron Patel', 95)" data-key="selectPayBtn">Select & Pay</button></div>
                </div>
            </div>
            <div id="financePage" class="result-card hidden">
                <h3 data-key="checkoutTitle">💳 Gateway Checkout Page</h3>
                <p id="checkoutDetails" style="margin: 15px 0; font-weight: bold;"></p>
                <div class="payment-box">
                    <p data-key="sandboxTitle">Secure Credit Card Transaction Sandbox</p>
                    <input type="text" id="cardholderName" placeholder="Cardholder Name" style="margin-bottom: 10px; width:100%">
                    <input type="text" placeholder="#### #### #### ####" style="margin-bottom: 10px; width:100%">
                    <button class="btn btn-success" onclick="processPaymentGateway()" data-key="processPaymentBtn">Process Payment Gateway</button>
                </div>
            </div>
        </section>

        <section id="subscriptions" class="view-state">
            <h2 data-key="subsPageTitle">💎 Manage/Update Premium Subscriptions</h2>
            <p class="subtitle" data-key="subsPageDesc">Modify your current portal setup parameters or update tiers easily here.</p>
            <div class="tier-container">
                <div class="tier-card">
                    <h3 data-key="tierFreeTitle">Free Tier Profile</h3>
                    <p class="price-large"><strong>$0</strong> <span data-key="perMonthText">/ month</span></p>
                    <p data-key="tierFreeDesc">Includes base questionnaires and general local listings.</p>
                    <button class="btn btn-secondary" disabled data-key="activeTierBtn">Active Tier</button>
                </div>
                <div class="tier-card premium">
                    <div class="badge" data-key="premiumChoiceBadge">PREMIUM CHOICE</div>
                    <h3 data-key="tierPremiumTitle">Plus Plan Membership</h3>
                    <p class="price-large"><strong>$14.99</strong> <span data-key="perMonthText">/ month</span></p>
                    <p data-key="tierPremiumDesc">Unlocks video database directories, remedy clips, and priority matching.</p>
                    <button class="btn btn-warning" onclick="alert('Redirecting to subscription dashboard...')" data-key="tierPremiumBtn">Update/Renew Subscription</button>
                </div>
            </div>
        </section>
    </main>

    <footer class="global-footer">
        <p>CareSync • HIPAA Compliant • 24/7 Support Available</p>
        <p data-key="footerSupport">Support: +251 911 234567 | support@caresync.com</p>
    </footer>

    <script src="app.js"></script>
</body>
</html>
EOF

# Create public/style.css
cat > public/style.css << 'EOF'
:root {
    --bg-primary: #f8fafc;
    --card-bg: #ffffff;
    --text-primary: #1e293b;
    --text-muted: #64748b;
    --color-trust: #2a4b7c;
    --color-calm: #a7d7c5;
    --color-calm-dark: #6fae96;
    --color-sos: #e06d53;
    --color-border: #e2e8f0;
    --radius-lg: 16px;
    --radius-sm: 8px;
    --shadow-md: 0 4px 6px -1px rgba(0,0,0,0.07);
    --transition: all 0.2s ease;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    background: var(--bg-primary);
    color: var(--text-primary);
    font-family: 'Inter', 'Noto Sans Ethiopic', sans-serif;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

.sos-container {
    background: var(--color-sos);
    padding: 10px;
    text-align: center;
    position: sticky;
    top: 0;
    z-index: 2000;
}
.sos-btn {
    background: none;
    border: none;
    color: white;
    font-weight: 700;
    cursor: pointer;
    width: 100%;
}

.global-header {
    background: var(--card-bg);
    border-bottom: 1px solid var(--color-border);
    padding: 12px 5%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    position: sticky;
    top: 0;
    z-index: 100;
}
.logo {
    font-weight: 700;
    color: var(--color-trust);
    font-size: 1.3rem;
    cursor: pointer;
}
.header-controls {
    display: flex;
    align-items: center;
    gap: 20px;
    flex-wrap: wrap;
}
.desktop-nav {
    display: flex;
    gap: 15px;
}
.desktop-nav button, .auth-btn {
    background: none;
    border: none;
    font-weight: 500;
    cursor: pointer;
    padding: 6px 12px;
    border-radius: 20px;
    transition: var(--transition);
}
.desktop-nav button:hover, .auth-btn:hover {
    background: var(--color-border);
}
.auth-btn {
    background: var(--color-trust);
    color: white;
}
.language-selector {
    display: flex;
    gap: 6px;
}
.lang-btn {
    padding: 4px 10px;
    border: 1px solid var(--color-border);
    background: var(--bg-primary);
    border-radius: 20px;
    cursor: pointer;
    font-weight: 500;
}
.lang-btn.active {
    background: var(--color-trust);
    color: white;
    border-color: var(--color-trust);
}
.lite-toggle {
    background: var(--bg-primary);
    border: 1px solid var(--color-border);
    padding: 6px 14px;
    border-radius: 20px;
    cursor: pointer;
}

.view-state {
    display: none;
    padding: 40px 5%;
    flex: 1;
}
.view-state.active {
    display: block;
}

.card, .card-dashboard, .result-card {
    background: var(--card-bg);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 32px;
    max-width: 600px;
    margin: 20px auto;
    box-shadow: var(--shadow-md);
}

.logo-large { font-size: 3rem; font-weight: 700; color: var(--color-trust); margin-bottom: 16px; }
.text-center { text-align: center; }
.subtitle { color: var(--text-muted); font-size: 0.9rem; margin-bottom: 24px; }
.btn { padding: 10px 20px; font-weight: 500; border-radius: var(--radius-sm); cursor: pointer; border: none; }
.btn-primary { background: var(--bg-primary); border: 1px solid var(--color-border); }
.btn-accent { background: var(--color-trust); color: white; }
.btn-success { background: var(--color-calm-dark); color: white; }
.btn-secondary { background: var(--text-muted); color: white; }
.btn-payment { background: var(--bg-primary); border: 1px solid var(--color-border); padding: 12px; font-weight: 600; cursor: pointer; }
.btn-group-vertical { display: flex; flex-direction: column; gap: 12px; }
.btn-group-horizontal { display: flex; gap: 12px; justify-content: flex-end; }
.w-100 { width: 100%; }
.mt-3 { margin-top: 16px; }
.mt-4 { margin-top: 24px; }
.mb-2 { margin-bottom: 8px; }
.hidden { display: none !important; }

.input-wrapper { display: flex; border: 1px solid var(--color-border); border-radius: var(--radius-sm); overflow: hidden; }
.input-prefix { background: var(--bg-primary); padding: 12px 15px; border-right: 1px solid var(--color-border); }
input, select { width: 100%; padding: 12px; border: 1px solid var(--color-border); border-radius: var(--radius-sm); }

.anatomy-layout { display: grid; grid-template-columns: 1fr 380px; gap: 30px; max-width: 1300px; margin: 0 auto; }
@media (max-width: 850px) { .anatomy-layout { grid-template-columns: 1fr; } }
.canvas-container { background: #0f172a; border-radius: var(--radius-lg); height: 500px; overflow: hidden; position: relative; }
#three-canvas-target { width: 100%; height: 100%; }
.flat-body-grid { display: flex; flex-direction: column; gap: 12px; padding: 24px; justify-content: center; height: 100%; }
.flat-body-grid button { padding: 18px; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); color: white; border-radius: var(--radius-sm); cursor: pointer; }
.anatomy-sidebar { background: var(--card-bg); border: 1px solid var(--color-border); border-radius: var(--radius-lg); padding: 24px; }
.chip-container { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
.chip { padding: 8px 18px; background: var(--bg-primary); border: 1px solid var(--color-border); border-radius: 30px; cursor: pointer; }
.chip.selected { background: var(--color-trust); color: white; }

.chat-layout { max-width: 800px; margin: 0 auto; background: var(--card-bg); border: 1px solid var(--color-border); border-radius: var(--radius-lg); height: 550px; display: flex; flex-direction: column; }
.chat-header { padding: 16px 20px; border-bottom: 1px solid var(--color-border); display: flex; align-items: center; gap: 12px; }
.bot-avatar { width: 44px; height: 44px; border-radius: 50%; background: var(--color-calm); display: flex; align-items: center; justify-content: center; font-size: 1.5rem; }
.chat-body { flex: 1; padding: 20px; overflow-y: auto; display: flex; flex-direction: column; gap: 12px; background: #fafcff; }
.message { max-width: 80%; padding: 10px 16px; border-radius: 18px; font-size: 0.9rem; }
.message.bot { background: var(--bg-primary); align-self: flex-start; }
.message.user { background: var(--color-trust); color: white; align-self: flex-end; }
.chat-footer { padding: 16px; border-top: 1px solid var(--color-border); background: white; }
.chat-input-wrapper { display: flex; gap: 10px; }
.chat-input-wrapper input { flex: 1; border-radius: 30px; }

.dashboard-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 30px; max-width: 1100px; margin: 0 auto; }
@media (max-width: 750px) { .dashboard-grid { grid-template-columns: 1fr; } }
.therapist-card { display: flex; gap: 16px; align-items: center; padding: 16px; background: var(--bg-primary); border-radius: var(--radius-sm); }
.booking-status-box { background: var(--bg-primary); padding: 16px; border-radius: var(--radius-sm); }
.status-row { display: flex; justify-content: space-between; padding: 4px 0; }
.payment-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.alert-info { background: #e0f2fe; color: #0369a1; padding: 12px; border-radius: var(--radius-sm); }
.alert-success { background: #dcfce7; color: #15803d; padding: 12px; border-radius: var(--radius-sm); }

.doctor-card { display: flex; justify-content: space-between; align-items: center; padding: 15px; border: 1px solid var(--color-border); margin-top: 10px; border-radius: var(--radius-sm); }
.tier-container { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 20px; }
.tier-card { border: 1px solid var(--color-border); padding: 24px; border-radius: var(--radius-lg); text-center: center; position: relative; }
.tier-card.premium { border-color: var(--color-calm-dark); background: #f0fdf4; }
.price-large { font-size: 2rem; margin: 15px 0; }

.global-footer { text-align: center; color: var(--text-muted); font-size: 0.75rem; padding: 30px; border-top: 1px solid var(--color-border); margin-top: auto; }
EOF

# Create public/app.js (Complete missing client code)
cat > public/app.js << 'EOF'
let currentLanguage = 'en';
let isLiteMode = false;
let selectedZone = null;
let selectedSymptom = null;
let chatHistory = [];

// Dictionary for multilingual localizations
const translations = {
    en: {
        navHome: "Home", navTrad: "Traditional Medicine", navAnatomy: "Symptom Mapper", navQuiz: "Mind Quiz", navSubs: "Premium", navAuth: "Sign In",
        splashTitle: "Select Your Language", splashSubtitle: "Welcome to your wellness journey",
        sendCodeBtn: "Send Verification Code", verifyBtn: "Verify & Continue",
        kycTitle: "Personalize Your Account", kycSubtitle: "Help us match you with the right care providers.",
        lblName: "Full Name", lblFayda: "Fayda National ID (Optional)", lblInsurance: "Insurance Provider (Optional)",
        noInsurance: "No Private Insurance (Community Care)", skipBtn: "Skip for Now", saveBtn: "Save Profile",
        anatomyHeading: "Symptom Mapping", anatomyLead: "Click on the 3D model or use the list below to select your area of concern.",
        selectedZoneLabel: "Selected Zone:", symptomPrompt: "What type of discomfort are you experiencing?",
        lockBtn: "Lock Symptoms & Start AI Intake", aiChatTitle: "CareSync Clinical AI", aiStatus: "Connected | Multi-Lingual Assistant",
        welcomeMsg: "Welcome! I'm your wellness assistant. Let's talk about how you're feeling.",
        sendBtn: "Send →", careTeamTitle: "👤 Your Care Team", psychiatristTitle: "Consultant Psychiatrist",
        aiMatched: "✓ AI-Matched to your symptoms", intakeComplete: "✓ Intake completed", caseTransmitted: "Your case has been securely transmitted",
        appointmentTitle: "📅 Appointment & Logistics", appointmentLabel: "📅 Appointment:", transportLabel: "🚗 Transport:",
        pendingPayment: "Pending Payment", locationLabel: "📍 Location:", paymentTitle: "💳 Complete Payment",
        bookRideBtn: "🚕 Book Ride to Appointment", startOver: "← Start Over",
        tradPageTitle: "🌿 Traditional Medicine Finder", tradPageDesc: "Select a recorded condition profile to pull verified traditional remedies and instructional links.",
        tradFormLabel: "Select Your Disease or Symptom Profile:", optDefault: "-- Click to choose an option --",
        optDigestive: "Indigestion & Severe Bloating", optSleep: "Insomnia & Persistent Restlessness", optFatigue: "Chronic Low Energy & Fatigue",
        tradSubmitBtn: "Generate Remedy Data", eduResourceText: "Educational Resource:", remedyLinkText: "Watch external video guides and tutorials here →",
        quizPageTitle: "🧠 Mental Health Check-In Quiz", quizPageDesc: "Complete these 5 critical questions accurately regarding your behaviors over the last 14 days.",
        quizSubmitBtn: "Submit Mind Evaluation", healthyResultTitle: "Your baseline scores look healthy!",
        healthyResultDesc: "Continue maintaining a robust routine, consistent sleep metrics, and regular mental breaks.",
        careRoutingTitle: "Professional Care Routing Required", careRoutingDesc: "Your score suggests you may be going through a tough time. Please pick an authorized professional from our panel below to proceed to booking:",
        selectPayBtn: "Select & Pay", checkoutTitle: "💳 Gateway Checkout Page", sandboxTitle: "Secure Credit Card Transaction Sandbox", processPaymentBtn: "Process Payment Gateway",
        subsPageTitle: "💎 Manage/Update Premium Subscriptions", subsPageDesc: "Modify your current portal setup parameters or update tiers easily here.",
        tierFreeTitle: "Free Tier Profile", perMonthText: "/ month", tierFreeDesc: "Includes base questionnaires and general local listings.", activeTierBtn: "Active Tier",
        premiumChoiceBadge: "PREMIUM CHOICE", tierPremiumTitle: "Plus Plan Membership", tierPremiumDesc: "Unlocks video database directories, remedy clips, and priority matching.", tierPremiumBtn: "Update/Renew Subscription"
    },
    am: {
        navHome: "ዋና ገጽ", navTrad: "ባህላዊ ህክምና", navAnatomy: "ምልክት መመርመሪያ", navQuiz: "የአእምሮ መጠይቅ", navSubs: "ፕሪሚየም", navAuth: "ግባ",
        splashTitle: "ቋንቋዎን ይምረጡ", splashSubtitle: "ወደ ጤና ጉዞዎ እንኳን ደህና መጡ",
        sendCodeBtn: "የማረጋገጫ ኮድ ላክ", verifyBtn: "አረጋግጥና ቀጥል",
        kycTitle: "መለያዎን ለግል ያብጁ", kycSubtitle: "ትክክለኛውን የጤና እንክብካቤ አቅራቢ እንድንፈልግልዎ ይረዱን።",
        lblName: "ሙሉ ስም", lblFayda: "የፋይዳ ብሄራዊ መታወቂያ (አማራጭ)", lblInsurance: "የመድን ዋስትና ሰጪ (አማራጭ)",
        noInsurance: "የግል መድን የለኝም (የማህበረሰብ እንክብካቤ)", skipBtn: "ለጊዜው ይለፍ", saveBtn: "ፕሮፋይል አስቀምጥ",
        anatomyHeading: "የበሽታ ምልክት ካርታ", anatomyLead: "የሚያሳስብዎትን የሰውነት ክፍል ለመምረጥ በ3ዲ ሞዴሉ ላይ ጠቅ ያድርጉ ወይም ከታች ያለውን ዝርዝር ይጠቀሙ።",
        selectedZoneLabel: "የተመረጠው ክፍል:", symptomPrompt: "ምን ዓይነት ህመም ወይም ምቾት ማጣት እየተሰማዎት ነው?",
        lockBtn: "ምልክቶችን መዝግብና AI ቃለ-መጠይቅ ጀምር", aiChatTitle: "CareSync ክሊኒካል AI", aiStatus: "ተገናኝቷል | ባለብዙ ቋንቋ ረዳት",
        welcomeMsg: "እንኳን ደህና መጡ! እኔ የእርስዎ የጤና ረዳት ነኝ። ስለሚሰማዎት ስሜት እንነጋገር።",
        sendBtn: "ላክ →", careTeamTitle: "👤 የህክምና ቡድንዎ", psychiatristTitle: "አማካሪ የስነ-አእምሮ ሐኪም",
        aiMatched: "✓ ከምልክቶችዎ ጋር በAI የተዛመደ", intakeComplete: "✓ የቅድመ ምርመራ ተጠናቋል", caseTransmitted: "የእርስዎ መረጃ በጥንቃቄ ተላልፏል",
        appointmentTitle: "📅 ቀጠሮ እና ሎጂስቲክስ", appointmentLabel: "📅 ቀጠሮ:", transportLabel: "🚗 ትራንስፖርት:",
        pendingPayment: "ክፍያ ይጠበቃል", locationLabel: "📍 ቦታ:", paymentTitle: "💳 ክፍያ ይፈጽሙ",
        bookRideBtn: "🚕 ወደ ቀጠሮው መጓጓዣ ይዘዙ", startOver: "← እንደገና ጀምር",
        tradPageTitle: "🌿 የባህላዊ ህክምና መፈለጊያ", tradPageDesc: "የተረጋገጡ ባህላዊ መፍትሄዎችን እና ትምህርታዊ አገናኞችን ለማውጣት የተመዘገበ የሕመም መገለጫ ይምረጡ።",
        tradFormLabel: "የበሽታዎን ወይም የምልክትዎን መገለጫ ይምረጡ፡", optDefault: "-- አማራጮችን ለመምረጥ እዚህ ጠቅ ያድርጉ --",
        optDigestive: "የምግብ አለመፈጨት እና ከባድ የሆድ መነፋት", optSleep: "የእንቅልፍ እጣት እና የማረፍ ችግር", optFatigue: "የመዛል ስሜት እና ከፍተኛ የሃይል መቀነስ",
        tradSubmitBtn: "የመፍትሄ መረጃ አውጣ", eduResourceText: "ትምህርታዊ መርጃዎች:", remedyLinkText: "የቪዲዮ መመሪያዎችን እዚህ ይመልከቱ →",
        quizPageTitle: "🧠 የአእምሮ ጤና መፈተሻ መጠይቅ", quizPageDesc: "ባለፉት 14 ቀናት ውስጥ ስለነበሩዎት ባህሪያት እነዚህን 5 ወሳኝ ጥያቄዎች በትክክል ይመልሱ።",
        quizSubmitBtn: "የአእምሮ ግምገማ አስገባ", healthyResultTitle: "የእርስዎ ውጤት ጤናማ ነው!",
        healthyResultDesc: "ጤናማ የአኗኗር ዘይቤን፣ ወጥ የሆነ የእንቅልፍ መርሃግብርን እና መደበኛ የአእምሮ እረፍትን ይቀጥሉ።",
        careRoutingTitle: "የባለሙያ እንክብካቤ ማግኘት ያስፈልጋል", careRoutingDesc: "ውጤትዎ አስቸጋሪ ጊዜ ውስጥ እያለፉ ሊሆን እንደሚችል ያሳያል። እባክዎ ከታች ካለው ዝርዝር ውስጥ የተፈቀደለትን ባለሙያ ይምረጡ፡",
        selectPayBtn: "ምረጥና ክፈል", checkoutTitle: "💳 የክፍያ ገጽ", sandboxTitle: "ደህንነቱ የተጠበቀ የክሬዲት ካርድ መሞከሪያ ሳጥን", processPaymentBtn: "ክፍያውን ፈጽም",
        subsPageTitle: "💎 የፕሪሚየም ምዝገባዎችን ያስተዳድሩ/ያድሱ", subsPageDesc: "የአሁኑን የፖርታል ማዋቀሪያ መለኪያዎች ያስተካክሉ ወይም ደረጃዎችን እዚህ በቀላሉ ያዘምኑ።",
        tierFreeTitle: "ነፃ መሠረታዊ ደረጃ", perMonthText: "/ በወር", tierFreeDesc: "መሠረታዊ መጠይቆችን እና አጠቃላይ የአካባቢ ዝርዝሮችን ያካትታል።", activeTierBtn: "ንቁ ደረጃ",
        premiumChoiceBadge: "የፕሪሚየም ምርጫ", tierPremiumTitle: "የፕላስ እቅድ አባልነት", tierPremiumDesc: "የቪዲዮ ዳታቤዝ ማውጫዎችን፣ የፈውስ ክሊፖችን እና ቅድሚያ የሚሰጠው ተዛማጅነትን ይከፍታል።", tierPremiumBtn: "ምዝገባን ያድሱ"
    },
    om: {
        navHome: "Mana", navTrad: "Qoricha Aadaa", navAnatomy: "Mallattooo Qaamaa", navQuiz: "Gaaffii Sammuu", navSubs: "Preemiyami", navAuth: "Seeni",
        splashTitle: "Afaan Keessan Filadha", splashSubtitle: "Baga gara imala fayyaa keessanii nagaan dhuftan",
        sendCodeBtn: "Koodii Mirkaneessaa Ergi", verifyBtn: "Mirkaneessi & Itti Fufi",
        kycTitle: "Akaawwuntii Keessan Dhuunfaysaa", kycSubtitle: "Ogeessa fayyaa sirrii wajjin akka isin walitti fidhnuuf nu gargaaraa.",
        lblName: "Maqaa Guutuu", lblFayda: "Waraqaa Eenyummaa Faydaa (Filannoo)", lblInsurance: "Inshuraansii (Filannoo)",
        noInsurance: "Inshuraansii Dhuunfaa Hin Qabu", skipBtn: "Ammaaf Dhiisi", saveBtn: "Galmee Olkaayi",
        anatomyHeading: "Mataa fi Qaama Mirkaneessuu", anatomyLead: "Bakka dhukkubbii keessanii filachuuf moodeela 3D irratti cuqaasaa ykn tarree gadii fayyadamaa.",
        selectedZoneLabel: "Naannoo Filatame:", symptomPrompt: "Miira dhukkubbii akkamii sitti dhagahamaa jira?",
        lockBtn: "Mallattoo Cuqi & AI Intake Jalqabi", aiChatTitle: "CareSync Clinical AI", aiStatus: "Hojirra Jira | Gargaaraa Afaan Baay'ee",
        welcomeMsg: "Baga nagaan dhuftan! Ani gargaaraa fayyaa keessani. Waa'ee miira keessanii haa haasofnu.",
        sendBtn: "Ergi →", careTeamTitle: "👤 Garee Yaala Keessanii", psychiatristTitle: "Ogeessa Yaala Sammuu",
        aiMatched: "✓ AI'n mallattoon keessan walitti fideera", intakeComplete: "✓ Inteeikii xumurameera", caseTransmitted: "Galmeen keessan haala amansiisaan darbeera",
        appointmentTitle: "📅 Beellama & Loojistiksii", appointmentLabel: "📅 Beellama:", transportLabel: "🚗 Geejjiba:",
        pendingPayment: "Kafaltii Eeggata", locationLabel: "📍 Bakka:", paymentTitle: "💳 Kafaltii Xumuri",
        bookRideBtn: "🚕 Gara Beellamaatti Geejjiba Ajaji", startOver: "← Jalqabarraa Jalqabi",
        tradPageTitle: "🌿 Qoricha Aadaa Barbaaduu", tradPageDesc: "Qorichaa aadaa mirkanaa'an fi liankii barsiisaa argachuuf piroofaayili dhukkubbaa filadhaa.",
        tradFormLabel: "Piroofaayili Mallattoo ykn Dhukkuba Keessan Filadha:", optDefault: "-- Filachuuf as tuqi --",
        optDigestive: "Garaa Kaasaa fi Baay'ee Furdifama Garaa", optSleep: "Hirriba Dhabuu fi Boqonnaa Dhabuu Persistent",
        optFatigue: "Humna Dhabuu fi Dadhabbi Cimaa",
        tradSubmitBtn: "Mataa Mirkaneessaa Maddisiisi", eduResourceText: "Meeshaa Barnootaa:", remedyLinkText: "Giddu-gala Viidiyoo Asitti Daawwadhaa →",
        quizPageTitle: "🧠 Qorannoo Fayyaa Sammuu", quizPageDesc: "Guyyoota 14n darban keessatti haala amala keessanii irratti hundaa'uun gaaffilee 5 kanneen sirriitti deebisaa.",
        quizSubmitBtn: "Mirkaneessa Sammuu Ergi", healthyResultTitle: "Giddu-galeessi keessan fayyaa dha!",
        healthyResultDesc: "Sirna gaarii, hamma hirriba walitti fufiinsa qabu fi boqonnaa sammuu yeroo hunda eegaa itti fufa.",
        careRoutingTitle: "Gargaarsa Ogeessaa Barbaachisa", careRoutingDesc: "Qabxiin keessan yeroo rakkisaa keessa darbaa akka jirtan argisiisa. Maaloo ogeessaa heyyamame tokko filadha:",
        selectPayBtn: "Filadhu & Kafali", checkoutTitle: "💳 Giddu-gala Kafaltii", sandboxTitle: "Imaammata Sandaaboksii Kilaasii Kaardii Amansiisaa", processPaymentBtn: "Kafaltii Hojirra Olchi",
        subsPageTitle: "💎 Maanaajii/Haoromsa Maandamtummaa Preemiyami", subsPageDesc: "Asitti dhimmoota portali keessan sirreessuu ykn sadarkaa haaromsuu dandeessu.",
        tierFreeTitle: "Sadarkaa Bilisaa", perMonthText: "/ ji'aan", tierFreeDesc: "Gaaffilee bu'uuraa fi tarreeffama naannoo ni dabalata.", activeTierBtn: "Sadarkaa Hojirra Jira",
        premiumChoiceBadge: "FILANNOO FILATAMAA", tierPremiumTitle: "Miseensummaa Karoora Plus", tierPremiumDesc: "Viidiyoo daatabeasii, kilipoota qorichaa fi walitti fiinsaa duraa duraa bana.", tierPremiumBtn: "Maandamtummaa Haaromsi"
    }
};

const zoneSymptoms = {
    Head: ["Headache / ራስ ምታት", "Dizziness / ማዞር", "Anxiety / ጭንቀት", "Brain Fog / የአእምሮ መታወክ"],
    Chest: ["Palpitations / የልብ ምት መጨመር", "Tightness / የደረት መጥበብ", "Shortness of Breath / የመተንፈስ ችግር"],
    Stomach: ["Nausea / ማቅለሽለሽ", "Acid Reflux / የቃጠሎ ስሜት", "Bloating / የሆድ መነፋት"],
    Limbs: ["Tremors / መንቀጥቀጥ", "Numbness / መደንዘዝ", "Weakness / የጡንቻ መላላት"]
};

// Application Routing View Management
function showPage(pageId) {
    document.querySelectorAll('.view-state').forEach(view => view.classList.remove('active'));
    const target = document.getElementById(`state-${pageId}`) || document.getElementById(pageId);
    if (target) target.classList.add('active');
    
    if (pageId === 'state-anatomy' || pageId === 'anatomy') {
        setTimeout(initThreeDModel, 100);
    }
}

function selectLanguage(lang) {
    currentLanguage = lang;
    updateUILanguage();
    showPage('auth');
}

function switchLanguage(lang) {
    currentLanguage = lang;
    updateUILanguage();
}

function updateUILanguage() {
    document.querySelectorAll('[data-key]').forEach(el => {
        const key = el.getAttribute('data-key');
        if (translations[currentLanguage] && translations[currentLanguage][key]) {
            if (el.tagName === 'INPUT' || el.tagName === 'SELECT') {
                el.placeholder = translations[currentLanguage][key];
            } else {
                el.innerText = translations[currentLanguage][key];
            }
        }
    });
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-lang') === currentLanguage);
    });
}

function toggleLiteMode() {
    isLiteMode = !isLiteMode;
    document.getElementById('lite-mode-toggle').innerText = isLiteMode ? "📉 Data Saver: ON" : "📉 Data Saver: OFF";
    document.getElementById('lite-fallback-map').classList.toggle('hidden', !isLiteMode);
    const canvas = document.getElementById('three-canvas-target');
    if (canvas) canvas.style.display = isLiteMode ? 'none' : 'block';
}

function triggerSOS() {
    alert("🚨 EMERGENCY NOTICE: Calling national health dispatcher (+251911) and alerting emergency nodes framework...");
}

// Phone Number Sandbox Logic
function sendOTP() {
    const num = document.getElementById('phone-number').value;
    if (num.length < 9) {
        document.getElementById('auth-error').innerText = "Invalid setup. Enter 9 digits.";
        document.getElementById('auth-error').classList.remove('hidden');
        return;
    }
    document.getElementById('auth-error').classList.add('hidden');
    document.getElementById('phone-input-group').classList.add('hidden');
    document.getElementById('otp-input-group').classList.remove('hidden');
    document.getElementById('auth-subtitle').innerText = "Enter verification code: 123456";
}

function verifyOTP() {
    const code = document.getElementById('otp-code').value;
    if (code !== '123456') {
        document.getElementById('auth-error').innerText = "Incorrect code. Use 123456";
        document.getElementById('auth-error').classList.remove('hidden');
        return;
    }
    showPage('kyc');
}

function skipKYC() { showPage('state-anatomy'); }
function saveKYC() { alert("Profile logged securely!"); showPage('state-anatomy'); }

// Three.js Pipeline Architecture
let renderer, camera, scene, mesh;
function initThreeDModel() {
    if (renderer || isLiteMode) return;
    const container = document.getElementById('three-canvas-target');
    if (!container) return;

    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 0.1, 100);
    camera.position.z = 5;

    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    container.appendChild(renderer.domElement);

    // Anatomical abstraction target system (Wireframe Node Structure)
    const geometry = new THREE.SphereGeometry(1.5, 32, 16);
    const material = new THREE.MeshBasicMaterial({ color: 0xa7d7c5, wireframe: true });
    mesh = new THREE.Mesh(geometry, material);
    scene.add(mesh);

    function animate() {
        if (isLiteMode) return;
        requestAnimationFrame(animate);
        mesh.rotation.y += 0.005;
        renderer.render(scene, camera);
    }
    animate();

    // Emulated Raycaster Click Processing
    container.addEventListener('click', () => {
        const parts = ["Head", "Chest", "Stomach", "Limbs"];
        handlePartSelection(parts[Math.floor(Math.random() * parts.length)]);
    });
}

function handlePartSelection(part) {
    selectedZone = part;
    document.getElementById('selected-zone-display').innerText = part;
    document.getElementById('selection-panel').classList.remove('hidden');
    
    const chipsBox = document.getElementById('symptom-chips');
    chipsBox.innerHTML = '';
    zoneSymptoms[part].forEach(symptom => {
        const chip = document.createElement('div');
        chip.className = 'chip';
        chip.innerText = symptom;
        chip.onclick = () => {
            document.querySelectorAll('.chip').forEach(c => c.classList.remove('selected'));
            chip.classList.add('selected');
            selectedSymptom = symptom;
        };
        chipsBox.appendChild(chip);
    });
}

function confirmSymptomMap() {
    if (!selectedSymptom) { alert("Please click to select a symptom first!"); return; }
    showPage('ai-intake');
    triggerInitialAICall();
}

// Intake Chat Core Architecture
async function triggerInitialAICall() {
    const stream = document.getElementById('chat-stream');
    stream.innerHTML = `<div class="message bot">⏳ System Initializing Intake Analysis Framework...</div>`;
    
    try {
        const res = await fetch('/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                message: "Initialize Intake Framework",
                language: currentLanguage,
                context: { isInitial: true, symptom: selectedSymptom, zone: selectedZone }
            })
        });
        const data = await res.json();
        renderBotMessage(data);
    } catch (e) {
        console.error(e);
    }
}

function renderBotMessage(data) {
    const stream = document.getElementById('chat-stream');
    const msg = document.createElement('div');
    msg.className = 'message bot';
    msg.innerText = data.message;
    stream.appendChild(msg);
    stream.scrollTop = stream.scrollHeight;

    const chipsBox = document.getElementById('ai-quick-chips');
    chipsBox.innerHTML = '';
    if (data.chips) {
        data.chips.forEach(chipText => {
            const btn = document.createElement('button');
            btn.className = 'btn btn-primary';
            btn.style.marginRight = '6px';
            btn.innerText = chipText;
            btn.onclick = () => sendCustomChatMessage(chipText);
            chipsBox.appendChild(btn);
        });
    }
}

async function sendCustomChatMessage(text) {
    if (!text.trim()) return;
    const stream = document.getElementById('chat-stream');
    
    const userMsg = document.createElement('div');
    userMsg.className = 'message user';
    userMsg.innerText = text;
    stream.appendChild(userMsg);
    
    chatHistory.push({ role: 'user', text: text });
    
    try {
        const res = await fetch('/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: text, language: currentLanguage, history: chatHistory })
        });
        const data = await res.json();
        chatHistory.push({ role: 'model', text: data.message });
        renderBotMessage(data);

        if (text.match(/Book appointment|ቀጠሮ ለማስያዝ|Beellama/i)) {
            setTimeout(() => showPage('dashboard'), 1500);
        }
    } catch (e) {
        console.error(e);
    }
}

function submitUserMessage() {
    const input = document.getElementById('user-message-input');
    sendCustomChatMessage(input.value);
    input.value = '';
}

function handleChatKeypress(e) {
    if (e.key === 'Enter') submitUserMessage();
}

// Payment & Logistics Operations Sandbox
function processPayment(method) {
    const overlay = document.getElementById('payment-overlay-status');
    overlay.innerText = `Connecting secure verification payload to ${method} framework API...`;
    
    fetch('/api/pay', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ provider: method, amount: 250 })
    })
    .then(r => r.json())
    .then(data => {
        overlay.innerHTML = `<span style="color: green; font-weight:bold;">✓ ${data.message} (ID: ${data.transactionId})</span>`;
        document.getElementById('ride-status').innerText = "Payment Verified | Logistics Ready";
    });
}

function bookRide() {
    const rideStatus = document.getElementById('ride-status');
    rideStatus.innerText = "Dispatching CareSync Transport Node...";
    
    fetch('/api/book-ride', { method: 'POST' })
    .then(r => r.json())
    .then(data => {
        rideStatus.innerHTML = `Driver Dispatched: ${data.driverName} (${data.plateNumber}) - ETA ${data.etaMinutes} mins. Contact: ${data.driverPhone}`;
    });
}

// Traditional Medicine Data Management
function findTraditionalRemedy() {
    const choice = document.getElementById('symptomSelect').value;
    const box = document.getElementById('traditionalResult');
    if (!choice) { box.classList.add('hidden'); return; }

    const remedies = {
        digestive: { title: "Dina (ዲና) Oil Extraction & Ginger Infusions", desc: "For extreme indigestion or bloating, extract organic ginger roots and combine with indigenous warm mint oils. Administer twice daily before meal structures." },
        sleep: { title: "Kosso-Root Chamomile Calming Tea Essence", desc: "To address insomnia, create high-concentration local loose chamomile flower infusions. Avoid sensory screens for 60 minutes following intake parameters." },
        fatigue: { title: "Moringa Whole leaf (ሽፈራው) Complex Infusions", desc: "For chronic exhaustion, boil dried whole leaf Moringa samples in sterile water fields. High trace macroelement content acts as an immune catalyst." }
    };

    document.getElementById('remedyTitle').innerText = remedies[choice].title;
    document.getElementById('remedyDesc').innerText = remedies[choice].desc;
    document.getElementById('remedyLink').href = "https://www.youtube.com/results?search_query=ethiopian+traditional+medicine";
    box.classList.remove('hidden');
}

// Behavioral Evaluation Quiz Logic
function evaluateQuiz() {
    let score = 0;
    const form = new FormData(document.getElementById('mindQuizForm'));
    for (let entry of form.values()) {
        score += parseInt(entry);
    }
    
    document.getElementById('quizHealthyResult').classList.add('hidden');
    document.getElementById('quizDirectoryResult').classList.add('hidden');

    if (score >= 5) {
        document.getElementById('quizDirectoryResult').classList.remove('hidden');
    } else {
        document.getElementById('quizHealthyResult').classList.remove('hidden');
    }
}

function goToFinance(docName, price) {
    document.getElementById('checkoutDetails').innerText = `Routing Gateway Sandbox Order for ${docName} (${price} USD)`;
    document.getElementById('financePage').classList.remove('hidden');
}

function processPaymentGateway() {
    alert("Payment processed successfully (Sandbox Demo mode) via international rails. Case transmitted!");
}

function resetToSplash() {
    chatHistory = [];
    showPage('splash');
}

// Global Event Initialization Bindings
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('lite-mode-toggle')?.addEventListener('click', toggleLiteMode);
    document.getElementById('sos-btn')?.addEventListener('click', triggerSOS);
    document.querySelectorAll('.body-part-btn').forEach(btn => {
        btn.addEventListener('click', () => handlePartSelection(btn.getAttribute('data-part')));
    });
    updateUILanguage();
});

window.addEventListener('resize', () => {
    if (renderer && camera && !isLiteMode) {
        const container = document.getElementById('three-canvas-target');
        if (container) {
            const w = container.clientWidth, h = container.clientHeight;
            camera.aspect = w / h;
            camera.updateProjectionMatrix();
            renderer.setSize(w, h);
        }
    }
});
EOF

echo "✅ Complete CareSync Wellness Hub fixed successfully!"
echo ""
echo "📁 Project location: $(pwd)"
echo ""
echo "🚀 To run:"
echo "  1. cd $(pwd)"
echo "  2. npm install"
echo "  3. Add GEMINI_API_KEY to your env configuration environment variables"
echo "  4. npm start"
echo ""
echo "🌐 Open http://localhost:3000"