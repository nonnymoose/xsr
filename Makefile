SHELL:=/bin/bash -eo pipefail

TEST_ARGS=--help

.PHONY: all
all: test maint xsr docker-image

.PHONY: test
test: test-help test-record

test-help: xsr
	./$< $(TEST_ARGS) 2>&1 1>/dev/null | [[ `tee >(cat >&2) | wc -c` -eq 0 ]]

test-record: docker-image .Xauthority
	( \
		touch $(RECORDING_FILE) && inotifywait -e OPEN $(RECORDING_FILE) \
		&& echo "Received wait event. Simulating a click and ending record" \
		&& sleep 1 && xdotool click 1 \
		&& sleep 0.2 && xdotool key Shift+Pause \
		&& xdotool click 1 \
	) & \
	( \
		sleep 0.5 && timeout --foreground 5 $(MAKE) run | tee >(cat >&2) | ( ! grep 'at /usr/bin/xsr line' ) \
	)

.PHONY: maint
maint: README.md

README.md: xsr README.md.m4 markdown-preset.m4
	m4 --prefix-builtins markdown-preset.m4 \
		README.md.m4 > README.md

DOCKER=docker

DOCKER_TAG=xsr
.PHONY: docker-image
docker-image: Dockerfile
	$(DOCKER) build . -t $(DOCKER_TAG)

X_SOCKET=/tmp/.X11-unix
DOCKER_XAUTHORITY=.Xauthority
ARGS=--no-countdown
RECORDING_FILE=record.html
$(RECORDING_FILE): docker-image $(X_SOCKET) $(DOCKER_XAUTHORITY)
	touch $@
# Getting realpath for $@ needs to be done at shell level, because else it would get touched after make expansion is done
	$(DOCKER) run -it --rm \
		-v $(realpath $(X_SOCKET)):$(realpath $(X_SOCKET)) \
		-v $(realpath $(DOCKER_XAUTHORITY)):/tmp/imported.Xauthority \
		-v "`realpath $@`":/tmp/record.html \
		-e DISPLAY=$(DISPLAY) \
		-e XAUTHORITY=/tmp/imported.Xauthority \
		$(DOCKER_TAG) /tmp/record.html $(ARGS)

.PHONY: run
# syntactic sugar
run: $(RECORDING_FILE)

# https://stackoverflow.com/questions/16296753/can-you-run-gui-apps-in-a-docker-container/25280523#25280523
.Xauthority:
	touch $@
	xauth nlist :0 | sed -e 's/^..../ffff/' | tee >(cat >&2) | xauth -f $@ nmerge -

.PHONY: open-record
open-record: $(RECORDING_FILE)
	xdg-open $<

.PHONY: maint-clean
maint-clean: clean
	-rm README.md

.PHONY: clean
clean: mostlyclean
	-$(DOCKER) rmi $(DOCKER_TAG)

.PHONY: mostlyclean
mostlyclean:
	-rm record.html
	-rm .Xauthority
