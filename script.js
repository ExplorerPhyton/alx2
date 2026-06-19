let currentLanguage = 'en';
let isLiteMode = false;
let activeSelectedZone = "";
let selectedSymptomType = "";
let chatHistory = [];
let chatStep = 0;
let userProfile = { name: '', faydaId: '', insurance: 'none' };

// Three.js variables
let scene, camera, renderer, humanoidGroup, animationFrameId;

// ==================== MULTI-LINGUAL DICTIONARY ====================
const translations = {
    en: {
        splashTitle: "Select Your Language",
        splashSubtitle: "Welcome to your wellness journey",
        authTitle: "Verify Phone Number",
        authSubtitle: "We'll send a verification code to your mobile number.",
        kycTitle: "Personalize Your Account",
        kycSubtitle: "Help us match you with the right care providers.",
        lblName: "Full Name",
        lblFayda: "Fayda National ID (Optional)",
        lblInsurance: "Insurance Provider (Optional)",
        anatomyHeading: "Symptom Mapping",
        anatomyLead: "Click on the 3D model or use the list below to select your area of concern.",
        symptomPrompt: "What type of discomfort are you experiencing?",
        lockBtn: "Lock Symptoms & Start AI Intake",
        sosAlert: "⚠️ EMERGENCY: Connecting you to immediate medical support. Please stay on the line.",
        paymentSuccess: "Payment Successful! Transaction ID: ",
        rideBooked: "Ride booked! Driver ",
        symptomsList: ["Tension / Tightness", "Aching / Throbbing", "Sudden Sharp Pain", "Numbness / Tingling", "Burning Sensation"]
    },
    am: {
        splashTitle: "ቋንቋ ይምረጡ",
        splashSubtitle: "እንኳን ወደ ጤና ጉዞዎ በደህና መጡ",
        authTitle: "ስልክ ቁጥርዎን ያረጋግጡ",
        authSubtitle: "የማረጋገጫ ኮድ ወደ ስልክዎ እንልካለን።",
        kycTitle: "መለያዎን ያብጁ",
        kycSubtitle: "ተገቢውን እንክብካቤ እንዲያገኙ እንረዳዎታለን።",
        lblName: "ሙሉ ስም",
        lblFayda: "ፋይዳ ብሔራዊ መታወቂያ (አማራጭ)",
        lblInsurance: "ኢንሹራንስ አቅራቢ (አማራጭ)",
        anatomyHeading: "የህመም ምልክቶች ካርታ",
        anatomyLead: "የሚሰማዎትን ቦታ ለመምረጥ በ3D ሞዴሉ ላይ ይጫኑ ወይም ከዝርዝሩ ይምረጡ።",
        symptomPrompt: "ምን አይነት ምቾት ማጣት ይሰማዎታል?",
        lockBtn: "ምልክቶችን መዝግብ እና AI ውይይት ጀምር",
        sosAlert: "⚠️ ድንገተኛ፡ ወደ ፈጣን የህክምና እርዳታ እያገናኘንዎት ነው።",
        paymentSuccess: "ክፍያ ተሳክቷል! ግብይት መለያ: ",
        rideBooked: "ማመላለሻ ተዘጋጅቷል! ሹፌር ",
        symptomsList: ["ውጥረት / መጨናነቅ", "የሚወጋ ህመም", "ድንገተኛ ሹል ህመም", "መደንዘዝ / ማነጠር", "የሚቃጠል ስሜት"]
    },
    om: {
        splashTitle: "Afaan filadhu",
        splashSubtitle: "Achumanii fayyaa keessanitti baga nagaan dhufte",
        authTitle: "Lakkoofsa bilbilaa mirkaneessi",
        authSubtitle: "Koodii mirkaneessaa bilbilaa keessaniif ergina.",
        kycTitle: "Herrega keessan buusuu",
        kycSubtitle: "Gargaarsa sirritti argachuuf isin gargaarra.",
        lblName: "Maqaa guutuu",
        lblFayda: "ID Fayda (Filannoo)",
        lblInsurance: "Dhaabbata Inshuraansii (Filannoo)",
        anatomyHeading: "Kaarta mallattoolee",
        anatomyLead: "Bakka miira dhukkubbii keessan filachuuf kaarta 3D tuqaa ykn tarree irraa filadhaa.",
        symptomPrompt: "Miira dhukkubbii akkamii qabdu?",
        lockBtn: "Mallattoo galmeessi fi AI jalqabi",
        sosAlert: "⚠️ Dimmisa: Gargaarsa fayyaa yeroo dhufiitti si siqsiisna.",
        paymentSuccess: "Kaffaltiif milkaa'e! ID: ",
        rideBooked: "Konkoolataa ",
        symptomsList: ["Dhiphina / Cimina", "Dhukkubbii walakkaa", "Dhukkubbii tasa cimaa", "Hadooduu / Qarraxa'uu", "Gubuufi"]
    }
};

