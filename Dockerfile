ARG BASE_IMAGE=git.lan/dev/npm:latest
FROM ${BASE_IMAGE}

ENV ANDROID_ADB_SERVER_ADDRESS=host.docker.internal

ENV WEBKIT_DISABLE_COMPOSITING_MODE=1
ENV ANDROID_HOME=/home/${USER_NAME}/Android/Sdk
ENV ANDROID_SDK_ROOT=/home/${USER_NAME}/Android/Sdk
ENV NDK_HOME="${ANDROID_HOME}/ndk/27.0.12077973"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/35.0.0:$PATH"

USER root

RUN apt update &&\
  apt install -y \
  x11-apps rustup xdg-utils file \
  libwebkit2gtk-4.1-dev libxdo-dev libssl-dev \
  libayatana-appindicator3-dev librsvg2-dev libcanberra-gtk3-module openjdk-17-jdk-headless

USER ${USER_NAME}

EXPOSE 1420

RUN rustup default stable &&\
  rustup target add x86_64-unknown-linux-gnu aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android &&\
  # Watchman
  wget https://github.com/facebook/watchman/releases/download/v2025.05.26.00/watchman-v2025.05.26.00-linux.zip &&\
  unzip watchman-v2025.05.26.00-linux.zip &&\
  cd watchman-v2025.05.26.00-linux &&\
  # Android
  mkdir -p ${ANDROID_HOME}/cmdline-tools ${ANDROID_HOME}/build-tools ${ANDROID_HOME}/ndk ${ANDROID_HOME}/platforms &&\
  wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip &&\
  unzip commandlinetools-linux-13114758_latest.zip -d /home/${USER_NAME}/Android/Sdk/cmdline-tools/ &&\
  rm commandlinetools-linux-13114758_latest.zip &&\
  mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest &&\
  yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses &&\
  yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973" &&\
  echo 'export PATH="$PATH:${ANDROID_HOME}/platform-tools"' >> /home/${USER_NAME}/.bashrc

USER root

RUN mkdir -p /usr/local/bin /usr/local/lib /usr/local/var/run/watchman &&\
  cp /home/${USER_NAME}/watchman-v2025.05.26.00-linux/bin/* /usr/local/bin &&\
  cp /home/${USER_NAME}/watchman-v2025.05.26.00-linux/lib/* /usr/local/lib &&\
  chmod 755 /usr/local/bin/watchman &&\
  chmod 2777 /usr/local/var/run/watchman

USER ${USER_NAME}

WORKDIR /home/${USER_NAME}
