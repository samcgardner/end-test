FROM python:3.7.2

COPY configuration /config
COPY media /media
COPY src /src
COPY requirements.txt /etc/requirements.txt

RUN pip install --user /etc/requirements.txt

ENTRYPOINT python src/HelloWorld.py
