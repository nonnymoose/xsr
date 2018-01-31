FROM ubuntu
RUN apt-get update && apt-get install -y --no-install-recommends \
	perl \
# Unfortunately installing HTML::Entities using cpanm requires installing gcc and libc-dev by hand
	cpanminus gcc libc-dev \
	make \
	scrot xinput x11-xserver-utils imagemagick xdotool \
	&& rm -rf /var/lib/apt/lists/*

COPY xsr /usr/bin/xsr
COPY Cursor.png /usr/share/xsr/Cursor.png
ENTRYPOINT ["/usr/bin/xsr"]

RUN ["cpanm", "HTML::Entities"]
