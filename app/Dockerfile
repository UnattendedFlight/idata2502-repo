# use slim image for a lightweight base
FROM python:3.11-slim

# use /app as the working directory for the content of the container
WORKDIR /app

# copy the requirements into the /app
COPY requirements.txt .

# install the requirements on system python of the contianer
RUN pip install --no-cache-dir -r requirements.txt

# copy only app.py into /app in the container
# could use "COPY . ."  but once the project grows its better to have control of layers
# and order based on what is most frequently changed/modified. Recomputing every layer gets expensive fast, and the least frequently changed
# or most depended on things should be earlier layers.
COPY app.py .

# build info is injected at build timje and read from the environment
ARG BUILD_VERSION=debug
ARG BUILD_TYPE=debug
ARG BUILD_TIME=debug
ARG BUILD_COMMIT=debug
ARG BUILD_BRANCH=debug
ARG BUILD_DIRTY=debug
ENV BUILD_VERSION=$BUILD_VERSION \
    BUILD_TYPE=$BUILD_TYPE \
    BUILD_TIME=$BUILD_TIME \
    BUILD_COMMIT=$BUILD_COMMIT \
    BUILD_BRANCH=$BUILD_BRANCH \
    BUILD_DIRTY=$BUILD_DIRTY

# expose flask serve port
EXPOSE 5000

# serve the flask app
# for now use flask serve, ona later pr i should porbably use uvicorn or similar wsgi/asgi with nginx to serve
CMD ["python", "app.py"]
