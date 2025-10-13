#!/bin/sh
#
# generate-personal-pricing.sh
# Generates personalized pricing PDF by replacing placeholders in template
#
# Usage: generate-personal-pricing.sh NAME EMAIL TEMPLATE_PATH

set -e

# Parse positional arguments
NAME="$1"
EMAIL="$2"
TEMPLATE_PATH="$3"

# Validate required arguments
if [ -z "$NAME" ] || [ -z "$EMAIL" ] || [ -z "$TEMPLATE_PATH" ]; then
    echo "ERROR: Missing required arguments" >&2
    echo "Usage: $0 NAME EMAIL TEMPLATE_PATH" >&2
    exit 1
fi

# Validate template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "ERROR: Template file not found: $TEMPLATE_PATH" >&2
    exit 1
fi

# Generate unique nonce for filename
NONCE="$(date +%s)-$$-$RANDOM"

# Output directory and filename
OUTPUT_DIR="/var/www/sewercide/www/static"
OUTPUT_FILE="${OUTPUT_DIR}/generated-${NONCE}.pdf"
OUTPUT_FILENAME="generated-${NONCE}.pdf"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Log to syslog
logger -t sewercide-generator "Generating PDF: NAME='$NAME', EMAIL='$EMAIL', OUTPUT='$OUTPUT_FILE'"

# Copy template to destination
cp "$TEMPLATE_PATH" "$OUTPUT_FILE"

# Create temporary file for sed operations
TEMP_FILE="${OUTPUT_FILE}.tmp"

# Replace NAME_PLACEHOLDER with actual name
sed "s|NAME_PLACEHOLDER|$NAME|g" "$OUTPUT_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$OUTPUT_FILE"

# Replace EMAIL_PLACEHOLDER with actual email
sed "s|EMAIL_PLACEHOLDER|$EMAIL|g" "$OUTPUT_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$OUTPUT_FILE"

# Set appropriate permissions
chmod 0644 "$OUTPUT_FILE"

# Output filename for web server
echo "$OUTPUT_FILENAME"

logger -t sewercide-generator "PDF generated successfully: $OUTPUT_FILE"

exit 0
