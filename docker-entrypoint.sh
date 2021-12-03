#!/bin/sh
set -e

VSFTPD_DIR=/home/vsftpd

touch /var/log/vsftpd.log
tail -f /var/log/vsftpd.log > /dev/stdout &

# Setup s3fs-fuse access keys
echo "$ACCESS_KEY_ID:$SECRET_ACCESS_KEY" > /etc/passwd-s3fs
chmod 600 /etc/passwd-s3fs

# Parse settings
USER_CONFIGS=$(env | grep -E '^(S3FTP_USER_[A-Z\d]+)=' | cut -f2 -d'=' | cut -f2 -d'"' )
BUCKETS=$(echo "$USER_CONFIGS" |  awk -F' \\|\\|\\| ' '{print $3}' | cut -d'/' -f1 | sort -u)

# Mount all buckets
BUCKET_DIR="$VSFTPD_DIR/buckets"
mkdir "$BUCKET_DIR"
chown -R vsftpd:vsftpd "$BUCKET_DIR"

echo "$BUCKETS" | while read -r BUCKET; do
    mkdir "$BUCKET_DIR/$BUCKET"
    chmod 750 "$BUCKET_DIR/$BUCKET"
    s3fs "$BUCKET" "$BUCKET_DIR/$BUCKET" -o uid=$(id -u vsftpd),gid=$(id -G vsftpd),allow_other,umask=027

    echo "Mounted \"$BUCKET\" bucket to $BUCKET_DIR/$BUCKET"
  done

#Setup users
PASSWD_FILE="$HOME/vsftpd.passwd"
touch "$PASSWD_FILE"

USERS_CONFIG_DIR="$HOME/user_config"
mkdir "$USERS_CONFIG_DIR"

echo "$USER_CONFIGS" | while read -r ENTRY; do
    USERNAME=$(echo "$ENTRY" |  awk -F' \\|\\|\\| ' '{print $1}')
    PASSWORD_PLAIN=$(echo "$ENTRY" |  awk -F' \\|\\|\\| ' '{print $2}')
    PASSWORD=$(openssl passwd -1 "$PASSWORD_PLAIN")
    BUCKET_PATH=$(echo "$ENTRY" |  awk -F' \\|\\|\\| ' '{print $3}')
    LOCAL_ROOT="$BUCKET_DIR/$BUCKET_PATH"
    echo "$USERNAME:$PASSWORD" >> "$PASSWD_FILE" # Setup password


    mkdir -p "$LOCAL_ROOT" #Ensure folder exists
    echo "local_root=$LOCAL_ROOT" > "$USERS_CONFIG_DIR/$USERNAME" # Setup user's root dir

    echo "FTP user setup: $USERNAME -> $BUCKET_PATH"
  done

chmod 600 "$PASSWD_FILE"
#END Login Setup

#Setup passive IP address
IP_ADDRESS=$(curl -s ifconfig.me)
sed -i -e '/pasv_address=/ s/=.*/='$IP_ADDRESS'/' /root/vsftpd.conf

exec "$@"
