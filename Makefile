PROJECT_NAME := MacWidgetBoilerplate

.PHONY: generate open clean bootstrap

generate:
	@command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen no esta instalado. Ejecuta: brew install xcodegen"; exit 1; }
	xcodegen generate

open: generate
	open $(PROJECT_NAME).xcodeproj

clean:
	rm -rf $(PROJECT_NAME).xcodeproj

bootstrap: open
