FROM apache/airflow:3.1.7
ADD requirements.txt .
RUN pip install -r requirements.txt

USER root
RUN /home/airflow/.local/bin/playwright install-deps
USER airflow
RUN /home/airflow/.local/bin/playwright install