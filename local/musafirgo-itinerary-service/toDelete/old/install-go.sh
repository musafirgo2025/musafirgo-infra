#!/bin/bash
# Script d'installation automatique de Go pour Linux/macOS

echo "=== Installation de Go pour MusafirGO Pipeline ==="

# Vérifier si Go est déjà installé
if command -v go &> /dev/null; then
    echo "✅ Go est déjà installé: $(go version)"
    echo "Vous pouvez maintenant exécuter: ./build-and-run.sh"
    exit 0
fi

# Détecter l'OS
OS=""
ARCH=""
GO_VERSION="1.21.5"

case "$(uname -s)" in
    Linux*)
        OS="linux"
        ;;
    Darwin*)
        OS="darwin"
        ;;
    *)
        echo "❌ OS non supporté: $(uname -s)"
        echo "Veuillez installer Go manuellement depuis: https://golang.org/dl/"
        exit 1
        ;;
esac

case "$(uname -m)" in
    x86_64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "❌ Architecture non supportée: $(uname -m)"
        echo "Veuillez installer Go manuellement depuis: https://golang.org/dl/"
        exit 1
        ;;
esac

echo "🔍 OS détecté: $OS"
echo "🔍 Architecture détectée: $ARCH"

# URL de téléchargement
GO_URL="https://go.dev/dl/go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
GO_FILE="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
GO_INSTALL_DIR="/usr/local"

echo "📥 Téléchargement de Go $GO_VERSION..."

# Télécharger Go
if command -v wget &> /dev/null; then
    wget -O "$GO_FILE" "$GO_URL"
elif command -v curl &> /dev/null; then
    curl -L -o "$GO_FILE" "$GO_URL"
else
    echo "❌ wget ou curl requis pour télécharger Go"
    exit 1
fi

if [ ! -f "$GO_FILE" ]; then
    echo "❌ Erreur lors du téléchargement de Go"
    exit 1
fi

echo "✅ Téléchargement terminé"

# Vérifier les permissions sudo
if [ "$EUID" -ne 0 ]; then
    echo "🔐 Installation nécessite des privilèges sudo..."
    SUDO_CMD="sudo"
else
    SUDO_CMD=""
fi

echo "🔧 Installation de Go..."

# Supprimer l'ancienne installation si elle existe
$SUDO_CMD rm -rf "$GO_INSTALL_DIR/go"

# Extraire Go
$SUDO_CMD tar -C "$GO_INSTALL_DIR" -xzf "$GO_FILE"

# Nettoyer le fichier téléchargé
rm "$GO_FILE"

echo "✅ Installation terminée"

# Configurer le PATH
echo "⚙️  Configuration du PATH..."

# Ajouter Go au PATH pour la session actuelle
export PATH="$GO_INSTALL_DIR/go/bin:$PATH"

# Ajouter Go au PATH de manière permanente
SHELL_CONFIG=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -f "$HOME/.profile" ]; then
    SHELL_CONFIG="$HOME/.profile"
fi

if [ -n "$SHELL_CONFIG" ]; then
    if ! grep -q "go/bin" "$SHELL_CONFIG"; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Go" >> "$SHELL_CONFIG"
        echo "export PATH=\"$GO_INSTALL_DIR/go/bin:\$PATH\"" >> "$SHELL_CONFIG"
        echo "export GOPATH=\"\$HOME/go\"" >> "$SHELL_CONFIG"
        echo "export GOROOT=\"$GO_INSTALL_DIR/go\"" >> "$SHELL_CONFIG"
        echo "✅ Configuration ajoutée à $SHELL_CONFIG"
    fi
fi

# Créer le répertoire de travail Go
mkdir -p "$HOME/go"
echo "📁 Répertoire Go créé: $HOME/go"

# Vérifier l'installation
if command -v go &> /dev/null; then
    echo "✅ Go installé avec succès: $(go version)"
else
    echo "⚠️  Go installé mais pas encore disponible dans le PATH"
    echo "Veuillez redémarrer votre terminal ou exécuter:"
    echo "export PATH=\"$GO_INSTALL_DIR/go/bin:\$PATH\""
fi

echo ""
echo "🎉 Installation de Go terminée avec succès !"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Redémarrez votre terminal"
echo "2. Exécutez: ./build-and-run.sh"
echo "3. Ou testez avec: go version"
echo ""
echo "=== INSTALLATION TERMINÉE ==="
