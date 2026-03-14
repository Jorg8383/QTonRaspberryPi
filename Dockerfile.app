FROM qtcrossbuild:latest

# Use bash and enable pipefail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG APP_DIR=project
ARG BUILD_TYPE=Release

WORKDIR /build/app

# Copy application sources
COPY ${APP_DIR}/ /build/app/

# Configure and build the application
RUN /build/qt6/pi/bin/qt-cmake . -DCMAKE_BUILD_TYPE=${BUILD_TYPE} && \
    cmake --build . --parallel $(nproc)

# Show build directory contents and detect executables
RUN echo "Build directory contents:" && \
    ls -lh /build/app && \
    echo "Detected executables:" && \
    find /build/app -type f -executable -exec file {} \;