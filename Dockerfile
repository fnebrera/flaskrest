FROM python:3.10.9-slim-bullseye

WORKDIR /usr/src/app
RUN pip install virtualenv
RUN virtualenv env
RUN . env/bin/activate
COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY . .
RUN chmod +x run.sh

CMD [ "./run.sh" ]
