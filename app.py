from fastapi import Request, HTTPException, RedirectResponse
from fastapi.responses import templates

@app.get("/vps/add")
async def add_vps_form(request: Request):
    """显示添加 VPS 表单"""
    return templates.TemplateResponse("add_vps.html", {"request": request})

@app.get("/vps/{vps_id}/edit")
async def edit_vps_form(request: Request, vps_id: int):
    """显示编辑 VPS 表单"""
    vps = get_vps_by_id(vps_id)
    if not vps:
        raise HTTPException(status_code=404, detail="VPS not found")
    return templates.TemplateResponse("edit_vps.html", {"request": request, "vps": vps})

@app.post("/vps")
async def create_vps(request: Request):
    """创建新的 VPS"""
    form = await request.form()
    # ... 处理表单数据 ...
    return RedirectResponse(url="/", status_code=303)

@app.post("/vps/{vps_id}")
async def update_vps(request: Request, vps_id: int):
    """更新现有的 VPS"""
    form = await request.form()
    # ... 处理表单数据 ...
    return RedirectResponse(url="/", status_code=303) 