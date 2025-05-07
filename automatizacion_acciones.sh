# Toda la información contenida en el script de abajo podrá ser susceptible de ser cambiada si en algún momento hemos cambiado el nombre de alguno de los archivos principales. El nombre que aparece es aquel por defecto en la descarga de Wordpress
#!/bin/bash

WP_PATH="/var/www/html"  # Deberemos ajustar las rutas o nombres de archivos a nuestro caso concreto. Esta ruta suele ser la determinada en sistemas como Ubuntu, pero podría cambiar

echo "[1/5] Estableciendo permisos seguros para directorios y archivos..."
find $WP_PATH -type d -exec chmod 755 {} \;
find $WP_PATH -type f -exec chmod 644 {} \;

echo "[2/5] Deshabilitando edición desde el panel de WordPress..."
if ! grep -q "DISALLOW_FILE_EDIT" "$WP_PATH/wp-config.php"; then
    echo "define('DISALLOW_FILE_EDIT', true);" >> "$WP_PATH/wp-config.php"
fi

echo "[3/5] Reemplazando claves SALT en wp-config.php..."
curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/salts.txt
sed -i '/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d' "$WP_PATH/wp-config.php"
cat /tmp/salts.txt >> "$WP_PATH/wp-config.php"
rm /tmp/salts.txt

echo "[4/5] Bloqueando ejecución PHP en uploads, plugins y themes..."
for dir in uploads plugins themes; do
    mkdir -p "$WP_PATH/wp-content/$dir"
    echo -e "<Files *.php>\ndeny from all\n</Files>" > "$WP_PATH/wp-content/$dir/.htaccess"
done

echo "[5/5] Bloqueando acceso a xmlrpc.php..."
if [ -f "$WP_PATH/.htaccess" ]; then
    if ! grep -q "xmlrpc.php" "$WP_PATH/.htaccess"; then
        echo -e "\n<Files xmlrpc.php>\nOrder Deny,Allow\nDeny from all\n</Files>" >> "$WP_PATH/.htaccess"
    fi
else
    echo -e "<Files xmlrpc.php>\nOrder Deny,Allow\nDeny from all\n</Files>" > "$WP_PATH/.htaccess"
fi

echo "✅ Hardening completado con éxito."
