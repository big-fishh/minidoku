from fastapi import FastAPI
import json

app = FastAPI()

with open('puzzles.json', 'r',encoding='utf-8') as file:
    data = json.load(file)

body = {"puzzle":data[0]["grid"], "solution":data[0]["solution"]}

@app.get("/")
async def root():
    # return {"message": "Hello World"}
    return body