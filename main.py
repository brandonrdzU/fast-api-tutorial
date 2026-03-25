from io import BytesIO
from typing import Union

import pytesseract
from PIL import Image, UnidentifiedImageError
from fastapi import FastAPI, File, HTTPException, UploadFile
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float
    is_offer: Union[bool, None] = None

@app.get("/")
async def health_check():
    return {"status": "healthy", "message": "FastAPI OCR API is running"}


@app.get("/items/{item_id}")
async def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}

@app.post("/items/")
async def create_item(item: Item):
    return item

@app.put("/items/{item_id}")
async def update_item(item_id: int, item: Item):
    return {"item_name": item.name, "item_id": item_id}

@app.post("/ocr")
async def ocr_endpoint(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    try:
        image_bytes = await file.read()
        image = Image.open(BytesIO(image_bytes))

        ocr_data = pytesseract.image_to_data(
            image,
            output_type=pytesseract.Output.DICT,
        )

        words = [word.strip() for word in ocr_data["text"] if word.strip()]
        return {"words": words}

    except UnidentifiedImageError as exc:
        raise HTTPException(status_code=400, detail="Invalid image") from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"OCR processing error: {exc}") from exc