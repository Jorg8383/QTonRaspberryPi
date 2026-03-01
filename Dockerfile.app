FROM qtcrossbuild:latest

WORKDIR /build/project

COPY project/ /build/project/

RUN /build/qt6/pi/bin/qt-cmake . -DCMAKE_BUILD_TYPE=Release && cmake --build .