// ==================== HELPER FUNCTIONS ====================
function updateUILanguage() {
    const t = translations[currentLanguage];
    if (!t) return;
    document.querySelectorAll('[data-key]').forEach(el => {
        const key = el.getAttribute('data-key');
        if (t[key]) el.textContent = t[key];
    });
    if (document.getElementById('auth-title')) document.getElementById('auth-title').innerText = t.authTitle;
    if (document.getElementById('auth-subtitle')) document.getElementById('auth-subtitle').innerText = t.authSubtitle;
    if (document.getElementById('kyc-title')) document.getElementById('kyc-title').innerText = t.kycTitle;
    if (document.getElementById('kyc-subtitle')) document.getElementById('kyc-subtitle').innerText = t.kycSubtitle;
    if (document.getElementById('lbl-fayda')) document.getElementById('lbl-fayda').innerText = t.lblName;
    if (document.getElementById('lbl-fayda-id')) document.getElementById('lbl-fayda-id').innerText = t.lblFayda;
    if (document.getElementById('lbl-insurance')) document.getElementById('lbl-insurance').innerText = t.lblInsurance;
    if (document.getElementById('anatomy-heading')) document.getElementById('anatomy-heading').innerText = t.anatomyHeading;
    if (document.getElementById('anatomy-lead')) document.getElementById('anatomy-lead').innerText = t.anatomyLead;
    if (document.getElementById('symptom-prompt-text')) document.getElementById('symptom-prompt-text').innerText = t.symptomPrompt;
}

function selectLanguage(lang) {
    currentLanguage = lang;
    updateUILanguage();
    transitionToState('state-auth');
}

