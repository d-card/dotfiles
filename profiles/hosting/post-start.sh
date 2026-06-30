#!/bin/sh
# Pterodactyl post-start fixup — branding, theme, env lock, cache perms

# ---- Branding ----
# Set app name
grep -v APP_NAME /app/.env > /tmp/.env-name
echo APP_NAME=Zentryx >> /tmp/.env-name
cp /tmp/.env-name /app/.env

# Replace footer copyright
sed -i "s|.*Copyright.*Pterodactyl.*|                Zentryx Hosting — Game Servers \\& VPS Portugal|" \
  /app/resources/views/layouts/admin.blade.php

# ---- Environment lock ----
cp /tmp/.env-clean /app/.env

# ---- Theme ----
CSS=/app/public/themes/pterodactyl/css/custom.css

# Replace AdminLTE blue skin
cp "$CSS" /app/public/themes/pterodactyl/vendor/adminlte/colors/skin-blue.min.css

# Inject inline style into all blade templates
for f in $(find /app/resources/views -name "*.blade.php"); do
  if grep -q "</head>" "$f" && ! grep -q "Zentryx" "$f"; then
    sed -i "s|</head>|<style>$(cat "$CSS")</style></head>|" "$f"
  fi
done

# ---- Fix permissions and clear cache ----
chmod -R 777 /app/storage/framework/cache /app/bootstrap/cache 2>/dev/null
php artisan view:clear 2>/dev/null
php artisan config:clear 2>/dev/null
