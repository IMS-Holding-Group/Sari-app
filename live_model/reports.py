import csv
import json
import logging
from pathlib import Path

log = logging.getLogger("sari.reports")

FAULT_AR = {
    "overcurrent": "ارتفاع التيار (حمل زائد)",
    "voltage": "اضطراب الجهد",
    "leakage": "تسرب أرضي",
    "overheat": "ارتفاع حرارة الموصلات",
}
FONT_CANDIDATES = (
    Path(r"C:\Windows\Fonts\arial.ttf"),
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    Path("/usr/share/fonts/dejavu/DejaVuSans.ttf"),
)
FILES = ("report.pdf", "report.json", "readings.csv")


def format_ar(ts):
    hour12 = ts.hour % 12 or 12
    suffix = "ص" if ts.hour < 12 else "م"
    return f"{ts.year}/{ts.month}/{ts.day}م {hour12}:{ts.minute:02d}{suffix}"


def _rtl(text):
    import arabic_reshaper
    from bidi.algorithm import get_display
    return get_display(arabic_reshaper.reshape(text))


def _pdf(path, summary, rows):
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    font = next((p for p in FONT_CANDIDATES if p.exists()), None)
    if font is None:
        log.warning("no Arabic font found, PDF skipped")
        return False
    pdfmetrics.registerFont(TTFont("SariArabic", str(font)))
    title = ParagraphStyle("t", fontName="SariArabic", fontSize=16, alignment=2, leading=22)
    body = ParagraphStyle("b", fontName="SariArabic", fontSize=11, alignment=2, leading=16)
    info = [
        ("الجهاز", summary["device_id"]),
        ("الموقع", summary["location"]),
        ("وقت الخلل", summary["time_display"]),
        ("نوع الخلل", "، ".join(FAULT_AR[f] for f in summary["faults"])),
        ("احتمال الخلل حسب النموذج", f"{summary['probability'] * 100:.1f}%"),
        ("التيار", f"{summary['current_a']:.2f} A"),
        ("الجهد", f"{summary['voltage_v']:.1f} V"),
        ("التسرب الأرضي", f"{summary['leakage_ma']:.0f} mA"),
        ("الحرارة", f"{summary['temperature_c']:.1f} C"),
        ("الإجراء المتخذ", "قطع التيار تلقائياً، ولا يعود إلا بإعادة تشغيل يدوية"),
        ("التوصية", summary["action_ar"]),
    ]
    table = Table(
        [[Paragraph(value if value.isascii() else _rtl(value), body), Paragraph(_rtl(label), body)] for label, value in info],
        colWidths=[10 * cm, 6 * cm],
    )
    table.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("BACKGROUND", (1, 0), (1, -1), colors.whitesmoke),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    head = ["T (C)", "Leak (mA)", "V (V)", "I (A)", "Time"]
    tail = rows[-30:]
    readings = Table(
        [head] + [[f"{r['temperature_c']:.1f}", f"{r['leakage_ma']:.0f}", f"{r['voltage_v']:.1f}", f"{r['current_a']:.2f}", r["time"][11:19]] for r in tail],
        colWidths=[3 * cm] * 5,
    )
    readings.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.25, colors.grey),
        ("BACKGROUND", (0, 0), (-1, 0), colors.lightgrey),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
    ]))
    doc = SimpleDocTemplate(str(path), pagesize=A4, rightMargin=2 * cm, leftMargin=2 * cm, topMargin=2 * cm, bottomMargin=2 * cm)
    doc.build([
        Paragraph(_rtl("تقرير خلل كهربائي - ساري"), title),
        Spacer(1, 12),
        table,
        Spacer(1, 16),
        Paragraph(_rtl("آخر 30 قراءة قبل القطع"), body),
        Spacer(1, 6),
        readings,
    ])
    return True


def write_report(root, report_id, summary, rows):
    folder = Path(root) / report_id
    folder.mkdir(parents=True, exist_ok=True)
    with open(folder / "readings.csv", "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    (folder / "report.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    files = ["report.json", "readings.csv"]
    try:
        if _pdf(folder / "report.pdf", summary, rows):
            files.insert(0, "report.pdf")
    except Exception:
        log.exception("PDF generation failed for %s", report_id)
    return files