function transitionToState(stateId) {
    document.querySelectorAll('.view-state').forEach(view => {
        view.classList.remove('active');
    });
    const target = document.getElementById(stateId);
    if (target) target.classList.add('active');
    
    if (stateId === 'state-anatomy') {
        initThreeAnatomy();
    } else {
        killThreeLoop();
    }
    if (stateId === 'state-ai-intake') {
        initializeAIChat();
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function resetToSplash() {
    transitionToState('state-splash');
    chatHistory = [];
    chatStep = 0;
    activeSelectedZone = "";
    selectedSymptomType = "";
}

function triggerSOS() {
    const msg = translations[currentLanguage]?.sosAlert || "Emergency help requested";
    alert(msg);
    console.log("SOS triggered - emergency dispatch notified");
}

// ==================== AUTH & KYC ====================
function sendOTP() {
    const phone = document.getElementById('phone-number').value;
    if (!phone || phone.length < 9) {
        showAuthError("Please enter a valid phone number");
        return;
    }
    document.getElementById('phone-input-group').classList.add('hidden');
    document.getElementById('otp-input-group').classList.remove('hidden');
}

function verifyOTP() {
    const otp = document.getElementById('otp-code').value;
    if (!otp || otp.length < 4) {
        showAuthError("Please enter the verification code");
        return;
    }
    transitionToState('state-kyc');
}

function showAuthError(msg) {
    const errEl = document.getElementById('auth-error');
    if (errEl) {
        errEl.innerText = msg;
        errEl.classList.remove('hidden');
        setTimeout(() => errEl.classList.add('hidden'), 3000);
    }
}

function saveKYC() {
    userProfile.name = document.getElementById('full-name')?.value || '';
    userProfile.faydaId = document.getElementById('fayda-id')?.value || '';
    userProfile.insurance = document.getElementById('insurance-provider')?.value || 'none';
    transitionToState('state-anatomy');
}

function skipKYC() {
    transitionToState('state-anatomy');
}

// ==================== LITE MODE & THREE.JS ====================
function toggleLiteMode() {
    isLiteMode = !isLiteMode;
    const btn = document.getElementById('lite-mode-toggle');
    const canvasTarget = document.getElementById('three-canvas-target');
    const flatFallback = document.getElementById('lite-fallback-map');
    
    if (isLiteMode) {
        btn.innerText = "📶 Data Saver: ON";
        if (canvasTarget) canvasTarget.classList.add('hidden');
        if (flatFallback) flatFallback.classList.remove('hidden');
        killThreeLoop();
    } else {
        btn.innerText = "📉 Data Saver: OFF";
        if (canvasTarget) canvasTarget.classList.remove('hidden');
        if (flatFallback) flatFallback.classList.add('hidden');
        initThreeAnatomy();
    }
}

function initThreeAnatomy() {
    if (isLiteMode || scene) return;
    const container = document.getElementById('three-canvas-target');
    if (!container) return;
    
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0f172a);
    scene.fog = new THREE.FogExp2(0x0f172a, 0.008);
    
    const width = container.clientWidth;
    const height = container.clientHeight;
    camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
    camera.position.set(0, 0.5, 8);
    camera.lookAt(0, 0.5, 0);
    
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    renderer.setSize(width, height);
    renderer.setPixelRatio(window.devicePixelRatio);
    container.innerHTML = '';
    container.appendChild(renderer.domElement);
    
    // Lighting
    const ambient = new THREE.AmbientLight(0x404060);
    scene.add(ambient);
    const mainLight = new THREE.DirectionalLight(0xffffff, 1);
    mainLight.position.set(5, 10, 7);
    scene.add(mainLight);
    const fillLight = new THREE.PointLight(0x4466cc, 0.3);
    fillLight.position.set(-2, 1, 3);
    scene.add(fillLight);
    
    humanoidGroup = new THREE.Group();
    const material = new THREE.MeshStandardMaterial({ color: 0x4a6fa5, roughness: 0.4, metalness: 0.1, emissive: 0x111822 });
    
    // Body parts
    const headGeo = new THREE.SphereGeometry(0.45, 32, 32);
    const head = new THREE.Mesh(headGeo, material.clone());
    head.position.y = 1.6;
    head.userData = { partName: "Head" };
    humanoidGroup.add(head);
    
    const chestGeo = new THREE.CylinderGeometry(0.55, 0.5, 1.1, 24);
    const chest = new THREE.Mesh(chestGeo, material.clone());
    chest.position.y = 0.7;
    chest.userData = { partName: "Chest" };
    humanoidGroup.add(chest);
    
    const stomachGeo = new THREE.CylinderGeometry(0.48, 0.42, 0.7, 24);
    const stomach = new THREE.Mesh(stomachGeo, material.clone());
    stomach.position.y = 0.0;
    stomach.userData = { partName: "Stomach" };
    humanoidGroup.add(stomach);
    
    const limbGeo = new THREE.CylinderGeometry(0.16, 0.14, 1.3, 12);
    const leftArm = new THREE.Mesh(limbGeo, material.clone());
    leftArm.position.set(-0.7, 1.1, 0);
    leftArm.rotation.z = 0.3;
    leftArm.userData = { partName: "Limbs" };
    humanoidGroup.add(leftArm);
    
    const rightArm = new THREE.Mesh(limbGeo, material.clone());
    rightArm.position.set(0.7, 1.1, 0);
    rightArm.rotation.z = -0.3;
    rightArm.userData = { partName: "Limbs" };
    humanoidGroup.add(rightArm);
    
    scene.add(humanoidGroup);
    
    // Raycaster
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();
    
    renderer.domElement.addEventListener('click', (event) => {
        const rect = renderer.domElement.getBoundingClientRect();
        mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
        mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
        raycaster.setFromCamera(mouse, camera);
        const intersects = raycaster.intersectObjects(humanoidGroup.children);
        if (intersects.length > 0) {
            const hit = intersects[0].object;
            humanoidGroup.children.forEach(child => {
                child.material.color.setHex(0x4a6fa5);
            });
            hit.material.color.setHex(0x2a4b7c);
            handlePartSelection(hit.userData.partName);
        }
    });
    
    function animate() {
        animationFrameId = requestAnimationFrame(animate);
        if (humanoidGroup) humanoidGroup.rotation.y += 0.003;
        if (camera && renderer && scene) renderer.render(scene, camera);
    }
    animate();
}

function killThreeLoop() {
    if (animationFrameId) cancelAnimationFrame(animationFrameId);
    if (renderer) {
        renderer.dispose();
        const container = document.getElementById('three-canvas-target');
        if (container) container.innerHTML = '';
    }
    scene = null;
    camera = null;
    renderer = null;
    humanoidGroup = null;
}

// ==================== SYMPTOM SELECTION ====================
function handlePartSelection(partName) {
    activeSelectedZone = partName;
    document.getElementById('selected-zone-display').innerText = partName;
    
    const chipContainer = document.getElementById('symptom-chips');
    if (chipContainer) {
        chipContainer.innerHTML = '';
        const symptoms = translations[currentLanguage]?.symptomsList || translations.en.symptomsList;
        symptoms.forEach(symptom => {
            const chip = document.createElement('div');
            chip.className = 'chip';
            chip.innerText = symptom;
            chip.onclick = () => {
                document.querySelectorAll('#symptom-chips .chip').forEach(c => c.classList.remove('selected'));
                chip.classList.add('selected');
                selectedSymptomType = symptom;
            };
            chipContainer.appendChild(chip);
        });
    }
    document.getElementById('selection-panel')?.classList.remove('hidden');
}

function confirmSymptomMap() {
    if (!selectedSymptomType) {
        alert(translations[currentLanguage]?.symptomPrompt || "Please select a symptom");
        return;
    }
    transitionToState('state-ai-intake');
}

// ==================== AI CHAT INTEGRATION ====================
async function initializeAIChat() {
    const streamDiv = document.getElementById('aiChatStream') || document.getElementById('chat-stream');
    if (streamDiv) streamDiv.innerHTML = '';
    chatHistory = [];
    chatStep = 0;
    
    try {
        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                message: "START_INTAKE",
                language: currentLanguage,
                context: {
                    isInitial: true,
                    symptom: selectedSymptomType,
                    zone: activeSelectedZone
                }
            })
        });
        const data = await response.json();
        appendAiMessage('bot', data.message);
        updateChips(data.chips);
        chatHistory.push({ role: 'assistant', content: data.message });
    } catch (error) {
        console.error("Chat init error:", error);
        const fallbackMsg = translations[currentLanguage]?.symptomPrompt || "How can I help you today?";
        appendAiMessage('bot', fallbackMsg);
        updateChips(["Tell me more", "I'm struggling", "Physical pain"]);
    }
}

