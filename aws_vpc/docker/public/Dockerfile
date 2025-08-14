FROM ubuntu

COPY app.py /app/
COPY requirements.txt /app/

WORKDIR /app/

RUN apt update
RUN apt install -y python3-pip
RUN pip install --break-system-packages uv
RUN uv pip install --system --break-system-packages -r requirements.txt

ENTRYPOINT ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80", "--reload"]
