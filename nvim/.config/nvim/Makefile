all:
	ln -s "$$(pwd)" "$$HOME/.config/nvim"
	-nvim --headless "+Lazy! sync" +qa

force:
	ln -sf "$$(pwd)" "$$HOME/.config/nvim"
	-nvim --headless "+Lazy! sync" +qa

.PHONY: all force