async function submitUserMessage() {
    const input = document.getElementById('user-message-input');
    const message = input?.value.trim();
    if (!message) return;
    
    addChatMessage('user', message);
    if (input) input.value = '';
    updateChips([]);
    chatHistory.push({ role: 'user', content: message });
    
    // Show typing indicator
    const typingMsg = addTypingIndicator();
    
    try {
        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                message: message,
                language: currentLanguage,
                history: chatHistory.slice(-6)
            })
        });
        const data = await response.json();
        removeTypingIndicator(typingMsg);
        addChatMessage('bot', data.message);
        if (data.chips && data.chips.length) updateChips(data.chips);
        chatHistory.push({ role: 'assistant', content: data.message });
        
        // Auto-transition after meaningful conversation (optional)
        if (chatHistory.length >= 6) {
            setTimeout(() => {
                if (confirm(translations[currentLanguage]?.lockBtn || "Ready to see your dashboard?")) {
                    transitionToState('state-dashboard');
                }
            }, 1000);
        }
    } catch (error) {
        console.error("Chat error:", error);
        removeTypingIndicator(typingMsg);
        addChatMessage('bot', "I'm having trouble connecting. Please try again.");
    }
}

function addChatMessage(sender, text) {
    const streamDiv = document.getElementById('chat-stream');
    if (!streamDiv) return;
    const msgDiv = document.createElement('div');
    msgDiv.className = `message ${sender}`;
    msgDiv.innerText = text;
    streamDiv.appendChild(msgDiv);
    streamDiv.scrollTop = streamDiv.scrollHeight;
}

