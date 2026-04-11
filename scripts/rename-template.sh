#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  cat <<'EOF'
Usage: ./scripts/rename-template.sh <ProjectName> <BundlePrefix> [AppGroupID]

Example:
  ./scripts/rename-template.sh DeskStats dev.cledesmc group.dev.cledesmc.deskstats
EOF
  exit 1
fi

project_name="$1"
bundle_prefix="$2"
project_slug="$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]')"
app_group_id="${3:-group.${bundle_prefix}.${project_slug}}"

if [[ ! "$project_name" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
  echo "ProjectName debe ir en PascalCase o camelCase y sin espacios." >&2
  exit 1
fi

if [[ ! "$bundle_prefix" =~ ^[A-Za-z0-9.-]+$ ]]; then
  echo "BundlePrefix solo debe contener letras, numeros, puntos o guiones." >&2
  exit 1
fi

old_project_name="MacWidgetBoilerplate"
old_app_bundle_id="com.example.MacWidgetBoilerplate"
old_widget_bundle_id="com.example.MacWidgetBoilerplate.Widget"
old_app_group_id="group.com.example.macwidgetboilerplate"

new_app_bundle_id="${bundle_prefix}.${project_name}"
new_widget_bundle_id="${new_app_bundle_id}.Widget"

files=(
  "Makefile"
  "README.md"
  "project.yml"
  "WidgetTemplate/App/WidgetTemplateApp.swift"
  "WidgetTemplate/Widget/TemplateWidget.swift"
  "WidgetTemplate/Widget/TemplateWidgetBundle.swift"
  "WidgetTemplate/Shared/WidgetTemplateConfig.swift"
)

for file in "${files[@]}"; do
  LC_ALL=C LANG=C perl -0pi -e "s/\Q${old_widget_bundle_id}\E/${new_widget_bundle_id}/g; s/\Q${old_app_bundle_id}\E/${new_app_bundle_id}/g; s/\Q${old_project_name}\E/${project_name}/g; s/\Q${old_app_group_id}\E/${app_group_id}/g;" "$file"
done

echo "Template actualizada."
echo "Project name: ${project_name}"
echo "App bundle id: ${new_app_bundle_id}"
echo "Widget bundle id: ${new_widget_bundle_id}"
echo "App Group: ${app_group_id}"
echo "Siguiente paso: make open"
