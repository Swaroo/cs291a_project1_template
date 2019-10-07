FROM python:3

ADD requirements.txt /

ADD words /

RUN pip install -r requirements.txt

ADD project1.py /

CMD [ "python", "./project1.py","https://pt8io3o0ng.execute-api.us-west-2.amazonaws.com/prod/"]