function addTypingIndicator() {
    const streamDiv = document.getElementById('chat-stream');
    const typingDiv = document.createElement('div');
    typingDiv.className = 'message bot typing-indicator';
    typingDiv.innerText = '...';
    streamDiv.appendChild(typingDiv);
    streamDiv.scrollTop = streamDiv.scrollHeight;
    return typingDiv;
}

function removeTypingIndicator(indicator) {
    if (indicator && indicator.remove) indicator.remove();
}

function updateChips(chips) {
    const chipContainer = document.getElementById('ai-quick-chips') || document.getElementById('aiQuickChipsPanel');
    if (!chipContainer) return;
    chipContainer.innerHTML = '';
    chips.forEach(chip => {
        const chipBtn = document.createElement('button');
        chipBtn.className = 'chip';
        chipBtn.innerText = chip;
        chipBtn.onclick = () => {
            const aiInput = document.getElementById('aiUserTextInput') || document.getElementById('user-message-input');
            if (aiInput) aiInput.value = chip;
            if (document.getElementById('aiUserTextInput')) {
                submitAiUserMessage();
            } else {
                submitUserMessage();
            }
        };
        chipContainer.appendChild(chipBtn);
    });
}

function handleChatKeypress(event) {
    if (event.key === 'Enter') submitUserMessage();
}

// ==================== PAYMENT & RIDE ====================
async function processPayment(provider = 'card') {
    const statusBox = document.getElementById('paymentStatus');
    if (!statusBox) return;
    statusBox.textContent = `Processing ${provider.toUpperCase()} payment...`;
    statusBox.style.color = '#2c3e50';
    
    setTimeout(async () => {
        try {
            const response = await fetch('/api/pay', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ provider, amount: 350, userPhone: '+251XXXXXXXXX' })
            });
            const data = await response.json();
            if (data.status === 'SUCCESS') {
                statusBox.textContent = `${translations[currentLanguage]?.paymentSuccess || "Payment Successful!"} ${data.transactionId}`;
                statusBox.style.color = '#27ae60';
            }
        } catch (error) {
            statusBox.textContent = "Demo mode: Payment simulated successfully!";
            statusBox.style.color = '#27ae60';
        }
    }, 1500);
}

function goToFinance(doctor, amount) {
    const checkoutDetails = document.getElementById('checkoutDetails');
    const financePage = document.getElementById('financePage');
    const healthyResult = document.getElementById('quizHealthyResult');
    const directoryResult = document.getElementById('quizDirectoryResult');
    if (checkoutDetails) {
        checkoutDetails.textContent = `Booking ${doctor} for $${amount}. Enter card details below to complete payment.`;
    }
    if (financePage) financePage.style.display = 'block';
    if (healthyResult) healthyResult.style.display = 'none';
    if (directoryResult) directoryResult.style.display = 'none';
    window.scrollTo({ top: financePage?.offsetTop || 0, behavior: 'smooth' });
}

function toggleAiBot() {
    const drawer = document.getElementById('aiChatDrawer');
    if (!drawer) return;
    const currentlyOpen = drawer.style.display === 'block';
    drawer.style.display = currentlyOpen ? 'none' : 'block';
    if (!currentlyOpen) {
        initializeAIChat();
    }
}

