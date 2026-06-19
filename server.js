import {GoogleGenAI} from '@google/genai';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import {fileURLToPath} from 'url';
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

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
const getRuleBasedResponse = (userMessage, language, conversationContext = {}) => {
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

// Generate AI response using Gemini
const generateGeminiResponse = async (userMessage, language, conversationHistory) => {
  if (!aiClient) {
    return getRuleBasedResponse(userMessage, language);
  }
  
  try {
    // Build conversation context
    const systemInstruction = `You are a compassionate medical intake assistant for a wellness platform called CareSync. 
    Your role is to provide empathetic, professional responses to users seeking mental and physical health support.
    Respond in ${language === 'am' ? 'Amharic (አማርኛ)' : language === 'om' ? 'Afaan Oromoo' : 'English'}.
    Keep responses concise (1-2 sentences) and always suggest 2-4 quick reply options (chips) that guide the conversation forward.
    Be warm but professional. Never give medical diagnoses, but offer general wellness advice and encourage professional consultation.`;
    
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
    
    const result = JSON.parse(response.text);
    return result;
  } catch (error) {
    console.error("Gemini API error:", error);
    return getRuleBasedResponse(userMessage, language);
  }
};

// API Endpoint: AI Chat
app.post('/api/chat', async (req, res) => {
  try {
    const { message, language = 'en', history = [], context = {} } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    // If this is the initial intake request (includes symptom and zone)
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
    
    // Generate response using Gemini or fallback
    const aiResponse = await generateGeminiResponse(message, language, history);
    res.json(aiResponse);
    
  } catch (error) {
    console.error('Chat API error:', error);
    const fallback = getRuleBasedResponse(req.body.message || "Help", req.body.language || 'en');
    res.json(fallback);
  }
});

// API Endpoint: Simulated Payment
app.post('/api/pay', (req, res) => {
  const { provider, amount, userPhone } = req.body;
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
  const { pickupLocation, destination } = req.body;
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

// Serve main.html for all other routes (SPA support)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'main.html'));
});

app.listen(PORT, () => {
  console.log(`✨ CareSync Wellness Hub running on http://localhost:${PORT}`);
  console.log(`📱 Multi-language support: ${Object.values(SUPPORTED_LANGUAGES).join(', ')}`);
  console.log(`🤖 AI Mode: ${aiClient ? 'Gemini AI' : 'Rule-based fallback'}`);
});