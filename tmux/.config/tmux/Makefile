CONFIG_HOME := ${HOME}/.config
PLUGINS_HOME := ${HOME}/.tmux

clean:
	rm -rf ${PLUGINS_HOME}/plugins

install:
	-git clone https://github.com/tmux-plugins/tpm ${PLUGINS_HOME}/plugins/tpm
	cd ${PLUGINS_HOME}
	${PLUGINS_HOME}/plugins/tpm/scripts/install_plugins.sh

link:
	ln -s "$$(pwd)" ${CONFIG_HOME}/

force-link:
	ln -sf "$$(pwd)" ${CONFIG_HOME}/

all: link install

force: clean force-link install

.PHONY: all clean force-link install link