function appendAiMessage(sender, text) {
    const streamDiv = document.getElementById('aiChatStream');
    if (!streamDiv) return;
    const messageEl = document.createElement('div');
    messageEl.className = `ai-bubble ${sender}`;
    messageEl.innerText = text;
    streamDiv.appendChild(messageEl);
    streamDiv.scrollTop = streamDiv.scrollHeight;
}

function addAiTypingIndicator() {
    const streamDiv = document.getElementById('aiChatStream');
    if (!streamDiv) return null;
    const typingEl = document.createElement('div');
    typingEl.className = 'ai-bubble bot typing';
    typingEl.innerText = '...';
    streamDiv.appendChild(typingEl);
    streamDiv.scrollTop = streamDiv.scrollHeight;
    return typingEl;
}

function clearAiTypingIndicator(indicator) {
    if (indicator && indicator.remove) indicator.remove();
}

function handleAiInputKey(event) {
    if (event.key === 'Enter') {
        event.preventDefault();
        submitAiUserMessage();
    }
}

async function submitAiUserMessage() {
    const input = document.getElementById('aiUserTextInput');
    const message = input?.value.trim();
    if (!message) return;
    appendAiMessage('user', message);
    if (input) input.value = '';
    updateChips([]);
    chatHistory.push({ role: 'user', content: message });
    const typingEl = addAiTypingIndicator();
    try {
        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message, language: currentLanguage, history: chatHistory.slice(-6) })
        });
        const data = await response.json();
        clearAiTypingIndicator(typingEl);
        appendAiMessage('bot', data.message || 'I am here to help you.');
        if (data.chips && data.chips.length) updateChips(data.chips);
        chatHistory.push({ role: 'assistant', content: data.message || '' });
    } catch (error) {
        console.error('AI chat submit error:', error);
        clearAiTypingIndicator(typingEl);
        appendAiMessage('bot', 'I am having trouble connecting. Please try again later.');
    }
}

const bioQuotes = [
    { text: 'Nothing in biology makes sense except in the light of evolution.', author: 'Theodosius Dobzhansky' },
    { text: 'The cell is the basic structural, functional, and biological unit of all known organisms.', author: 'Cell Theory Principle' },
    { text: 'Biology is the study of complicated things that have the appearance of having been designed for a purpose.', author: 'Richard Dawkins' },
    { text: 'In nature, nothing exists alone. Systemic feedback regulates all biological networks.', author: 'Rachel Carson' },
    { text: 'DNA is a ledger containing history, instructions, and design structures for organic pathways.', author: 'Genomics Research' }
];

const currentUser = { isLoggedIn: false, username: '', symptoms: [] };

function loadDailyQuote() {
    const quoteIndex = new Date().getDate() % bioQuotes.length;
    const quoteEl = document.getElementById('dailyQuote');
    const authorEl = document.getElementById('dailyAuthor');
    if (quoteEl && authorEl) {
        quoteEl.innerText = bioQuotes[quoteIndex].text;
        authorEl.innerText = `- ${bioQuotes[quoteIndex].author}`;
    }
}

