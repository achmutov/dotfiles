all:
	ln -s "$$(pwd)/.zshrc" "$$HOME/.zshrc"
	ln -s "$$(pwd)/.zsh_aliases" "$$HOME/.zsh_aliases"
	ln -s "$$(pwd)/.zshenv" "$$HOME/.zshenv"
	mkdir -p ~/.zsh
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

force:
	ln -sf "$$(pwd)/.zshrc" "$$HOME/.zshrc"
	ln -sf "$$(pwd)/.zsh_aliases" "$$HOME/.zsh_aliases"
	ln -sf "$$(pwd)/.zshenv" "$$HOME/.zshenv"
	rm -rf ~/.zsh
	mkdir ~/.zsh
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

.PHONY: all force
