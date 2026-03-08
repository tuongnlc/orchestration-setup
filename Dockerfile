FROM apache/airflow:3.1.7
ADD requirements.txt .
RUN pip install apache-airflow==${AIRFLOW_VERSION} -r requirements.txt

USER root
ENV PYTHONPATH=/home/airflow/.local/lib/python3.12/site-packages
RUN /home/airflow/.local/bin/playwright install-deps
USER airflow
RUN /home/airflow/.local/bin/playwright install