function showPage(pageId) {
    const pages = document.querySelectorAll('.page');
    pages.forEach(page => page.classList.remove('active'));
    const target = document.getElementById(pageId);
    if (target) {
        target.classList.add('active');
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}

function toggleAuthForms(showSignUp) {
    const signInContainer = document.getElementById('signInContainer');
    const signUpContainer = document.getElementById('signUpContainer');
    if (signInContainer && signUpContainer) {
        signInContainer.style.display = showSignUp ? 'none' : 'block';
        signUpContainer.style.display = showSignUp ? 'block' : 'none';
    }
}

function handleAuthAction(event, type) {
    event.preventDefault();
    currentUser.isLoggedIn = true;
    currentUser.username = type === 'login' ? 'Alex' : 'New User';
    const authBtn = document.getElementById('navAuthBtn');
    if (authBtn) {
        authBtn.innerText = 'Logged In';
        authBtn.style.background = '#27ae60';
    }
    showPage('home');
}

function updateFrontPage() {
    const welcomeMessage = document.getElementById('welcome-heading');
    const dashboardContent = document.getElementById('dashboard-content');
    if (!welcomeMessage || !dashboardContent) return;
    if (currentUser.isLoggedIn) {
        welcomeMessage.innerText = `Welcome back, ${currentUser.username}!`;
        dashboardContent.innerHTML = `<p>Glad to see you again. Your wellness portal is ready.</p>`;
    } else {
        welcomeMessage.innerText = 'Welcome! Please log in.';
        dashboardContent.innerHTML = `<button onclick="showPage('auth-page')">Log In / Sign Up</button>`;
    }
}

function findTraditionalRemedy() {
    const symptom = document.getElementById('symptom')?.value;
    const resultBox = document.getElementById('traditionalResult');
    const title = document.getElementById('remedyTitle');
    const desc = document.getElementById('remedyDesc');
    const link = document.getElementById('remedyLink');
    if (!symptom || !resultBox || !title || !desc || !link) {
        alert('Please choose a symptom before generating remedies.');
        return;
    }
    resultBox.style.display = 'block';
    if (symptom === 'digestive') {
        title.innerText = 'Suggested Herb: Ginger & Peppermint Concentrates';
        desc.innerText = 'Historically documented to minimize gastrointestinal discomfort, ease flatulence, and settle active tracking issues.';
        link.href = 'https://www.youtube.com/results?search_query=how+to+make+ginger+peppermint+tea+medicinal';
    } else if (symptom === 'sleep') {
        title.innerText = 'Suggested Herb: Extracted Chamomile with Valerian Compounds';
        desc.innerText = 'Valerian works as an organic sedative compound to down-regulate nervous activity, accelerating sleep cycle onset.';
        link.href = 'https://www.youtube.com/results?search_query=herbal+remedies+for+insomnia+deep+sleep';
    } else if (symptom === 'fatigue') {
        title.innerText = 'Suggested Herb: Organic Ashwagandha Extract';
        desc.innerText = 'An adaptogenic agent engineered to regulate overactive adrenal spikes and lower baseline exhaustion rates.';
        link.href = 'https://www.youtube.com/results?search_query=adaptogen+herbs+for+energy+ashwagandha';
    }
}

function findNearestHospital() {
    const emergencyText = document.getElementById('emergencyText');
    if (!emergencyText) return;
    emergencyText.innerText = 'Analyzing your coordinates for the fastest route...';
    if (!navigator.geolocation) {
        emergencyText.innerText = '⚠️ Geolocation is not supported by this browser.';
        return;
    }
    navigator.geolocation.getCurrentPosition(
        function () {
            const googleMapsRouteUrl = 'https://www.google.com/maps/dir/?api=1&destination=hospital&travelmode=driving';
            emergencyText.innerHTML = `🚨 Route Found! <a href="${googleMapsRouteUrl}" target="_blank" style="color: #f1c40f; text-decoration: underline;">Open Google Maps Directions</a>`;
        },
        function () {
            emergencyText.innerText = '⚠️ Location access denied. Please dial local emergency numbers manually.';
        }
    );
}

function evaluateQuiz() {
    const form = document.getElementById('mindQuiz');
    if (!form) return;
    const answers = [1,2,3,4,5].map(i => Number(form.querySelector(`input[name="q${i}"]:checked`)?.value || -1));
    if (answers.some(value => value < 0)) {
        alert('Please answer all quiz questions before submitting.');
        return;
    }
    const score = answers.reduce((sum, value) => sum + value, 0);
    const healthyResult = document.getElementById('quizHealthyResult');
    const directoryResult = document.getElementById('quizDirectoryResult');
    if (healthyResult) healthyResult.style.display = score <= 3 ? 'block' : 'none';
    if (directoryResult) directoryResult.style.display = score > 3 ? 'block' : 'none';
}

function clearAllFormErrors(form) {
    if (!form) return;
    form.querySelectorAll('.error-message').forEach(el => {
        el.innerText = '';
        el.style.display = 'none';
    });
}

function setFieldError(input, message) {
    if (!input) return;
    const errorEl = input.parentElement?.querySelector('.error-message');
    if (errorEl) {
        errorEl.innerText = message;
        errorEl.style.display = message ? 'block' : 'none';
    }
}

function validateFaydaId(value) {
    return /^[A-Za-z0-9]{6,}$/.test(value);
}

function validatePassword(value) {
    return value.length >= 6;
}

function validateFullName(value) {
    return value.trim().length >= 3;
}

function handleSignIn(event) {
    event.preventDefault();
    const form = document.getElementById('signInForm');
    clearAllFormErrors(form);
    const faydaIdInput = document.getElementById('faydaId');
    const passwordInput = document.getElementById('signinPassword');
    const faydaId = faydaIdInput?.value.trim() || '';
    const password = passwordInput?.value || '';
    let valid = true;
    if (!validateFaydaId(faydaId)) {
        setFieldError(faydaIdInput, 'Fayda ID must contain at least 6 letters or numbers.');
        valid = false;
    }
    if (!validatePassword(password)) {
        setFieldError(passwordInput, 'Password must be at least 6 characters long.');
        valid = false;
    }
    if (!valid) return;
    const successMsg = document.getElementById('successMessage');
    if (successMsg) {
        successMsg.textContent = '✓ Login successful! Redirecting...';
        successMsg.style.display = 'block';
    }
    setTimeout(() => {
        window.location.href = 'main.html';
    }, 1500);
}

function handleSignUp(event) {
    event.preventDefault();
    const form = document.getElementById('signUpForm');
    clearAllFormErrors(form);
    const fullNameInput = document.getElementById('fullName');
    const faydaIdInput = document.getElementById('faydaIdSignup');
    const passwordInput = document.getElementById('signupPassword');
    const confirmPasswordInput = document.getElementById('confirmPassword');
    const fullName = fullNameInput?.value.trim() || '';
    const faydaId = faydaIdInput?.value.trim() || '';
    const password = passwordInput?.value || '';
    const confirmPassword = confirmPasswordInput?.value || '';
    let valid = true;
    if (!validateFullName(fullName)) {
        setFieldError(fullNameInput, 'Please enter your full name.');
        valid = false;
    }
    if (!validateFaydaId(faydaId)) {
        setFieldError(faydaIdInput, 'Fayda ID must contain at least 6 letters or numbers.');
        valid = false;
    }
    if (!validatePassword(password)) {
        setFieldError(passwordInput, 'Password must be at least 6 characters long.');
        valid = false;
    }
    if (password !== confirmPassword) {
        setFieldError(confirmPasswordInput, 'Passwords do not match.');
        valid = false;
    }
    if (!valid) return;
    alert(`Account created for ${fullName}! You can now sign in with your Fayda ID.`);
    toggleAuthForms(false);
}

document.addEventListener('DOMContentLoaded', () => {
    const liteToggle = document.getElementById('lite-mode-toggle');
    if (liteToggle) liteToggle.addEventListener('click', toggleLiteMode);
    const sosBtn = document.getElementById('sos-btn');
    if (sosBtn) sosBtn.addEventListener('click', triggerSOS);
    const flatBtns = document.querySelectorAll('.body-part-btn');
    flatBtns.forEach(btn => btn.addEventListener('click', () => handlePartSelection(btn.getAttribute('data-part'))));
    updateUILanguage();
    loadDailyQuote();
    updateFrontPage();
});

window.addEventListener('resize', () => {
    if (renderer && camera && !isLiteMode) {
        const container = document.getElementById('three-canvas-target');
        if (container) {
            const width = container.clientWidth;
            const height = container.clientHeight;
            camera.aspect = width / height;
            camera.updateProjectionMatrix();
            renderer.setSize(width, height);
        }
    }
});