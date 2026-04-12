import io
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from app.domain.models import Lead
from app.infrastructure.database import get_db

router = APIRouter()


class LeadCreate(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    whatsapp: str
    source: str = "ai_analysis"


@router.post("", status_code=201)
def create_lead(data: LeadCreate, db: Session = Depends(get_db)):
    lead = Lead(
        first_name=data.first_name,
        last_name=data.last_name,
        email=data.email,
        whatsapp=data.whatsapp,
        source=data.source,
    )
    db.add(lead)
    db.commit()
    return {"ok": True}


@router.get("/export")
def export_leads(db: Session = Depends(get_db)):
    try:
        import openpyxl
    except ImportError:
        raise HTTPException(status_code=500, detail="openpyxl not installed")

    leads = db.query(Lead).order_by(Lead.created_at.desc()).all()

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Leads"

    headers = ["ID", "Имя", "Фамилия", "Email", "WhatsApp", "Источник", "Дата"]
    ws.append(headers)

    # Bold header
    from openpyxl.styles import Font
    for cell in ws[1]:
        cell.font = Font(bold=True)

    for lead in leads:
        ws.append([
            lead.id,
            lead.first_name,
            lead.last_name,
            lead.email,
            lead.whatsapp,
            lead.source,
            lead.created_at.strftime("%Y-%m-%d %H:%M") if lead.created_at else "",
        ])

    # Auto column width
    for col in ws.columns:
        max_len = max(len(str(cell.value or "")) for cell in col)
        ws.column_dimensions[col[0].column_letter].width = min(max_len + 4, 50)

    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)

    filename = f"leads_{datetime.utcnow().strftime('%Y%m%d_%H%M')}.xlsx"
    return StreamingResponse(
        buf,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
