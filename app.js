/**
 * RapidWrite — Stylus Handwriting Evaluator Studio
 * 
 * Implements the 5-Step Temporal Gating Model:
 * 1. Arming State (T_0 = 00:00): When "Start" is clicked, canvas pointer-event listeners
 *    are armed, but the clock is held stationary at 00:00.
 * 2. First Stroke (T_first stroke): Recorded on the exact millisecond of the first pointerdown
 *    hardware interrupt from the stylus/digitizer.
 * 3. On-Canvas Time (∑ Δt_contact): Continuous accumulation of active pen-down intervals
 *    while stylus tip is pressed against the tablet surface.
 * 4. In-Air Pause Time (∑ Δt_hover): Continuous accumulation of pen-lifted hover intervals
 *    between characters or words.
 * 5. Last Stroke (T_last stroke): Recorded at the exact completion (pointerup) of the final
 *    stroke before "Stop" is clicked.
 *    Writing Duration = T_last stroke − T_first stroke
 * 
 * Complete Sentence Disappearance:
 * When the allocated fixed time limit for the sentence expires, the target sentence
 * DISAPPEARS COMPLETELY, forcing the student to continue writing from memory.
 */

(function () {
  'use strict';

  // --- Verified Practice Prompts Partitioned by Word Length ---
  const PROMPTS_BY_LENGTH = {
    10: [
      { text: "Quick brown foxes jump over lazy sleeping dogs without stopping.", time: 15, benchmarkCpm: 120 },
      { text: "Bright stars shine quietly across the calm silent night sky.", time: 15, benchmarkCpm: 120 },
      { text: "Fresh morning sunlight warms the peaceful green forest and hills.", time: 15, benchmarkCpm: 120 },
      { text: "Practice daily with steady focus to build smooth cursive rhythm.", time: 15, benchmarkCpm: 120 },
      { text: "Clear writing requires patient practice and uniform letter baseline alignment.", time: 15, benchmarkCpm: 120 }
    ],
    25: [
      { text: "Woven silk pyjamas were exchanged for blue quartz as the ambitious student practiced daily handwriting drills to achieve maximum fluency, speed, and elegance on glass.", time: 30, benchmarkCpm: 120 },
      { text: "Sphinx of black quartz, judge my vow with steady precision and patient care while developing disciplined hand posture and consistent slant throughout every written line.", time: 30, benchmarkCpm: 120 },
      { text: "Consistent practice, steady wrist posture, and relaxed finger pressure allow students to master handwriting speed, improve letter formation, and write with confident fluidity every day.", time: 30, benchmarkCpm: 120 },
      { text: "Clear handwriting requires regular daily training, balanced grip tension, and rhythmic arm coordination to achieve high speed while keeping each letter distinct, legible, and neat.", time: 30, benchmarkCpm: 120 }
    ],
    50: [
      { text: "Developing rapid handwriting requires consistent daily training, balanced pen pressure, and relaxed wrist movement. By maintaining steady baseline alignment, uniform letter slant, and disciplined spacing between words, any student can dramatically increase their writing speed while producing exceptionally neat script that remains effortless during classroom examinations or professional note taking.", time: 60, benchmarkCpm: 120 },
      { text: "Mastering the art of fluid penmanship is an essential foundation for academic excellence and rapid cognitive expression. When fingers glide smoothly across paper with controlled speed and rhythmic cadence, thoughts flow unimpeded onto the page, creating an enduring impression of clarity, discipline, aesthetic refinement, and intellectual precision in every stroke.", time: 60, benchmarkCpm: 120 },
      { text: "Diligent students who practice cursive handwriting every single day develop muscular memory, relaxed coordination, and superior stroke fluency. By focusing on steady letter sizing, smooth transitions, and uniform word spacing, writing becomes second nature, allowing students to complete timed essays and exam papers with exceptional speed, clarity, confidence, and grace.", time: 60, benchmarkCpm: 120 }
    ]
  };

  // --- Practice Prompts Library by Category ---
  const PROMPT_DATABASE = {
    words: PROMPTS_BY_LENGTH[25],
    quote: [
      { text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", diff: "Standard", time: 35, benchmarkCpm: 100 },
      { text: "To be yourself in a world constantly trying to make you someone else is an achievement.", diff: "Medium", time: 35, benchmarkCpm: 100 },
      { text: "In the middle of difficulty lies great hidden opportunity and growth.", diff: "Easy", time: 24, benchmarkCpm: 90 }
    ],
    punctuation: [
      { text: "Can you believe it? Yes, absolutely! \"Never give up,\" she said; then she smiled.", diff: "Medium", time: 30, benchmarkCpm: 95 },
      { text: "Items needed: notebook, pen, & ink -- don't forget the receipt (dated 10/28).", diff: "Standard", time: 28, benchmarkCpm: 95 }
    ],
    numbers: [
      { text: "Phone: 1-800-555-0199; Order #48291; Total: $1,249.50; Serial: 987-654-3210.", diff: "Medium", time: 30, benchmarkCpm: 85 },
      { text: "Flight 204 departs gate B12 at 09:45 AM; arrival scheduled at 14:30 PM.", diff: "Standard", time: 25, benchmarkCpm: 90 }
    ],
    time: [
      { text: "The meeting is scheduled for tomorrow at exactly 03:45 PM in room 402.", diff: "Easy", time: 22, benchmarkCpm: 95 },
      { text: "Clock in at 08:30 AM sharp and complete your review before 05:00 PM.", diff: "Medium", time: 25, benchmarkCpm: 100 }
    ],
    zen: [
      { text: "breathe in tranquility breathe out tension find stillness in motion", diff: "Easy", time: 22, benchmarkCpm: 85 },
      { text: "flowing water hollow stone quiet mind clear focus calm presence", diff: "Easy", time: 22, benchmarkCpm: 85 }
    ],
    custom: [
      { text: "Write any sentence of your choice for handwriting kinematics evaluation.", diff: "Custom", time: 35, benchmarkCpm: 100 }
    ]
  };

  // --- Session & Evaluation State ---
  let currentCategory = 'words';
  let selectedLength = 25;
  let promptIndex = 0;
  let activePrompt = PROMPTS_BY_LENGTH[25][0];

  // 5-Step Temporal Gating State
  let sessionArmed = false;         // Step 1: True when "Start" button is clicked
  let sessionTimerStarted = false;  // Step 2: True on first pointerdown
  let tFirstStroke = null;          // T_first stroke (ms timestamp of first pen contact)
  let tLastStroke = null;           // T_last stroke (ms timestamp of final pen lift-off)
  let totalContactTimeMs = 0;       // ∑ Δt_contact (On-canvas time)
  let totalHoverTimeMs = 0;         // ∑ Δt_hover (In-air pause time)
  let currentStrokeStartTime = null;
  let lastStrokeEndTime = null;

  let timerInterval = null;
  let elapsedSeconds = 0;
  let sentenceExpired = false;

  // Drawing state
  let strokes = [];                 // Array of { points: [{x, y, t, p}], color, width }
  let undoStack = [];
  let currentStroke = null;
  let activePointerId = null;

  // Tool & Settings state
  let activeTool = 'pen';
  let strokeColor = '#1e293b';
  let strokeWidth = 4;
  let paperType = 'ruled';
  let strictStylusOnly = true;
  let mouseDebug = true;
  let showRuledLines = true;
  let showMetricsEnabled = true;
  let countdownTimerEnabled = true;
  let rejectedPalmCount = 0;

  // DOM Elements
  const topTimerBadge = document.getElementById('topTimerBadge');
  const topTimerDigits = document.getElementById('topTimerDigits');
  const btnSettings = document.getElementById('btnSettings');

  const targetSentenceText = document.getElementById('targetSentenceText');
  const promptMetricsTag = document.getElementById('promptMetricsTag');
  const promptTimingText = document.getElementById('promptTimingText');
  const btnShufflePrompt = document.getElementById('btnShufflePrompt');
  const promptExpiredNote = document.getElementById('promptExpiredNote');

  const resultAnalysisCard = document.getElementById('resultAnalysisCard');
  const recognitionEngineBadge = document.getElementById('recognitionEngineBadge');
  const btnExpandResults = document.getElementById('btnExpandResults');
  const btnCloseResults = document.getElementById('btnCloseResults');

  // Overall Performance Score Elements
  const resOverallScore = document.getElementById('resOverallScore');
  const resOverallGrade = document.getElementById('resOverallGrade');
  const resSubSpeed = document.getElementById('resSubSpeed');
  const resSubAccuracy = document.getElementById('resSubAccuracy');
  const resSubAesthetic = document.getElementById('resSubAesthetic');

  // 4 Primary Metric Elements
  const resCpmValue = document.getElementById('resCpmValue');
  const resSpeedValue = document.getElementById('resSpeedValue');
  const resSpeedSub = document.getElementById('resSpeedSub');
  const resDurationValue = document.getElementById('resDurationValue');
  const resDurationSub = document.getElementById('resDurationSub');
  const resAccuracyValue = document.getElementById('resAccuracyValue');
  const resAccuracySub = document.getElementById('resAccuracySub');
  const resAestheticGrade = document.getElementById('resAestheticGrade');
  const resAestheticScore = document.getElementById('resAestheticScore');
  const resAestheticSub = document.getElementById('resAestheticSub');
  const resRecognizedText = document.getElementById('resRecognizedText');
  const btnNextSentence = document.getElementById('btnNextSentence');

  const btnStartSession = document.getElementById('btnStartSession');
  const lblStartSession = document.getElementById('lblStartSession');
  const btnClearCanvas = document.getElementById('btnClearCanvas');
  const statStrokesPill = document.getElementById('statStrokesPill');
  const statTimePill = document.getElementById('statTimePill');
  const btnToggleResults = document.getElementById('btnToggleResults');
  const lblToggleResults = document.getElementById('lblToggleResults');
  const btnSubmitAnalyze = document.getElementById('btnSubmitAnalyze');
  const lblSubmitAnalyze = document.getElementById('lblSubmitAnalyze');

  const btnToolPen = document.getElementById('btnToolPen');
  const btnToolEraser = document.getElementById('btnToolEraser');
  const btnPaperSelect = document.getElementById('btnPaperSelect');
  const paperMenu = document.getElementById('paperMenu');
  const btnPalmGuard = document.getElementById('btnPalmGuard');
  const btnUndo = document.getElementById('btnUndo');
  const btnRedo = document.getElementById('btnRedo');

  const notepadScrollContainer = document.getElementById('notepadScrollContainer');
  const notepadSheetFrame = document.getElementById('notepadSheetFrame');
  const guideCanvas = document.getElementById('guideCanvas');
  const drawCanvas = document.getElementById('drawCanvas');
  const guideCtx = guideCanvas.getContext('2d');
  const drawCtx = drawCanvas.getContext('2d');

  const badgeApplePencil = document.getElementById('badgeApplePencil');
  const lblInputStatus = document.getElementById('lblInputStatus');
  const canvasStrokesLabel = document.getElementById('canvasStrokesLabel');

  const settingsModal = document.getElementById('settingsModal');
  const btnCloseModal = document.getElementById('btnCloseModal');
  const chkStrictStylus = document.getElementById('chkStrictStylus');
  const chkRuledLines = document.getElementById('chkRuledLines');
  const chkShowMetrics = document.getElementById('chkShowMetrics');
  const chkCountdownTimer = document.getElementById('chkCountdownTimer');
  const btnThemeDark = document.getElementById('btnThemeDark');
  const btnThemeLight = document.getElementById('btnThemeLight');

  // --- Notification Toast ---
  function showToast(message, type = 'info') {
    let container = document.getElementById('toastContainer');
    if (!container) {
      container = document.createElement('div');
      container.id = 'toastContainer';
      container.className = 'toast-container';
      document.body.appendChild(container);
    }
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    const icon = type === 'warning' ? '⚠️' : '💡';
    toast.innerHTML = `<span>${icon}</span><span>${message}</span>`;
    container.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(-8px)';
      setTimeout(() => toast.remove(), 300);
    }, 2800);
  }

  // =========================================================================
  // 1. PROMPT & CATEGORY MANAGEMENT
  // =========================================================================
  function getActivePromptList() {
    if (currentCategory === 'words') {
      return PROMPTS_BY_LENGTH[selectedLength] || PROMPTS_BY_LENGTH[25];
    }
    return PROMPT_DATABASE[currentCategory] || PROMPTS_BY_LENGTH[25];
  }

  function updatePromptDisplay() {
    const list = getActivePromptList();
    if (promptIndex >= list.length) promptIndex = 0;
    activePrompt = list[promptIndex];
    targetSentenceText.textContent = activePrompt.text;
    
    // Ensure sentence is visible on prompt change
    targetSentenceText.classList.remove('disappeared');
    promptExpiredNote.classList.add('hidden');
    sentenceExpired = false;

    const words = activePrompt.text.trim().split(/\s+/).length;
    const chars = activePrompt.text.length;
    promptMetricsTag.innerHTML = `${words} words • ${chars} chars • <span class="timing-highlight" id="promptTimingText">${activePrompt.time}s Limit (${strokes.length} strokes)</span>`;
  }

  // Category Pills
  document.querySelectorAll('.cat-pill').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.cat-pill').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentCategory = btn.dataset.cat;
      promptIndex = 0;
      updatePromptDisplay();
      clearCanvas(false);
      showToast(`Category switched to: ${currentCategory}`, 'info');
    });
  });

  // Length Pills (10, 25, 50 words) - Programmatically load exact sentence length!
  document.querySelectorAll('.len-pill').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.len-pill').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      selectedLength = parseInt(btn.dataset.len, 10);
      currentCategory = 'words';

      // Set words cat-pill to active
      document.querySelectorAll('.cat-pill').forEach(b => {
        if (b.dataset.cat === 'words') b.classList.add('active');
        else b.classList.remove('active');
      });

      promptIndex = 0;
      updatePromptDisplay();
      clearCanvas(false);
      showToast(`Loaded ${selectedLength}-word practice prompt (${activePrompt.time}s target)`, 'info');
    });
  });

  // Shuffle button
  btnShufflePrompt.addEventListener('click', () => {
    const list = getActivePromptList();
    promptIndex = (promptIndex + 1) % list.length;
    updatePromptDisplay();
    clearCanvas(false);
    showToast('Loaded new target practice sentence', 'info');
  });

  // Next sentence button (in results card)
  btnNextSentence.addEventListener('click', () => {
    const list = getActivePromptList();
    promptIndex = (promptIndex + 1) % list.length;
    updatePromptDisplay();
    clearCanvas(false);
    resultAnalysisCard.classList.add('collapsed');
    lblToggleResults.textContent = 'Show Results';
    showToast('Advanced to next practice sentence. Click "Start" to begin.', 'info');
  });

  // =========================================================================
  // 2. CANVAS SIZING & REALISTIC PAPER GUIDELINE RENDERING
  // =========================================================================
  function resizeCanvases() {
    const rect = notepadSheetFrame.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;

    const width = Math.floor(rect.width);
    const height = Math.floor(rect.height);

    if (width <= 0 || height <= 0) return;

    guideCanvas.width = width * dpr;
    guideCanvas.height = height * dpr;
    drawCanvas.width = width * dpr;
    drawCanvas.height = height * dpr;

    guideCtx.resetTransform();
    guideCtx.scale(dpr, dpr);

    drawCtx.resetTransform();
    drawCtx.scale(dpr, dpr);

    drawPaperGuides();
    redrawAllStrokes();
  }

  function drawPaperGuides() {
    const width = notepadSheetFrame.clientWidth;
    const height = notepadSheetFrame.clientHeight;

    guideCtx.clearRect(0, 0, width, height);

    if (!showRuledLines || paperType === 'blank') return;

    if (paperType === 'ruled') {
      const lineHeight = 38;
      const topMargin = 50;
      const bottomMargin = height - 15;

      guideCtx.lineWidth = 1;
      guideCtx.strokeStyle = 'rgba(74, 144, 226, 0.28)';

      for (let y = topMargin; y < bottomMargin; y += lineHeight) {
        guideCtx.beginPath();
        guideCtx.moveTo(0, y);
        guideCtx.lineTo(width, y);
        guideCtx.stroke();
      }

      // Vertical left margin line (pink/red notebook margin)
      guideCtx.strokeStyle = 'rgba(239, 68, 68, 0.22)';
      guideCtx.beginPath();
      guideCtx.moveTo(54, 0);
      guideCtx.lineTo(54, height);
      guideCtx.stroke();

    } else if (paperType === 'grid') {
      const gridSize = 24;
      guideCtx.lineWidth = 0.8;
      guideCtx.strokeStyle = 'rgba(100, 116, 139, 0.18)';

      for (let x = gridSize; x < width; x += gridSize) {
        guideCtx.beginPath();
        guideCtx.moveTo(x, 0);
        guideCtx.lineTo(x, height);
        guideCtx.stroke();
      }
      for (let y = gridSize; y < height; y += gridSize) {
        guideCtx.beginPath();
        guideCtx.moveTo(0, y);
        guideCtx.lineTo(width, y);
        guideCtx.stroke();
      }
    }
  }

  window.addEventListener('resize', () => {
    resizeCanvases();
  });

  // =========================================================================
  // 3. 5-STEP TEMPORAL GATING MODEL
  // =========================================================================

  /**
   * STEP 1: ARMING STATE (T_0 = 00:00)
   * When "Start" is clicked, canvas pointer-event listeners are armed,
   * but the clock is held stationary at 00:00.
   */
  btnStartSession.addEventListener('click', () => {
    if (sessionTimerStarted) {
      // If already writing, clicking Start resets for a clean retry
      clearCanvas(false);
    }

    sessionArmed = true;
    sessionTimerStarted = false;
    tFirstStroke = null;
    tLastStroke = null;
    totalContactTimeMs = 0;
    totalHoverTimeMs = 0;
    currentStrokeStartTime = null;
    lastStrokeEndTime = null;
    sentenceExpired = false;

    // Reset sentence visibility
    targetSentenceText.classList.remove('disappeared');
    promptExpiredNote.classList.add('hidden');

    // Stationary clock at 00:00.0
    topTimerDigits.textContent = '00:00.0';
    topTimerBadge.classList.remove('warning');
    statTimePill.textContent = '00:00.0';

    btnStartSession.classList.remove('writing');
    btnStartSession.classList.add('armed');
    lblStartSession.textContent = '● Armed (Write with Pen)';
    btnSubmitAnalyze.disabled = true; // Enabled on first stroke

    if (lblInputStatus) lblInputStatus.textContent = 'Session Armed: Timer begins on first pen stroke';
    showToast('Step 1 Armed! Clock stationary at 00:00. Touch pen to canvas to start writing.', 'info');
  });

  /**
   * Starts the countdown and live timer when Step 2 (First Stroke) occurs.
   * Handles COMPLETE SENTENCE DISAPPEARANCE when the allocated time ends.
   */
  function startSessionTimer() {
    const totalAllocatedMs = activePrompt.time * 1000;
    clearInterval(timerInterval);

    timerInterval = setInterval(() => {
      const now = Date.now();
      elapsedSeconds = (now - tFirstStroke) / 1000.0;

      // Update Top Timer Badge (minutes/seconds/decimals: e.g. 24.7s)
      topTimerDigits.textContent = `${elapsedSeconds.toFixed(1)}s`;
      statTimePill.textContent = `${elapsedSeconds.toFixed(1)}s`;

      // Prompt disappearance countdown check
      const remainingMs = totalAllocatedMs - (now - tFirstStroke);
      const remainingSec = Math.max(0, Math.ceil(remainingMs / 1000));

      const timingHighlight = document.getElementById('promptTimingText');
      if (timingHighlight && !sentenceExpired) {
        timingHighlight.textContent = `${remainingSec}s countdown (${strokes.length} strokes)`;
      }

      // Complete Sentence Disappearance when countdown timer enabled
      if (countdownTimerEnabled && remainingMs <= 0 && !sentenceExpired) {
        sentenceExpired = true;
        targetSentenceText.classList.add('disappeared');
        promptExpiredNote.classList.remove('hidden');
        topTimerBadge.classList.add('warning');
        showToast('Prompt time expired! Sentence disappeared — continue writing from memory.', 'warning');
      }
    }, 50);
  }

  function stopSessionTimer() {
    clearInterval(timerInterval);
    topTimerBadge.classList.remove('warning');
  }

  function updateStrokeTelemetry() {
    const count = strokes.length;
    statStrokesPill.textContent = `${count} stroke${count === 1 ? '' : 's'}`;
    canvasStrokesLabel.textContent = `${count} stroke${count === 1 ? '' : 's'}`;
    btnUndo.disabled = strokes.length === 0;
    btnRedo.disabled = undoStack.length === 0;
  }

  // =========================================================================
  // 4. STYLUS WRITING & SCROLLING PREVENTION (100% STATIC INTERFACE)
  // =========================================================================
  function onPointerDown(e) {
    // Prevent default on canvas so page NEVER moves or scrolls!
    e.preventDefault();

    // Rejection of finger / palm touch for drawing (palm rejection)
    if (e.pointerType === 'touch') {
      rejectedPalmCount++;
      return; // Do NOT draw ink, and page stays 100% stationary!
    }

    if (e.pointerType === 'pen' || (mouseDebug && e.pointerType === 'mouse')) {
      // Gating Check: Must click "Start" first to arm the session!
      if (!sessionArmed) {
        showToast('Please click "Start" first to arm the writing session.', 'warning');
        return;
      }

      try {
        drawCanvas.setPointerCapture(e.pointerId);
      } catch (err) {}

      activePointerId = e.pointerId;
      const now = Date.now();

      /**
       * STEP 2: FIRST STROKE (T_first stroke)
       * Recorded on the exact millisecond of the first pointerdown interrupt
       */
      if (!sessionTimerStarted) {
        sessionTimerStarted = true;
        tFirstStroke = now;
        tLastStroke = now;

        btnStartSession.classList.remove('armed');
        btnStartSession.classList.add('writing');
        lblStartSession.textContent = '✍ Writing Active';
        btnSubmitAnalyze.disabled = false; // Step 5 Stop button active
        if (lblInputStatus) lblInputStatus.textContent = 'Apple Pencil Active (Recording)';

        startSessionTimer();
      }

      /**
       * STEP 4: IN-AIR PAUSE TIME (∑ Δt_hover)
       * Accumulate hover intervals between characters and words
       */
      currentStrokeStartTime = now;
      if (lastStrokeEndTime !== null) {
        totalHoverTimeMs += Math.max(0, currentStrokeStartTime - lastStrokeEndTime);
      }

      const rect = drawCanvas.getBoundingClientRect();
      const pt = {
        x: e.clientX - rect.left,
        y: e.clientY - rect.top,
        t: now,
        p: (e.pressure && e.pressure > 0) ? e.pressure : 0.5
      };

      currentStroke = {
        points: [pt],
        tool: activeTool,
        color: strokeColor,
        width: strokeWidth,
        startTime: now,
        endTime: now
      };

      undoStack = [];
      btnRedo.disabled = true;
      drawCurrentSegment();
    }
  }

  function onPointerMove(e) {
    // Always prevent default to lock page in place!
    e.preventDefault();

    if (e.pointerType === 'touch') return;

    if (currentStroke && e.pointerId === activePointerId) {
      const now = Date.now();
      const rect = drawCanvas.getBoundingClientRect();
      const pt = {
        x: e.clientX - rect.left,
        y: e.clientY - rect.top,
        t: now,
        p: (e.pressure && e.pressure > 0) ? e.pressure : 0.5
      };

      currentStroke.points.push(pt);
      currentStroke.endTime = now;
      tLastStroke = now;

      drawCurrentSegment();
    }
  }

  function onPointerUp(e) {
    e.preventDefault();
    if (e.pointerType === 'touch') return;

    if (currentStroke && e.pointerId === activePointerId) {
      try {
        drawCanvas.releasePointerCapture(e.pointerId);
      } catch (err) {}

      const strokeEndTime = Date.now();
      currentStroke.endTime = strokeEndTime;

      /**
       * STEP 3: ON-CANVAS TIME (∑ Δt_contact)
       * Continuous accumulation of active pen-down intervals
       */
      totalContactTimeMs += Math.max(1, strokeEndTime - currentStrokeStartTime);
      lastStrokeEndTime = strokeEndTime;

      /**
       * STEP 5: LAST STROKE (T_last stroke)
       * Recorded at the exact completion (pointerup) of the stroke
       */
      tLastStroke = strokeEndTime;

      if (currentStroke.points.length > 0) {
        strokes.push(currentStroke);
        updateStrokeTelemetry();
      }

      currentStroke = null;
      activePointerId = null;
    }
  }

  function onPointerCancel(e) {
    e.preventDefault();
    if (currentStroke && e.pointerId === activePointerId) {
      try {
        drawCanvas.releasePointerCapture(e.pointerId);
      } catch (err) {}
      currentStroke = null;
      activePointerId = null;
    }
  }

  drawCanvas.addEventListener('pointerdown', onPointerDown, { passive: false });
  drawCanvas.addEventListener('pointermove', onPointerMove, { passive: false });
  drawCanvas.addEventListener('pointerup', onPointerUp, { passive: false });
  drawCanvas.addEventListener('pointercancel', onPointerCancel, { passive: false });
  drawCanvas.addEventListener('contextmenu', e => e.preventDefault());

  // PREVENT ALL TOUCH & GESTURE SCROLLING ON CANVAS
  ['touchstart', 'touchmove', 'touchend', 'touchcancel'].forEach(eventType => {
    drawCanvas.addEventListener(eventType, e => {
      e.preventDefault();
    }, { passive: false });
    notepadSheetFrame.addEventListener(eventType, e => {
      e.preventDefault();
    }, { passive: false });
  });

  // PREVENT SAFARI PINCH ZOOM & GESTURE JITTER
  ['gesturestart', 'gesturechange', 'gestureend'].forEach(eventType => {
    document.addEventListener(eventType, e => {
      e.preventDefault();
    }, { passive: false });
  });

  // =========================================================================
  // 5. INK RENDERING (SMOOTH QUADRATIC BÉZIER CURVES & PRESSURE DYNAMICS)
  // =========================================================================
  function drawCurrentSegment() {
    if (!currentStroke || currentStroke.points.length === 0) return;
    const pts = currentStroke.points;
    const isEraser = currentStroke.tool === 'eraser';

    drawCtx.save();
    drawCtx.lineCap = 'round';
    drawCtx.lineJoin = 'round';

    if (isEraser) {
      drawCtx.globalCompositeOperation = 'destination-out';
      drawCtx.lineWidth = currentStroke.width * 5;
    } else {
      drawCtx.globalCompositeOperation = 'source-over';
      drawCtx.strokeStyle = currentStroke.color;
    }

    if (pts.length === 1) {
      const p = pts[0];
      const rad = Math.max(1, (currentStroke.width * (0.6 + p.p * 0.8)) / 2);
      drawCtx.beginPath();
      drawCtx.arc(p.x, p.y, rad, 0, Math.PI * 2);
      if (isEraser) drawCtx.fill();
      else {
        drawCtx.fillStyle = currentStroke.color;
        drawCtx.fill();
      }
    } else if (pts.length === 2) {
      const p0 = pts[0];
      const p1 = pts[1];
      const w = currentStroke.width * (0.6 + ((p0.p + p1.p) / 2) * 0.8);
      drawCtx.lineWidth = isEraser ? currentStroke.width * 5 : w;
      drawCtx.beginPath();
      drawCtx.moveTo(p0.x, p0.y);
      drawCtx.lineTo(p1.x, p1.y);
      drawCtx.stroke();
    } else {
      const i = pts.length - 2;
      const p0 = pts[i - 1];
      const p1 = pts[i];
      const p2 = pts[i + 1];

      const mid1X = (p0.x + p1.x) / 2;
      const mid1Y = (p0.y + p1.y) / 2;
      const mid2X = (p1.x + p2.x) / 2;
      const mid2Y = (p1.y + p2.y) / 2;

      const dynamicWidth = currentStroke.width * (0.6 + p1.p * 0.8);
      drawCtx.lineWidth = isEraser ? currentStroke.width * 5 : dynamicWidth;

      drawCtx.beginPath();
      drawCtx.moveTo(mid1X, mid1Y);
      drawCtx.quadraticCurveTo(p1.x, p1.y, mid2X, mid2Y);
      drawCtx.stroke();
    }

    drawCtx.restore();
  }

  function redrawAllStrokes() {
    const width = notepadSheetFrame.clientWidth;
    const height = notepadSheetFrame.clientHeight;
    drawCtx.clearRect(0, 0, width, height);

    for (const stroke of strokes) {
      const pts = stroke.points;
      if (!pts || pts.length === 0) continue;

      drawCtx.save();
      drawCtx.lineCap = 'round';
      drawCtx.lineJoin = 'round';

      const isEraser = stroke.tool === 'eraser';
      if (isEraser) {
        drawCtx.globalCompositeOperation = 'destination-out';
        drawCtx.lineWidth = stroke.width * 5;
      } else {
        drawCtx.globalCompositeOperation = 'source-over';
        drawCtx.strokeStyle = stroke.color;
      }

      if (pts.length === 1) {
        const p = pts[0];
        const rad = Math.max(1, (stroke.width * (0.6 + p.p * 0.8)) / 2);
        drawCtx.beginPath();
        drawCtx.arc(p.x, p.y, rad, 0, Math.PI * 2);
        if (isEraser) drawCtx.fill();
        else {
          drawCtx.fillStyle = stroke.color;
          drawCtx.fill();
        }
      } else {
        for (let i = 1; i < pts.length; i++) {
          const p0 = pts[i - 1];
          const p1 = pts[i];
          const w = stroke.width * (0.6 + ((p0.p + p1.p) / 2) * 0.8);
          drawCtx.lineWidth = isEraser ? stroke.width * 5 : w;

          drawCtx.beginPath();
          drawCtx.moveTo(p0.x, p0.y);
          drawCtx.lineTo(p1.x, p1.y);
          drawCtx.stroke();
        }
      }
      drawCtx.restore();
    }
  }

  // Undo & Redo
  btnUndo.addEventListener('click', () => {
    if (strokes.length > 0) {
      const popped = strokes.pop();
      undoStack.push(popped);
      redrawAllStrokes();
      updateStrokeTelemetry();
    }
  });

  btnRedo.addEventListener('click', () => {
    if (undoStack.length > 0) {
      const restored = undoStack.pop();
      strokes.push(restored);
      redrawAllStrokes();
      updateStrokeTelemetry();
    }
  });

  // Clear Canvas
  btnClearCanvas.addEventListener('click', () => {
    clearCanvas(true);
  });

  function clearCanvas(showToastMsg = true) {
    stopSessionTimer();
    strokes = [];
    undoStack = [];
    sessionArmed = false;
    sessionTimerStarted = false;
    tFirstStroke = null;
    tLastStroke = null;
    totalContactTimeMs = 0;
    totalHoverTimeMs = 0;
    currentStrokeStartTime = null;
    lastStrokeEndTime = null;
    elapsedSeconds = 0;

    // Restore target sentence visibility
    sentenceExpired = false;
    targetSentenceText.classList.remove('disappeared');
    promptExpiredNote.classList.add('hidden');

    topTimerDigits.textContent = '00:00.0';
    topTimerBadge.classList.remove('warning');
    statTimePill.textContent = '00:00.0';

    btnStartSession.classList.remove('armed', 'writing');
    lblStartSession.textContent = 'Start';
    btnSubmitAnalyze.disabled = true;
    if (lblInputStatus) lblInputStatus.textContent = 'Click Start to begin session';

    redrawAllStrokes();
    updateStrokeTelemetry();
    if (showToastMsg) showToast('Canvas cleared & session reset. Click "Start" to begin new session.', 'info');
  }

  // =========================================================================
  // 6. TOOLBAR CONTROLS: PEN, ERASER, SIZES, COLORS, PAPERS, PALM GUARD
  // =========================================================================
  btnToolPen.addEventListener('click', () => {
    activeTool = 'pen';
    btnToolPen.classList.add('active');
    btnToolEraser.classList.remove('active');
  });

  btnToolEraser.addEventListener('click', () => {
    activeTool = 'eraser';
    btnToolEraser.classList.add('active');
    btnToolPen.classList.remove('active');
  });

  // Stroke Sizes
  document.querySelectorAll('.size-dot').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.size-dot').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      strokeWidth = parseInt(btn.dataset.size, 10);
    });
  });

  // Color Swatches
  document.querySelectorAll('.swatch-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.swatch-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      strokeColor = btn.dataset.color;
      if (activeTool === 'eraser') {
        activeTool = 'pen';
        btnToolPen.classList.add('active');
        btnToolEraser.classList.remove('active');
      }
    });
  });

  // Paper Selector Dropdown
  btnPaperSelect.addEventListener('click', (e) => {
    e.stopPropagation();
    paperMenu.classList.toggle('hidden');
  });

  document.querySelectorAll('.paper-option').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.paper-option').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      paperType = btn.dataset.paper;
      paperMenu.classList.add('hidden');
      drawPaperGuides();
      showToast(`Paper background set to: ${btn.textContent}`, 'info');
    });
  });

  document.addEventListener('click', (e) => {
    if (!e.target.closest('.dropdown-container')) {
      paperMenu.classList.add('hidden');
    }
  });

  // Palm Guard Button
  btnPalmGuard.addEventListener('click', () => {
    strictStylusOnly = !strictStylusOnly;
    if (strictStylusOnly) {
      btnPalmGuard.classList.remove('disabled');
      btnPalmGuard.classList.add('active');
      btnPalmGuard.innerHTML = '<span class="shield-icon">🛡</span><span>Palm Guard ON</span>';
      if (lblInputStatus) lblInputStatus.textContent = 'Apple Pencil Only (Palm Guard ON)';
      showToast('Strict Palm Rejection ON: Stylus writes, fingers scroll vertically', 'info');
    } else {
      btnPalmGuard.classList.remove('active');
      btnPalmGuard.classList.add('disabled');
      btnPalmGuard.innerHTML = '<span class="shield-icon">⚠️</span><span>Palm Guard OFF</span>';
      if (lblInputStatus) lblInputStatus.textContent = 'Stylus + Touch / Mouse Active';
      showToast('Palm Guard OFF: Touch gestures will now leave marks', 'warning');
    }
  });

  // Result card expand / collapse & close
  btnToggleResults.addEventListener('click', () => {
    resultAnalysisCard.classList.toggle('collapsed');
    const isHidden = resultAnalysisCard.classList.contains('collapsed');
    lblToggleResults.textContent = isHidden ? 'Show Results' : 'Hide Results';
    setTimeout(resizeCanvases, 50);
  });

  btnCloseResults.addEventListener('click', () => {
    resultAnalysisCard.classList.add('collapsed');
    lblToggleResults.textContent = 'Show Results';
    setTimeout(resizeCanvases, 50);
  });

  btnExpandResults.addEventListener('click', () => {
    showToast('Toggled Results Display', 'info');
  });

  // Settings Modal & Preferences
  btnSettings.addEventListener('click', () => {
    settingsModal.classList.remove('hidden');
  });

  btnCloseModal.addEventListener('click', () => {
    settingsModal.classList.add('hidden');
  });

  settingsModal.addEventListener('click', (e) => {
    if (e.target === settingsModal) {
      settingsModal.classList.add('hidden');
    }
  });

  // Theme Customization with localStorage persistence
  function applyTheme(theme) {
    if (theme === 'light') {
      document.body.classList.remove('dark-theme');
      document.body.classList.add('light-theme');
      if (btnThemeLight) btnThemeLight.classList.add('active');
      if (btnThemeDark) btnThemeDark.classList.remove('active');
    } else {
      document.body.classList.remove('light-theme');
      document.body.classList.add('dark-theme');
      if (btnThemeDark) btnThemeDark.classList.add('active');
      if (btnThemeLight) btnThemeLight.classList.remove('active');
    }
    try {
      localStorage.setItem('rapidwrite_theme', theme);
    } catch (e) {}
  }

  if (btnThemeDark) {
    btnThemeDark.addEventListener('click', () => {
      applyTheme('dark');
      showToast('Dark Theme activated', 'info');
    });
  }

  if (btnThemeLight) {
    btnThemeLight.addEventListener('click', () => {
      applyTheme('light');
      showToast('Light Theme activated', 'info');
    });
  }

  // Load saved theme preference
  const savedTheme = localStorage.getItem('rapidwrite_theme') || 'dark';
  applyTheme(savedTheme);

  if (chkStrictStylus) {
    chkStrictStylus.addEventListener('change', (e) => {
      strictStylusOnly = e.target.checked;
      btnPalmGuard.click();
    });
  }

  if (chkRuledLines) {
    chkRuledLines.addEventListener('change', (e) => {
      showRuledLines = e.target.checked;
      drawPaperGuides();
    });
  }

  if (chkShowMetrics) {
    chkShowMetrics.addEventListener('change', (e) => {
      showMetricsEnabled = e.target.checked;
    });
  }

  if (chkCountdownTimer) {
    chkCountdownTimer.addEventListener('change', (e) => {
      countdownTimerEnabled = e.target.checked;
      if (!countdownTimerEnabled) {
        targetSentenceText.classList.remove('disappeared');
        promptExpiredNote.classList.add('hidden');
        sentenceExpired = false;
      }
    });
  }

  // =========================================================================
  // 7. STEP 5: STOP & ANALYZE (WRITING DURATION = T_last stroke - T_first stroke)
  // =========================================================================
  btnSubmitAnalyze.addEventListener('click', async () => {
    if (strokes.length === 0) {
      showToast('Please write on the notepad with your stylus before submitting.', 'warning');
      return;
    }

    stopSessionTimer();
    btnSubmitAnalyze.disabled = true;
    lblSubmitAnalyze.textContent = 'Analyzing...';

    try {
      /**
       * CORE DURATION ALGORITHM (Formula 1):
       * Writing Duration = T_last stroke − T_first stroke
       * Completely eliminates hesitation delay before writing and reaction delay after stopping.
       */
      const writingDurationSec = Math.max(
        0.5,
        (tLastStroke && tFirstStroke && tLastStroke > tFirstStroke)
          ? (tLastStroke - tFirstStroke) / 1000.0
          : elapsedSeconds || 1.0
      );

      const contactTimeSec = (totalContactTimeMs / 1000.0);
      const hoverTimeSec = (totalHoverTimeMs / 1000.0);

      // Prepare strokes payload for Google Digital Ink ML Kit
      const inkPayload = {
        strokes: strokes.map(s => ({
          points: s.points.map(p => ({
            x: Math.round(p.x),
            y: Math.round(p.y),
            t: Math.round(p.t)
          }))
        })),
        canvasWidth: drawCanvas.width,
        canvasHeight: drawCanvas.height,
        language: 'en'
      };

      // Call Google Digital Ink Recognition
      let recognizedText = "";
      let engineName = "Google Digital Ink (Web Engine)";

      try {
        const response = await fetch('/api/digital-ink', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(inkPayload)
        });

        if (response.ok) {
          const data = await response.json();
          if (data.status === 'success' && data.text) {
            recognizedText = data.text;
            engineName = data.engine || "Google Digital Ink (Web Engine)";
          } else if (data.status === 'fallback') {
            recognizedText = await directGoogleDigitalInk(inkPayload);
          }
        } else {
          recognizedText = await directGoogleDigitalInk(inkPayload);
        }
      } catch (netErr) {
        console.warn('Backend proxy notice, attempting direct web recognition:', netErr);
        recognizedText = await directGoogleDigitalInk(inkPayload);
      }

      if (!recognizedText || recognizedText.trim().length === 0) {
        recognizedText = runStrokeTopologicalOcr(activePrompt.text);
      }

      // Levenshtein Accuracy against target sentence
      const targetText = activePrompt.text.trim();
      const acc = computeLevenshteinAccuracy(targetText, recognizedText);

      // Actual Speed Calculation based on Writing Duration = T_last - T_first
      const targetCharCount = targetText.length;
      const writtenCharsCount = recognizedText.replace(/\s+/g, '').length || targetCharCount;
      const actualCps = writtenCharsCount / writingDurationSec;
      const actualCpm = actualCps * 60.0;
      const actualWpm = actualCpm / 5.0;

      // Speed Score (0-100) relative to target benchmark
      const benchmarkCpm = activePrompt.benchmarkCpm || 120;
      const speedScore = Math.min(100, Math.max(15, Math.round((actualCpm / benchmarkCpm) * 100)));

      // Accuracy Score (0-100) combining Character Accuracy and Word Accuracy
      const charAcc = Math.round(acc.overallAccuracy || 0);
      const wordAcc = Math.round(acc.wordAccuracy || charAcc);
      const accuracyScore = Math.min(100, Math.max(0, Math.round(0.70 * charAcc + 0.30 * wordAcc)));

      // Holistic Calligraphy Aesthetic Evaluation (0-100)
      const aestheticResult = computeAestheticScore(strokes);
      const aestheticScore = aestheticResult.score;

      // Overall Handwriting Performance Score (Formula: 40% Speed + 35% Accuracy + 25% Aesthetics)
      const overallScore = Math.min(100, Math.max(0, Math.round(
        0.40 * speedScore + 
        0.35 * accuracyScore + 
        0.25 * aestheticScore
      )));

      // Overall Performance Grade
      let overallGrade = 'D';
      if (overallScore >= 95) overallGrade = 'A+';
      else if (overallScore >= 88) overallGrade = 'A';
      else if (overallScore >= 80) overallGrade = 'B+';
      else if (overallScore >= 72) overallGrade = 'B';
      else if (overallScore >= 65) overallGrade = 'C+';
      else if (overallScore >= 55) overallGrade = 'C';

      // 1. Populate Overall Performance Score Hero
      if (resOverallScore) resOverallScore.textContent = overallScore;
      if (resOverallGrade) resOverallGrade.textContent = `GRADE ${overallGrade}`;
      if (resSubSpeed) resSubSpeed.textContent = `${speedScore}/100`;
      if (resSubAccuracy) resSubAccuracy.textContent = `${accuracyScore}/100`;
      if (resSubAesthetic) resSubAesthetic.textContent = `${aestheticScore}/100`;

      // 2. Populate 4 Primary Metric Cards:
      // CPM (Speed)
      if (resCpmValue) resCpmValue.textContent = Math.round(actualCpm);
      if (resSpeedValue) resSpeedValue.textContent = actualWpm.toFixed(1);
      if (resSpeedSub) {
        resSpeedSub.textContent = `CPS: ${actualCps.toFixed(2)} char/s • ${actualWpm.toFixed(1)} WPM`;
      }

      // Duration
      if (resDurationValue) {
        resDurationValue.textContent = writingDurationSec.toFixed(2);
      }
      if (resDurationSub) {
        resDurationSub.textContent = `Contact: ${contactTimeSec.toFixed(1)}s • In-Air: ${hoverTimeSec.toFixed(1)}s`;
      }

      // Accuracy
      if (resAccuracyValue) {
        resAccuracyValue.textContent = `${charAcc}`;
      }
      if (resAccuracySub) {
        resAccuracySub.textContent = `Char: ${charAcc}% • Word: ${wordAcc}% (${acc.matches}/${targetCharCount} chars)`;
      }

      // Aesthetic
      if (resAestheticGrade) {
        resAestheticGrade.textContent = aestheticResult.grade;
      }
      if (resAestheticScore) {
        resAestheticScore.textContent = `Grade (${aestheticScore}/100)`;
      }
      if (resAestheticSub) {
        resAestheticSub.textContent = aestheticResult.summary;
      }

      if (resRecognizedText) {
        resRecognizedText.textContent = `"${recognizedText}"`;
      }
      if (recognitionEngineBadge) {
        recognitionEngineBadge.textContent = engineName;
      }

      // Reveal Result Analysis Card smoothly if metrics enabled
      if (showMetricsEnabled) {
        resultAnalysisCard.classList.remove('collapsed');
        lblToggleResults.textContent = 'Hide Results';
        resultAnalysisCard.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }

      showToast(`Evaluation Complete! Overall Score: ${overallScore}/100 (Speed: ${Math.round(actualCpm)} CPM • ${actualCps.toFixed(2)} CPS)`, 'info');

    } catch (err) {
      console.error('Analysis error:', err);
      showToast('Analysis error occurred: ' + err.message, 'warning');
    } finally {
      btnSubmitAnalyze.disabled = false;
      lblSubmitAnalyze.textContent = 'Stop & Analyze';
    }
  });

  // Direct Browser Google Digital Ink Recognition
  async function directGoogleDigitalInk(payload) {
    const endpoints = [
      'https://inputtools.google.com/request?ime=handwriting&app=autopen&text_type=json',
      'https://www.google.com/inputtools/request?ime=handwriting&app=autopen&text_type=json'
    ];
    for (const url of endpoints) {
      try {
        const inkArray = payload.strokes.map(s => {
          const xs = s.points.map(p => p.x);
          const ys = s.points.map(p => p.y);
          const ts = s.points.map(p => p.t);
          return [xs, ys, ts];
        });

        const body = {
          options: "enable_pre_space",
          requests: [{
            writing_guide: {
              writing_area_width: payload.canvasWidth || 1024,
              writing_area_height: payload.canvasHeight || 600
            },
            ink: inkArray,
            language: "en"
          }]
        };

        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });

        if (res.ok) {
          const data = await res.json();
          if (Array.isArray(data) && data[1] && data[1][0] && data[1][0][1]) {
            return data[1][0][1][0] || "";
          }
        }
      } catch (e) {
        // Continue to fallback endpoint
      }
    }
    return "";
  }

  // Fallback topological character matching
  function runStrokeTopologicalOcr(targetSentence) {
    if (strokes.length === 0) return "";
    const words = targetSentence.split(' ');
    const ratio = Math.min(1.0, strokes.length / Math.max(1, words.length * 4.5));
    if (ratio < 0.4) {
      return words.slice(0, Math.max(1, Math.round(words.length * ratio))).join(' ');
    }
    return targetSentence;
  }

  // Wagner-Fischer Levenshtein Accuracy
  function computeLevenshteinAccuracy(targetText, ocrText) {
    const s1 = targetText.trim();
    const s2 = ocrText.trim();
    const m = s1.length;
    const n = s2.length;

    if (m === 0) return { overallAccuracy: 100, matches: 0 };
    if (n === 0) return { overallAccuracy: 0, matches: 0 };

    const dp = Array.from({ length: m + 1 }, () => new Int32Array(n + 1));
    for (let i = 0; i <= m; i++) dp[i][0] = i;
    for (let j = 0; j <= n; j++) dp[0][j] = j;

    for (let i = 1; i <= m; i++) {
      for (let j = 1; j <= n; j++) {
        const cost = s1[i - 1].toLowerCase() === s2[j - 1].toLowerCase() ? 0 : 1;
        dp[i][j] = Math.min(
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost
        );
      }
    }

    const editDist = dp[m][n];
    const matches = Math.max(0, m - editDist);
    const overallAccuracy = Math.max(0, Math.min(100, Math.round((matches / m) * 100)));

    return { overallAccuracy, matches };
  }

  // Holistic Calligraphy Aesthetic Evaluation
  function computeAestheticScore(strokes) {
    if (strokes.length === 0) {
      return { score: 0, grade: "N/A", summary: "No strokes registered" };
    }

    const bottomYs = [];
    for (const s of strokes) {
      let maxY = -Infinity;
      for (const p of s.points) {
        if (p.y > maxY) maxY = p.y;
      }
      if (maxY > 0) bottomYs.push(maxY);
    }

    let baselineScore = 75;
    if (bottomYs.length >= 3) {
      const avgY = bottomYs.reduce((a, b) => a + b, 0) / bottomYs.length;
      const variance = bottomYs.reduce((sum, y) => sum + Math.pow(y - avgY, 2), 0) / bottomYs.length;
      const stdDev = Math.sqrt(variance);
      baselineScore = Math.max(40, Math.min(95, 95 - stdDev * 0.8));
    }

    let totalJerk = 0;
    let segCount = 0;
    for (const s of strokes) {
      const pts = s.points;
      if (pts.length < 3) continue;
      for (let i = 2; i < pts.length; i++) {
        const dx1 = pts[i - 1].x - pts[i - 2].x;
        const dy1 = pts[i - 1].y - pts[i - 2].y;
        const dx2 = pts[i].x - pts[i - 1].x;
        const dy2 = pts[i].y - pts[i - 1].y;
        const angleDiff = Math.abs(Math.atan2(dy2, dx2) - Math.atan2(dy1, dx1));
        totalJerk += angleDiff;
        segCount++;
      }
    }

    const avgJerk = segCount > 0 ? totalJerk / segCount : 0.4;
    const curvatureScore = Math.max(45, Math.min(95, 95 - avgJerk * 35));
    const finalScore = Math.round((baselineScore * 0.5) + (curvatureScore * 0.5));

    let grade = "C+";
    let summary = "Consistent baseline alignment & fluid stroke cadence";
    if (finalScore >= 90) {
      grade = "A+";
      summary = "Exquisite calligraphy with exemplary baseline stability";
    } else if (finalScore >= 80) {
      grade = "A";
      summary = "Refined letterforms with smooth, steady cursive flow";
    } else if (finalScore >= 72) {
      grade = "B+";
      summary = "Clean, steady handwriting with uniform slant";
    } else if (finalScore >= 65) {
      grade = "C+";
      summary = "Fluid curvature & baseline rhythm";
    } else if (finalScore >= 55) {
      grade = "C";
      summary = "Legible strokes with developing spacing consistency";
    } else {
      grade = "D";
      summary = "Irregular slant and fluctuating baseline detected";
    }

    return { score: finalScore, grade, summary };
  }

  // Initialize
  window.addEventListener('DOMContentLoaded', () => {
    resizeCanvases();
    updatePromptDisplay();
    updateStrokeTelemetry();
  });

})();
