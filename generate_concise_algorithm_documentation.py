import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)
from reportlab.pdfgen import canvas

OUTPUT_DIR = r"D:\RAPID WRITE\APPLICATION\Reports"
OUTPUT_PDF = os.path.join(OUTPUT_DIR, "RapidWrite_Concise_Algorithm_Documentation.pdf")

os.makedirs(OUTPUT_DIR, exist_ok=True)

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        if self._pageNumber == 1:
            return

        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#475569"))

        # Running Header
        header_text = "RAPIDWRITE — CONCISE ALGORITHM & ENGINEERING DOCUMENTATION"
        self.drawString(54, 750, header_text)
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.6)
        self.line(54, 744, 558, 744)

        # Running Footer
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 38, page_str)
        self.drawString(54, 38, "RAPIDWRITE ENGINEERING SPECIFICATION — CONFIDENTIAL & PROPRIETARY")
        self.line(54, 48, 558, 48)

        self.restoreState()

def build_pdf():
    doc = SimpleDocTemplate(
        OUTPUT_PDF,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    c_primary = colors.HexColor("#0F172A")    # Slate 900
    c_accent = colors.HexColor("#0284C7")     # Sky 600
    c_sub = colors.HexColor("#334155")        # Slate 700
    c_body = colors.HexColor("#1E293B")       # Slate 800
    c_border = colors.HexColor("#CBD5E1")     # Slate 300
    c_bg_light = colors.HexColor("#F8FAFC")   # Slate 50
    c_code_bg = colors.HexColor("#F1F5F9")    # Slate 100
    c_callout_bg = colors.HexColor("#E0F2FE") # Light Cyan

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=c_primary,
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10.5,
        leading=14,
        textColor=c_accent,
        spaceAfter=10
    )

    meta_style = ParagraphStyle(
        'DocMeta',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=c_sub,
        spaceAfter=12
    )

    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=c_primary,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9.5,
        leading=13,
        textColor=c_accent,
        spaceBefore=7,
        spaceAfter=3,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=c_body,
        spaceAfter=4
    )

    bullet_style = ParagraphStyle(
        'Bullet',
        parent=body_style,
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=2.5
    )

    math_block = ParagraphStyle(
        'MathBlock',
        parent=styles['Normal'],
        fontName='Courier-Bold',
        fontSize=7.8,
        leading=10.5,
        textColor=colors.HexColor("#1E3A8A"),
        leftIndent=12,
        spaceBefore=2,
        spaceAfter=3
    )

    table_header = ParagraphStyle(
        'TH',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.white,
        alignment=1
    )

    table_cell = ParagraphStyle(
        'TC',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7,
        leading=9,
        textColor=c_body
    )

    table_cell_bold = ParagraphStyle(
        'TCB',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7,
        leading=9,
        textColor=c_primary
    )

    callout_style = ParagraphStyle(
        'Callout',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=7.8,
        leading=10.5,
        textColor=colors.HexColor("#0369A1")
    )

    story = []

    # Title Block
    story.append(Paragraph("RAPIDWRITE: CONCISE ALGORITHM TECHNICAL DOCUMENTATION", title_style))
    story.append(Paragraph("Comprehensive Engineering Reference covering all Implemented Systems, Formulations & Dataflows", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=c_accent, spaceBefore=0, spaceAfter=6))

    meta_text = """
    <b>Document Reference:</b> RW-ENG-DOC-CONCISE-2026 &nbsp;|&nbsp; 
    <b>Source Code Repositories:</b> <code>handwriting_evaluator/</code> &amp; <code>web_testing_environment/</code><br/>
    <b>Output Destination:</b> <code>D:\\RAPID WRITE\\APPLICATION\\Reports</code> &nbsp;|&nbsp; 
    <b>Date:</b> October 30, 2026
    """
    story.append(Paragraph(meta_text, meta_style))

    # =========================================================================
    # 1. PROJECT OVERVIEW
    # =========================================================================
    story.append(Paragraph("1. Project Overview", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))
    sec1 = (
        "<b>RapidWrite</b> is a high-precision stylus handwriting and kinematics evaluation system designed for Android tablets, "
        "iPads (Apple Pencil), and desktop browsers. It replaces subjective human grading and ungrounded wall-clock timers "
        "with an event-grounded 5-step temporal gating model, strict hardware palm rejection, physical kinematic velocity integration, "
        "Wagner-Fischer dynamic programming accuracy analysis, and deterministic on-device geometric calligraphy scoring."
    )
    story.append(Paragraph(sec1, body_style))

    # =========================================================================
    # 2. ALGORITHM INVENTORY
    # =========================================================================
    story.append(Paragraph("2. Algorithm Inventory", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    inv_data = [
        [Paragraph("ID", table_header), Paragraph("Algorithm Name", table_header), Paragraph("Core Purpose", table_header), Paragraph("Status", table_header), Paragraph("Source Location", table_header)],
        [Paragraph("<b>ALG-01</b>", table_cell), Paragraph("<b>5-Step Temporal Gating & Duration</b>", table_cell), Paragraph("Isolates motor execution time from pre-reading and post-stopping delays.", table_cell), Paragraph("Implemented", table_cell), Paragraph("<code>speed_calculator_service.dart</code><br/><code>app.js:365-545</code>", table_cell)],
        [Paragraph("<b>ALG-02</b>", table_cell), Paragraph("<b>Signal Discriminator & Palm Rejection</b>", table_cell), Paragraph("Rejects touch/palm gestures; locks drawing to stylus pointer.", table_cell), Paragraph("Implemented", table_cell), Paragraph("<code>stylus_canvas.dart:48-67</code><br/><code>app.js:414-434</code>", table_cell)],
        [Paragraph("<b>ALG-03</b>", table_cell), Paragraph("<b>Curriculum Pacing & Disappearance</b>", table_cell), Paragraph("Hides prompt sentence when countdown expires to test visual recall.", table_cell), Paragraph("Implemented", table_cell), Paragraph("<code>sentence_prompt.dart</code><br/><code>app.js:365-396</code>", table_cell)],
        [Paragraph("<b>ALG-04</b>", table_cell), Paragraph("<b>Kinematics & Multi-Factor Speed</b>", table_cell), Paragraph("Computes arc-length, tip velocities (px/s, mm/s), and completion-scaled speed score.", table_cell), Paragraph("Implemented", table_cell), Paragraph("<code>speed_calculator_service.dart:53-185</code><br/><code>app.js:890-958</code>", table_cell)],
        [Paragraph("<b>ALG-05</b>", table_cell), Paragraph("<b>Wagner-Fischer Dynamic Programming</b>", table_cell), Paragraph("Generates character/word accuracy and backtracked edit error counts.", table_cell), Paragraph("Implemented", table_cell), Paragraph("<code>ink_recognition_service.dart:115-246</code><br/><code>app.js:1056-1086</code>", table_cell)],
        [Paragraph("<b>ALG-06</b>", table_cell), Paragraph("<b>Deterministic Geometric Calligraphy</b>", table_cell), Paragraph("Evaluates baseline jitter, slant angle variance, spacing rhythm, and tremor.", table_cell), Paragraph("Implemented", table_cell), Paragraph("<code>aesthetic_evaluation_service.dart:177-400</code><br/><code>app.js:1089-1154</code>", table_cell)],
        [Paragraph("<b>ALG-07</b>", table_cell), Paragraph("<b>Multimodal Vision AI Evaluator</b>", table_cell), Paragraph("Evaluates canvas PNG + OCR text via Gemini 2.5 Flash Vision.", table_cell), Paragraph("Optional / API Gated", table_cell), Paragraph("<code>aesthetic_evaluation_service.dart:58-173</code>", table_cell)],
        [Paragraph("<b>ALG-08</b>", table_cell), Paragraph("<b>Digital Ink Tensor Translation & OCR</b>", table_cell), Paragraph("Translates vector strokes into 3D tensors for neural OCR recognition.", table_cell), Paragraph("Implemented", table_cell), Paragraph("<code>server.py:49-115</code><br/><code>app.js:1000-1054</code>", table_cell)],
    ]
    inv_tbl = Table(inv_data, colWidths=[36, 120, 150, 68, 130])
    inv_tbl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_primary),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, c_bg_light]),
        ('PADDING', (0,0), (-1,-1), 3),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(inv_tbl)
    story.append(Spacer(1, 6))

    # =========================================================================
    # 3. INDIVIDUAL ALGORITHM EXPLANATIONS
    # =========================================================================
    story.append(Paragraph("3. Individual Algorithm Explanations", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    algs = [
        ("ALG-01: 5-Step Temporal Gating & Duration", 
         "<b>Purpose:</b> Eliminate human hesitation and stopping button reaction time.<br/>"
         "<b>Working Principle:</b> Step 1 arms listeners ($T_0=00:00$). Step 2 locks $T_{first}$ on first pen-down hardware interrupt. "
         "Step 3 accumulates active contact time $\\sum \\Delta t_{contact}$. Step 4 accumulates in-air pause time $\\sum \\Delta t_{hover}$. "
         "Step 5 captures $T_{last}$ at final stroke release. Formula: $\\Delta t_{writing} = T_{last} - T_{first}$.<br/>"
         "<b>Input/Output:</b> Input: PointerEvent stream. Output: $T_{first}, T_{last}, \\Delta t_{writing}, \\Delta t_{contact}, \\Delta t_{hover}$.<br/>"
         "<b>Conditions & Limits:</b> Clamped to $\\max(0.5\\text{ s}, \\Delta t)$ to prevent arithmetic overflow on single taps.<br/>"
         "<b>Source:</b> <code>speed_calculator_service.dart:30-105</code>; <code>app.js:365-545</code>."),

        ("ALG-02: Hardware Signal Discriminator & Strict Palm Rejection",
         "<b>Purpose:</b> Prevent palm resting and accidental touches from causing canvas marks or viewport scrolling.<br/>"
         "<b>Working Principle:</b> Evaluates <code>event.kind</code>. Accepts <code>PointerDeviceKind.stylus</code> or <code>invertedStylus</code>. "
         "Rejects <code>PointerDeviceKind.touch</code> and invokes <code>e.preventDefault()</code>. Locks session to first active <code>pointerId</code> "
         "and calls <code>setPointerCapture()</code> to prevent stroke loss across canvas boundaries.<br/>"
         "<b>Input/Output:</b> Input: Raw pointer event. Output: Boolean permit/reject, incremented <code>rejectedPalmTouches</code>.<br/>"
         "<b>Source:</b> <code>stylus_canvas.dart:48-67</code>; <code>app.js:414-434</code>."),

        ("ALG-03: Curriculum Pacing & Target Prompt Disappearance",
         "<b>Purpose:</b> Challenge student visual motor memory by enforcing fixed time limits.<br/>"
         "<b>Working Principle:</b> Evaluates $t_{remaining} = T_{alloc} - (t_{now} - T_{first})$. When $t_{remaining} \\le 0$, sets prompt CSS to "
         "<code>display: none !important;</code>. Fixed tiers: Easy (10-12s, 70 CPM), Medium (18-22s, 100 CPM), Hard (28-32s, 130 CPM).<br/>"
         "<b>Input/Output:</b> Input: Difficulty tier, elapsed time. Output: Display toggle, <code>sentenceExpired</code> state.<br/>"
         "<b>Source:</b> <code>sentence_prompt.dart:7-45</code>; <code>app.js:365-396</code>."),

        ("ALG-04: Kinematic Velocity & Multi-Factor Speed Scoring",
         "<b>Purpose:</b> Measure physical stroke speed and compute a balanced, anti-gaming speed grade.<br/>"
         "<b>Working Principle:</b> Integrates Euclidean segment lengths: $L_{px} = \\sum \\sqrt{\\Delta x^2 + \\Delta y^2}$, converts to millimeters "
         "using $\\kappa = 6.2992\\text{ px/mm}$ (160 DPI). Computes tip velocity $V_{tip} = L_{mm} / \\Delta t_{contact}$. Production rates: "
         "$\\text{CPM} = (C_{written} / \\Delta t_{writing}) \\cdot 60$, $\\text{WPM} = \\text{CPM} / 5.0$. Combines Pacing, Velocity, and Fluency scores, "
         "scaled by anti-gaming factor $(C_{written} / C_{target})^{1.25}$.<br/>"
         "<b>Input/Output:</b> Input: Strokes list, prompt char count, duration. Output: CPM, WPM, Tip Velocity, Speed Score.<br/>"
         "<b>Source:</b> <code>speed_calculator_service.dart:53-185</code>; <code>app.js:890-958</code>."),

        ("ALG-05: Wagner-Fischer Dynamic Programming Text Accuracy",
         "<b>Purpose:</b> Compute exact string edit distance and classify character/word errors.<br/>"
         "<b>Working Principle:</b> Computes $(m+1) \\times (n+1)$ distance matrix using recurrence: $D[i,j] = \\min(D[i-1,j]+1, D[i,j-1]+1, D[i-1,j-1]+\\text{cost})$. "
         "Backtracks from $(m,n)$ to $(0,0)$ to extract exact Matches ($M$), Substitutions ($S$), Deletions ($D$), and Insertions ($I$). "
         "Character accuracy: $\\text{Acc}_{char} = ((m - (D + S + 0.5I)) / m) \\cdot 100$. Word accuracy: $(1 - D_{word} / \\max(|W_1|, |W_2|)) \\cdot 100$.<br/>"
         "<b>Input/Output:</b> Input: Target prompt $s_1$, recognized OCR $s_2$. Output: Edit matrix, Character Accuracy %, Word Accuracy %.<br/>"
         "<b>Source:</b> <code>ink_recognition_service.dart:115-246</code>; <code>app.js:1056-1086</code>."),

        ("ALG-06: Deterministic Geometric Calligraphy Analyzer",
         "<b>Purpose:</b> Grade handwriting neatness, baseline stability, and rhythm on-device without internet.<br/>"
         "<b>Working Principle:</b> 1) <i>Baseline:</i> Clusters stroke bounding box bottoms into bands within 65px; penalizes weighted standard deviation $\\sigma_{base}$. "
         "2) <i>Slant:</i> Extracts vertical segments ($|dy| > 0.6|dx|$); computes $\\theta = \\text{atan2}(dx, |dy|)$ and penalizes standard deviation $\\sigma_\\theta$. "
         "3) <i>Spacing:</i> Sorts bounding boxes horizontally; evaluates gap coefficient of variation $CV = \\sigma_g / \\mu_g$. "
         "4) <i>Tremor:</i> Measures angular jerk $\\Delta \\theta$ between consecutive vectors and tortuosity $\\tau = \\text{path} / \\text{chord}$.<br/>"
         "<b>Input/Output:</b> Input: Stroke vector list. Output: Baseline, Slant, Spacing, Formation scores & Composite Grade (A-D).<br/>"
         "<b>Source:</b> <code>aesthetic_evaluation_service.dart:177-400</code>; <code>app.js:1089-1154</code>."),

        ("ALG-08: Google Digital Ink 3D Tensor Translation & OCR",
         "<b>Purpose:</b> Convert vector strokes into Google's proprietary handwriting tensor format for neural OCR.<br/>"
         "<b>Working Principle:</b> Transforms stroke point streams into 3D nested coordinate tensors $[ [ [x_1..x_M], [y_1..y_M], [t_1..t_M] ] ]$. "
         "In Flutter, invokes native on-device <code>mlkit.DigitalInkRecognizer</code> (`en-US`). In web, dispatches payload to Google Input Tools API.<br/>"
         "<b>Input/Output:</b> Input: Stroke points list. Output: Transcribed text string, candidate list.<br/>"
         "<b>Source:</b> <code>ink_recognition_service.dart:58-111</code>; <code>server.py:49-115</code>; <code>app.js:1000-1054</code>.")
    ]

    for a_title, a_desc in algs:
        story.append(Paragraph(f"<b>{a_title}</b>", h2_style))
        story.append(Paragraph(a_desc, body_style))

    story.append(Spacer(1, 6))

    # =========================================================================
    # 4. MATHEMATICAL CONCEPTS AND FORMULAS
    # =========================================================================
    story.append(Paragraph("4. Mathematical Concepts and Formulas", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    math_items = [
        ("Event-Grounded Writing Duration",
         "$$\\Delta t_{writing} = T_{last\\ stroke} - T_{first\\ stroke} = \\sum_{k=1}^N \\Delta t_{contact, k} + \\sum_{k=1}^{N-1} \\Delta t_{hover, k}$$",
         "Determines actual motor execution time on glass. Example: First stroke down at 2.45s, last stroke lifted at 20.90s $\\rightarrow \\Delta t_{writing} = 18.45\\text{ s}$."),

        ("Kinematic Arc-Length & Physical Velocity",
         "$$L_{px} = \\sum_{k=1}^N \\sum_{i=1}^{M_k - 1} \\sqrt{(x_{i+1} - x_i)^2 + (y_{i+1} - y_i)^2}, \\quad V_{tip, mm} = \\frac{L_{px} / 6.2992}{\\Delta t_{contact}}$$",
         "Calculates total path drawn and active pen-down tip speed in mm/s (standard 160 DPI = 6.2992 px/mm). Example: $L_{px} = 3420\\text{ px} \\rightarrow 542.92\\text{ mm}$; contact time $12.80\\text{ s} \\rightarrow V_{tip} = 42.42\\text{ mm/s}$."),

        ("Typographical Production Rates (CPM & WPM)",
         "$$\\text{CPM} = \\left(\\frac{C_{written}}{\\Delta t_{writing}}\\right) \\cdot 60, \\quad \\text{WPM} = \\frac{\\text{CPM}}{5.0}$$",
         "Calculates Characters Per Minute and standard Words Per Minute (5 characters/word). Example: 26 characters in $18.45\\text{ s} \\rightarrow \\text{CPM} = 84.55$, $\\text{WPM} = 16.91$."),

        ("Anti-Gaming Completion-Scaled Speed Score",
         "$$S_{speed} = \\left(0.50 S_{pacing} + 0.30 S_{velocity} + 0.20 S_{fluency}\\right) \\cdot \\left(\\frac{C_{written}}{C_{target}}\\right)^{1.25}$$",
         "Penalizes incomplete writing so scribbling 2 letters rapidly does not yield a high score. Example: Writing 2 of 45 characters yields completion multiplier $(2/45)^{1.25} = 0.021$ ($97.9\\%$ penalty)."),

        ("Wagner-Fischer Matrix Recurrence & Character Accuracy",
         "$$D[i,j] = \\min(D[i-1,j]+1, D[i,j-1]+1, D[i-1,j-1]+\\text{cost}), \\quad \\text{Acc}_{char} = \\left(\\frac{m - (D + S + 0.5I)}{m}\\right) \\cdot 100$$",
         "Computes minimum edit operations. Backtracking yields exact Matches ($M$), Substitutions ($S$), Deletions ($D$), Insertions ($I$). Example: Prompt 'fox' ($m=3$), OCR 'box' $\\rightarrow D=0, S=1, I=0, M=2 \\rightarrow \\text{Acc}_{char} = 66.7\\%$."),

        ("Baseline Jitter & Slant Angle Standard Deviation",
         "$$\\sigma_{base} = \\sqrt{\\frac{1}{N}\\sum (y_i - \\bar{y})^2}, \\quad \\theta = \\text{atan2}(dx, |dy|) \\cdot \\frac{180}{\\pi}, \\quad S_{slant} = 97.0 - \\max(0, \\sigma_\\theta - 4.5) \\cdot 2.8$$",
         "Evaluates vertical baseline drift and cursive slant uniformity across vertical stroke segments.")
    ]

    for m_title, m_eq, m_desc in math_items:
        story.append(Paragraph(f"<b>{m_title}:</b>", h2_style))
        story.append(Paragraph(m_eq, math_block))
        story.append(Paragraph(m_desc, body_style))

    story.append(Spacer(1, 6))

    # =========================================================================
    # 5. IMPORTANT TECHNICAL KEYWORDS
    # =========================================================================
    story.append(Paragraph("5. Important Technical Keywords", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    keywords = [
        ("Temporal Gating", "A state-driven biomechanical timing technique that activates on the millisecond of the first stylus contact and stops on the last stroke release, isolating motor execution."),
        ("Euclidean Arc-Length", "The sum of straight-line distances between consecutive sample points representing the total physical path drawn by the pen tip."),
        ("Active Tip Velocity", "The speed of the stylus while actively touching the digitizer ($L_{\\text{mm}} / \\Delta t_{\\text{contact}}$), excluding in-air hesitation pauses."),
        ("Palm Rejection", "Hardware-level filtering that discards capacitive finger/hand contacts (<code>PointerDeviceKind.touch</code>) while allowing active digitizer pens to draw."),
        ("Pointer Capture", "The programmatic locking of a digitizer pointer stream to the canvas, ensuring that rapid strokes extending past the canvas border are captured without sample loss."),
        ("Digital Ink Tensor", "A 3D coordinate data structure $[ [ [x_1..x_M], [y_1..y_M], [t_1..t_M] ] ]$ preserving stroke sequence, direction, and velocity for neural OCR recognition."),
        ("Wagner-Fischer DP", "An $\\mathcal{O}(m \\cdot n)$ dynamic programming algorithm that computes the Levenshtein distance matrix and aligns reference text with OCR transcriptions."),
        ("Baseline Jitter", "The statistical standard deviation of stroke bottom coordinates along horizontal text lines, measuring line straightness."),
        ("Slant Angle Dispersion", "The standard deviation of stroke segment angles relative to the vertical axis, quantifying cursive consistency."),
        ("Angular Jerk", "The absolute divergence in direction between consecutive stroke vectors, measuring pen tremor and letter formation smoothness."),
        ("Stroke Tortuosity", "The ratio of total stroke path length to the straight-line Euclidean distance between stroke start and end points ($L / \\text{chord}$).")
    ]

    for kw_name, kw_def in keywords:
        story.append(Paragraph(f"• <b>{kw_name}:</b> {kw_def}", bullet_style))

    story.append(Spacer(1, 6))

    # =========================================================================
    # 6. SOURCE CODE MAPPING
    # =========================================================================
    story.append(Paragraph("6. Source Code Mapping", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    map_data = [
        [Paragraph("Algorithm", table_header), Paragraph("Source File", table_header), Paragraph("Main Function / Entry Point", table_header), Paragraph("Key Operations & Data Processing", table_header)],
        [Paragraph("<b>ALG-01: Temporal Gating</b>", table_cell), Paragraph("<code>speed_calculator_service.dart</code><br/><code>app.js</code>", table_cell), Paragraph("<code>onFirstStylusStrokeDown()</code><br/><code>startSessionTimer()</code>", table_cell), Paragraph("Locks $T_{first}$ on first pen-down. Accumulates contact vs hover intervals. Subtracts $T_{first}$ from $T_{last}$.", table_cell)],
        [Paragraph("<b>ALG-02: Palm Rejection</b>", table_cell), Paragraph("<code>stylus_canvas.dart</code><br/><code>app.js</code>", table_cell), Paragraph("<code>_handlePointerDown()</code><br/><code>onPointerDown()</code>", table_cell), Paragraph("Checks <code>kind == stylus</code>. Rejects touch. Locks <code>pointerId</code> and captures pointer stream.", table_cell)],
        [Paragraph("<b>ALG-03: Curriculum Pacing</b>", table_cell), Paragraph("<code>sentence_prompt.dart</code><br/><code>app.js</code>", table_cell), Paragraph("<code>SentencePrompt()</code><br/><code>startSessionTimer()</code>", table_cell), Paragraph("Evaluates remaining time every 50ms. Adds <code>.disappeared</code> CSS class when $t_{rem} \\le 0$.", table_cell)],
        [Paragraph("<b>ALG-04: Kinematics & Speed</b>", table_cell), Paragraph("<code>speed_calculator_service.dart</code><br/><code>app.js</code>", table_cell), Paragraph("<code>computeMetrics()</code><br/><code>btnSubmitAnalyze</code>", table_cell), Paragraph("Iterates stroke points; sums Euclidean distance. Divides by duration for WPM/CPM. Applies completion power 1.25.", table_cell)],
        [Paragraph("<b>ALG-05: Wagner-Fischer DP</b>", table_cell), Paragraph("<code>ink_recognition_service.dart</code><br/><code>app.js</code>", table_cell), Paragraph("<code>computeTextAccuracy()</code><br/><code>computeLevenshteinAccuracy()</code>", table_cell), Paragraph("Populates DP table. Backtracks path to extract match, deletion, substitution, and insertion error counts.", table_cell)],
        [Paragraph("<b>ALG-06: Geometric Aesthetics</b>", table_cell), Paragraph("<code>aesthetic_evaluation_service.dart</code><br/><code>app.js</code>", table_cell), Paragraph("<code>_evaluateHolisticallyOnDevice()</code><br/><code>computeAestheticScore()</code>", table_cell), Paragraph("Groups stroke bottoms into line bands ($\\Delta y < 65$). Computes slant angles and vector jerk $\\Delta \\theta$. Assigns grades A-D.", table_cell)],
        [Paragraph("<b>ALG-08: Digital Ink OCR</b>", table_cell), Paragraph("<code>ink_recognition_service.dart</code><br/><code>server.py</code>", table_cell), Paragraph("<code>recognizeHandwriting()</code><br/><code>handle_google_digital_ink()</code>", table_cell), Paragraph("Maps strokes to <code>[ [ [x], [y], [t] ] ]</code>. Calls Google ML Kit native recognizer or Google Cloud Input Tools REST API.", table_cell)],
    ]
    map_tbl = Table(map_data, colWidths=[90, 114, 120, 180])
    map_tbl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_primary),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, c_bg_light]),
        ('PADDING', (0,0), (-1,-1), 3),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    story.append(map_tbl)
    story.append(Spacer(1, 6))

    # =========================================================================
    # 7. ALGORITHM DEPENDENCIES
    # =========================================================================
    story.append(Paragraph("7. Algorithm Dependencies", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    dep_table_data = [
        [Paragraph("Algorithm", table_header), Paragraph("Input", table_header), Paragraph("Output", table_header), Paragraph("Connected Algorithm", table_header)],
        [Paragraph("<b>ALG-02: Palm Rejection</b>", table_cell), Paragraph("Raw digitizer pointer event stream", table_cell), Paragraph("Filtered <code>StylusPoint</code> coordinate tuples", table_cell), Paragraph("Feeds <b>ALG-01</b> (Temporal Gating) and <b>ALG-04</b> (Kinematics)", table_cell)],
        [Paragraph("<b>ALG-01: Temporal Gating</b>", table_cell), Paragraph("Filtered stylus pen-down / pen-up events", table_cell), Paragraph("$\\Delta t_{writing}, \\Delta t_{contact}, \\Delta t_{hover}$", table_cell), Paragraph("Feeds <b>ALG-04</b> (Kinematics) and <b>UI Dashboard</b> (Duration)", table_cell)],
        [Paragraph("<b>ALG-03: Curriculum Pacing</b>", table_cell), Paragraph("$T_{first\\ stroke}$ timestamp and difficulty limit", table_cell), Paragraph("State flag: <code>sentenceExpired</code>", table_cell), Paragraph("Controls <b>StylusCanvas</b> prompt visibility", table_cell)],
        [Paragraph("<b>ALG-08: Digital Ink OCR</b>", table_cell), Paragraph("Stroke vector coordinate list $[(x, y, t)]$", table_cell), Paragraph("Recognized text string ($s_{ocr}$)", table_cell), Paragraph("Feeds <b>ALG-05</b> (Accuracy) and <b>ALG-04</b> (Completion ratio)", table_cell)],
        [Paragraph("<b>ALG-05: Wagner-Fischer DP</b>", table_cell), Paragraph("Recognized string and prompt reference", table_cell), Paragraph("Character Accuracy %, Word Accuracy %", table_cell), Paragraph("Feeds <b>ALG-06</b> (Aesthetics) and <b>UI Dashboard</b>", table_cell)],
        [Paragraph("<b>ALG-04: Kinematics</b>", table_cell), Paragraph("Strokes, $\\Delta t_{writing}$, written char count", table_cell), Paragraph("WPM, CPM, Tip Velocity, Speed Score", table_cell), Paragraph("Feeds <b>UI Dashboard</b> (WPM card)", table_cell)],
        [Paragraph("<b>ALG-06: Calligraphy</b>", table_cell), Paragraph("Strokes, bounding boxes, accuracy metrics", table_cell), Paragraph("Aesthetic Score (0-100), Grade (A-D)", table_cell), Paragraph("Feeds <b>UI Dashboard</b> (Aesthetic card)", table_cell)],
    ]
    dep_matrix = Table(dep_table_data, colWidths=[110, 120, 120, 154])
    dep_matrix.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_primary),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, c_bg_light]),
        ('PADDING', (0,0), (-1,-1), 3),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    story.append(dep_matrix)
    story.append(Spacer(1, 6))

    # =========================================================================
    # 8. COMPUTATIONAL COMPLEXITY
    # =========================================================================
    story.append(Paragraph("8. Computational Complexity", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    cplx_data = [
        [Paragraph("Algorithm", table_header), Paragraph("Time Complexity", table_header), Paragraph("Space Complexity", table_header), Paragraph("Performance Characterization", table_header)],
        [Paragraph("<b>ALG-01: Temporal Gating</b>", table_cell), Paragraph("$\\mathcal{O}(1)$ per event", table_cell), Paragraph("$\\mathcal{O}(1)$", table_cell), Paragraph("Constant-time timestamp subtractions on hardware callbacks.", table_cell)],
        [Paragraph("<b>ALG-02: Palm Rejection</b>", table_cell), Paragraph("$\\mathcal{O}(1)$ per event", table_cell), Paragraph("$\\mathcal{O}(1)$", table_cell), Paragraph("Enum kind comparison; executes in $< 1\\mu\\text{s}$.", table_cell)],
        [Paragraph("<b>ALG-04: Kinematics</b>", table_cell), Paragraph("$\\mathcal{O}(P)$ linear scan", table_cell), Paragraph("$\\mathcal{O}(1)$ auxiliary", table_cell), Paragraph("Processes $P \\approx 2,000$ points in $< 0.5\\text{ ms}$ on mobile ARM.", table_cell)],
        [Paragraph("<b>ALG-05: Wagner-Fischer DP</b>", table_cell), Paragraph("$\\mathcal{O}(m \\cdot n)$", table_cell), Paragraph("$\\mathcal{O}(m \\cdot n)$ matrix", table_cell), Paragraph("For $m, n \\le 60$, matrix has $\\le 3,600$ ints ($< 15\\text{ KB}$); completes in $< 0.2\\text{ ms}$.", table_cell)],
        [Paragraph("<b>ALG-06: Baseline Clustering</b>", table_cell), Paragraph("$\\mathcal{O}(N \\cdot B) \\approx \\mathcal{O}(N)$", table_cell), Paragraph("$\\mathcal{O}(N)$", table_cell), Paragraph("Line bands $B \\le 4$, strokes $N \\le 100$; runs in $< 0.1\\text{ ms}$.", table_cell)],
        [Paragraph("<b>ALG-06: Spacing Rhythm</b>", table_cell), Paragraph("$\\mathcal{O}(N \\log N)$", table_cell), Paragraph("$\\mathcal{O}(N)$", table_cell), Paragraph("Quicksort on stroke bounding box horizontal coordinates.", table_cell)],
        [Paragraph("<b>ALG-08: Tensor Formatting</b>", table_cell), Paragraph("$\\mathcal{O}(P)$", table_cell), Paragraph("$\\mathcal{O}(P)$", table_cell), Paragraph("Linear extraction of coordinate arrays into JSON arrays.", table_cell)],
    ]
    cplx_tbl = Table(cplx_data, colWidths=[120, 94, 94, 196])
    cplx_tbl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_primary),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, c_bg_light]),
        ('PADDING', (0,0), (-1,-1), 3),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    story.append(cplx_tbl)
    story.append(Spacer(1, 6))

    # =========================================================================
    # 9. LIMITATIONS AND TECHNICAL OBSERVATIONS
    # =========================================================================
    story.append(Paragraph("9. Limitations and Technical Observations", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    limits = [
        ("<b>Empty Canvas Guard:</b> Submitting zero strokes is caught by <code>strokes.isEmpty</code> guards, returning zeroed metrics and descriptive labels (<i>'No Strokes Recorded'</i>) without division-by-zero crashes.", body_style),
        ("<b>Capacitive Passive Styluses:</b> Budget Android tablets using non-active passive styluses lack digitizer hardware reporting (reporting <code>PointerDeviceKind.touch</code>). RapidWrite requires active digitizers (Samsung S-Pen, Apple Pencil) for strict palm rejection.", body_style),
        ("<b>Offline Neural OCR:</b> In the native Flutter app, Google ML Kit operates completely offline with an on-device neural model. In the web test harness, a cloud fallback to Google Input Tools API is utilized; when network is unavailable, <code>runStrokeTopologicalOcr()</code> acts as an offline heuristic fallback.", body_style),
        ("<b>High-Frequency Touch Coalescing:</b> While Apple Pencil samples at 240 Hz, standard pointermove callbacks deliver samples at screen refresh rate (60-120 Hz). Utilizing coalesced touch lists (<code>event.coalesced</code>) would capture intermediate points for even finer micro-tremor analysis.", body_style)
    ]
    for l_title, l_desc in limits:
        story.append(Paragraph(f"• {l_title} {l_desc}", bullet_style))

    story.append(Spacer(1, 6))

    # =========================================================================
    # 10. REFERENCES
    # =========================================================================
    story.append(Paragraph("10. References", h1_style))
    story.append(HRFlowable(width="100%", thickness=0.6, color=c_primary, spaceBefore=0, spaceAfter=4))

    refs = [
        "[1] Wagner, R. A., & Fischer, M. J. (1974). <i>The String-to-String Correction Problem</i>. Journal of the ACM (JACM), 21(1), 168-173.",
        "[2] Plamondon, R., & Srihari, S. N. (2000). <i>On-Line and Off-Line Handwriting Recognition: A Comprehensive Survey</i>. IEEE TPAMI, 22(1), 63-84.",
        "[3] Google ML Kit Documentation (2024). <i>Digital Ink Recognition API Specification & Writing Area Protocol</i>.",
        "[4] W3C Pointer Events Level 3 (2023). <i>PointerEvent Interface Specification</i>. World Wide Web Consortium Recommendation.",
        "[5] ISO/IEC 19794-7:2014. <i>Information Technology — Biometric Data Interchange Formats — Part 7: Signature Time Series Data</i>."
    ]
    for r in refs:
        story.append(Paragraph(r, body_style))

    story.append(Spacer(1, 10))

    # Build Document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Report generated successfully: {OUTPUT_PDF}")

if __name__ == '__main__':
    build_pdf()

